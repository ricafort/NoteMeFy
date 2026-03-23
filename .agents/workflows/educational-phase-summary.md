---
description: Generates a comprehensive, step-by-step educational guide after a development phase is completed.
---

When the user asks to generate Phase documentation or runs this workflow, you must dynamically generate an educational guide so the user can manually replicate the work.

Follow these exact steps:

1. **Analyze the Completed Phase:**
   - Review the `implementation_plan.md`, the completed tasks, and the specific technical decisions made during the current phase.

2. **Create the Documentation:**
   - Create a new file in the `project_docs/` folder named `phase_<number>_educational_guide.md`.

3. **Strict Document Structure:**
   The document MUST follow this exact structure for every major feature built in the phase:
   
   - **Title & Overview:** A brief summary of the phase's goals.
   - **Step-by-Step Breakdown:** For each core task completed, include:
      - **What we did:** A short, high-level summary of the accomplishment.
      - **How to replicate it:** The exact terminal commands to run, the specific folder structures to create, and the foundational code snippets needed.
      - **Why we did it:** The architectural reasoning, Flutter best practices, and industry standards behind the technical decision (e.g., "Why we used `go_router` instead of standard navigation").
   - **Quality Assurance:** Explain how the code was verified (e.g., running `flutter analyze`, fixing warnings, browser testing).

4. **Tone & Style:**
   - The tone must be beginner-friendly but highly technical.
   - Do not just paste raw code; explain the concepts (e.g., explain what a `Sliver` is, or why `ListView.builder` is important for memory).

5. **Final Step:**
   - Save the file and notify the user with a link to the new documentation so they can review and learn from it.
