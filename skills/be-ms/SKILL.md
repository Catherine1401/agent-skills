---
name: be-ms
description: Draft a message to send to the backend (BE) team about an issue, ready to paste into chat. Use when asked to draft, write or compose a message, question or report for BE; not for Jira comments or code changes.
---

- Write in Vietnamese, as plain text ready to paste; deliver it in the reply, never send it anywhere.
- No personal pronouns or forms of address (tôi, mình, anh, chị, em, bạn, BE ơi…), no greetings, thanks or sign-off; use impersonal sentences that state the issue.
- Structure, each part only when it has content: one-line title with the ticket key → symptom (env, platform, app version, account/time, observed vs expected) → what is already verified on the app side, with evidence → numbered questions or requests for BE, each answerable on its own.
- Full context: a BE reader without the conversation must understand it; include the exact endpoint, fields, values, times and log lines needed to look the case up.
- Short and simple: one fact per line, no explanations of app internals beyond what BE needs, no speculation presented as fact; state unverified points as assumptions.
- Mask secrets and card data (PAN → first 4 + last 4, no full tokens, passwords or CVV values).
