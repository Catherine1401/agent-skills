## User policy

- KISS: write the least and simplest code that satisfies the task. Write code only when required; when not required, write none.
- Scope: edit only code within the assigned task. Never edit code outside it. Never change the logic of existing code.
- DRY: never duplicate code, for any reason. Extract and reuse shared logic.
- DRY vs Scope: if DRY requires editing code outside the task, do not edit it. Report to the user and propose extracting the shared code for reuse. Any extraction must preserve the existing logic exactly.
- Reuse first: follow existing patterns. Write new code only when no existing pattern fits.
- Scope of data: prefer local over global. Minimize global and static variables.
