# MenuMind — Google Play store listing (draft)

Copy-paste-ready text + answers for the Play Console forms. Review and tweak the
**bracketed** bits before submitting.

Privacy Policy URL: `https://menu-mind-tawny.vercel.app/privacy`
Contact email: `tanigna.work@gmail.com`
Category: **Food & Drink** · Type: App · Free · No ads · No in-app purchases

---

## App name (≤ 30 chars)
```
MenuMind: Menu Translator
```

## Short description (≤ 80 chars)
```
Photograph any menu and get every dish translated — with AI-generated photos.
```

## Full description (≤ 4000 chars)
```
Traveling abroad and can’t read the menu? MenuMind turns a photo of any
restaurant menu into a menu you actually understand.

Point your camera at the menu, and MenuMind reads every dish, translates it into
English, and generates a photorealistic image of each one — so you can see what
an unfamiliar dish really looks like before you order.

WHAT IT DOES
• Snap & translate — every dish translated (original + English), original text kept
• AI dish photos — a generated image for each dish, so nothing is a mystery
• 40+ languages — even mixed-language menus (e.g. German + Italian on one page)
• Dietary filters — Vegetarian, Vegan, Gluten-free, Spicy, Sweet, with allergen warnings
• Nutrition estimates — calories plus protein / carbs / fat per dish
• History — your past scans, saved and searchable
• Fast — translated text appears instantly while photos stream in

HOW IT WORKS
1. Take a photo of the menu (or pick one from your gallery).
2. MenuMind reads and translates it in seconds.
3. Browse dishes by category, tap any for its photo, description and nutrition.

No account, no sign-up. Just scan and go.

MenuMind is perfect for travelers, foodies, and anyone facing a menu in a
language they don’t speak.
```

## Notes
- Dish images and nutrition are AI-generated estimates — a disclaimer is shown in-app.

---

## Content rating (IARC questionnaire) — expected answers
- Violence / scary content: **No**
- Sexual content / nudity: **No**
- Profanity, drugs, alcohol, tobacco, gambling: **No**
- User-generated content shared with others: **No** (results are private to the user)
- Does the app share the user’s location: **No**
- → Expected rating: **Everyone / PEGI 3**

---

## Data safety form — answers

> Scope: this form is about the **Android app**. The Android app has **no
> analytics/crash SDK** (PostHog is web-only), so don't declare analytics here.

**Does your app collect or share any of the required user data types?** → **Yes**

**Is all data encrypted in transit?** → **Yes** (HTTPS)
**Do you provide a way to request data deletion?** → **Yes** (email in privacy policy)

### Data types — declare exactly these

**Photos and videos → Photos**
- Collected: **Yes** · Shared: **Yes**
- Purpose: **App functionality** (read + translate the menu; the stored copy is
  used to diagnose and improve menu recognition)
- Linked to the user's identity: **No** (app has no account/login)
- Processed ephemerally: **No** — the menu photo is sent to the server and to
  Google (Gemini) to read the text, and is **stored for up to 30 days** (then
  auto-deleted) so failed scans can be inspected. (AI-*generated* dish images are
  cached separately, keyed by a content hash.)
- Shared with: our backend and **Google (Gemini)** for OCR/translation.

That is the **only user-data type to declare.**

### Do NOT declare
- **App activity / analytics** — the Android app has no analytics SDK.
- **Crash/diagnostics** — no crash-reporting SDK in the app.
- Name, email, phone, precise/approx location, contacts, financial info, health,
  messages, calendar, files — none collected (no account, no login).

### IP address (edge case)
Collected server-side **only** to rate-limit uploads / prevent abuse. Google's
Data safety form has no dedicated "IP for security" data type, and IP used purely
for fraud/abuse prevention is one of the documented exceptions you are **not
required to disclose**. Leave it undeclared; it's covered by the privacy policy.

---

## Other required declarations
- **App access:** All functionality is available without any special access / login → declare "All functionality is available without restrictions."
- **Ads:** No ads.
- **Target audience:** 13+ (not designed for children).
- **News app / COVID / government:** No.
- **Financial features:** No.

---

## Assets (in ./assets)
- `icon-512.png` — 512×512 app icon
- `feature-graphic-1024x500.png` — Play feature graphic
- Screenshots: **you capture** ≥ 2 (phone), ideally 4–8 — Scan, Loading, Menu, Dish detail.
