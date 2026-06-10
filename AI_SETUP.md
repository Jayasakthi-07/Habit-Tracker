# 🤖 AI Coach — API key setup (Aura Habits)

> The AI Coach gives personalised habit advice grounded in your real data. It
> supports **three engines — OpenRouter, OpenAI, and Google Gemini**. You only
> need **one** key to start.
>
> **Priority:** the app uses **OpenRouter first**, and **automatically falls back
> to OpenAI** if OpenRouter is unavailable (then Gemini). You can also switch
> manually in the coach when more than one key is configured.
>
> Everything you do here is clicking in the browser. When you have a key, paste
> it to me and I'll drop it into `env.json` and rebuild — you never touch code.

---

## ✨ Easiest way (v1.1+): paste the key inside the app

Both apps now accept keys **at runtime** — no rebuild needed, and this is how
the **public release downloads** (GitHub APK / Windows zip) unlock AI, since
those builds ship with **no embedded keys** for security:

1. Open **AI Coach** (sparkle icon on the dashboard / sidebar).
2. Click the **key icon** (top-right) — or the **"Add API key"** button shown
   when no key is set.
3. Paste your OpenRouter (recommended), OpenAI, and/or Gemini key and **Save**.

The key is stored **only on that device** (local settings, never synced, never
committed). Priority stays OpenRouter → OpenAI → Gemini with automatic
fallback. Keys baked into a personal `env.json` build keep working as before —
an in-app key simply takes precedence.

---

## Option 0 — OpenRouter (preferred — one key, many models)

1. Go to **https://openrouter.ai/keys** and sign in.
2. Click **Create Key**, name it "Aura Habits", and copy it (starts with
   `sk-or-...`).
3. (Optional) add a few dollars of credit, or pick a free model — see below.
4. 📋 **Paste it to me.** I add it as `OPENROUTER_API_KEY` in `env.json`.

The default model is `openai/gpt-4o-mini` (cheap, reliable). To use a different
or free model, set `OPENROUTER_MODEL` (e.g. `google/gemini-flash-1.5` or a
`:free` model) — just tell me which and I'll set it.

---

## Option A — Google Gemini (free, recommended to start)

1. Go to **https://aistudio.google.com/app/apikey** (sign in with your Google
   account).
2. Click **"Create API key"** (and pick/allow a Google Cloud project if asked —
   "Create API key in new project" is fine).
3. Copy the key it shows (a long string starting with `AIza...`).
4. 📋 **Paste that key to me.** I'll add it as `GEMINI_API_KEY` in `env.json`.

That's it — the free tier is plenty for personal coaching.

---

## Option B — OpenAI (paid, optional)

OpenAI requires a small prepaid balance (a few dollars lasts a long time at the
default low-cost model).

1. Go to **https://platform.openai.com/api-keys** and sign in / sign up.
2. If you haven't already, add a little credit under **Settings → Billing**
   (e.g. \$5). Coaching uses tiny amounts.
3. Click **"Create new secret key"**, name it "Aura Habits", and **Create**.
4. **Copy the key immediately** (starts with `sk-...`) — OpenAI only shows it
   once.
5. 📋 **Paste that key to me.** I'll add it as `OPENAI_API_KEY` in `env.json`.

---

## What I do with the key(s)

I add them to the gitignored `env.json` (never committed):

```json
{
  "SUPABASE_URL": "…",
  "SUPABASE_ANON_KEY": "…",
  "GEMINI_API_KEY": "AIza…",
  "OPENAI_API_KEY": "sk-…"
}
```

Then I rebuild the app. The **AI Coach** (sparkle icon on the dashboard, and in
Profile → AI Coach) unlocks. If both keys are present, a **switcher** appears in
the coach's top-right so you can choose Gemini or OpenAI per the locked product
decision.

Optional model overrides (defaults are fine): `GEMINI_MODEL`
(default `gemini-2.0-flash`), `OPENAI_MODEL` (default `gpt-4o-mini`).

---

## Privacy note

The coach sends a **compact summary of your habit stats** (names, streaks,
success rates, today's status, average mood) plus your question to the provider
you chose. It does not send your account credentials. Use Gemini if you prefer
to keep it on Google's free tier.
