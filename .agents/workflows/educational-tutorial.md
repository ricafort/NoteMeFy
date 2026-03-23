---
description: Generates a deep-dive educational programming tutorial based on the current project's code, architecture, and technology stack.
---

When triggered, generate a standalone tutorial document targeting a specific technical implementation from the project.

1. **Context Parsing:** Read the current user's prompt or the actively open file to determine the tutorial's subject.
2. **File Creation:** Create `project_docs/tutorial_<topic>.md`.
3. **Structure & Content:**
   - **Objective:** What the reader will learn.
   - **Prerequisites:** What prior knowledge/tools are needed.
   - **The "Why":** Why this specific architecture/tool was chosen.
   - **Code Walkthrough:** Step-by-step code analysis using the actual project's codebase snippet as the reference.
   - **Edge Cases & Best Practices:** Common pitfalls to avoid.
4. **Tone:** Academic but practical. Use analogies where helpful.
