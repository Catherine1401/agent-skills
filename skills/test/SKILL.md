---
name: test
description: After writing or changing code, guide the user through testing the changed behavior. Provide runnable mocks when the user explicitly says required APIs or backend dependencies are unavailable or unfinished.
---

- Before finishing a coding task, provide beginner-friendly testing instructions for the changed behavior without waiting for the user to ask. Inspect the project's existing run commands, test tools, and prerequisites; give exact setup and launch steps rather than assuming the user knows them.
- Cover all cases within the changed behavior and stated requirements: successful flows, alternate branches, boundaries, validation failures, and applicable empty, loading, and error states. For each case, give concrete inputs or actions, the expected observable result, and how to reset state when needed. Distinguish checks already run by the agent from checks the user still needs to perform.
- When the user explicitly says a required real API or backend dependency is unavailable or unfinished, implement runnable mock data or responses so the user can exercise every affected case. Do not stop at suggesting mocks or providing disconnected sample data.
- Reuse existing mock tools, fixtures, and project conventions. Match known request and response contracts; inspect available schemas and callers, and clarify only missing contract details that materially affect testing. Mock the unavailable dependency at its boundary without changing production behavior or bypassing the code being tested.
- Make mock scenarios deterministic and selectable so the user can trigger each outcome. Keep mock activation local to the test or development environment; explain how to enable it, select cases, reset data, and return to real services.
- Run applicable checks and verify mock scenarios when possible. Report execution limits and identify behavior that still requires real integration testing; passing mocks does not establish that a real API or backend works.
