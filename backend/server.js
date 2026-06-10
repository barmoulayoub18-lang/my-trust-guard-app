import express from "express";
import axios from "axios";
import cors from "cors";
import dotenv from "dotenv";
import { scanLink } from "./services/link_scanner.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const SERPER_URL = "https://google.serper.dev/search";
const AI_URL = "https://openrouter.ai/api/v1/chat/completions";

const cache = new Map();

function logStep(step, data = null) {
  const time = new Date().toISOString();
  console.log(`\n🟡 [${time}] ${step}`);
  if (data) {
    console.log("➡️", JSON.stringify(data, null, 2));
  }
}

function getCache(key) {
  const item = cache.get(key);
  if (!item) return null;

  if (Date.now() > item.expiry) {
    cache.delete(key);
    return null;
  }

  logStep("CACHE HIT", key);
  return item.data;
}

function setCache(key, data, ttl = 1000 * 60 * 10) {
  cache.set(key, {
    data,
    expiry: Date.now() + ttl,
  });
}

async function searchGoogle(query) {
  logStep("STEP 1: GOOGLE SEARCH START", { query });

  const cached = getCache("search_" + query);
  if (cached) return cached;

  try {
    const res = await axios.post(
      SERPER_URL,
      {
        q: query,
        gl: "us",
        hl: "en",
        num: 5,
      },
      {
        headers: {
          "X-API-KEY": process.env.SERPER_KEY,
          "Content-Type": "application/json",
        },
        timeout: 10000,
      }
    );

    logStep("STEP 1 SUCCESS: GOOGLE RESPONSE", res.data);

    setCache("search_" + query, res.data);
    return res.data;

  } catch (e) {
    logStep("STEP 1 ERROR", {
      message: e.message,
      response: e.response?.data,
    });
    throw e;
  }
}

function prepareData(data) {
  logStep("STEP 2: CLEAN DATA START");

  const cleaned = {
    results: (data.organic || []).slice(0, 5).map((r) => ({
      title: r.title,
      snippet: r.snippet,
      link: r.link,
    })),
    questions: (data.peopleAlsoAsk || []).map((q) => q.question),
    knowledge: data.knowledgeGraph || {},
  };

  logStep("STEP 2 SUCCESS: CLEANED DATA", cleaned);

  return cleaned;
}

async function analyzeWithAI(cleanData, query) {
  logStep("STEP 3: AI ANALYSIS START", { query });

  const cached = getCache("ai_" + query);
  if (cached) return cached;

  try {
    const payload = {
      model: process.env.AI_MODEL,
      temperature: 0.1,
      messages: [
        {
          role: "system",
          content:
            "You are a STRICT scam detection AI. You MUST return ONLY JSON.",
        },
        {
          role: "user",
          content: `
Analyze this store or product:

"${query}"

DATA:
${JSON.stringify(cleanData)}

Return ONLY JSON:

{
  "score": number (0-100),
  "risk": "low" | "medium" | "high",
  "reviews": "short summary",
  "activity": "active | suspicious | inactive",
  "trust_signals": "positive indicators",
  "red_flags": ["list of risks"],
  "explanation": "clear short explanation"
}
          `,
        },
      ],
    };

    logStep("AI REQUEST PAYLOAD", payload);

    const res = await axios.post(
      AI_URL,
      payload,
      {
        headers: {
          "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "trust_guard_app",
        },
        timeout: 20000,
      }
    );

    logStep("AI RAW RESPONSE", res.data);

    const content = res.data.choices?.[0]?.message?.content;

    logStep("AI TEXT RESPONSE", content);

    const parsed = extractJson(content);

    logStep("AI PARSED JSON", parsed);

    setCache("ai_" + query, parsed);

    return parsed;

  } catch (e) {
    logStep("STEP 3 ERROR", {
      message: e.message,
      response: e.response?.data,
    });
    throw e;
  }
}

function extractJson(text) {
  logStep("STEP 4: PARSE JSON");

  try {
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}") + 1;

    const jsonString = text.substring(start, end);

    logStep("JSON STRING EXTRACTED", jsonString);

    return JSON.parse(jsonString);

  } catch (e) {
    logStep("JSON PARSE FAILED", e.message);

    return {
      score: 50,
      risk: "medium",
      reviews: "unknown",
      activity: "unknown",
      trust_signals: "unknown",
      red_flags: ["AI parsing failed"],
      explanation: "AI response parsing failed",
    };
  }
}

app.post("/analyze", async (req, res) => {
  const startTime = Date.now();

  try {
    logStep("NEW REQUEST RECEIVED", req.body);

    const { query } = req.body;

    if (!query || query.length < 2) {
      logStep("VALIDATION FAILED");
      return res.status(400).json({
        success: false,
        error: "Invalid query",
      });
    }

    const searchData = await searchGoogle(query);

    const cleanData = prepareData(searchData);

    const aiResult = await analyzeWithAI(cleanData, query);

    const duration = Date.now() - startTime;

    logStep("REQUEST COMPLETED", { duration: `${duration}ms` });

    return res.json({
      success: true,
      data: aiResult,
    });

  } catch (e) {
    logStep("FINAL ERROR", {
      message: e.message,
      stack: e.stack,
    });

    return res.status(500).json({
      success: false,
      error: e.message,
    });
  }
});

app.post("/scan-link", async (req, res) => {
  try {
    const { url } = req.body;
    if (!url) {
      return res.status(400).json({ success: false, error: "URL parameter required" });
    }
    const scanResult = await scanLink(url);
    return res.json({ success: true, data: scanResult });
  } catch (e) {
    return res.status(500).json({ success: false, error: e.message });
  }
});

app.post("/generate-panic-report", async (req, res) => {
  try {
    const { scamType, country, details } = req.body;
    if (!scamType || !country) {
      return res.status(400).json({ success: false, error: "Missing required payload metrics" });
    }

    const payload = {
      model: process.env.AI_MODEL || "google/gemini-2.5-flash",
      temperature: 0.3,
      messages: [
        {
          role: "system",
          content: "You are a professional legal cybersecurity analyst specializing in standard international cybercrime response frameworks. Draft a structured, detailed, and clean legal complaint report based on user input without any markdown formatting characters."
        },
        {
          role: "user",
          content: `Generate a formal legal complaint statement for authority submission. Region: ${country}. Classification: ${scamType}. Event Specifics: ${details || 'Not documented'}.`
        }
      ]
    };

    const response = await axios.post(AI_URL, payload, {
      headers: {
        "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "trust_guard_app"
      },
      timeout: 20000
    });

    const reportText = response.data.choices?.[0]?.message?.content || "Failed to structure dynamic legal framework metrics.";
    return res.json({ success: true, report: reportText });
  } catch (e) {
    return res.status(500).json({ success: false, error: e.message });
  }
});

app.get("/", (req, res) => {
  res.send("✅ TrustGuard API Running");
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`🔥 Server running on port ${PORT}`);
});