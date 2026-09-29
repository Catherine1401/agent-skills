---
name: ok
description: Give blanket approval to the agent's latest pending confirmation request, or confirm the agent's latest result worked when it asked the user to verify. Use when the user invokes /ok.
---

- Read only the agent's latest message; a request from an earlier message that the agent moved past is no longer pending.
- If it asks the user to confirm an action (e.g. a proposed commit, plan, or other approval-gated step), treat this invocation as explicit approval and proceed with exactly that action as proposed.
- If it reports a result the agent could not verify or asks the user to test or check it, treat this invocation as the user's confirmation that the result is correct: record it as verified and take no further action, including no commit.
- If neither applies, say so instead of taking any action.
- This approves only that one item; any later proposal still needs its own confirmation (a new `/ok` or explicit approval).
