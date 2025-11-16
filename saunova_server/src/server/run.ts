import os from "os";
import express, { Router, Request, Response, NextFunction } from "express";
import cors from "cors";
import { res_success } from "../models/res_functions";
import { logInfo } from "../utils/logger";
import { initFirebase } from "../utils/firebase";
import http from "http";
import { connectDB } from "../utils/mongodb";
import { logError } from "../utils/logger";
import { PORT, IP } from "../utils/config";
import r_auth from "../app/auth/r_auth";
import r_image from "../app/image/r_image";
import r_sauna from "../app/sauna/r_sauna";
import r_chat from "../app/chat/r_chat";
import { Bridge } from "../python_bridge/bridge";
import { SessionModel } from "../models/mongodb/m_session";
import { UserModel } from "../models/mongodb/m_user";

function getLocalIP(): string {
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === "IPv4" && !iface.internal) {
        return iface.address;
      }
    }
  }
  return "127.0.0.1"; // fallback
}

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(
  cors({
    origin: "*", // TODO: tighten for production
  })
);

const router = Router();
router.get("/ping", (req: Request, res: Response) =>
  res_success(res, {
    status: "ok",
  })
);

router.post("/python", (req: Request, res: Response) => {
  try {
    const {
      start,
      stop,
      humidity,
      elapsed,
      uid,
      temperature,
      brief,
      axis_data,
    } = req.body;
    const session = SessionModel.createSession(
      uid,
      elapsed,
      humidity,
      new Date(start),
      new Date(stop),
      temperature,
      brief,
      axis_data
    );
    return res_success(res, { status: "session logged" });
  } catch (error) {
    logError("Error in /python endpoint", "SERVER");
    res.status(500).json({ error: "Internal Server Error" });
  }
});

app.use((req: Request, res: Response, next: NextFunction) => {
  const formattedTime = new Date().toTimeString().split(" ")[0].slice(0, 8);
  logInfo(`[${formattedTime}] ${req.method} ${req.path}`, "REQUEST");
  next();
});

app.use(router);
app.use("/auth", r_auth);
app.use("/image", r_image);
app.use("/sauna", r_sauna);
app.use("/chat", r_chat);
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: "Not Found" });
});

initFirebase();

async function startServer() {
  try {
    const connection = await connectDB();
    if (!connection) {
      throw new Error("Database connection failed");
    }

    await Bridge.init();

    const server = http.createServer(app);

    server.listen(PORT, IP, () => {
      const localIP = getLocalIP();
      logInfo(`🚀 Server running at:`);
      logInfo(`   Local:   http://localhost:${PORT}`);
      logInfo(`   Network: http://${localIP}:${PORT}`);
    });

  } catch (error) {
    logError("❌ Failed to Start the Server", "SERVER");
    process.exit(1);
  }
}

startServer();
