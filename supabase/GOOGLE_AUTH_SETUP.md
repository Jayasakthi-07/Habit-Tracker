# Google Sign-In setup (for Supabase)

This enables the **"Continue with Google"** button. **You can skip this for now** —
email + password + verification code works without it. Do this whenever you're
ready; I'll wire the button to work the moment it's configured.

Your Supabase project reference is **`qvjixjniytgwfrjlygtb`**, so your callback URL
(used below) is:

```
https://qvjixjniytgwfrjlygtb.supabase.co/auth/v1/callback
```

---

## Part A — Create a Google "Web" OAuth client (required)

1. Go to **https://console.cloud.google.com** and select (or create) a project.
2. Left menu → **APIs & Services → OAuth consent screen** (if not already set up):
   - User type **External** → Create. Fill App name (`Aura Habit Tracker`), your
     email for support + developer contact → Save and continue through the steps.
   - Under **Audience/Test users**, add your own Gmail as a test user.
3. Left menu → **APIs & Services → Credentials → + Create credentials → OAuth client ID**.
   - Application type: **Web application**.
   - Name: `Aura Supabase Web`.
   - Under **Authorized redirect URIs**, click **+ Add URI** and paste:
     `https://qvjixjniytgwfrjlygtb.supabase.co/auth/v1/callback`
   - Click **Create**. A dialog shows a **Client ID** and **Client secret** —
     keep this open / copy both.

## Part B — Turn on Google in Supabase

1. Open your project at **https://supabase.com/dashboard** → **Authentication**
   (left menu) → **Providers** (or **Sign In / Providers**).
2. Click **Google** → toggle **Enable**.
3. Paste the **Client ID** and **Client Secret** from Part A.
4. **Save**.

## Part C — Authorize the Windows desktop app (so its browser sign-in works)

The Windows app signs in with a Google **"Desktop"** client (you already created one
earlier: `client_secret_135527892577-...json`). Supabase needs to trust it:

1. Still on the **Google** provider page in Supabase, find
   **"Authorized Client IDs"** (a comma-separated list).
2. Paste the **Desktop client ID** —
   `135527892577-be44t136c8e2aenr02iq4jp1o9u3rvgj.apps.googleusercontent.com`
3. **Save**.

> Android will get its own client later (in the mobile phase) — I'll guide that
> when we build the Android app, since it also needs your app's SHA-1 fingerprint.

---

## What to tell me
Just say **"Google is configured"** once Parts A–C are done. You don't need to send
me the secret — it lives only in your Supabase dashboard. I'll then verify the
Windows "Continue with Google" button creates your account in Supabase.

If you'd rather start with **email sign-up only**, that's already being built and
needs nothing from you here.
