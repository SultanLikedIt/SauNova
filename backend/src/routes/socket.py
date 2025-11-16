import json
import uuid

from fastapi import APIRouter, Request, HTTPException
from starlette.websockets import WebSocket, WebSocketDisconnect

from backend.LLM.qa import chat_stream
from backend.src.services.llm import faiss_index, qa_chain_streaming
from backend.src.utils.logger import get_logger

router = APIRouter()

logger = get_logger('websocket')


@router.websocket("/ws/echo")
async def websocket_echo(ws: WebSocket):
    await ws.accept()
    logger.info("WebSocket client connected")
    try:
        while True:
            text = await ws.receive_text()
            await ws.send_text(f"echo: {text}")
    except WebSocketDisconnect:
        logger.info("WebSocket client disconnected")


@router.websocket("/ws/chat")
async def websocket_chat(ws: WebSocket):
    await ws.accept()

    if not faiss_index or not qa_chain_streaming:
        await ws.send_json({
            "type": "error",
            "content": "Chat service is initializing. Please try again shortly."
        })
        await ws.close()
        return

    logger.info("Chat WebSocket client connected")

    try:
        while True:
            message = await ws.receive_text()
            try:
                payload = json.loads(message)
            except json.JSONDecodeError:
                await ws.send_json({
                    "type": "error",
                    "content": "Invalid message format. Expected JSON."
                })
                continue

            question = (payload.get("question") or "").strip()
            incoming_session_id = payload.get("session_id")
            session_id = incoming_session_id or str(uuid.uuid4())

            if not question:
                await ws.send_json({
                    "type": "error",
                    "content": "Question is required."
                })
                continue

            await ws.send_json({
                "type": "session_init",
                "session_id": session_id
            })

            async for chunk in chat_stream(
                qa_chain_streaming,
                question,
                session_id=session_id
            ):
                try:
                    await ws.send_json(chunk)
                except Exception as send_err:
                    logger.error(f"Error sending chunk over WebSocket: {send_err}", exc_info=True)
                    break

    except WebSocketDisconnect:
        logger.info("Chat WebSocket client disconnected")
    except Exception as e:
        logger.error(f"WebSocket chat error: {e}", exc_info=True)
        try:
            await ws.send_json({
                "type": "error",
                "content": f"Server error: {str(e)}"
            })
        except Exception:
            pass