# arXiv LLM Quantization Paper Monitor

每天自动从 arXiv 抓取 LLM 量化论文，用 AI 生成中文摘要和作者单位，推送到飞书，并提供本地静态论文阅读网站。全程无人值守，你只需要设置一次，之后每天 9 点自动收到论文日报。

## 效果展示

### 飞书日报

每天早上 9 点自动推送 Markdown 格式日报，包含：

- 📄 论文标题、作者、单位
- 🔗 arXiv ID + PDF 直链
- 📝 中文摘要（90-150 字，AI 生成）

### 本地论文阅读网站

启动后浏览器访问 `http://localhost:8765`，支持：

- 📅 按日期筛选（今天 / 近 3 天 / 近 1 周 / 全部）
- 🔍 关键词全文检索（标题 / 作者 / 单位 / 摘要）
- ⭐ 收藏功能（服务端持久化）
- 📖 Abstract 展开查看

---

## Hermes 介绍与安装

**Hermes** 是本项目的核心依赖 —— 一个 AI coding agent，支持：

- 🧠 **持久记忆**：记得你的偏好和项目上下文
- 🔧 **工具调用**：读写文件、执行代码、操作服务
- ⏰ **Cronjob**：定时任务，支持每天自动执行
- 📨 **飞书集成**：自动推送消息到飞书
- 🤖 **内置 LLM**：可直接完成中文摘要生成和单位提取

### 安装 Hermes

```bash
pip install hermes-agent
```

### 配置飞书

在 Hermes 中配置你的飞书 Bot（参考 [Feishu Integration](https://www.feishu.cn)），配置好 Bot 的 Chat ID，后续 cronjob 会自动向飞书推送日报。

---

## 项目安装与配置

### 克隆仓库

```bash
git clone https://github.com/genggng/arxiv_llm_quantization_paper_monitor.git
cd arxiv_llm_quantization_paper_monitor
```

### 安装依赖

```bash
# 如果使用 hermes 内置的 Python 环境
/home/wsg/.hermes/hermes-agent/venv/bin/pip install openpyxl requests pdfplumber

# 或者系统 Python
pip install openpyxl requests pdfplumber
```

### 网络代理（如需要）

部分地区访问 arXiv 或 GitHub 需要代理：

```bash
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
```

### 配置 hermes skill

将本项目注册为 hermes 的 skill，这样 hermes agent 能找到相关文件路径和工具脚本：

```bash
# 假设 hermes skill 目录在 ~/.hermes/skills/
# 将本项目复制为 hermes skill
cp -r arxiv_llm_quantization_paper_monitor ~/.hermes/skills/
```

---

## 核心功能：添加定时任务（/cron add）

**这是本项目的正确使用方式，不是手动运行 Python 脚本。**

在 hermes 对话中发送：

```
/cron add
```

然后按提示配置，任务内容如下：

### 定时任务完整流程

```
┌─────────────────────────────────────────────┐
│  hermes cronjob 每天 9:00 自动执行           │
├─────────────────────────────────────────────┤
│                                             │
│  1. 运行 monitor.py                         │
│     - 调用 arXiv API 搜索 LLM 量化论文       │
│     - 自动去重（crawled_ids.txt + Excel）    │
│     - 下载新论文 PDF                         │
│     - 写入 papers_record.xlsx                │
│     - 导出 viewer/papers_data.json           │
│     - 输出 new_papers.json（供后续使用）     │
│                                             │
│  2. 判断是否有新论文                        │
│     - 无新论文 → 直接推送"今日无新论文"     │
│     - 有新论文 → 进入第 3 步                │
│                                             │
│  3. hermes 内置 LLM 完成信息补全            │
│     - 从 PDF 提取作者单位 affiliations       │
│     - 基于 abstract 生成中文摘要 summary_cn  │
│     - 将结果回填到 Excel                    │
│                                             │
│  4. 生成飞书 Markdown 日报并推送            │
│     - 标题 / 作者 / 单位 / PDF 链接          │
│     - 90-150 字中文摘要                     │
│                                             │
└─────────────────────────────────────────────┘
```

### 查看定时任务

```
/cron list
```

### 删除定时任务

```
/cron remove <job_id>
```

---

## 手动测试命令（可选）

用于调试，不影响定时任务的正常运行：

```bash
# 运行 monitor.py（Python 搜索脚本）
python3 monitor.py

# 提取单篇论文作者单位
python3 extract_affiliation.py <arxiv_id>

# 启动本地论文阅读网站
cd viewer && python3 run_viewer.py
```

---

## 本地论文阅读网站

### 启动

```bash
cd viewer
python3 run_viewer.py
```

启动后访问：`http://localhost:8765`

### 功能

| 功能 | 说明 |
|------|------|
| 日期筛选 | 快捷按钮：今天 / 近 3 天 / 近 1 周 / 全部 |
| 关键词搜索 | 标题 / 作者 / 单位 / 摘要全文检索 |
| 收藏 | 点击 ⭐ 收藏，保存到 `viewer/favorites.json`（服务端持久化） |
| 展开 Abstract | 点击论文标题展开英文摘要 |

---

## 目录结构

```
arxiv_llm_quantization_paper_monitor/
├── monitor.py                 # 主脚本：搜索 arXiv + 下载 PDF + 写 Excel + 导出 viewer JSON
├── extract_affiliation.py     # 从 PDF 提取作者单位（pdfplumber，含 CamelCase 分词）
├── extract_pdf_info.py        # 辅助 PDF 信息提取脚本
├── search_keywords.txt        # arXiv 搜索关键词（可自定义）
├── crawled_ids.txt            # 已抓取 arXiv ID（自动维护）
├── cron_add_command.txt       # cronjob 任务配置模板
├── papers_record.xlsx         # 论文主记录 Excel（本地生成，不上传 Git）
├── new_papers.json            # 中间 JSON（供 hermes LLM 读取，本地生成）
└── viewer/
    ├── run_viewer.py          # 启动静态论文阅读网站
    ├── build_data.py          # 从 Excel 生成 papers_data.json
    ├── index.html             # 前端页面
    ├── app.js                 # 前端逻辑（筛选 / 搜索 / 收藏）
    ├── styles.css             # 样式
    ├── papers_data.json       # 网站数据（由 build_data.py 生成）
    ├── favorites.json         # 收藏记录（服务端持久化）
    └── README.md              # viewer 子模块说明
```

---

## 技术细节

### 作者单位提取（extract_affiliation.py）

- 使用 `pdfplumber` 提取 PDF 前 2 页带坐标的词列表
- 自动检测双栏布局（找最大 x 间隙分离左右栏）
- 对 CamelCase 连写词做分词还原（如 `DepartmentofPoliticalSciences` → `Department of Political Sciences`）
- 合并跨行连字符词（如 `Repub-` + `licof Korea` → `Republic of Korea`）
- 全词边界匹配机构关键词，不过度匹配子串

### 中文摘要生成

- 由 hermes 内置 LLM 基于论文英文 abstract 生成
- 字数要求：90-150 个中文字符
- 覆盖内容：方法核心、主要贡献、关键结果
- 禁止模板化泛化句，必须基于论文内容

### 查重机制

- `crawled_ids.txt`：每行一个 arXiv ID（无版本号）
- `papers_record.xlsx`：`arxiv_id` 列行级完整记录
- arXiv ID 版本剥离：`2604.11080v1` → `2604.11080`

### 静态网站数据

- 由 `monitor.py` 每次运行后自动导出 `viewer/papers_data.json`
- 或手动运行 `viewer/build_data.py` 单独构建
- `run_viewer.py` 启动时自动执行一次 `build_data.py`
