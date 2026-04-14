---
name: hermes-arxiv-agent
description: 使用 hermes cronjob 每天自动从 arXiv 监控论文，AI 生成中文摘要和作者单位，推送飞书，并提供本地静态阅读网站。
version: 1.0.0
author: Shigeng Wang
source: https://github.com/genggng/hermes-arxiv-agent
license: MIT
tags: [Research, arxiv, Cronjob, LLM, Automation, Feishu, Static-Site]
---

# hermes-arxiv-agent

使用 hermes cronjob 每天自动从 arXiv 监控论文，AI 生成中文摘要和作者单位，推送飞书，并提供本地静态阅读网站。

## 安装部署

### 第一步：克隆代码

```bash
git clone https://github.com/genggng/hermes-arxiv-agent.git
cd hermes-arxiv-agent
```

### 第二步：安装依赖

```bash
pip install openpyxl requests pdfplumber
```

### 第三步：配置网络代理（如需要）

部分地区访问 arXiv 需要代理：

```bash
export HTTP_PROXY=http://127.0.0.1:7890
export HTTPS_PROXY=http://127.0.0.1:7890
```

### 第四步：部署定时任务

在 hermes 对话中发送：

```
/cron add '0 9 * * *'
```

然后将 `cronjob_prompt.txt` 中的全部内容粘贴作为 prompt。

**注意**：首次使用时，需要将 `cronjob_prompt.txt` 中所有的 `/path/to/hermes-arxiv-agent` 替换为你本机实际的项目路径。

## 定时任务工作流程

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

## 本地论文阅读网站

```bash
cd viewer && python3 run_viewer.py
```

访问 `http://localhost:8765`，支持日期筛选、关键词搜索、收藏。

## 项目文件说明

| 文件 | 说明 |
|------|------|
| `monitor.py` | 主脚本：搜索 arXiv + 下载 PDF + 写 Excel + 导出 viewer JSON |
| `extract_affiliation.py` | 从 PDF 提取作者单位（含 CamelCase 分词） |
| `cronjob_prompt.txt` | cron 定时任务的完整 prompt（部署时粘贴到 /cron add） |
| `cron_setup.sh` | 辅助安装脚本（可选） |
| `viewer/` | 本地静态论文阅读网站 |
| `search_keywords.txt` | arXiv 搜索关键词（可自定义） |
| `crawled_ids.txt` | 已抓取 arXiv ID（自动维护） |
| `papers_record.xlsx` | 论文记录（本地生成，不上传 Git） |

## cronjob 相关命令

```bash
/cron list                    # 查看定时任务
/cron run <job_id>            # 手动测试某个任务
/cron remove <job_id>         # 删除某个任务
```

## 环境要求

- Python 3
- pip（openpyxl, requests, pdfplumber）
- 网络访问 arXiv.org
- hermes-agent（用于 cronjob 和飞书推送）
