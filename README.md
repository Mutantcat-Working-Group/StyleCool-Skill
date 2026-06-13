<div align="center">
<img src="./logo.png" style="width:100px;" width="100"/>
<h2>StyleCool Skill</h2>
<p><em> 给 AI 装一个在线的"设计顾问"——联网查询审美规范，再动手写 UI 代码</em></p>
</div>

###  一、功能简介

**StyleCool Skill** 是一个面向 AI 编程助手（Claude Code / Cursor / Codex 等）的极简技能插件。它不携带任何模型权重、不依赖任何本地运行时，**仅由一份 Markdown 说明 + 三个跨平台脚本组成（Python 主实现 + bash/curl 封装 + PowerShell 兜底），核心脚本 26KB**。

它能做的事情只有一件：**当你写 CSS/UI 时，模型会实时联网查询 StyleCool 设计模式库，拿到一份"审美参考卡片"（设计规范 + 反模式清单），再据此写出符合专业设计标准的代码**。

> AI 模型的知识截止于训练数据，且天然缺乏视觉审美判断力。StyleCool 相当于给模型装了一个**在线设计顾问**——它不告诉模型"抄什么代码"，而是告诉模型"什么是好的设计、什么不该做"。

#### 核心卖点

- 🌐 **联网审美** —— 模型实时查询线上设计模式库，获得超越训练数据的专业设计指引，不再凭"感觉"瞎写 CSS。
- 🎨 **反模式感知** —— 每个设计模式自带 `anti` 字段（如"禁止霓虹发光"、"禁止双主按钮"），模型会在生成时主动避开常见 UI 错误。
- 📐 **规范驱动** —— 不贴代码、只给规范。模型拿到的是设计原则（命名、描述、标签、禁忌），自己动手写实现，保证每次产出都是"理解后生成"而非"复制粘贴"。
- 🖥️ **跨平台** —— Windows / macOS / Linux 行为一致；Python、curl、PowerShell 三套入口任选。
- ⚡ **零门槛** —— clone 即用，免配置、免登录、免 API Key。Token 硬编码，26KB 纯文本，无需任何运行时依赖。
- 💰 **顺带省钱** —— 查索引替代从零生成，输出 token 大幅减少。库内容稳定，重复查询命中 prompt cache，边际成本趋零。

###  二、基础用法

#### 1. 安装（以 Claude Code 为例）

**macOS / Linux:**
```bash
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git \
  ~/.claude/skills/stylecool
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git `
  "$env:USERPROFILE\.claude\skills\stylecool"
```

安装后目录结构如下（**核心脚本 26KB**）：

```
~/.claude/skills/stylecool/
├── SKILL.md              # 技能描述（自动加载）
├── scripts/
│   ├── query.py          # ★ 跨平台主实现（Python 3.6+，零依赖）
│   ├── query.sh          # Bash + curl 封装（macOS / Linux / WSL）
│   └── query.ps1         # Windows 原生 PowerShell 兜底（无需 Python）
└── logo.png              # 品牌标识
```

重启 Claude / Cursor 即可。**无需配置 Token、无需登录、无需任何环境变量**——Token 硬编码在脚本里，直接调用。

> 💡 **跨平台调用方式**：
> - **macOS / Linux (Python)**：`python3 scripts/query.py "button" "web"`
> - **Windows (Python)**：`python scripts\query.py "flex layout" "all"`
> - **macOS / Linux / WSL (curl)**：`bash scripts/query.sh "card" "mobile"`
> - **Windows (PowerShell, 无 Python)**：`powershell -ExecutionPolicy Bypass -File scripts\query.ps1 "navbar" "web"`

#### 2. 使用

安装完成后，**直接用自然语言问模型写 UI 代码即可**，无需特殊指令。Skill 会在合适的场景下自动触发。

触发示例（中英文均可）：

```
帮我写一个网页的主按钮样式
give me a CSS card component with hover effect
怎么做一个居中的 flex 布局？
移动端底部导航栏怎么写
How do I make a responsive grid layout?
loading spinner animation in CSS
```

模型返回的代码会带一个引用标签，例如：

```css
/* [StyleCool: web / Primary Button — Flat Solid / category: button] */
.btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 10px 24px;
    ...
}
```

你可以一眼看出这段 CSS "参考了哪个设计模式的什么规范"，方便审计与追溯。

#### 3. 手动验证

想确认脚本工作正常？直接跑：

**macOS / Linux (Python):**
```bash
python3 ~/.claude/skills/stylecool/scripts/query.py "button" "web"
```

**Windows (PowerShell + Python):**
```powershell
python "$env:USERPROFILE\.claude\skills\stylecool\scripts\query.py" "button" "web"
```

**macOS / Linux / WSL (curl/bash):**
```bash
bash ~/.claude/skills/stylecool/scripts/query.sh "button" "web"
```

**Windows (PowerShell 原生, 无 Python):**
```powershell
& "$env:USERPROFILE\.claude\skills\stylecool\scripts\query.ps1" "button" "web"
```

返回的是一份**精简版 JSON**（已经去掉了 `css` 字段）：

```json
{
  "query": "button",
  "cat": "web",
  "count": 2,
  "results": [
    {
      "name": "Primary Button — Flat Solid",
      "name_zh": "主按钮 — 扁平实心",
      "desc": "A single primary CTA per viewport. Flat fill, no shadow at rest...",
      "desc_zh": "每视口最多一个主 CTA。扁平实心填充...",
      "tags": ["button", "CTA", "primary", "interaction", "accessibility"],
      "anti": ["neon glow button", "dual primary buttons", "gradient + shadow button"],
      "category": "web"
    }
  ]
}
```

### 三、原理

#### 朴素做法的痛点：AI 没有"审美"

当你让模型"写个卡片组件"，它当然能写——但写成什么样，完全取决于训练数据里的统计模式：

```
用户提问 ──► 模型凭训练数据"感觉"生成 CSS ──► 用户
                 │
                 ▼
        可能是 Bootstrap 风格，可能是 Material Design
        可能是霓虹渐变重阴影，可能塞了 3 个主按钮
        ——模型自己也不知道哪个是"好设计"
```

**LLM 本质是语言模型，不是设计师。** 它没有视觉审美、不认识设计系统、不知道什么是"专业感"。训练数据里什么风格都有，好的坏的混在一起，模型无从分辨。

#### StyleCool 的解法：给模型装一个"在线设计顾问"

StyleCool Skill 在模型生成代码之前，先让它**联网查一份设计规范**：

```
┌──────────────────────────────────────────────────────────────┐
│  Step 1: 联网查审美参考（模型主动发起 HTTP 请求）               │
│                                                              │
│  模型 ──HTTP GET──► https://style.functioncool.xyz/skillapi  │
│       ◄── 设计卡片 ──   {name, desc, tags, anti, category}   │
│                         （只有规范，没有代码）                  │
│                                                              │
│  例：查 "button" →                                          │
│     ✓ 每视口最多一个主 CTA                                    │
│     ✓ 扁平实心，底部 1px 细线                                  │
│     ✓ 悬停加深 + 抬 1px                                      │
│     ✗ 禁止霓虹外发光                                          │
│     ✗ 禁止双主按钮并存                                        │
│     ✗ 禁止渐变+阴影叠加                                       │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│  Step 2: 模型照着规范自己写 CSS（不是抄代码）                    │
│                                                              │
│  模型： "好，我现在知道什么是专业按钮的设计标准了。                │
│          我来写一个符合这些规范的实现。"                         │
│                                                              │
│  → 写出来的 CSS 遵循了设计原则、避开了反模式                     │
│  → 因为 css 字段根本没传过来，模型只能自己理解后实现              │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    用户拿到有设计依据的 UI 代码
                    （附引用标签，可审计出处）
```

#### 关键设计

1. **联网实时查询**
   模型不是查本地缓存，是实时请求线上设计库。设计规范可以持续更新、扩充，模型始终拿到最新版本。对用户完全透明——不需要注册、不需要配置。

2. **只给规范，不给代码**
   脚本 `query.py`（以及 `query.sh` / `query.ps1`）拿到 API 返回后会**主动剥离 `css` 字段**。模型只看到"这个设计应该长什么样、不该长什么样"，看不到任何实现代码。这强制模型**先理解设计原则、再自己动手写**——就像设计师看了一本规范手册后自己画图，而不是描摹成品。

3. **反模式清单 (`anti` 字段)**
   每个设计模式都标注了明确的"禁区"。这比正面描述更有效——告诉模型"不要做 A、B、C"能精准阻断最常犯的 UI 错误。比如按钮组件的 anti 包括"霓虹外发光"、"并排双主按钮"、"渐变+阴影叠加"——每一条都是实践中反复出现的坑。

4. **审美一致性**
   因为所有查询都指向同一套设计库，不同组件、不同会话产出的 UI 代码保持一致的审美风格。不会出现"按钮是 Material Design、卡片是 iOS HIG、导航栏是 Ant Design"的拼接怪。

5. **零本地状态，纯在线**
   没有数据库、没有索引文件、没有 vector store。26KB 全是启动指令——SKILL.md 告诉模型"什么时候用、怎么用"，三个脚本帮它发一次 HTTP 请求。设计库的维护和更新全在服务端完成，Skill 本体不需要改动。

6. **跨平台脚本架构**
   `query.py` 是跨平台主实现（纯 Python stdlib，零外部依赖），`query.sh` 是 curl + bash 封装（自动 fallback jq/python/perl 做 JSON 处理），`query.ps1` 是 Windows 原生 PowerShell 兜底（无 Python 也能跑）。三个脚本的 CLI 契约、JSON 输出、退出码完全一致。

#### 一句话总结

> **给模型装一个联网的设计顾问——让它先查"什么是好的设计"，再动手写代码。审美在线，风格统一，自带避坑指南。**

### 四、其他说明

#### API 契约

```
GET https://style.functioncool.xyz/skillapi
    ?token=mutantcat                    （永久 Token，公开低权限）
    &q={url-encoded 查询词}              （e.g. "button", "flex layout", "card"）
    &cat={web|desktop|miniapp|mobile|all} （目标平台分类）
```

#### 适用与不适用

✅ **适合**：UI 组件设计、CSS 布局、响应式样式、交互动效、移动端适配、设计系统搭建。

❌ **不适合**：调试已写好的 CSS、JavaScript 业务逻辑（用 functioncool）、纯概念性问题、后端任务。脚本在查不到结果时会优雅降级，模型直接靠自身知识回答，不加引用标签。

### 进阶：迭代 Skill 本身

- 想改触发条件？编辑 `SKILL.md` 顶部的 `description`。
- 想加平台分类？在 `query.py` 的 `VALID_CATS` 和 `SKILL.md` 的分类说明里加。
- 想调超时时间？修改各脚本里的 `TIMEOUT` 变量（默认 10 秒）。
