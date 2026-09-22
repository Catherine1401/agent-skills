---
name: report
description: Create or update a searchable task context handoff when the user asks to report, save context, hand off work, or prepare another agent to continue.
---

- Follow the project's existing context or handoff convention when one is defined by project instructions, an explicit user path, or existing context files.
- If no convention exists, use `.docs/context/<domain>-<task-slug>.md`; use lowercase letters, numbers, and hyphens, with no date, status, or agent name in the filename.
- Reuse the same file for the same task. Never overwrite a different task or create a duplicate context file.
- Before reading context bodies, list filenames and search frontmatter for matching `title`, `keywords`, `paths`, `status`, and `related_context`; read only the most relevant files.
- Start fallback files with this exact frontmatter shape, filling every field:

  ```yaml
  ---
  context: task
  title: <short objective>
  status: active
  keywords: [<search terms>]
  paths: [<related files or directories>]
  branch: <git branch>
  head: <git commit>
  related_context: []
  ---
  ```

- Keep the body operational and factual. Include: objective and success criteria; scope; mandatory rules, conventions, and constraints; verified codebase findings and relevant entry points/data flow; completed changes and reasons; git state; commands and test results; blockers/risks; remaining work; and the next concrete action.
- Preserve valid information while removing stale information. Mark assumptions and open questions explicitly; never record secrets or personal data.
- Treat `branch` and `head` as the repository anchor. A later agent must act from the report and only revalidate findings that changed after that anchor.
