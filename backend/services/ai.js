import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const AI_URL = "https://openrouter.ai/api/v1/chat/completions";

const MODEL = process.env.AI_MODEL || "meta-llama/llama-3-8b-instruct";
const API_KEY = process.env.OPENROUTER_API_KEY;

const TIMEOUT = Number(process.env.TIMEOUT) || 20000;

export async function analyzeStoreWithAI(cleanData, query) {
  console.log("\n================ AI START =================");
  console.log("QUERY:", query);

  try {
    if (!API_KEY) {
      console.log("❌ ERROR: Missing API KEY");
      throw new Error("Missing OPENROUTER_API_KEY");
    }

    console.log("🟡 STEP 1: Building prompt...");
    const prompt = buildPrompt(cleanData, query);

    console.log("🟡 STEP 2: Sending request to AI...");
    console.log("MODEL:", MODEL);
    console.log("TIMEOUT:", TIMEOUT);

    const startTime = Date.now();

    const response = await axios.post(
      AI_URL,
      {
        model: MODEL,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: `
You are an advanced scam detection AI.
Return ONLY JSON.
            `,
          },
          {
            role: "user",
            content: prompt,
          },
        ],
      },
      {
        headers: {
          Authorization: `Bearer ${API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://trust_guard_app",
          "X-Title": "trust_guard_app",
        },
        timeout: TIMEOUT,
      }
    );

    const duration = Date.now() - startTime;

    console.log("🟢 STEP 3: AI response received");
    console.log("⏱ Duration:", duration, "ms");

    const content = response.data?.choices?.[0]?.message?.content;

    if (!content) {
      console.log("❌ ERROR: Empty AI content");
      throw new Error("Empty AI response");
    }

    console.log("🟢 STEP 4: Raw AI content:");
    console.log(content);

    console.log("🟡 STEP 5: Extracting JSON...");
    const parsed = extractJson(content);

    console.log("🟢 STEP 6: Parsed JSON:");
    console.log(parsed);

    console.log("🟡 STEP 7: Normalizing response...");
    const normalized = normalizeResponse(parsed);

    console.log("🟢 STEP 8: Final normalized result:");
    console.log(normalized);

    console.log("================ AI END =================\n");

    return normalized;

  } catch (error) {
    console.log("❌ AI ERROR OCCURRED");
    console.log("MESSAGE:", error.message);

    if (error.response) {
      console.log("STATUS:", error.response.status);
      console.log("DATA:", error.response.data);
    }

    if (error.code) {
      console.log("CODE:", error.code);
    }

    console.log("================ AI FAILED =================\n");

    return fallbackAnalysis();
  }
}

export async function generatePanicReportWithAI(scamType, country, details) {
  console.log("\n================ PANIC REPORT AI START =================");
  try {
    if (!API_KEY) throw new Error("Missing OPENROUTER_API_KEY");

    const response = await axios.post(
      AI_URL,
      {
        model: MODEL,
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
      },
      {
        headers: {
          Authorization: `Bearer ${API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://trust_guard_app",
          "X-Title": "trust_guard_app"
        },
        timeout: TIMEOUT
      }
    );

    return response.data.choices?.[0]?.message?.content || "Failed to structure dynamic legal framework metrics.";
  } catch (error) {
    console.log("❌ PANIC REPORT AI ERROR:", error.message);
    return `OFFICIAL CYBERCRIME COMPLAINT REPORT\n\nRegion: ${country}\nClassification: ${scamType}\n\nIncident Details: ${details || 'No additional details provided.'}\n\nStatus: Generated under server connectivity bypass. Please present this log to local authorities.`;
  }
}

export async function deepScanLinkWithAI(domain, finalUrl, redirectsCount, heuristicFlags) {
  console.log("\n================ LINK SCAN AI START =================");
  try {
    if (!API_KEY) throw new Error("Missing OPENROUTER_API_KEY");

    const response = await axios.post(
      AI_URL,
      {
        model: MODEL,
        messages: [
          {
            role: "system",
            content: "Analyze the domain, final destination URL, redirect count, and flags to determine if it is a phishing or scam attempt. Return a JSON object with keys: AI_Score (integer 0-100), Phishing_Detected (boolean), and Deep_Reason (string analysis in English without markdown formatting)."
          },
          {
            role: "user",
            content: JSON.stringify({
              target_domain: domain,
              final_url: finalUrl,
              redirects_count: redirectsCount,
              heuristic_flags: heuristicFlags
            })
          }
        ],
        response_format: { type: 'json_object' }
      },
      {
        headers: {
          Authorization: `Bearer ${API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://trust_guard_app",
          "X-Title": "trust_guard_app"
        },
        timeout: TIMEOUT
      }
    );

    const content = response.data?.choices?.[0]?.message?.content;
    return content ? JSON.parse(content) : null;
  } catch (error) {
    console.log("❌ LINK SCAN AI ERROR:", error.message);
    return null;
  }
}

function buildPrompt(data, query) {
  console.log("📦 CLEAN DATA SENT TO AI:");
  console.log(JSON.stringify(data, null, 2));

  return `
Analyze this store or product:

QUERY:
"${query}"

REAL DATA:
${JSON.stringify(data, null, 2)}

Return ONLY JSON:

{
  "score": number,
  "risk": "low" | "medium" | "high",
  "reviews": "short summary",
  "activity": "active | suspicious | inactive",
  "trust_signals": "positive indicators",
  "red_flags": ["list of risks"],
  "explanation": "clear reasoning"
}
`;
}

function extractJson(text) {
  try {
    console.log("🟡 JSON EXTRACT START");

    const start = text.indexOf("{");
    const end = text.lastIndexOf("}") + 1;

    console.log("START INDEX:", start);
    console.log("END INDEX:", end);

    const jsonString = text.substring(start, end);

    console.log("🟢 JSON STRING:");
    console.log(jsonString);

    const parsed = JSON.parse(jsonString);

    console.log("🟢 JSON PARSED SUCCESS");

    return parsed;

  } catch (e) {
    console.log("❌ JSON PARSE ERROR");
    console.log("RAW TEXT:");
    console.log(text);

    return fallbackAnalysis();
  }
}

function normalizeResponse(data) {
  console.log("🟡 NORMALIZING RESPONSE");

  const normalized = {
    score: Number(data.score) || 0,
    risk: data.risk || "medium",
    reviews: data.reviews || "unknown",
    activity: data.activity || "unknown",
    trust_signals: data.trust_signals || "unknown",
    red_flags: Array.isArray(data.red_flags) ? data.red_flags : [],
    explanation: data.explanation || "No explanation",
  };

  console.log("🟢 NORMALIZED RESULT:");
  console.log(normalized);

  return normalized;
}

function fallbackAnalysis() {
  console.log("⚠️ USING FALLBACK ANALYSIS");

  return {
    score: 50,
    risk: "medium",
    reviews: "Not enough reliable data",
    activity: "unknown",
    trust_signals: "No clear signals",
    red_flags: ["Analysis failed"],
    explanation: "AI could not analyze reliably. Try again later.",
  };
}