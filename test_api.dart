import 'dart:convert';
import 'dart:io';

void main() async {
  final apiKey = File('.env').readAsStringSync().split('GEMINI_API_KEY=').last.split('\n').first.trim();
  final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\$apiKey';
  
  final prompt = """You are a medicine expert AI. Your job is to give clear, specific, accurate information to someone who has zero medical knowledge.

[USER PROFILE — USE THIS TO PERSONALISE THE WARNING]
- Age: 30
- Known allergies: None
- Medical history / conditions: Hypertension, High Blood Pressure
You MUST check this profile when filling in personalizedWarning.

STEP 1 — IDENTIFY the medicine from the image and OCR text below.
CRITICAL VALIDATION: If the image and text clearly show something that is NOT a medicine, supplement, or health product (e.g., a phone case, food, toy, screen protector), you MUST STOP. Return exactly this JSON:
{ "name": "Unknown Medicine", "shortDescription": "", "function": "", "dosage": "", "sideEffects": [], "recipients": [], "contraindications": [], "allergies": [], "personalizedWarning": "" }
Do NOT hallucinate a medicine. Only proceed to STEP 2 if it is actually a health product.

STEP 2 — FILL IN ALL FIELDS from your pharmaceutical knowledge database. Pretend the user can only see the medicine box front — give them everything else they need to know.

FIELD-BY-FIELD RULES (follow strictly):

"shortDescription": Max 12 words. Ultra-brief. What this medicine is for, in the simplest words. E.g. "Helps with gout pain and bladder discomfort." or "Antibiotic tablet that fights bacterial infections."

"function": 1 short sentence. Use simple everyday words and an analogy if possible. Imagine explaining to a 10-year-old. BAD: "It makes the urine less acidic which prevents calcium oxalate crystallization." GOOD: "It makes your pee less sour so crystals can't form and hurt your joints."

"dosage": Format as EXACTLY 3 short lines, each on a new line, like this:
Amount: 1 sachet (4g)
How often: 3 times a day
When: After meals. Keep each line under 6 words. Do NOT write a paragraph.

"sideEffects": List real known side effects with plain descriptions. Max 4 items. E.g. "Bloating or gassy feeling", "Stomach cramps", "Nausea if taken on empty stomach". BAD: "Gastrointestinal discomfort".

"recipients": State exactly who benefits. E.g. "Adults with gout flare-ups", "People with frequent urinary tract infections", "Anyone told by a doctor their urine is too acidic".

"contraindications": State exactly who must NOT take it and why in simple words. E.g. "People with high blood pressure (it contains sodium)", "Anyone with kidney failure", "Pregnant women — ask doctor first".

"allergies": List the actual chemical ingredients that could cause allergic reactions. Name them. E.g. "Sodium Citrate", "Citric Acid", "Tartaric Acid", "Sodium Bicarbonate". Do NOT say "allergic to any ingredient" — that is useless.

"personalizedWarning": CRITICAL — You MUST check the [USER PROFILE] section above before filling this field. Prioritize MEDICAL HISTORY and ALLERGIES above all else.
Generate SHORT bullet-point warnings. Each bullet max 15 words. Only include a bullet if it genuinely applies. Rules (in priority order):
1. MEDICAL HISTORY — STRICTLY cross-check 'Medical history / conditions' from the user profile against known contraindications for this medicine. For example, if user has hypertension/high blood pressure and the medicine contains NSAIDs/decongestants/pseudophedrine or high sodium, you MUST output: "⚠️ Caution: Not suitable if you have [condition] — consult doctor."
2. ALLERGY — STRICTLY cross-check this medicine's ingredients against 'Known allergies'. If matched: "🚨 Allergy alert: Contains [ingredient] — avoid."
3. EXPIRY — If you clearly read a date in the image/OCR ("EXP", "Expiry", "Best Before", "Use By") with HIGH confidence. If expired vs today (\${DateTime.now().year}): "⚠️ Expired: [Date] — do not take.". If still valid: "📅 Expires: [Date].". If date is NOT clearly visible/readable, say NOTHING about expiry.
4. AGE — If user age makes this medicine unsuitable: "⚠️ Age caution: [brief reason]."
5. FOOD — Name specific foods/drinks that interact with it. Be extremely brief, name the food only. Format: "��️ Avoid: [food1, food2]". If no specific food interacts, do NOT include this bullet.
If none apply, return "". Use bullet points only. No generic advice. No paragraphs.

GENERAL RULES:
- Plain English only. No medical jargon. Replace: "renal"→"kidney", "hypersensitivity"→"allergy", "dysuria"→"pain when peeing", "alkalinizer"→"makes urine less acidic".
- Every field must have REAL, SPECIFIC content from your training data. Never say "not listed", "not on packet", "see a doctor for details", or leave generic filler text.
- Lists: max 4 items, each max 10 words.
- Text fields: max 2 sentences.
- Return ONLY valid JSON. No markdown. No text outside the JSON.

OCR text (to identify the medicine only):
Sudafed PE Sinus Congestion
Active Ingredient: Phenylephrine HCl

{
  "name": "<brand name + strength>",
  "shortDescription": "<1 sentence, specific>",
  "function": "<1 sentence, specific mechanism>",
  "dosage": "<specific amount, timing, method>",
  "sideEffects": ["<specific>", "<specific>", "<specific>"],
  "recipients": ["<specific group>", "<specific group>"],
  "contraindications": ["<specific + reason>", "<specific + reason>"],
  "allergies": ["<actual ingredient name>", "<actual ingredient name>"],
  "personalizedWarning": "• bullet one\\n• bullet two\\n(plain string with \\n between bullets, NOT a JSON array)"
}""";

  final requestBody = jsonEncode({
    "contents": [{"parts":[{"text": prompt}]}]
  });

  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Content-Type', 'application/json');
    request.add(utf8.encode(requestBody));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    print(responseBody);
    client.close();
  } catch (e) {
    print('Error: \$e');
  }
}
