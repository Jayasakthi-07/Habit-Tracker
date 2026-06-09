# Supabase setup — step by step (Phase 0)

This connects Aura Habit Tracker to its cloud backend. It's free and takes about
10 minutes. Follow each step; no coding required. When you're done, send me the
**two values** from Step 4.

---

## Step 1 — Create a free Supabase account
1. Go to **https://supabase.com** and click **Start your project** (sign in with
   GitHub or email).

## Step 2 — Create a project
1. Click **New project**.
2. **Name:** `aura-habit-tracker` (anything is fine).
3. **Database Password:** click **Generate a password**, then **copy and save it**
   somewhere safe (you won't need to type it often, but keep it).
4. **Region:** pick the one closest to you.
5. Click **Create new project** and wait ~2 minutes while it provisions.

## Step 3 — Create the database tables (run the migration)
1. In the left sidebar, open **SQL Editor**.
2. Click **+ New query**.
3. Open the file in this repo: **`supabase/migrations/0001_init.sql`**, copy **all**
   of its contents, and paste into the editor.
4. Click **Run** (bottom-right). You should see **"Success. No rows returned."**
   - This creates all tables, security rules (so each user only sees their own
     data), and turns on real-time sync.

## Step 4 — Get the two values I need
1. In the left sidebar, click the **gear / Project Settings**.
2. Click **API**.
3. Copy these two values and send them to me in chat:
   - **Project URL** — looks like `https://abcdefgh.supabase.co`
   - **anon public** key (under *Project API keys*) — a long string starting
     with `eyJ...`

> ✅ The **anon public** key is safe to share and ship — the database security
> rules (RLS) make sure nobody can read anyone else's data with it.
> ❌ Do **NOT** send the **service_role** key (it's secret). I only need the two
> values above.

---

## What happens next
Once you send me the **Project URL** + **anon public key**, I'll:
- Wire the app to your Supabase project (kept out of source code via build flags).
- Verify the connection and that security rules work.
- Move on to **Phase 1: accounts & sign-in** (Google + email + verification code),
  where I'll give you the next short guide for the Google sign-in setup.

You can keep using the app offline the entire time — nothing breaks while we wait.
