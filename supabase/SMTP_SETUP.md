# Email / SMTP — fixing "Error sending confirmation email"

## Why Resend failed
Resend's **free** tier only lets you send **from a domain you've verified** (or
from `onboarding@resend.dev`, which only delivers to *your own* account email).
So when Supabase tried to send a confirmation to a normal sign-up address, Resend
rejected it → Supabase reports **"unexpected_failure: Error sending confirmation
email"**. It's not a bug in the app — it's the SMTP provider rejecting the send.

You have two good paths. **You can do Option A right now to be unblocked, and add
Option B later for real verification emails.**

---

## ✅ Option A — Unblock instantly: turn OFF email confirmation (no SMTP at all)
Best if you just want sign-up working today. The app already handles this: with
confirmation off, creating an account signs you in immediately (no code step).

1. Supabase Dashboard → **Authentication → Providers → Email**
   (or **Sign In / Providers → Email**).
2. Turn **OFF** "**Confirm email**".
3. **Save.**

That's it — **Create account** now works with no email needed. (Trade-off: emails
aren't verified. Fine for now; switch on Option B whenever you want verification.)

---

## ⭐ Option B — Recommended free SMTP that actually works: **Brevo**
Free **300 emails/day**, no domain required (just verify one sender email), easy,
reliable. Keep "Confirm email" **ON** to use the 6-digit code flow.

### 1. Create a Brevo account
- Go to **https://www.brevo.com** → sign up (free). Verify your account email.

### 2. Verify a sender
- Brevo → **Senders, Domains & Dedicated IPs → Senders → Add a sender**.
- Use your own email (e.g. your Gmail) as the sender → Brevo emails you a
  confirmation link → click it. Now you can send **to anyone**.

### 3. Get SMTP credentials
- Brevo → **SMTP & API → SMTP** tab. Note:
  - **Server / Host:** `smtp-relay.brevo.com`
  - **Port:** `587`
  - **Login:** the email/login shown there (your Brevo account email)
  - **Password:** click **Generate a new SMTP key** → copy it.

### 4. Put them into Supabase
- Supabase → **Authentication → Emails → SMTP Settings** (toggle **Enable Custom
  SMTP**), and fill:
  | Field | Value |
  |-------|-------|
  | Sender email | the sender you verified in step 2 |
  | Sender name | `Aura Habits` |
  | Host | `smtp-relay.brevo.com` |
  | Port number | `587` |
  | Username | your Brevo login (step 3) |
  | Password | the Brevo SMTP key (step 3) |
- **Save.**

### 5. Raise the email rate limit (optional)
- Supabase → **Authentication → Rate Limits** → increase "**Emails per hour**"
  (default is low). 100–300 is fine on Brevo's free tier.

### 6. Make the email show the 6-digit code
- Do the one-minute step in **`supabase/EMAIL_VERIFICATION.md`** (template must
  contain `{{ .Token }}`).

### 7. Test
- App → **Create account** → you'll receive the 6-digit code → enter it. ✅

> **Backup option:** if you ever prefer another provider, **Mailjet** (free
> ~200/day) works the same way — host `in-v3.mailjet.com`, port `587`, username =
> API key, password = secret key.

---

## My recommendation
Do **Option A now** (1 toggle) so you can build/test the whole app today, then set
up **Brevo (Option B)** when you want proper email verification before launch.
Both are free; the app supports either with no code changes.
