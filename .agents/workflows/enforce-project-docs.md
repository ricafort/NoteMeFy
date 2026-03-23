---
description: Enforce presence of project_docs and standard AI documentation.
---

Whenever a new major feature is started or the repository is initialized:

1. **Verify Integrity:** Ensure the `project_docs/` directory exists.
2. **Required Files:** Verify that `agents.md` (AI instructions), `architecture.md`, and an updated `README.md` exist and reflect current dependencies.
3. **Living Summaries:** Before writing code for a feature, explicitly write the plan in `implementation_plan.md` and await user approval.
4. **Docstrings Check:** Before completion, ensure all newly created service classes contain formatted docscripts explaining *why* the code was implemented that way.
