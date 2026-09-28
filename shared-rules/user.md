## User policy

- KISS: write the least and simplest code that satisfies the task. Write code only when required; when not required, write none.
- Single responsibility: each code unit—function, method, class, module, script, and workflow—has one clear responsibility. Split it when it handles more than one.
- Scope: edit only code within the assigned task. Never edit code outside it. Never change the logic of existing code.
- DRY is mandatory: before writing code, search the task scope for equivalent logic. Reuse or extract it; never create a second implementation. Before finishing, remove any duplication introduced by the current task.
- DRY vs Scope: if DRY requires editing code outside the task, do not edit it. Report to the user and propose extracting the shared code for reuse. Any extraction must preserve the existing logic exactly.
- Reuse first: follow existing patterns. Write new code only when no existing pattern fits.
- Scope of data: default to local scope. Never introduce a global or static variable unless a local alternative is technically impossible — this is a hard constraint, not a preference.
- File names: use English words; keep names short and concise.
- Typed data only: always use a model/class, never a primitive map. If a map is unavoidable, populate it only by converting from a model — never pass raw parameters into it.
- No magic values: declare every literal as a named constant/variable at the top of its scope, with no exceptions for literals that occur only once or are unique to one call site. Never leave a literal inline because it does not repeat elsewhere or because other code in the codebase inlines similar literals.
- Immutability by default: use `const`/`final` everywhere; only omit them when mutation is required.
- For all UI coding involving text or images, match text exactly character by character and images exactly pixel by pixel; use tools to verify an exact match, never rely on subjective judgment, and allow no exceptions.
- Skills and policies: always write skill and policy content in English, without exception.
- GitHub: write all content intended for GitHub in English, without exception, including tracked files, commit messages, pull requests, issues, and comments.
- Language: respond to the user in Vietnamese, including plans, artifacts, and local-only documents, except content required to be in English by the rules above.
- Commit ticket code: every commit message must end with a lowercase ticket code in parentheses, e.g. `(ew1234)`, derived from the current branch name. If no ticket code can be derived from the branch name, ask the user for it — never guess or omit it. This applies in addition to any other commit-message rules (e.g. the commit skill's format).
