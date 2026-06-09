# Email / SMTP — fixing "Error sending confirmation email"

## Why Resend failed
Resend's **free** tier only lets you send **from a domain you've verified** (or
from `onboarding@resend.dev`, which only delivers to *your own* account email).
So when Supabase tried to send a confirmation to a normal sign-up address, Resend
rejected it → Supabase reports **"unexpected_failure: Error sending confirmation
email"**. It's not a bug in the app — it's the SMTP provider rejecting the send.

## Why Brevo failed too (freemail senders)
If you sent **from a `@gmail.com` address**, Brevo (and most providers) now **block
transactional sending from free webmail domains** because of Gmail/Yahoo's 2024
DMARC rules — you can't add the required DNS records to `gmail.com`. Brevo flags
this as *"not compliant… to be able to use it for email sending."* That's the
`unexpected_failure`. The fix is to send from an address whose mail server you
actually control. The two reliable free ways:

- **Gmail SMTP with an App Password (Option B below)** — sends *through* Gmail
  itself, authenticated as you, so DMARC passes. Free, ~500/day, no domain needed.
- **A custom domain** verified in Brevo (Option C) — best for launch, costs ~\$1-2/yr.

**You can do Option A right now to be unblocked, and set up Option B for real
verification emails.**

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

## ⭐ Option B — Gmail SMTP with an App Password (recommended, free, works with your Gmail)
Sends *through* Gmail's own servers authenticated as you, so DMARC passes and
there's no freemail block. ~500 emails/day free — way above your 100/day need.
Keep "Confirm email" **ON** to use the 6-digit code flow.

> Use the Gmail account you want to send from (e.g. `aurahabittracker@gmail.com`).

### 1. Turn on 2-Step Verification (required for App Passwords)
- Go to **https://myaccount.google.com/security** (signed in as that Gmail).
- Enable **2-Step Verification** if it isn't already.

### 2. Create an App Password
- Go to **https://myaccount.google.com/apppasswords**
  (or search "App passwords" in your Google Account).
- App name: `Supabase` → **Create**.
- Google shows a **16-character password** like `abcd efgh ijkl mnop`.
  **Copy it and remove the spaces** → `abcdefghijklmnop`.

### 3. Put it into Supabase (Authentication → Emails → SMTP Settings)
| Field | Value |
|-------|-------|
| Enable custom SMTP | ON |
| Sender email address | `aurahabittracker@gmail.com` (the SAME Gmail) |
| Sender name | `Aura Habit Tracker` |
| Host | `smtp.gmail.com` |
| Port number | `587` |
| Username | `aurahabittracker@gmail.com` (the SAME Gmail) |
| Password | the 16-char App Password (no spaces) |

> ⚠️ With Gmail, **Sender email = Username = your Gmail address**. Gmail won't send
> "from" a different address than the authenticated account.

### 4. Save → then do the `{{ .Token }}` template
(`supabase/EMAIL_VERIFICATION.md`) and test **Create account**. You'll get the
6-digit code in your inbox. ✅

If it still errors, double-check there are **no spaces** in the App Password and
that **Sender email exactly equals Username**.

---

## Option C — Brevo (only reliable with a custom domain)
Free **300/day**, but as you found, sending from a `@gmail.com` sender is blocked.
This option works well **once you verify a domain you own** (~\$1-2/yr from
Namecheap/Cloudflare) in Brevo with DKIM. If you have/get a domain, tell me and
I'll guide the DNS records. Otherwise prefer Option B above.

Brevo SMTP fields (for reference, with a verified **domain** sender):

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
