# Store listing prep — Google Play & Apple App Store

Working sheet for the first store submissions. Everything the listings need,
mapped to what the app actually does. Update URLs once splitllm.com is live.

## App identity

| | |
|---|---|
| Name | SplitLLM |
| Android applicationId | `com.splitllm.app` |
| iOS bundle id | `com.splitllm.app` |
| Category | Finance (both stores) |
| Support email | support@splitllm.com |
| Marketing / website | https://splitllm.com (until then: the Catalyst web app URL) |
| Privacy policy URL | https://splitllm.com/privacy — served by the web app (`/app/privacy` on the dev domain) |
| Terms URL | https://splitllm.com/terms |

Both policy pages are public routes in the app itself, so the in-app and
hosted versions can never drift.

## Copy

**Short description (Play, ≤80 chars):**
> Split bills with friends — scan receipts, type expenses, settle up with UPI.

**Subtitle (App Store, ≤30 chars):**
> Split bills. Settle with UPI.

**Full description (both stores):**
> SplitLLM keeps group expenses painless. Type "dinner 1200 split with Ana
> and Raj" or snap the receipt — AI fills in the amount, date, and items for
> you to confirm.
>
> • Groups and friends — track trips, flats, and one-off dinners
> • Receipt scanning — photograph a bill and get a structured expense
> • Natural-language entry — describe the expense, skip the forms
> • Multi-currency — spend in one currency, settle in yours
> • Settle up with UPI — one tap opens your payment app, or share a QR code
> • Personal expenses — private spending tracked alongside shared ones
>
> No ads. Your data is never sold. Delete your account (and your data)
> any time from the Account screen.

**Keywords (App Store, ≤100 chars):**
> split,bills,expenses,group,friends,UPI,settle,receipt,scanner,travel,flatmates,money,shared

## Data safety (Play) / Privacy nutrition (Apple)

Answers reflect the actual implementation — see `/privacy` for the full text.

| Data | Collected? | Linked to identity | Purpose |
|---|---|---|---|
| Email address | Yes | Yes | Account management |
| Name | Yes | Yes | App functionality (shown to friends) |
| User ID | Yes | Yes | App functionality |
| Photos (receipts) | Yes, only when user scans | Yes | App functionality (AI parsing) |
| Other user content (expenses, messages to the parser) | Yes | Yes | App functionality |
| Financial info | **No** — amounts you type are user content; no payment credentials ever touch the app | — | — |
| Location, contacts, browsing, device IDs for ads | No | — | — |

- Tracking (Apple ATT): **none** — no ads, no cross-app tracking, no third-party analytics SDKs.
- Data encrypted in transit: yes (TLS).
- Deletion: in-app (Account → Delete Account) + email support@splitllm.com.
  Play's "account deletion URL": link the hosted app's account screen
  (https://splitllm.com/user-account) and mention the support email.
- Processors to name if asked: Supabase (auth), Zoho Catalyst (hosting + AI,
  IN DC), MongoDB Atlas (DB), ZeptoMail (email).

## Content rating (IARC / Apple age rating)

No violence, gambling, user-to-user unmoderated chat, or mature content →
expect **Everyone / 4+**. The "users can interact" answer: users only share
expenses with people they explicitly invite (invite codes) — answer the
questionnaire accordingly.

## Review-readiness checklist

- [ ] **Demo account for reviewers — required.** Signup needs an invite code
      from an existing user, so reviewers cannot self-register. Create a demo
      user, put its email+password in App Review notes / Play testing
      instructions, and note that signup is invite-gated.
- [ ] Supabase → Auth → URL Configuration: add
      `com.splitllm.app://login-callback` and `com.splitllm.app://reset-password`.
- [ ] `SUPABASE_SERVICE_ROLE_KEY` set on the API (AppSail) so account deletion
      also removes the auth record.
- [ ] Play: upload keystore created (`android/key.properties.example`),
      `flutter build appbundle --release`.
- [ ] Apple: team selected in Xcode, `flutter build ipa`, encryption question
      already answered in Info.plist (`ITSAppUsesNonExemptEncryption=false`).
- [ ] Bump `version:` in pubspec.yaml for every upload (`1.0.0+2`, …).

## Assets still to produce

- Play: feature graphic 1024×500; phone screenshots (min 2, 9:16), 7"/10"
  tablet sets if targeting tablets.
- Apple: 6.9" iPhone screenshots (mandatory), 13" iPad if iPad is enabled.
- Screenshot flow suggestion: dashboard → receipt scan → split editor →
  settle-up QR → friends balance list (dark theme shows well).
- App icon: already shipped in-repo (`assets/icon/`, 1024px master).
