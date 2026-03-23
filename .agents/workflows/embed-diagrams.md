---
description: How to ensure Markdown documentation with Mermaid diagrams has static image fallbacks.
---

When documenting system architecture or state flows:

1. Write the standard Markdown Mermaid block (```mermaid ... ```).
2. If requested to provide an image fallback, use an external Mermaid rendering service link below the code block:
   `![Diagram Description](https://mermaid.ink/img/pako:<BASE64_ENCODED_MERMAID_STRING>)`
3. Always verify that the Mermaid syntax is strictly valid and avoids unsupported HTML nodes.
4. Save such diagrams explicitly in `project_docs/architecture.md` when defining core application flows.
