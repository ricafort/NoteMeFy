# Project Architecture

## Overview
This document outlines the core architecture of NoteMeFy.

## Example Diagram (following embed-diagrams workflow)

```mermaid
%%{init: {'theme': 'base', 'themeVariables': { 'primaryColor': '#ffcc00', 'edgeLabelBackground':'#ffffff', 'tertiaryColor': '#fff0f0'}}}%%
graph TD;
    User-->UI;
    UI-->NoteRepository;
    NoteRepository-->HiveDb[(Local Hive Database)];
```
*(To render the above diagram for static viewers, run `npx -y @mermaid-js/mermaid-cli -i architecture.md -o assets/architecture.png -b white` and embed it below)*

![NoteMeFy Architecture](assets/architecture-1.png)
