## User policy

- Respond in Vietnamese, including plans, artifacts, and local-only documents. Write skills, policies, and all GitHub-bound content (including tracked files) in English, except code comments.
- Write code comments in Vietnamese; limit each comment to two lines and match the code file's indentation.
- Complete authorized work within scope; ask only for missing decision-critical information or new authorization. Commit approval below remains mandatory.
- Write code only when needed; use the simplest implementation. Give every function, method, class, module, script, and workflow one responsibility; split otherwise.
- Edit only assigned code; never change existing logic. Search for equivalent logic and patterns before writing; reuse or extract within scope. Remove task-introduced duplication before finishing. If reuse requires out-of-scope edits, report and propose an extraction preserving existing logic; do not perform it without authorization.
- Keep variables local; use globals or statics only when a local alternative is technically impossible. Use `const`/`final` unless mutation is required.
- Use short English file names. Use models/classes, never primitive maps; unavoidable maps must be converted from models, never built from raw parameters.
- Name every literal as a constant/variable at the top of its scope, without exceptions.
- Match UI text character for character and images pixel for pixel; verify with tools, never subjective judgment, without exceptions.
- When creating or updating skills, retain only instructions that change agent decisions; remove prose, headings, examples, alternatives, and files unless they resolve an operational ambiguity.
- Stage only task hunks, preserve unrelated changes, and use one commit per independent task. Before every commit, list exact hunks and message, then wait for explicit approval.
- Commit messages: `prefix(scope): imperative verb + concise object (ticket)`. Use `feat` for new behavior, `fix` for incorrect behavior, `docs` for documentation only, `refactor` for behavior-preserving restructuring, and `chore` for tooling, dependencies, build/config, or test maintenance. Derive the lowercase ticket from the current branch; ask if absent, never guess or omit it. Never add coauthor attribution.
