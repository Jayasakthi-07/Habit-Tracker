# Email verification code setup (1 minute)

The app's sign-up uses a **6-digit code** (not a link). Supabase's default
confirmation email sends a *link*, so we switch the template to show the **code**.

## Steps
1. Open **https://supabase.com/dashboard** → your project.
2. Left menu → **Authentication** → **Emails** (a.k.a. *Email Templates*).
3. Select the **"Confirm signup"** template.
4. Replace its content with the template below, then **Save**:

```html
<h2>Confirm your sign-up</h2>
<p>Welcome to Aura Habits! Enter this code in the app to verify your account:</p>
<p style="font-size:32px;font-weight:800;letter-spacing:8px;margin:16px 0;color:#0e9f6e;">
  {{ .Token }}
</p>
<p style="color:#666;font-size:13px;">This code expires in 1 hour. If you didn't request it, you can ignore this email.</p>
```

The key part is **`{{ .Token }}`** — that's the 6-digit code the app asks for.

## Also check
- **Authentication → Providers → Email** should have **"Confirm email" ON**
  (this is the default). That's what triggers the verification step.
- The built-in email sender is **rate-limited** (a handful per hour) and is fine
  for testing. For production, I'll later help you connect a free **Resend** SMTP
  so emails are fast and unlimited.

## Test it
After saving, in the app: **Create account → enter name/email/password → Create
account**. You'll get the code by email; type it on the next screen to finish.

> Nothing to send me here — just save the template and you can test sign-up.
