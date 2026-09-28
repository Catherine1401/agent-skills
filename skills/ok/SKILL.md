---
name: ok
description: Give blanket approval to the single most recent pending confirmation request in this conversation, so the user doesn't have to type it out. Use when the user invokes /ok.
---

- Treat this invocation as explicit approval for the single most recent action the agent asked the user to confirm (e.g. a proposed commit, plan, or other approval-gated step) — proceed with exactly that action as proposed.
- If nothing is currently awaiting approval, say so instead of taking any action.
- This approves only that one pending request; any later proposal still needs its own confirmation (a new `/ok` or explicit approval).
