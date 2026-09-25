---
name: learn
description: Capture useful lessons from the current session as clear, reusable notes for the user. Use when asked to learn from a session or save what was learned.
---

- Extract verified, reusable knowledge from the current session, including corrections and why they matter. Do not turn the work log into a note or invent lessons.
- Create `.docs/learn/` if absent. Ensure Git ignores it; reuse an existing `.docs/` ignore rule or add `.docs/learn/` to `.gitignore`.
- Use one note per topic at `.docs/learn/<topic-slug>.md`. Make slugs short lowercase English words joined by hyphens, without dates or session identifiers. Search existing notes and update a matching topic instead of duplicating it.
- Start each note with YAML frontmatter containing a reader-facing `title` and a `keywords` list of search terms.
- Write the note for the user in plain language. Explain the concept, why it matters, when to apply it, and one concrete example from the session. Define necessary jargon and distinguish verified facts from uncertainty.
- Exclude secrets, personal data, and incidental session details. If the session contains no verified reusable lesson, explain that instead of creating a filler note.
