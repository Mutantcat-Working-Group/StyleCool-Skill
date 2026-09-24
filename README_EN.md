<div align=center>
<img src="https://raw.githubusercontent.com/Mutantcat-Working-Group/StyleCool-Skill/main/logo.png" width="100"/>
<h2>StyleCool Skill</h2>
<p><em>An online "design consultant" for AI agents</em></p>
</div>

**Publisher**: Released by the Mutantcat Working Group (mutantcat.org) · GitHub: <https://github.com/Mutantcat-Working-Group>

> English | [中文](README.md)

### 1. Overview
- A minimal skill plugin for AI coding assistants (Claude Code / Cursor / Codex, etc.): one Markdown guide plus three cross-platform scripts (Python main implementation + bash/curl wrapper + PowerShell fallback), about 26KB of core code.
- Ships no model weights, needs no local runtime, no configuration, no login, and no API key. Clone and use.
- It does exactly one thing: before the model writes CSS/UI, it queries the StyleCool design-pattern library online and returns an "aesthetic reference card" (design rules + anti-pattern list) to guide the code.
- Generated code carries a citation tag such as `[StyleCool: web / Primary Button — Flat Solid / category: button]`, so the source is auditable.

### 2. How It Works
Ask the model to "write a card component" and it can, but what it writes depends on statistical patterns in the training data: Bootstrap-style, Material Design, neon gradients with heavy shadows, or three primary buttons in one viewport. The model cannot judge which one is good design. StyleCool Skill makes it consult the rules online before generating:

First, fetch the aesthetic reference: the model issues one HTTP GET to `https://style.functioncool.xyz/skillapi` and receives a design card with name, Chinese/English descriptions, tags, category, and the `anti` anti-pattern list. The helper script deliberately strips the `css` field, so the model only sees the rules, never the implementation code.

Second, write the CSS from the rules: because the source code is never sent, the model must understand the design principles first and implement them itself, instead of tracing a finished example.

Four key design decisions:
- Live online lookup: rules are continuously updated server-side, so the model always gets the latest version
- Rules only, no code: forces "understand then generate" and prevents copy-paste
- Anti-pattern list (`anti` field): names the forbidden patterns and blocks the most common UI mistakes more precisely than positive descriptions
- Aesthetic consistency: every query hits the same design library, so outputs stay consistent across components and sessions

In one sentence: install an online design consultant for the model, let it check what good design looks like, then write the code. Taste stays online, style stays consistent, and a pitfall guide is built in.

### 3. API
1. Style query - `/skillapi`
   - Description: queries the StyleCool design-pattern library online and returns a slim JSON design card
   - Method: GET
   - Parameters:
     - `token`: permanent public low-privilege key (built in, default `mutantcat`)
     - `q`: query term, matched in Chinese or English (e.g. `button`, `flex layout`)
     - `cat`: `web` / `desktop` / `miniapp` / `mobile` / `all`
   - Response fields: `name` / `name_zh`, `desc` / `desc_zh`, `tags`, `anti`, `category`
   - Response example:
     ```json
     {
         "query": "button",
         "cat": "web",
         "count": 2,
         "results": [
             {
                 "name": "Primary Button — Flat Solid",
                 "tags": ["button", "CTA"],
                 "anti": ["neon glow button", "dual primary buttons"],
                 "category": "web"
             }
         ]
     }
     ```
2. Cross-platform scripts
   - `query.py`: cross-platform main implementation, pure Python standard library, zero external dependencies
   - `query.sh`: Bash + curl wrapper that automatically falls back among jq / python / perl for JSON handling
   - `query.ps1`: native Windows PowerShell fallback that works without Python
   - All three scripts share the same CLI contract, JSON output, and exit codes

Covered design patterns:
- Components: buttons, cards, input fields, navigation bars, dropdown menus, dialogs, tabs
- Layout: flex centering, responsive grids, mobile bottom navigation, header/footer skeletons
- Feedback: loading animations, empty states, error messages, toasts
- Style: color systems, spacing rhythm, shadows and radii, type hierarchy

Good for: UI component design, CSS layout, responsive styling, interaction effects, mobile adaptation, and design systems.
Not good for: debugging existing CSS, JavaScript business logic (use the FunctionCool Skill for those), pure conceptual questions, or backend tasks.

### 4. Install & Download
This repository is distributed as source with no prebuilt artifacts, and none are needed: clone it into the skills directory and use it.

macOS / Linux:

```bash
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git \
  ~/.claude/skills/stylecool
```

Windows (PowerShell):

```powershell
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git `
  "$env:USERPROFILE\.claude\skills\stylecool"
```

Restart Claude / Cursor after installation. No token setup, login, or environment variables are needed; the public low-privilege token is already built into the scripts.

Installed directory layout:

```text
~/.claude/skills/stylecool/
├── SKILL.md              # Skill description (auto-loaded)
├── scripts/
│   ├── query.py          # Cross-platform main implementation (Python 3.6+, zero deps)
│   ├── query.sh          # Bash + curl wrapper (macOS / Linux / WSL)
│   └── query.ps1         # Native Windows PowerShell fallback (no Python needed)
└── logo.png              # Brand logo
```

Cross-platform usage:

- macOS / Linux (Python): `python3 scripts/query.py "button" "web"`
- Windows (Python): `python scripts\query.py "flex layout" "all"`
- macOS / Linux / WSL (curl): `bash scripts/query.sh "card" "mobile"`
- Windows (PowerShell, no Python): `powershell -ExecutionPolicy Bypass -File scripts\query.ps1 "navbar" "web"`

### 5. Quick Start
1. Clone the repository into the skills directory as shown above, then restart the assistant.
2. Ask something like "write a primary button style for a web page" and the model triggers a lookup automatically.
3. The resulting CSS starts with a `[StyleCool: web / ...]` citation tag so you can see which pattern was referenced.
4. To verify the script manually, run `python3 ~/.claude/skills/stylecool/scripts/query.py "button" "web"`; it should return slim JSON including the `anti` field.

### 6. Design Focus
- Gives the model online "aesthetic judgment": check what good design is first, then write the code
- Rules only, no code: forces "understand then generate" and prevents straight imitation of common UI templates
- Anti-pattern lists precisely block the most frequent UI mistakes, more effectively than positive descriptions
- Every query hits the same design library, keeping style consistent across components and sessions

### 7. Roadmap
- [X] Three-platform scripts (Python / Bash / PowerShell) with a unified CLI contract
- [X] Online design-pattern lookup with `anti` anti-pattern output
- [X] Automatic `css` field stripping; only design rules are delivered
- [X] Graceful degradation (fall back to the model's own knowledge on no results / timeout)
- [X] Installable as a Claude Code / Cursor / Codex skill
- [X] Source-readable skill package copy (`skills/stylecool-skill/`)

### 8. Directory Layout
- `SKILL.md` — skill description; edit the `description` at the top to change trigger conditions
- `scripts/` — three cross-platform query scripts
- `skills/stylecool-skill/` — a copy of the skill package at the root for standalone distribution
- `logo.png` — brand logo
- `VERSION` — version number

### Notes & Keys
- API contract: `GET https://style.functioncool.xyz/skillapi?token=mutantcat&q=<query>&cat=<web|desktop|miniapp|mobile|all>`
- The token is a permanent public low-privilege key used only to query the public design index; do not expose internal details in conversation.
- To add a platform category, update `VALID_CATS` in `query.py` and the category documentation in `SKILL.md` together.
- To adjust the timeout, change the `TIMEOUT` variable in each script; the default is 10 seconds.
- The sister project, the FunctionCool Skill, uses the same architecture but replaces "design rules" with a "function index".
