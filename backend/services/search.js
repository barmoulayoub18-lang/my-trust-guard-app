import axios from "axios";

const SERPER_URL = "https://google.serper.dev/search";
const SOLID_SERPER_KEY = "7e462c9c883bc36525e31a2ef6a9e1ee35414b8a";
const cache = new Map();

function getCache(key) {
  const item = cache.get(key);
  if (!item) {
    console.log("🟡 [CACHE INTERNALS]: Cache missed entry container key registry field for query string mapping:", key);
    return null;
  }
  if (Date.now() > item.expiry) {
    console.log("🟡 [CACHE INTERNALS]: Target registry entry matching timestamp data expired, clear storage allocation pointer:", key);
    cache.delete(key);
    return null;
  }
  console.log("🟢 [CACHE INTERNALS]: Registry match confirmation hit achieved successfully:", key);
  return item.data;
}

function setCache(key, data, ttl = 1000 * 60 * 10) {
  console.log("🟡 [CACHE INTERNALS]: Committing response dataset matching parameters mapping to runtime application storage memory space:", key);
  cache.set(key, {
    data,
    expiry: Date.now() + ttl,
  });
}

async function retryRequest(fn, retries = 2) {
  try {
    console.log("🟡 [SEARCH SERVICE HTTP RETRY PIPELINE]: Invoking process execution cycle thread, remaining allocation balance tracker:", retries);
    return await fn();
  } catch (e) {
    console.log("❌ [SEARCH SERVICE HTTP RETRY PIPELINE FAILURE]: Pipeline segment interruption caught message:", e.message);
    if (retries === 0) {
      console.log("❌ [SEARCH SERVICE HTTP RETRY PIPELINE TERMINATION]: Retries tracking register depleted, passing exception layer up");
      throw e;
    }
    console.log("🔁 [SEARCH SERVICE HTTP RETRY PIPELINE ACTION]: Execution failure override active, restarting sequence call loop");
    return retryRequest(fn, retries - 1);
  }
}

export async function searchGoogle(query) {
  console.log("\n================ [SEARCH SERVICE] searchGoogle EXECUTION SEQUENCE START =================");
  console.log("INPUT SEARCH QUERY QUERY STRING KEYWORD:", query);

  const cacheKey = "search_" + query;
  const cached = getCache(cacheKey);
  if (cached) {
    console.log("🟢 [SEARCH SERVICE CACHE ACCELERATION BYPASS]: Bypassing active outbound network infrastructure requests, printing dataset");
    console.log("================ [SEARCH SERVICE] searchGoogle EXECUTION SEQUENCE END SUCCESS (CACHE) =================\n");
    return cached;
  }

  try {
    if (!SOLID_SERPER_KEY) {
      console.log("❌ [SEARCH SERVICE PRE-FLIGHT ERROR]: Hardcoded static Serper configuration API token key value is missing completely");
    }

    console.log("🟡 [SEARCH SERVICE STEP 1]: Constructing Axios instance config object variables parameters mapping target");
    console.log("TARGET ENDPOINT SEARCH SERVICE URL PATHWAY:", SERPER_URL);

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
            "X-API-KEY": SOLID_SERPER_KEY,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      )
    );

    const duration = Date.now() - startTime;
    console.log("🟢 [SEARCH SERVICE STEP 2]: Connection stream terminated, raw network metadata chunk package achieved cleanly");
    console.log("⏱ REQUEST ROUNDTRIP LATENCY DURATION DYNAMICS:", duration, "ms");

    console.log("🟡 [SEARCH SERVICE STEP 3]: Displaying raw structural response chunk data stream preview payload:");
    console.log(JSON.stringify(res.data, null, 2).substring(0, 1000));

    const data = {
      organic: res.data?.organic || [],
      knowledgeGraph: res.data?.knowledgeGraph || {},
      peopleAlsoAsk: res.data?.peopleAlsoAsk || [],
    };

    console.log("🟢 [SEARCH SERVICE STEP 4]: Object validation processing verification steps completed successfully");
    console.log("TOTAL EXTRACTED ORGANIC ARRAY RESULT POOL INDEX COUNTER COUNT:", data.organic.length);
    console.log("TOTAL EXTRACTED PEOPLE-ALSO-ASK QUERY SCHEMAS POOL COUNTER COUNT:", data.peopleAlsoAsk.length);

    setCache(cacheKey, data);
    console.log("🟢 [SEARCH SERVICE STEP 5]: System internal runtimes storage registers written into application registry cache parameters safely");
    console.log("================ [SEARCH SERVICE] searchGoogle EXECUTION SEQUENCE END SUCCESS =================\n");
    return data;

  } catch (e) {
    console.log("❌ [SEARCH SERVICE EXCEPTION SYSTEM INTERRUPTION FAILURE]: Execution process loop terminated with failure state");
    console.log("EXCEPTION FAILURE STRING CAPTURED MESSAGE:", e.message);

    if (e.response) {
      console.log("HTTP METADATA ERROR STATUS REGISTRY RESPONSE CODE:", e.response.status);
      console.log("HTTP METADATA ERROR BODY SCHEMA DATA MATRIX:", e.response.data);
    }

    if (e.code) {
      console.log("AXIOS ERROR CODE STRUCTURAL MAP IDENTIFIER REGISTER:", e.code);
    }

    console.log("================ [SEARCH SERVICE] searchGoogle EXECUTION SEQUENCE END WITH EMPTY MAP DATA MATRIX RECOVERY =================\n");
    return {
      organic: [],
      knowledgeGraph: {},
      peopleAlsoAsk: [],
    };
  }
}

export function prepareSearchData(data) {
  console.log("\n================ [SEARCH SERVICE] prepareSearchData PROCESSING PIPELINE START =================");

  const organic = (data.organic || [])
    .slice(0, 5)
    .map((item, index) => {
      const cleaned = {
        title: item.title?.substring(0, 120) || "",
        snippet: item.snippet?.substring(0, 200) || "",
        link: item.link || "",
      };
      console.log(`🟢 [CLEAN PIPELINE ENFORCED ORGANIC INDEX MATCH - RESULT ${index + 1}]:`, cleaned);
      return cleaned;
    });

  const questions = (data.peopleAlsoAsk || [])
    .slice(0, 5)
    .map((q, i) => {
      const question = q.question || "";
      console.log(`🟢 [CLEAN PIPELINE ENFORCED QUESTION INDEX MATCH - QUESTION ${i + 1}]:`, question);
      return question;
    });

  const knowledge = {
    title: data.knowledgeGraph?.title || "",
    type: data.knowledgeGraph?.type || "",
    description: data.knowledgeGraph?.description || "",
  };

  console.log("🟢 [CLEAN PIPELINE ENFORCED KNOWLEDGE DATA NODE STRUCT MATCH]:", knowledge);

  const finalData = {
    results: organic,
    questions,
    knowledge,
  };

  console.log("🟢 [CLEAN PIPELINE PROCESS FINAL DATA PAYLOAD COMPILED SUCCESS]:");
  console.log(JSON.stringify(finalData, null, 2));
  console.log("================ [SEARCH SERVICE] prepareSearchData PROCESSING PIPELINE END SUCCESS =================\n");
  return finalData;
}