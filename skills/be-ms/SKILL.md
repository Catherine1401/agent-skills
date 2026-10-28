---
name: be-ms
description: Draft a message to send to the backend (BE) team about an issue, ready to paste into chat. Use when asked to draft, write or compose a message, question or report for BE; not for Jira comments or code changes.
---

- Write in Vietnamese, as plain text ready to paste; deliver it in the reply, never send it anywhere.
- No personal pronouns or forms of address (tôi, mình, anh, chị, em, bạn, BE ơi…), no greetings, thanks or sign-off; use impersonal sentences that state the issue.
- Structure: bold title (ticket key if known) → `Hiện trạng:` one line observed + one line requested → numbered sections per endpoint, each with `Request:` and `Response:` code blocks (method + full path, complete JSON with realistic values) → `Cần BE xác nhận` only for points the app cannot decide; omit any empty part.
- The app owns field names, enum values and payload shape: state them as requirements; never ask BE to confirm or choose them.
- Read the app's current mappers and data sources first; reuse their existing field names and endpoints.
- Omit app-internal findings, root-cause analysis, verification notes and prose explanations; one fact per line.
- Mask secrets and card data (PAN → first 4 + last 4, no full tokens, passwords or CVV values).
