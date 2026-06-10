const axios = require('axios');

async function scanLink(url) {
    try {
        let currentUrl = url;
        const redirectHistory = [];
        let redirectsCount = 0;
        const maxRedirects = 5;

        if (!/^https?:\/\//i.test(currentUrl)) {
            currentUrl = 'http://' + currentUrl;
        }

        while (redirectsCount < maxRedirects) {
            redirectHistory.push(currentUrl);
            try {
                const response = await axios.get(currentUrl, {
                    maxRedirects: 0,
                    validateStatus: (status) => status >= 200 && status < 400,
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                    },
                    timeout: 5000
                });

                if (response.status >= 300 && response.status < 400 && response.headers.location) {
                    let nextUrl = response.headers.location;
                    if (!/^https?:\/\//i.test(nextUrl)) {
                        const parsed = new URL(currentUrl);
                        nextUrl = new URL(nextUrl, parsed.origin).href;
                    }
                    currentUrl = nextUrl;
                    redirectsCount++;
                } else {
                    break;
                }
            } catch (err) {
                if (err.response && err.response.status >= 300 && err.response.status < 400 && err.response.headers.location) {
                    let nextUrl = err.response.headers.location;
                    if (!/^https?:\/\//i.test(nextUrl)) {
                        const parsed = new URL(currentUrl);
                        nextUrl = new URL(nextUrl, parsed.origin).href;
                    }
                    currentUrl = nextUrl;
                    redirectsCount++;
                } else {
                    break;
                }
            }
        }

        const finalUrl = currentUrl;
        let domain = '';
        try {
            domain = new URL(finalUrl).hostname;
        } catch (e) {
            domain = finalUrl;
        }

        let isPhishing = false;
        let riskScore = 10;
        const flags = [];

        if (redirectsCount > 2) {
            riskScore += 30;
            flags.push('Multiple hidden redirects detected');
        }
        if (/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/.test(domain)) {
            riskScore += 40;
            flags.push('URL uses raw IP address instead of domain name');
        }
        if ((domain.match(/-/g) || []).length > 2) {
            riskScore += 20;
            flags.push('Excessive hyphens in domain structure');
        }
        const commonBrands = ['paypal', 'bank', 'netflix', 'google', 'facebook', 'instagram', 'binance', 'crypto'];
        for (const brand of commonBrands) {
            if (domain.includes(brand) && !domain.endsWith(brand + '.com') && !domain.endsWith(brand + '.net')) {
                riskScore += 45;
                flags.push(`Potential brand spoofing target: ${brand}`);
            }
        }

        try {
            const openRouterUrl = process.env.OPENROUTER_API_URL || 'https://openrouter.ai/api/v1/chat/completions';
            const openRouterKey = process.env.OPENROUTER_API_KEY;

            if (openRouterKey) {
                const aiResponse = await axios.post(
                    openRouterUrl,
                    {
                        model: 'google/gemini-2.5-flash',
                        messages: [
                            {
                                role: 'system',
                                content: 'Analyze the domain, final destination URL, redirect count, and flags to determine if it is a phishing or scam attempt. Return a JSON object with keys: AI_Score (integer 0-100), Phishing_Detected (boolean), and Deep_Reason (string analysis in English without markdown formatting).'
                            },
                            {
                                role: 'user',
                                content: JSON.stringify({
                                    target_domain: domain,
                                    final_url: finalUrl,
                                    redirects_count: redirectsCount,
                                    heuristic_flags: flags
                                })
                            }
                        ],
                        response_format: { type: 'json_object' }
                    },
                    {
                        headers: {
                            'Authorization': `Bearer ${openRouterKey}`,
                            'Content-Type': 'application/json'
                        },
                        timeout: 7000
                    }
                );

                if (aiResponse.data && aiResponse.data.choices && aiResponse.data.choices[0]) {
                    const aiResult = JSON.parse(aiResponse.data.choices[0].message.content);
                    if (aiResult.AI_Score !== undefined) {
                        riskScore = Math.max(riskScore, aiResult.AI_Score);
                    }
                    if (aiResult.Phishing_Detected === true) {
                        isPhishing = true;
                    }
                    if (aiResult.Deep_Reason) {
                        flags.push(`AI Analysis: ${aiResult.Deep_Reason}`);
                    }
                }
            }
        } catch (aiErr) {
            flags.push('Heuristic scanning completed. Deep AI context verification bypassed due to transport layer state.');
        }

        if (riskScore >= 50) {
            isPhishing = true;
        }

        return {
            original_url: url,
            final_url: finalUrl,
            risk_score: Math.min(riskScore, 100),
            is_phishing: isPhishing,
            details: {
                redirects_count: redirectsCount,
                redirect_path: redirectHistory,
                detected_flags: flags,
                target_domain: domain
            }
        };
    } catch (error) {
        return {
            original_url: url,
            final_url: url,
            risk_score: 0,
            is_phishing: false,
            details: {
                error: error.message,
                redirects_count: 0,
                redirect_path: [url],
                detected_flags: ['Failed to reach target server completely']
            }
        };
    }
}

module.exports = { scanLink };