# 🔐 Android Google Sign-In — Setup Guide (Aura Habits mobile)

> **You only need this to make the "Continue with Google" button work on the
> Android app.** Email + verification-code sign-in already works with no setup.
> When you're ready for Google, follow these steps. It takes ~15 minutes and is
> all clicking in the browser — no coding. Do them **in order**.

We use the same Google Cloud project and the same Supabase project that the
Windows app already uses. We're just **adding an Android client** to it.

---

## The two values I already generated for you

You'll paste these into Google Cloud below — copy them from here:

| Field | Value |
|---|---|
| **Android package name** | `com.aura.aura_habits_mobile` |
| **SHA-1 fingerprint (debug)** | `E4:EC:3A:E4:3A:5F:C8:B7:85:93:EE:22:37:95:51:32:64:AB:3E:D4` |

> The SHA-1 above is from your computer's **debug** signing key (used while
> testing). When we publish to the Play Store (Phase 11) we'll add a second,
> **release** SHA-1 the same way — I'll generate it for you then.

---

## Part A — Create the Android OAuth client (Google Cloud)

1. Go to **https://console.cloud.google.com/apis/credentials**.
2. At the very top, make sure the **project selector** (next to the "Google
   Cloud" logo) shows the **same project** you used for the Windows app's Google
   sign-in. If you're not sure which one, pick the project that already has
   "Aura" / habit-tracker OAuth clients listed on this page.
3. Click **➕ Create credentials** (top of the page) → **OAuth client ID**.
4. **Application type:** choose **Android**.
5. Fill in:
   - **Name:** `Aura Habits Android` (any name; just for you to recognise it).
   - **Package name:** `com.aura.aura_habits_mobile`
   - **SHA-1 certificate fingerprint:** paste
     `E4:EC:3A:E4:3A:5F:C8:B7:85:93:EE:22:37:95:51:32:64:AB:3E:D4`
6. Click **Create**. You'll see a confirmation — there's **no secret** to copy
   for Android clients, so just click **OK**. ✅

---

## Part B — Get (or confirm) the Web client ID

The Android app needs a **Web** OAuth client ID to ask Google for a token that
Supabase can verify. Your project very likely already has one (the Windows
loopback flow / Supabase setup created it). Let's find or create it.

1. Still on **https://console.cloud.google.com/apis/credentials**.
2. Look under **"OAuth 2.0 Client IDs"** for an entry whose **Type** is **Web
   application**. If one exists, click it and **copy its Client ID** (it ends in
   `…apps.googleusercontent.com`). That's your **Web client ID** — skip to Part C.
3. **If there is no Web client**, create one:
   - **➕ Create credentials** → **OAuth client ID** → **Application type: Web
     application** → **Name:** `Aura Habits Web` → **Create**.
   - Copy the **Client ID** it shows you (ends in `…apps.googleusercontent.com`).

📋 **Paste that Web client ID here when you give it to me** — I'll add it to
`env.json` as `GOOGLE_WEB_CLIENT_ID` so the app can use it. (The Web client's
*secret* is **not** needed on Android — only the ID.)

---

## Part C — Tell Supabase to trust the Android sign-in

Supabase must accept tokens that Google issued for our app.

1. Go to **https://supabase.com/dashboard** → open the **Aura** project
   (`qvjixjniytgwfrjlygtb`).
2. Left sidebar: **Authentication** → **Providers** (or **Sign In / Providers**)
   → click **Google**.
3. In the **"Authorized Client IDs"** box you'll already see the desktop client
   IDs (comma-separated). **Add two more**, separated by commas:
   - the **Web client ID** from Part B, and
   - the **Android client ID** from Part A (open the Android client you created
     to copy its Client ID — it also ends in `…apps.googleusercontent.com`).
4. Click **Save**. ✅

> Why both: Supabase checks the token's "audience". Google issues the token for
> the **Web** client (so include that), and listing the **Android** client too
> keeps things future-proof. Adding extra IDs here is safe.

---

## Part D — Give me the Web client ID

Send me the **Web client ID** (the `…apps.googleusercontent.com` string from
Part B). I will:
1. Add `GOOGLE_WEB_CLIENT_ID` to `env.json`.
2. Rebuild the Android app.
3. The **Continue with Google** button will then work — tapping it shows the
   Google account picker and signs you straight in, syncing the same data as on
   Windows.

---

## Troubleshooting (for later)

- **"Google sign-in failed" / token error right after picking an account** →
  almost always the **Web client ID** isn't in Supabase's *Authorized Client
  IDs*, or `GOOGLE_WEB_CLIENT_ID` doesn't match. Re-check Part C.
- **`DEVELOPER_ERROR` / code 10 in logs** → the **SHA-1** or **package name** in
  the Android client (Part A) doesn't match the app. They must be exactly the
  values in the table at the top.
- **Works in debug but not after Play Store release** → you'll need to add the
  **release** SHA-1 (Play App Signing key). Ping me in Phase 11 and I'll walk
  you through it.
