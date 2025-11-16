import { Router } from "express";
// import { BRIDGE_URL } from "../utils/config";
import { UserModel } from "../models/mongodb/m_user";

const BRIDGE_URL = "http://0.0.0.0:41751";

export class Bridge {
  static router = Router();
  static ready = false;

  static async init() {
    try {
      const response = await fetch(BRIDGE_URL + "/health");
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();

      if (data["status"] === "ok") {
        this.ready = true;
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    }
  }

  static async getRecommendations(userId: string) {
    try {
      const userData = await UserModel.findByFirebaseID(userId);
      if (!userData) {
        throw new Error("User not found");
      }
      const payload = {
        age: userData.age,
        gender: userData.gender,
        height: userData.height,
        weight: userData.weight,
        goals: userData.goals,
      };

      const response = await fetch(`${BRIDGE_URL}/sauna/recommendations`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await response.json();
      return data;
    } catch (error) {
      console.error("Error fetching recommendations:", error);
    }
  }

  static start_session(
    temperature: number,
    humidity: number,
    session_length: number,
    uid: string
  ) {
    const payload = { temperature, humidity, session_length, uid };
    console.log("Starting session with payload:", payload);

    // Fire-and-forget with catch
    fetch(`${BRIDGE_URL}/sauna/start_session`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    }).catch((err) => {
      console.warn("Non-fatal start_session fetch error:", err);
    });
  }

  static async end_session() {
    try {
      const response = await fetch(`${BRIDGE_URL}/sauna/end_session`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });

      const data = await response.json();
      return data;
    } catch (error) {
      console.error("Error ending session:", error);
    }
  }

  static async ask(question: string) {
    try {
      const payload = { question: question };

      const response = await fetch(`${BRIDGE_URL}/chat/ask`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      const data = await response.json();
      return data;
    } catch (error) {
      console.error("Error asking question:", error);
    }
  }
}
