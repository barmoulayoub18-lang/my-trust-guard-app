import axios from "axios";
import dotenv from "dotenv";

dotenv.config();

const SERPER_URL = "https://google.serper.dev/search";

const cache = new Map();

function getCache(key) {
  const item = cache.get(key);

  if (!item) {
    console.log("🟡 CACHE MISS:", key);
    return null;
  }

  if (Date.now() > item.expiry) {
    console.log("🟡 CACHE EXPIRED:", key);
    cache.delete(key);
    return null;
  }

  console.log("🟢 CACHE HIT:", key);
  return item.data;
}

function setCache(key, data, ttl = 1000 * 60 * 10) {
  console.log("🟡 SAVING TO CACHE:", key);

  cache.set(key, {
    data,
    expiry: Date.now() + ttl,
  });
}

async function retryRequest(fn, retries = 2) {
  try {
    console.log("🟡 TRY REQUEST, retries left:", retries);
    return await fn();
  } catch (e) {
    console.log("❌ REQUEST FAILED:", e.message);

    if (retries === 0) {
      console.log("❌ NO MORE RETRIES");
      throw e;
    }

    console.log("🔁 RETRYING...");
    return retryRequest(fn, retries - 1);
  }
}

export async function searchGoogle(query) {
  console.log("\n================ SEARCH START =================");
  console.log("QUERY:", query);

  const cacheKey = "search_" + query;

  const cached = getCache(cacheKey);
  if (cached) {
    console.log("🟢 RETURNING CACHED DATA");
    console.log("================ SEARCH END (CACHE) =================\n");
    return cached;
  }

  try {
    if (!process.env.SERPER_KEY) {
      console.log("❌ ERROR: Missing SERPER_KEY");
    }

    console.log("🟡 STEP 1: Sending request to Google API...");
    console.log("URL:", SERPER_URL);

    const startTime = Date.now();

    const res = await retryRequest(() =>
      axios.post(
        SERPER_URL,
        {
          q: query,
          gl: "us",
          hl: "en",
          num: 8,
        },
        {
          headers: {
            "X-API-KEY": process.env.SERPER_KEY,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      )
    );

    const duration = Date.now() - startTime;

    console.log("🟢 STEP 2: Response received");
    console.log("⏱ Duration:", duration, "ms");

    console.log("🟡 STEP 3: Raw response preview:");
    console.log(JSON.stringify(res.data, null, 2).substring(0, 1000));

    const data = {
      organic: res.data?.organic || [],
      knowledgeGraph: res.data?.knowledgeGraph || {},
      peopleAlsoAsk: res.data?.peopleAlsoAsk || [],
    };

    console.log("🟢 STEP 4: Data extracted");
    console.log("Organic count:", data.organic.length);
    console.log("Questions count:", data.peopleAlsoAsk.length);

    setCache(cacheKey, data);

    console.log("🟢 STEP 5: Cached successfully");
    console.log("================ SEARCH END =================\n");

    return data;

  } catch (e) {
    console.log("❌ SEARCH FAILED COMPLETELY");
    console.log("MESSAGE:", e.message);

    if (e.response) {
      console.log("STATUS:", e.response.status);
      console.log("DATA:", e.response.data);
    }

    if (e.code) {
      console.log("CODE:", e.code);
    }

    console.log("================ SEARCH FAILED =================\n");

    return {
      organic: [],
      knowledgeGraph: {},
      peopleAlsoAsk: [],
    };
  }
}

export function prepareSearchData(data) {
  console.log("\n================ CLEAN DATA START =================");

  const organic = (data.organic || [])
    .slice(0, 5)
    .map((item, index) => {
      const cleaned = {
        title: item.title?.substring(0, 120) || "",
        snippet: item.snippet?.substring(0, 200) || "",
        link: item.link || "",
      };

      console.log(`🟢 RESULT ${index + 1}:`, cleaned);
      return cleaned;
    });

  const questions = (data.peopleAlsoAsk || [])
    .slice(0, 5)
    .map((q, i) => {
      const question = q.question || "";
      console.log(`🟢 QUESTION ${i + 1}:`, question);
      return question;
    });

  const knowledge = {
    title: data.knowledgeGraph?.title || "",
    type: data.knowledgeGraph?.type || "",
    description: data.knowledgeGraph?.description || "",
  };

  console.log("🟢 KNOWLEDGE GRAPH:", knowledge);

  const finalData = {
    results: organic,
    questions,
    knowledge,
  };

  console.log("🟢 FINAL CLEAN DATA:");
  console.log(JSON.stringify(finalData, null, 2));

  console.log("================ CLEAN DATA END =================\n");

  return finalData;
}