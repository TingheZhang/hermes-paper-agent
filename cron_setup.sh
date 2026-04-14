#!/bin/bash
# hermes-arxiv-agent 定时任务安装脚本
# 使用方法：bash cron_setup.sh
#
# 【重要】部署前必读
# 1. 修改下面的 PROJECT_DIR 为本项目实际路径（绝对路径）
# 2. 在 hermes 对话中运行：/cron add '0 9 * * *' "$(cat cronjob_prompt.txt)"
# 3. 或者：hermes cron create --name "arxiv-daily" --prompt "$(cat cronjob_prompt.txt)" --schedule "0 9 * * *"

# ========== 请修改以下路径 ==========
PROJECT_DIR="/path/to/hermes-arxiv-agent"
# ===================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# 安装依赖
pip install openpyxl requests pdfplumber

# 验证路径
if [ ! -f "$PROJECT_DIR/monitor.py" ]; then
    echo "错误：找不到 monitor.py，请检查 PROJECT_DIR 配置是否正确"
    exit 1
fi

echo "✅ 依赖已安装，项目路径：$PROJECT_DIR"
echo ""
echo "下一步："
echo "  1. 在 hermes 对话中发送："
echo "     /cron add '0 9 * * *'"
echo ""
echo "  2. 粘贴 cronjob_prompt.txt 中的内容作为 prompt"
echo ""
echo "  3. 将 cronjob_prompt.txt 中的占位符 /path/to/... 替换为实际项目路径"
