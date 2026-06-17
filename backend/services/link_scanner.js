import axios from 'axios';
import { deepScanLinkWithAI } from './ai.js';

async function scanLink(url) {
    console.log("\n================ [LINK SCANNER SERVICE] scanLink EXECUTION SEQUENCE START =================");
    console.log("TARGET PAYLOAD WEB URL INPUT:", url);

    try {
        let currentUrl = url;
        const redirectHistory = [];
        let redirectsCount = 0;
        const maxRedirects = 5;

        if (!/^https?:\/\//i.test(currentUrl)) {
            currentUrl = 'http://' + currentUrl;
            console.log("🟡 [LINK SCANNER]: Target scheme missing, pre-pending transport protocol path prefix:", currentUrl);
        }

        console.log("🟡 [LINK SCANNER]: Launching secure tracing HTTP redirect pattern tracking loop");
        while (redirectsCount < maxRedirects) {
            console.log(`🟡 [LINK SCANNER REDIRECT LOOP]: Processing hop index [${redirectsCount}] URL target: ${currentUrl}`);
            redirectHistory.push(currentUrl);
            try {
                const response = await axios.get(currentUrl, {
                    maxRedirects: 0,
                    validateStatus: (status) => status >= 200 && status < 400,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
                    },
                    timeout: 5000
                });

                if (response.status >= 300 && response.status < 400 && response.headers.location) {
                    let nextUrl = response.headers.location;
                    if (!/^https?:\/\//i.test(nextUrl)) {
                        const parsed = new URL(currentUrl);
                        nextUrl = new URL(nextUrl, parsed.origin).href;
                    }
                    console.log(`🟢 [LINK SCANNER REDIRECT HOP DETECTED]: Status [${response.status}] Forwarding chain redirection targeting -> ${nextUrl}`);
                    currentUrl = nextUrl;
                    redirectsCount++;
                } else {
                    console.log(`🟢 [LINK SCANNER REDIRECT LOOP TERMINATED]: Final destination transport stable endpoint achieved at status: [${response.status}]`);
                    break;
                }
            } catch (err) {
                if (err.response && err.response.status >= 300 && err.response.status < 400 && err.response.headers.location) {
                    let nextUrl = err.response.headers.location;
                    if (!/^https?:\/\//i.test(nextUrl)) {
                        const parsed = new URL(currentUrl);
                        nextUrl = new URL(nextUrl, parsed.origin).href;
                    }
                    console.log(`🟢 [LINK SCANNER REDIRECT EXCEPTION HOP]: Capturing 3xx response inside catch wrapper block -> ${nextUrl}`);
                    currentUrl = nextUrl;
                    redirectsCount++;
                } else {
                    console.log("⚠️ [LINK SCANNER REDIRECT LOOP EXCEPTION INTERRUPT]: Network tracing request halted. Trapping pipeline trace exception message:", err.message);
                    break;
                }
            }
        }

        const finalUrl = currentUrl;
        let domain = '';
        try {
            domain = new URL(finalUrl).hostname;
            console.log("🟢 [LINK SCANNER]: Parsed domain hostname string container:", domain);
        } catch (e) {
            domain = finalUrl;
            console.log("⚠️ [LINK SCANNER URL PARSER EXCEPTION]: Native host URL instantiation error, falling back to primitive raw format:", domain);
        }

        let pageTitle = '';
        let pageSnippet = '';
        let isFetchedSuccessfully = false;

        console.log("🟡 [LINK SCANNER]: Initializing real destination body scrape and DOM tree extraction workflow sequence");
        try {
            const pageResponse = await axios.get(finalUrl, {
                headers: {
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                    'Accept-Language': 'en-US,en;q=0.5'
                },
                timeout: 6000
            });
            const html = pageResponse.data;
            if (typeof html === 'string') {
                isFetchedSuccessfully = true;
                console.log("🟢 [LINK SCANNER]: Remote raw server document source returned successfully, size:", html.length, "characters");
                const titleMatch = html.match(/<title[^>]*>([\s\S]*?)<\/title>/i);
                if (titleMatch && titleMatch[1]) {
                    pageTitle = titleMatch[1].trim();
                }
                const bodyMatch = html.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
                if (bodyMatch && bodyMatch[1]) {
                    pageSnippet = bodyMatch[1].replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 800);
                } else {
                    pageSnippet = html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ').trim().slice(0, 800);
                }
                console.log("🟢 [LINK SCANNER PARSED HTML SUMMARY]: TITLE SUITE METRIC:", pageTitle, " | SNIPPET CHAR BUFFER COUNT:", pageSnippet.length);
            }
        } catch (fetchErr) {
            console.log("⚠️ [LINK SCANNER FETCH DOM EXCEPTION CAUGHT]: Content processing sequence blocked by security layer or connection dropped:", fetchErr.message);
            pageTitle = 'Secure Protocol Shield Active';
            pageSnippet = 'Direct endpoint content analysis timed out or access restricted by target host.';
        }

        let isPhishing = false;
        let riskScore = 15;
        const flags = [];

        console.log("🟡 [LINK SCANNER HEURISTIC ENGINE]: Calculating baseline rule metrics indicators");
        if (redirectsCount > 2) {
            riskScore += 30;
            flags.push('Multiple hidden redirects detected');
            console.log("🚨 [FLAG TRIGGERED]: High redirect threshold reached. Appended flag metric tracking indices.");
        }
        if (/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/.test(domain)) {
            riskScore += 45;
            flags.push('URL uses raw IP address instead of domain name');
            console.log("🚨 [FLAG TRIGGERED]: Raw literal digital address sequence detected inside domain name variable container.");
        }
        if ((domain.match(/-/g) || []).length > 2) {
            riskScore += 20;
            flags.push('Excessive hyphens in domain structure');
            console.log("🚨 [FLAG TRIGGERED]: Suspicious domain word separation character frequency detected.");
        }

        if (!isFetchedSuccessfully) {
            riskScore += 15;
            flags.push('Host enforces anti-analysis connection drop or private metadata encryption');
            console.log("🚨 [FLAG TRIGGERED]: Empty data channel state forcing risk weight multiplier adjustment.");
        }

        const commonBrands = ['paypal', 'bank', 'netflix', 'google', 'facebook', 'instagram', 'binance', 'crypto', 'shein', 'amazon', 'baridimob', 'ccp'];
        for (const brand of commonBrands) {
            if (domain.includes(brand) && !domain.endsWith(brand + '.com') && !domain.endsWith(brand + '.net') && !domain.endsWith(brand + '.org')) {
                riskScore += 50;
                flags.push(`Potential brand spoofing target: ${brand}`);
                console.log(`🚨 [FLAG TRIGGERED]: Brand keyword match target spoof tracking warning active for: ${brand}`);
            }
        }

        if (url.includes('secure') || url.includes('login') || url.includes('verify') || url.includes('update')) {
            if (riskScore > 20) {
                riskScore += 15;
                flags.push('Urgent semantic keywords found in suspicious path structure');
                console.log("🚨 [FLAG TRIGGERED]: Semantic URL syntax match found.");
            }
        }

        let siteSummary = 'Failed to establish direct connection with the target host for real-time digital identity verification.';
        let dynamicReason = 'The link has been scanned based on structural indicators and current domain behavior.';

        console.log("🟡 [LINK SCANNER AI ROUTER]: Invoking deepScanLinkWithAI function from ai.js module pipeline");
        const aiResult = await deepScanLinkWithAI(domain, finalUrl, redirectsCount, flags, pageTitle, pageSnippet, isFetchedSuccessfully);

        if (aiResult) {
            console.log("🟢 [LINK SCANNER AI ROUTER SUCCESS]: AI parsed object successfully returned into link scanner execution context");
            if (aiResult.AI_Score !== undefined) {
                riskScore = Math.max(riskScore, aiResult.AI_Score);
                console.log("⚖️ [LINK SCANNER METRIC RE-CALCULATION]: Adjusting score parameter matching AI calculations output score:", riskScore);
            }
            if (aiResult.AI_Score === undefined && aiResult.risk_score !== undefined) {
                riskScore = Math.max(riskScore, aiResult.risk_score);
            }
            if (aiResult.Phishing_Detected === true || aiResult.is_phishing === true) {
                isPhishing = true;
                console.log("🚨 [LINK SCANNER STATE FLAG OVERRIDE]: Threat matrix verification confirmed by deep scanning sequence.");
            }
            if (aiResult.Site_Summary || aiResult.site_summary) {
                siteSummary = aiResult.Site_Summary || aiResult.site_summary;
            }
            if (aiResult.Verifiable_Reason || aiResult.verifiable_reason) {
                dynamicReason = aiResult.Verifiable_Reason || aiResult.verifiable_reason;
            }
        } else {
            console.log("⚠️ [LINK SCANNER AI ROUTER PIPELINE ERROR]: aiResult object returned empty, executing standard baseline security rules text output mapping");
            if (riskScore >= 45) {
                dynamicReason = 'We could not retrieve direct content from the target host, but multiple high-risk indicators were detected in the URL structure and redirection behavior, suggesting a strong likelihood of phishing activity.';
            } else {
                dynamicReason = 'Failed to establish direct connection with the target host for real-time digital identity verification.';
            }
        }

        if (riskScore >= 50) {
            isPhishing = true;
        }

        const finalOutputResponse = {
            original_url: url,
            final_url: finalUrl,
            risk_score: Math.min(riskScore, 100),
            is_phishing: isPhishing,
            details: {
                redirect_path: redirectHistory,
                redirects_count: redirectsCount,
                detected_flags: flags,
                target_domain: domain,
                site_summary: siteSummary,
                verifiable_reason: dynamicReason
            }
        };

        console.log("🟢 [LINK SCANNER SERVICE SUCCESS]: Constructing secure response structural configuration matrix output data safely");
        console.log("================ [LINK SCANNER SERVICE] scanLink EXECUTION SEQUENCE END SUCCESS =================");
        return finalOutputResponse;

    } catch (error) {
        console.log("❌ [LINK SCANNER SERVICE CRITICAL FAULT]: Exception captured inside service execution logic framework wrapper block");
        console.log("CRITICAL ERROR MESSAGE:", error.message);
        console.log("CRITICAL THREAD ERROR STACK TRACE LOG DATA:", error.stack);
        console.log("================ [LINK SCANNER SERVICE] scanLink EXECUTION SEQUENCE END WITH EXCEPTION SYSTEM RECOVERY =================");
        return {
            original_url: url,
            final_url: url,
            risk_score: 85,
            is_phishing: true,
            details: {
                error: error.message,
                redirects_count: 0,
                redirect_path: [url],
                detected_flags: ['Failed to establish connection sequence with target host completely'],
                target_domain: url,
                site_summary: 'Failed to establish direct connection with the target host for real-time digital identity verification.',
                verifiable_reason: 'The target server drops connections immediately, which is a common practice in short-range random phishing campaigns.'
            }
        };
    }
}

export { scanLink };