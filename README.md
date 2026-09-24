<div align="center">
<img src="https://raw.githubusercontent.com/Mutantcat-Working-Group/StyleCool-Skill/main/logo.png" style="width:100px;" width="100"/>
<h2>StyleCool Skill</h2>
<p><em>给 AI 装一个在线的「设计顾问」</em></p>
</div>

**发行方**：由异猫工作群（mutantcat.org）发行 · GitHub: <https://github.com/Mutantcat-Working-Group>

> 装在 Claude Code / Cursor / Codex 等 AI 编程助手里的轻量技能插件。
> 写 UI 之前，模型先联网查一份设计规范卡片，再动手写 CSS。

### 一、产品概述

- StyleCool Skill 面向 AI 编程助手（Claude Code / Cursor / Codex 等），是一个极简技能插件
- 核心由一份 Markdown 说明 + 三个跨平台脚本组成（Python 主实现 + bash/curl 封装 + PowerShell 兜底），核心脚本约 26KB
- 不携带模型权重、不依赖本地运行时、免配置、免登录、免 API Key，clone 即用
- 它能做且只做一件事：模型写 CSS / UI 之前，实时联网查询 StyleCool 设计模式库，拿到一份「审美参考卡片」（设计规范 + 反模式清单），再据此写出符合设计标准的代码
- 生成的代码带引用标签（如 `[StyleCool: web / Primary Button — Flat Solid / category: button]`），出处可审计

核心价值：模型的知识止于训练数据，且天生缺乏视觉审美判断。StyleCool 相当于给模型装了一个在线设计顾问——它不告诉模型抄什么代码，而是告诉它什么是好的设计、什么不该做。

### 二、工作方式

让模型「写个卡片组件」，它当然能写，但写成什么样全看训练数据里的统计模式：可能是 Bootstrap 风，可能是 Material Design，可能霓虹渐变重阴影，也可能一个视口塞三个主按钮。它自己并不知道哪个算好设计。

StyleCool Skill 在生成代码之前先让它联网查规范：

第一步，查审美参考：模型向 `https://style.functioncool.xyz/skillapi` 发一次 HTTP GET，拿回设计卡片——名称、中英描述、标签、分类，以及 `anti` 反模式清单。脚本会主动剥离 `css` 字段，模型只看到规范，看不到任何实现代码。

第二步，照着规范自己写 CSS：因为源码根本没传过来，模型只能先理解设计原则再动手实现。就像设计师看完规范手册自己画图，而不是描摹成品。

四个关键设计：

- 联网实时查询：规范在服务端持续更新，模型永远拿到最新版本，对用户完全透明
- 只给规范，不给代码：强制「理解后生成」，杜绝复制粘贴
- 反模式清单（`anti` 字段）：明确标注禁区，比正面描述更能精准阻断最常犯的 UI 错误
- 审美一致性：所有查询指向同一套设计库，不同组件、不同会话的产出风格统一，不会出现「按钮是 Material、卡片是 iOS HIG、导航栏是 Ant Design」的拼接怪

一句话：给模型装一个联网的设计顾问——让它先查什么是好的设计，再动手写代码。审美在线，风格统一，自带避坑指南。

### 三、功能说明

#### 查询能力

- 目标平台分类：`web`、`desktop`、`miniapp`、`mobile`、`all`
- 返回字段：`name` / `name_zh`、`desc` / `desc_zh`、`tags`、`anti`、`category`
- 中英文查询词都能命中，例如「主按钮样式」与「button」
- 查不到结果时脚本优雅降级，模型直接靠自身知识回答，不加引用标签

#### 覆盖的设计模式

- 组件类：按钮、卡片、输入框、导航栏、下拉菜单、对话框、标签页
- 布局类：flex 居中、响应式 grid、移动端底部导航、页头页脚骨架
- 反馈类：loading 动画、空状态、错误提示、toast
- 风格类：色彩系统、间距节奏、阴影与圆角、字体层级

#### 跨平台脚本

- `query.py`：跨平台主实现，纯 Python 标准库，零外部依赖
- `query.sh`：Bash + curl 封装，自动在 jq / python / perl 之间 fallback 处理 JSON
- `query.ps1`：Windows 原生 PowerShell 兜底，不装 Python 也能跑
- 三个脚本的 CLI 契约、JSON 输出、退出码完全一致

#### 适用与不适用

适合 UI 组件设计、CSS 布局、响应式样式、交互动效、移动端适配、设计系统搭建。不适合调试已写好的 CSS、JavaScript 业务逻辑（这类问题用 FunctionCool Skill）、纯概念性问题、后端任务。

### 四、安装与下载

本仓库当前以源码形式发布，无预编译产物，也不需要：clone 到技能目录即可用。

macOS / Linux：

```bash
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git \
  ~/.claude/skills/stylecool
```

Windows（PowerShell）：

```powershell
git clone https://github.com/Mutantcat-Working-Group/StyleCool-Skill.git `
  "$env:USERPROFILE\.claude\skills\stylecool"
```

装完重启 Claude / Cursor 即生效。无需配置 Token、无需登录、无需任何环境变量——公开低权限 Token 已内置在脚本里。

安装后目录结构（核心脚本约 26KB）：

```text
~/.claude/skills/stylecool/
├── SKILL.md              # 技能描述（自动加载）
├── scripts/
│   ├── query.py          # 跨平台主实现（Python 3.6+，零依赖）
│   ├── query.sh          # Bash + curl 封装（macOS / Linux / WSL）
│   └── query.ps1         # Windows 原生 PowerShell 兜底（无需 Python）
└── logo.png              # 品牌标识
```

跨平台调用方式：

- macOS / Linux（Python）：`python3 scripts/query.py "button" "web"`
- Windows（Python）：`python scripts\query.py "flex layout" "all"`
- macOS / Linux / WSL（curl）：`bash scripts/query.sh "card" "mobile"`
- Windows（PowerShell，无 Python）：`powershell -ExecutionPolicy Bypass -File scripts\query.ps1 "navbar" "web"`

### 五、快速上手

1. 按上文把仓库 clone 进技能目录，重启助手。
2. 直接问「帮我写一个网页的主按钮样式」，模型会自动触发查询。
3. 拿到的 CSS 头部带 `[StyleCool: web / …]` 引用标签，一眼看出参考了哪个设计模式。
4. 想手动确认脚本正常，跑一次：`python3 ~/.claude/skills/stylecool/scripts/query.py "button" "web"`，应当返回带 `anti` 字段的精简 JSON。

### 六、工程结构与迭代

- `SKILL.md`：技能描述，改触发条件就编辑它顶部的 `description`
- `scripts/`：三个跨平台查询脚本
- `skills/stylecool-skill/`：与根目录同源的技能包副本，便于单独分发
- `logo.png`：品牌标识

### 备注

- API 契约：`GET https://style.functioncool.xyz/skillapi?token=mutantcat&q=<查询词>&cat=<web|desktop|miniapp|mobile|all>`
- Token 为永久公开低权限密钥，仅用于查询公开设计索引。
- 想加平台分类？在 `query.py` 的 `VALID_CATS` 与 `SKILL.md` 的分类说明里同步补一处。
- 想调超时？修改各脚本里的 `TIMEOUT` 变量，默认 10 秒。
- 姊妹项目 FunctionCool Skill 走同一套架构，只是把「设计规范」换成「函数索引」。
