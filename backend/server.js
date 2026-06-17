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

function logStep(step,data=null){
    console.log("\n["+step+"]");
    if(data){
        console.log(JSON.stringify(data,null,2));
    }
}


function getCache(key){

    const item = cache.get(key);

    if(!item){
        return null;
    }

    if(Date.now()>item.expiry){
        cache.delete(key);
        return null;
    }

    return item.data;
}


function setCache(key,data,ttl=600000){

    cache.set(key,{
        data,
        expiry:Date.now()+ttl
    });

}



async function searchGoogle(query){

    const cached=getCache("search_"+query);

    if(cached){
        return cached;
    }


    const response=await axios.post(
        SERPER_URL,
        {
            q:query,
            gl:"us",
            hl:"en",
            num:10
        },
        {
            headers:{
                "X-API-KEY":process.env.SERPER_KEY,
                "Content-Type":"application/json"
            },
            timeout:15000
        }
    );


    setCache("search_"+query,response.data);

    return response.data;
}



function prepareData(data){

    return {

        results:(data.organic||[]).map(x=>({
            title:x.title||"",
            snippet:x.snippet||"",
            link:x.link||""
        })),

        questions:(data.peopleAlsoAsk||[])
        .map(x=>x.question||""),

        knowledge:data.knowledgeGraph||{}

    };

}




function calculateBaseTrust(data,query){


    let score=50;

    const text=JSON.stringify(data).toLowerCase();


    if(
        text.includes("official") ||
        text.includes("verified")
    ){
        score+=15;
    }


    if(
        text.includes("reviews") ||
        text.includes("rating")
    ){
        score+=10;
    }



    if(
        text.includes("scam") ||
        text.includes("fraud") ||
        text.includes("fake") ||
        text.includes("complaint")
    ){
        score-=25;
    }



    if(
        query.includes("login") ||
        query.includes("verify") ||
        query.includes("wallet")
    ){
        score-=10;
    }


    return Math.max(0,Math.min(100,score));

}




async function analyzeWithAI(cleanData,query,baseScore){


    const payload={

        model:process.env.AI_MODEL || "google/gemini-2.5-flash",

        temperature:0,

        messages:[

            {
                role:"system",
                content:
                `
You are a professional ecommerce trust evaluation engine.

You must evaluate any online store.

Never give default medium.
Use the evidence.

A trusted known store can have score 85-100.
A suspicious store can have 40-70.
A scam can have 0-40.

Return ONLY JSON.
`
            },


            {
                role:"user",

                content:
`
Store:

${query}


Search evidence:

${JSON.stringify(cleanData)}


Initial calculated trust score:

${baseScore}


Return:

{
"score":number,
"risk":"low|medium|high",
"reviews":"summary",
"activity":"active|suspicious|inactive",
"trust_signals":"positive evidence",
"red_flags":[],
"explanation":"reason"
}
`
            }

        ]

    };



    const response=await axios.post(
        AI_URL,
        payload,
        {
            headers:{
                Authorization:
                `Bearer ${process.env.OPENROUTER_API_KEY}`,

                "Content-Type":"application/json",

                "HTTP-Referer":"trust_guard_app"
            },

            timeout:25000
        }
    );



    return extractJson(
        response.data.choices[0].message.content
    );

}




function extractJson(text){

    try{

        const start=text.indexOf("{");

        const end=text.lastIndexOf("}")+1;


        return JSON.parse(
            text.substring(start,end)
        );


    }catch(e){


        return {

            score:50,

            risk:"medium",

            reviews:"unknown",

            activity:"unknown",

            trust_signals:"unknown",

            red_flags:["AI format error"],

            explanation:"analysis failed"

        };

    }

}




app.post("/analyze",async(req,res)=>{


try{


const {query}=req.body;


if(!query){

return res.status(400).json({
success:false,
error:"missing query"
});

}



const search=await searchGoogle(query);


const clean=prepareData(search);



const baseScore=
calculateBaseTrust(clean,query);



const ai=
await analyzeWithAI(
clean,
query,
baseScore
);



let finalScore =
Math.round(
(baseScore + ai.score)/2
);



let risk="medium";


if(finalScore>=75){
risk="low";
}


if(finalScore<45){
risk="high";
}



ai.score=finalScore;

ai.risk=risk;



return res.json({

success:true,

data:ai

});



}catch(e){


return res.status(500).json({

success:false,

error:e.message

});


}



});




app.post("/scan-link",async(req,res)=>{


try{


const {url}=req.body;


if(!url){

return res.status(400).json({
success:false,
error:"URL required"
});

}



const result=
await scanLink(url);



return res.json({

success:true,

data:result

});



}catch(e){


return res.status(500).json({

success:false,

error:e.message

});


}


});





app.post("/generate-panic-report",
async(req,res)=>{


try{


const {scamType,country,details}=req.body;


const response=
await axios.post(
AI_URL,
{

model:
process.env.AI_MODEL ||
"google/gemini-2.5-flash",

messages:[

{
role:"system",
content:
"You are cybersecurity report generator."
},

{
role:"user",
content:
`Generate report.
Type:${scamType}
Country:${country}
Details:${details}`
}

]

},
{

headers:{

Authorization:
`Bearer ${process.env.OPENROUTER_API_KEY}`,

"Content-Type":"application/json"

}

}

);



return res.json({

success:true,

report:
response.data.choices[0].message.content

});



}catch(e){


return res.status(500).json({

success:false,

error:e.message

});


}


});





app.get("/",(req,res)=>{

res.send("TrustGuard API Running");

});





app.listen(PORT,"0.0.0.0",()=>{

console.log(
"Server running on port "+PORT
);

});