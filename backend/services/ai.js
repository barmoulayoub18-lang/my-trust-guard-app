import axios from "axios";

const AI_URL = "https://openrouter.ai/api/v1/chat/completions";
const MODEL = process.env.AI_MODEL || "google/gemini-2.5-flash";
const API_KEY = process.env.OPENROUTER_API_KEY;
const TIMEOUT = 25000;

export async function analyzeStoreWithAI(cleanData, query) {
  console.log("\n================ [AI SERVICE] analyzeStoreWithAI START =================");
  console.log("QUERY RECEIVED IN SERVICE:", query);
  console.log("DATA PAYLOAD RECEIVED IN SERVICE:", JSON.stringify(cleanData, null, 2));

  try {
    if (!API_KEY) {
      console.log("❌ [AI SERVICE ERROR]: API_KEY is completely blank or missing");
      throw new Error("Missing OPENROUTER_API_KEY");
    }

    console.log("🟡 [AI SERVICE STEP 1]: Constructing query prompt text structure");
    const prompt = buildPrompt(cleanData, query);

    console.log("🟡 [AI SERVICE STEP 2]: Initializing Axios Post to OpenRouter Endpoint");
    console.log("ENDPOINT TARGET URL:", AI_URL);
    console.log("TARGET MODEL DEFINITION:", MODEL);
    console.log("REQUEST TIMEOUT METRIC:", TIMEOUT);

    const startTime = Date.now();

    const response = await axios.post(
      AI_URL,
      {
        model: MODEL,
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "\nYou are an advanced scam detection AI.\nReturn ONLY JSON.\n            ",
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
    console.log("🟢 [AI SERVICE STEP 3]: Axios response transmission completed");
    console.log("⏱ HTTP LATENCY DURATION:", duration, "ms");

    const content = response.data?.choices?.[0]?.message?.content;

    if (!content) {
      console.log("❌ [AI SERVICE ERROR]: Response content text segment is undefined or empty");
      throw new Error("Empty AI response");
    }

    console.log("🟢 [AI SERVICE STEP 4]: Printing raw response text payload body output:");
    console.log(content);

    console.log("🟡 [AI SERVICE STEP 5]: Triggering string content JSON block isolation extraction");
    const parsed = extractJson(content);

    console.log("🟢 [AI SERVICE STEP 6]: Resulting parsed JSON matrix object output:");
    console.log(parsed);

    console.log("🟡 [AI SERVICE STEP 7]: Normalizing object parameters matching interface keys");
    const normalized = normalizeResponse(parsed);

    console.log("🟢 [AI SERVICE STEP 8]: Target object normalization structure verified successfully");
    console.log("================ [AI SERVICE] analyzeStoreWithAI END SUCCESS =================\n");

    return normalized;

  } catch (error) {
    console.log("❌ [AI SERVICE EXCEPTION CAUGHT]: Direct processing operation sequence aborted");
    console.log("EXCEPTION ERROR MESSAGE:", error.message);

    if (error.response) {
      console.log("REMOTE SERVER RESPONSE HTTP STATUS CODE:", error.response.status);
      console.log("REMOTE SERVER RETURNED ERROR BODY OBJECT:", error.response.data);
    }

    if (error.code) {
      console.log("AXIOS ERROR CODE SPECS:", error.code);
    }

    console.log("================ [AI SERVICE] analyzeStoreWithAI END WITH FALLBACK =================\n");
    return fallbackAnalysis();
  }
}

export async function generatePanicReportWithAI(scamType, country, details) {
  console.log("\n================ [AI SERVICE] generatePanicReportWithAI START =================");
  console.log("INPUT PARAMETERS - TYPE:", scamType, " | COUNTRY:", country);
  
  try {
    if (!API_KEY) throw new Error("Missing OPENROUTER_API_KEY");

    console.log("🟡 [AI SERVICE PANIC REPORT STEP 1]: Dispatching secure payload request to AI");
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

    console.log("🟢 [AI SERVICE PANIC REPORT STEP 2]: AI report content compiled safely");
    console.log("================ [AI SERVICE] generatePanicReportWithAI END SUCCESS =================\n");
    return response.data.choices?.[0]?.message?.content || "Failed to structure dynamic legal framework metrics.";
  } catch (error) {
    console.log("❌ [AI SERVICE PANIC REPORT EXCEPTION]: Redirecting execution thread to secure offline template bypass");
    console.log("ERROR MESSAGE:", error.message);
    console.log("================ [AI SERVICE] generatePanicReportWithAI END WITH BYPASS =================\n");
    return `OFFICIAL CYBERCRIME COMPLAINT REPORT\n\nRegion: ${country}\nClassification: ${scamType}\n\nIncident Details: ${details || 'No additional details provided.'}\n\nStatus: Generated under server connectivity bypass. Please present this log to local authorities.`;
  }
}

export async function deepScanLinkWithAI(domain, finalUrl, redirectsCount, heuristicFlags, pageTitle, pageSnippet, isFetchedSuccessfully) {
  console.log("\n================ [AI SERVICE] deepScanLinkWithAI START =================");
  console.log("DOMAIN:", domain, " | REDIRECTS:", redirectsCount, " | FETCH:", isFetchedSuccessfully);
  
  try {
    if (!API_KEY) throw new Error("Missing OPENROUTER_API_KEY");

    console.log("🟡 [AI SERVICE LINK SCAN STEP 1]: Transmitting structural link properties payload directly");
    const response = await axios.post(
      AI_URL,
      {
        model: MODEL,
        messages: [
          {
            role: "system",
            content: "Analyze the domain, final destination URL, redirect count, flags, and HTML metadata to determine if it is a phishing or scam attempt. Return a clean JSON object with keys: AI_Score (integer 0-100), Phishing_Detected (boolean), Site_Summary (string, maximum 2 sentences in Arabic summarizing exactly what this website pretends to be), and Verifiable_Reason (string in Arabic explaining the scientific and technical reason behind this security assessment based on structural indicators, brand spoofing risk, or transport patterns)."
          },
          {
            role: "user",
            content: JSON.stringify({
              target_domain: domain,
              final_url: finalUrl,
              redirects_count: redirectsCount,
              heuristic_flags: heuristicFlags,
              extracted_title: pageTitle,
              extracted_text: pageSnippet,
              connection_successful: isFetchedSuccessfully
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
    console.log("🟢 [AI SERVICE LINK SCAN STEP 2]: Response content buffer payload body extracted:");
    console.log(content);

    if (!content) {
      console.log("❌ [AI SERVICE LINK SCAN ERROR]: Content field response container missing");
      return null;
    }

    try {
      const parsedData = JSON.parse(content);
      console.log("================ [AI SERVICE] deepScanLinkWithAI END SUCCESS =================\n");
      return parsedData;
    } catch (_) {
      console.log("⚠️ [AI SERVICE LINK SCAN WARNING]: Native JSON parsing blocked, implementing substring index extraction fallback");
      const start = content.indexOf("{");
      const end = content.lastIndexOf("}") + 1;
      if (start !== -1 && end !== -1) {
        const parsedSubData = JSON.parse(content.substring(start, end));
        console.log("================ [AI SERVICE] deepScanLinkWithAI END SUCCESS VIA ISOLATION =================\n");
        return parsedSubData;
      }
      throw new Error("Failed to parse link scan JSON payload structure.");
    }
  } catch (error) {
    console.log("❌ [AI SERVICE LINK SCAN EXCEPTION]: Deep analysis workflow halted");
    console.log("ERROR MESSAGE:", error.message);
    console.log("================ [AI SERVICE] deepScanLinkWithAI END WITH NULL RECOVERY =================\n");
    return null;
  }
}

function buildPrompt(data, query) {
  console.log("🟡 [AI SERVICE PROMPT COMPILER]: Formatting payload string template");
  return `\nAnalyze this store or product:\n\nQUERY:\n"${query}"\n\nREAL DATA:\n${JSON.stringify(data, null, 2)}\n\nReturn ONLY JSON:\n\n{\n  "score": number,\n  "risk": "low" | "medium" | "high",\n  "reviews": "short summary",\n  "activity": "active | suspicious | inactive",\n  "trust_signals": "positive indicators",\n  "red_flags": ["list of risks"],\n  "explanation": "clear reasoning"\n}\n`;
}

function extractJson(text) {
  try {
    console.log("🟡 [AI SERVICE JSON EXTRACTOR INTERNALS]: Attempting regex-less string positional slice extraction");
    const start = text.indexOf("{");
    const end = text.lastIndexOf("}") + 1;
    console.log("TARGET DETECTED SUBSTRING POINTERS - START AT:", start, " | END AT:", end);
    const jsonString = text.substring(start, end);
    const parsed = JSON.parse(jsonString);
    console.log("🟢 [AI SERVICE JSON EXTRACTOR INTERNALS]: Raw conversion validation check success");
    return parsed;
  } catch (e) {
    console.log("❌ [AI SERVICE JSON EXTRACTOR INTERNALS INTERRUPT]: Failure during string structure conversion");
    console.log("CRITICAL TEXT METRIC CAUSING CRASH:");
    console.log(text);
    return fallbackAnalysis();
  }
}

function normalizeResponse(data) {
  console.log("🟡 [AI SERVICE NORMALIZER INTERNALS]: Conforming dataset parameters mapping schema validation structure");
  const normalized = {
    score: Number(data.score) || 0,
    risk: data.risk || "medium",
    reviews: data.reviews || "unknown",
    activity: data.activity || "unknown",
    trust_signals: data.trust_signals || "unknown",
    red_flags: Array.isArray(data.red_flags) ? data.red_flags : [],
    explanation: data.explanation || "No explanation",
  };
  console.log("🟢 [AI SERVICE NORMALIZER INTERNALS Output]: Normalized dataset fields values established");
  return normalized;
}

function fallbackAnalysis() {
  console.log("⚠️ [AI SERVICE BACKUP RECOVERY TRIGGERED]: Constructing static failover fallback analysis metrics object");
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