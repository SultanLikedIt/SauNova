# Saunova-AI

**AI-driven sauna coaching with RAG chat and personalized recommendations**

[![Python](https://img.shields.io/badge/Python-3.10+-blue)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/FastAPI-Backend-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)
[![PyTorch](https://img.shields.io/badge/PyTorch-ML-EE4C2C?logo=pytorch&logoColor=white)](https://pytorch.org/)
[![LangChain](https://img.shields.io/badge/LangChain-RAG-1b6d8a)](https://python.langchain.com/)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-Bridge-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

Note: This repository has been moved here from another one due to privacy concerns. The current version here includes all the recent updates and is the main repository.

## 🎯 Project Overview
Saunova is an AI-first sauna companion. The backend combines retrieval-augmented generation over sauna science PDFs with a PyTorch model that personalizes temperature, humidity, and session length. A Flutter client consumes the APIs, and a lightweight TypeScript bridge handles auth and chat relay.

---

## 💡 Motivation
Safe sauna practice is nuanced (goals, physiology, setpoints). Saunova blends vetted research (via RAG) with data-driven recommendations so users can get personalized, explainable guidance instead of generic tips.

---

## ⚡ Key Features
- **RAG chat** grounded in uploaded sauna/wellness PDFs with session memory.
- **Personalized recommendations** for temp/humidity/session length via PyTorch.
- **Session telemetry briefing**: dual-axis plots + LLM narrative summary.
- **Mobile-first** Flutter experience; TypeScript bridge for auth/chat/image routes.
- **Analytics kit** to generate graphs that support model and retrieval quality.

---

## 🏗️ Architecture
Backend: FastAPI (`backend/src`) with chat, recommendation, and session routes.  
LLM stack: LangChain `ChatOpenAI` (`gpt-4o-mini` default) + FAISS retriever (HuggingFace `all-MiniLM-L6-v2` embeddings).  
Recommendation: PyTorch MLP predicting temperature/humidity/session length.  
Bridge: `saunova_server/` (Node/TS) for auth/chat relay and Python bridge.  
Client: `saunova_flutter/` Flutter app for chat, dashboard, sessions, social.

---

---

## 📊 Demonstration

STILL UNDER CONSTRUCTION

Incoming Changes:
- Marketing/Advertisement video
- Video demostration of the app in use

Possible Changes:
- RAG quality: top-k hit rate/MRR on a PDF-derived Q&A set; % answers citing retrieved docs; latency breakdown.  
- Recommendation: predicted vs actual plots, MAE per target, learning curves, feature/goal distributions.  
- Session telemetry: dual-axis time series with target setpoints, time-in-range %, ramp-up rates; attach LLM-generated briefs.  
- Synthetic data: distribution checks for HR/VO2/BP vs plausible ranges; sensitivity sweeps for BMI/goal changes.

---

## 🧠 Technical Overview
1) **Input**: User question or profile (age, height, weight, goals) and optional session telemetry.  
2) **Preprocessing**: PDF loading (`PyPDFLoader`), recursive chunking, HuggingFace embeddings, FAISS index.  
3) **ML/LLM**:  
   - RAG chain with history-aware retriever + QA chain (`backend/LLM/qa.py`).  
   - PyTorch MLP for recommendations (`predictive_model/neural_network.py`).  
4) **Postprocessing**: Session telemetry graph + LLM brief; bounded outputs for safe ranges.  
5) **Frontend Integration**: Flutter calls FastAPI endpoints; TypeScript bridge can relay chat/auth/image routes.

### Tech Stack
- **Backend**: Python, FastAPI, LangChain, OpenAI, FAISS, PyTorch, scikit-learn, pandas, numpy, matplotlib.  
- **Frontend**: Flutter (Dart), theming/widgets for chat/dashboard/sessions.  
- **Bridge**: Node/TypeScript (auth, chat relay, python bridge).  
- **Data**: PDFs for RAG, CSVs for recommendation, optional synthetic generation.

### Model Choices
- **LLM (chat)**: `gpt-4o-mini` for balance of cost/latency; prompt enforces citation of retrieved PDFs and safe fallbacks.  
- **Embeddings**: `sentence-transformers/all-MiniLM-L6-v2` for lightweight, high-recall retrieval.  
- **Vector store**: FAISS (CPU) persisted at `backend/LLM/data/faiss_index/`.  
- **Recommendation model**: 3-head regression MLP with batch norm, ReLU, dropout, Adam, LR scheduler, early stopping. Targets: best_temp, best_humidity, best_session. Features: age, BMI, body_mass, height, one-hot goal.
- **Synthetic data**: `synthetic_data_generation.py` to augment physiology/response signals when real data is sparse.

### Hyperparameters and Tuning
- Chunking: 500 chars, 50 overlap for PDF splits.
- Retrieval: top-k=3 via FAISS retriever.
- LLM: temperature=0, max_tokens=500, input capped at 3000 tokens.
- Recommendation training (default): 200 epochs, batch 32, lr 1e-3, weight_decay 1e-5, ReduceLROnPlateau, patience 20, 0.2 test / 0.1 val split.
- Prediction bounds: temp 60–100°C, humidity 5–25%, session 10–30 min.


---

## 🛠️ Installation & Quick Start
```bash
# Clone
git clone <repo-url>
cd saunova

# Backend setup
pip install -r backend/requirements.txt
export OPENAI_API_KEY=sk-...   # required for chat/RAG
uvicorn backend.src.main:app --reload --port 8000

# Flutter app
cd saunova_flutter
flutter pub get
flutter run

# TypeScript bridge (optional)
cd ../saunova_server
npm install
npm run dev
```

### LLM assets
- Ensure `backend/LLM/data/faiss_index/index.faiss` and `index.pkl` exist.  
- Rebuild index from PDFs: load PDFs → chunk → `build_faiss_index` → save (see `backend/LLM/faiss_indexing.py` and `backend/LLM/indexing.py`).

### Recommendation model
- Train: `python backend/predictive_model/train_model.py` (uses `optimal_sauna_settings_with_height.csv`).  
- Inference served via `/recommendations` and `SaunaRecommendationEngine.predict`.

### Graphs & analytics
- New helper: `backend/analytics/reporting.py` produces publish-ready plots.  
- Example:
  ```bash
  python backend/analytics/reporting.py \
    --csv backend/predictive_model/optimal_sauna_settings_with_height.csv \
    --model backend/predictive_model/sauna_recommendation_model.pth \
    --scaler backend/predictive_model/sauna_scaler.pkl \
    --output backend/analytics/outputs
  ```
- To visualize a session payload (from `/start_session` telemetry/brief):
  ```bash
  python backend/analytics/reporting.py --session-json path/to/session.json
  ```



## 🗂️ Project Structure
- `backend/` – FastAPI app, RAG stack, recommendation model, analytics.  
  - `src/` – routes, models, services, middleware.  
  - `LLM/` – chunking, PDF loading, FAISS indexing, QA chain.  
  - `predictive_model/` – PyTorch model, training, synthetic data.  
  - `analytics/` – `reporting.py` for graphs (outputs to `analytics/outputs/`).  
- `saunova_flutter/` – Flutter client (chat, sessions, social).  
- `saunova_server/` – Node/TypeScript bridge for auth/chat/image and Python bridge.  
- `README.md`, `LICENSE`.

---

## 🤝 Contributing
1) Fork and branch.  
2) Keep PRs focused (backend AI, data, or docs).  
3) Add context and sample commands in your PR description.

## 📄 License
MIT License. See `LICENSE`.

## 📬 Contact
**Uygar** – [uygar017@gmail.com](mailto:uygar017@gmail.com)  
GitHub: [https://github.com/SultanLikedIt](https://github.com/SultanLikedIt)

---

*Made by Uygar Yilmaz and Teammates for Junction AI Hackathon– Politecnico di Torino, Computer Engineering (Exp. Grad: 2027)*
