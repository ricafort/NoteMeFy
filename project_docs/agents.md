# AI Agent Rulebook & Living Summary

> **FOR ALL AI AGENTS:** Read this document FIRST before starting any task.

## 1. Living Project Summary

### 📂 Rule 1: Documentation Integrity
*   **Location**: Always save plans, research, and diagrams in the `project_docs/` folder.
*   **Visuals**: Generate and embed Mermaid diagrams for architecture or flow changes.
*   **Format**: Use Markdown. Keep it clean and updated.

### 📝 Rule 2: Code Quality & Explanation
*   **Comments**: Every function, class, and complex logic block MUST have clear, explanatory comments.
*   **Why, Not just What**: Explain *why* a decision was made.
    *   *Bad*: "Sets timeout to 5000ms"
    *   *Good*: "Increased timeout to 5000ms to allow for slow legacy upstream service."
*   **Standardized Documentation**: Use the standard documentation format for your language (e.g., Python Docstrings, C# XML Comments, JSDoc) to ensure automated tools (like Swagger) can parse it.

### 🛡️ Rule 3: Security & Best Practices
*   **Priority 0**: Security is non-negotiable.
    *   NEVER commit secrets to git/artifacts (use `.env`).
    *   NEVER use plain-text passwords (hash them).
    *   NEVER allow unrestricted database access (use specific Schemas/Permissions).

### 🧠 Rule 4: Research First
*   **Exhaustive Analysis**: Do not blindly write code. Research the problem, easy traps, and best practices first.
*   **Planning**: Create or update `implementation_plan.md` *before* writing a single line of feature code.
*   **Context**: Verify your assumptions by reading related files first.

### 📏 Rule 5: Naming Consistency
*   **Database First**: The Database Schema is the Source of Truth.
*   **Match Names**: API/JSON Field names MUST match the SQL Column names exactly.
    *   *Bad*: SQL=`PONumber` -> API=`po_number` (Requires error-prone mapping).
    *   *Good*: SQL=`PONumber` -> API=`PONumber` (Zero mapping required).

---
*This document is a living artifact. Update the "Current State" section as you complete major milestones.*
