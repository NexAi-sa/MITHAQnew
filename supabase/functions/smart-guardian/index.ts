import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai@0.1.3"

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY!)

const SYSTEM_PROMPT = `
You are the "Mithaq Smart Guardian," an AI moderator for a serious Saudi marriage application. Your mission is to enforce the "Al-Faisal Protocol" which strictly prohibits exchanging direct contact information or external links within the chat to ensure user privacy and seriousness.

Task: Analyze the incoming message for any attempt to share:
1. Phone Numbers: Even if written in words (e.g., "five five zero..."), split by spaces, or using Arabic/Eastern digits.
2. Social Media Handles: Snapchat, Instagram, WhatsApp, or Telegram mentions.
3. External Links: Any URL or domain name intended to move communication off-platform.
4. Indirect Sharing: Phrases like "Find me on..." or "My number is in my profile" (if not officially unlocked).

Output Requirements (JSON format only):
- is_blocked: (Boolean) True if a violation is detected.
- reason: (String) Brief explanation of the violation.
- clean_text: (String) If blocked, return: "⚠️ [تم حجب معلومات التواصل] - يرجى الالتزام ببروتوكول التواصل المرحلي حفاظاً على الخصوصية والجدية." If not blocked, return the original text.
- risk_score: (Integer 0-10) Level of intentional circumvention.
`

serve(async (req) => {
    // CORS handling
    if (req.method === 'OPTIONS') {
        return new Response('ok', {
            headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
            },
        })
    }

    try {
        const { text } = await req.json()

        if (!text) {
            return new Response(JSON.stringify({ error: "No text provided" }), {
                status: 400,
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
            })
        }

        // Quick regex check as advised for cost saving
        const phonePattern = /(\d|[٠-٩]){8,}/
        const handlePattern = /@\w+/

        if (phonePattern.test(text) || handlePattern.test(text)) {
            return new Response(JSON.stringify({
                is_blocked: true,
                reason: "Detected via Regex",
                clean_text: "⚠️ [تم حجب معلومات التواصل] - يرجى الالتزام ببروتوكول التواصل المرحلي حفاظاً على الخصوصية والجدية.",
                risk_score: 10
            }), {
                headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' }
            })
        }

        // AI Check
        const model = genAI.getGenerativeModel({ model: "gemini-pro" })
        const result = await model.generateContent([
            SYSTEM_PROMPT,
            `Message to analyze: "${text}"`
        ])

        const response = await result.response
        const outputText = response.text()

        const jsonMatch = outputText.match(/\{[\s\S]*\}/)
        const analysis = jsonMatch ? JSON.parse(jsonMatch[0]) : { is_blocked: false, clean_text: text }

        return new Response(JSON.stringify(analysis), {
            headers: {
                "Content-Type": "application/json",
                'Access-Control-Allow-Origin': '*'
            },
        })
    } catch (error) {
        return new Response(JSON.stringify({
            error: error.message,
            is_blocked: false,
            clean_text: "Error in processing"
        }), {
            status: 500,
            headers: {
                "Content-Type": "application/json",
                'Access-Control-Allow-Origin': '*'
            },
        })
    }
})
