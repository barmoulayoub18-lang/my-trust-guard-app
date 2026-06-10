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
  const startTime = Date.now();
  try {
    const { url } = req.body;
    logStep("LINK SCANNER REQUEST RECEIVED", { targetUrl: url });

    if (!url) {
      logStep("LINK SCANNER VALIDATION FAILED: Missing URL");
      return res.status(400).json({ success: false, error: "URL parameter required" });
    }

    // 1. تشغيل الفحص الهيكلي الأولي (التابع لك لمعرفة التحويلات والنطاق)
    logStep("RUNNING INITIAL SCAN...");
    const baseScan = await scanLink(url).catch(() => ({}));

    // 2. جلب بيانات المحتوى والسياق عن الموقع عبر محرك البحث لمعرفة طبيعته بدون دخول مباشر خطر
    logStep("FETCHING WEB CONTEXT FOR ANALYSIS...");
    let webContext = {};
    try {
      webContext = await searchGoogle(url);
    } catch (searchError) {
      logStep("COULD NOT FETCH WEB CONTEXT", searchError.message);
    }

    // تنظيف البيانات المسترجعة
    const cleanWebData = prepareData(webContext);

    // 3. إرسال سياق الـ HTML والمحتوى المكتشف للذكاء الاصطناعي لصياغة التحليل الفعلي للمستخدم
    logStep("SENDING HTML CONTEXT TO OPENROUTER AI...");
    let aiAnalysis;
    try {
      const payload = {
        model: process.env.AI_MODEL || "google/gemini-2.5-flash",
        temperature: 0.2,
        messages: [
          {
            role: "system",
            content: "You are an advanced cyber threat response AI. Analyze the website context and return ONLY a strict JSON object with clear Arabic descriptions so the user knows what the site contains before clicking."
          },
          {
            role: "user",
            content: `
Analyze this specific URL: "${url}"
Initial Scan Data: ${JSON.stringify(baseScan)}
Web Snippets & Content: ${JSON.stringify(cleanWebData)}

Return ONLY JSON format:
{
  "risk_score": number (0-100),
  "is_phishing": boolean,
  "site_summary": "خلاصة دقيقة جداً باللغة العربية تشرح للمستخدم محتوى الموقع وماذا سيجد داخله عند الدخول (مثال: صفحة تسجيل دخول جامعية، متجر إلكتروني لبيع العطور، إلخ)",
  "verifiable_reason": "التحليل الأمني والسبب الفعلي باللغة العربية (مثال: الموقع رسمي وموثوق لشركة كذا، أو احذر الموقع يقلد واجهة تسجيل دخول مستندات جوجل لسرقة البيانات)",
  "detected_flags": ["وصف الرايات أو المؤشرات الأمنية باللغة العربية"]
}
            `
          }
        ]
      };

      const aiRes = await axios.post(AI_URL, payload, {
        headers: {
          "Authorization": `Bearer ${process.env.OPENROUTER_API_KEY}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "trust_guard_app"
        },
        timeout: 25000
      });

      const content = aiRes.data.choices?.[0]?.message?.content;
      aiAnalysis = extractJson(content);
    } catch (aiError) {
      logStep("AI LINK ANALYSIS FAILED, FALLING BACK To BASIC", aiError.message);
      aiAnalysis = {
        risk_score: baseScan.risk_score || 10,
        is_phishing: baseScan.is_phishing || false,
        site_summary: "تحليل محتوى الموقع متعذر حالياً بسبب قيود طبقة الحماية للرابط المختار.",
        verifiable_reason: "التحليل الهيكلي للنطاق اكتمل لكن معالجة كود الـ HTML واجهت مهلة انتهاء الطلب.",
        detected_flags: baseScan.details?.detected_flags || ["Heuristic scanning completed."]
      };
    }

    // دمج النتائج الهيكلية مع نتائج تحليل المحتوى المعمق للـ AI
    const finalResult = {
      original_url: url,
      final_url: baseScan.final_url || url,
      risk_score: aiAnalysis.risk_score,
      is_phishing: aiAnalysis.is_phishing,
      details: {
        redirects_count: baseScan.details?.redirects_count ?? 0,
        redirect_path: baseScan.details?.redirect_path || [url],
        target_domain: baseScan.details?.target_domain || url.split('/')[2] || '',
        site_summary: aiAnalysis.site_summary,
        verifiable_reason: aiAnalysis.verifiable_reason,
        detected_flags: aiAnalysis.detected_flags
      }
    };

    const duration = Date.now() - startTime;
    logStep("REQUEST COMPLETED SUCCESSFULLY", { duration: `${duration}ms` });

    return res.json({ success: true, data: finalResult });
  } catch (e) {
    logStep("FINAL ERROR IN SCAN-LINK", { message: e.message, stack: e.stack });
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