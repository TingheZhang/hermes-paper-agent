# hermes-arxiv-agent

每天自动从 arXiv 抓取论文，用 AI 生成中文摘要和作者单位，推送到飞书，并提供本地静态阅读网站。全程无人值守，一次配置，每天自动运行。

## 效果展示

### 飞书日报

每天早上 9 点自动推送 Markdown 格式日报，包含论文标题、作者、单位、arXiv ID、PDF 直链，以及 AI 生成的中文摘要（90-150 字）。

### 本地论文阅读网站

启动后浏览器访问 `http://localhost:8765`，支持按日期筛选、关键词全文检索、收藏、Abstract 展开查看。

---

## Hermes 安装与配置

**Hermes** 是本项目的核心依赖，一个支持持久记忆、工具调用、cronjob 和飞书集成的 AI agent。

### 安装 Hermes（Linux / macOS / WSL2）

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc  # 或 source ~/.zshrc
hermes            # 启动
```

详细说明：[Hermes 安装指南](https://hermes-agent.nousresearch.com/docs/getting-started/installation)

### 配置飞书

```bash
hermes gateway setup
```

选择 **Feishu / Lark**，按提示扫码配置。

详细说明：[飞书配置指南](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/feishu)

---

## 安装部署

### 克隆仓库

```bash
git clone https://github.com/genggng/hermes-arxiv-agent.git
cd hermes-arxiv-agent
```

### 安装依赖

```bash
pip install openpyxl requests pdfplumber
```

### 部署定时任务

**方式一：参考项目内的 skill.md**

项目内已包含 [`SKILL.md`](./SKILL.md)，本项目就是一个 hermes skill，可直接参考其部署步骤。

**方式二：直接使用 /cron add**

在 hermes 对话中发送：

```
/cron add '0 9 * * *'
```

然后将 [`cronjob_prompt.txt`](./cronjob_prompt.txt) 中的全部内容粘贴作为 prompt。

> ⚠️ **首次使用时**：需要将 `cronjob_prompt.txt` 中所有的 `/path/to/hermes-arxiv-agent` 替换为你本机实际的项目路径。

### 定时任务工作流程

```
每天 9:00
    ↓
运行 monitor.py（搜索 arXiv + 下载 PDF + 写 Excel + 导出 viewer JSON）
    ↓
判断是否有新论文
    ↓ 有
hermes LLM 读取 PDF → 提取作者单位 + 生成中文摘要 → 回填 Excel
    ↓
推送飞书 Markdown 日报
```

### cronjob 相关命令

```
/cron list                    # 查看定时任务
/cron run <job_id>            # 手动测试某个任务
/cron remove <job_id>         # 删除某个任务
```

---

## 本地论文阅读网站

### 启动

```bash
cd viewer
python3 run_viewer.py
```

访问：`http://localhost:8765`

### 功能

| 功能 | 说明 |
|------|------|
| 日期筛选 | 快捷按钮：今天 / 近 3 天 / 近 1 周 / 全部 |
| 关键词搜索 | 标题 / 作者 / 单位 / 摘要全文检索 |
| 收藏 | 点击 ⭐ 收藏，保存到 `favorites.json` |
| 展开 Abstract | 点击论文标题展开英文摘要 |

---

## 目录结构

```
hermes-arxiv-agent/
├── monitor.py                 # 主脚本：搜索 arXiv + 下载 PDF + 写 Excel + 导出 viewer JSON
├── extract_affiliation.py     # 从 PDF 提取作者单位（pdfplumber，含 CamelCase 分词）
├── extract_pdf_info.py        # 辅助 PDF 信息提取脚本
├── search_keywords.txt        # arXiv 搜索关键词（可自定义）
├── crawled_ids.txt            # 已抓取 arXiv ID（自动维护）
├── cronjob_prompt.txt         # cron 定时任务 prompt（部署时粘贴到 /cron add）
├── cron_setup.sh              # 辅助安装脚本（可选）
├── SKILL.md                  # hermes skill 说明（参考部署）
└── viewer/
    ├── run_viewer.py          # 启动静态论文阅读网站
    ├── build_data.py          # 从 Excel 生成 papers_data.json
    ├── index.html             # 前端页面
    ├── app.js                 # 前端逻辑（筛选 / 搜索 / 收藏）
    ├── styles.css             # 样式
    ├── papers_data.json        # 网站数据（由 build_data.py 生成）
    ├── favorites.json         # 收藏记录（服务端持久化）
    └── README.md              # viewer 子模块说明
```

---

## 技术细节

### 作者单位提取

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
