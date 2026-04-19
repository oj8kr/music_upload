#!/usr/bin/env bash
# download-worker.sh — 下载 music-upload 最新 Release 文件到 ./music-worker 目录
#
# 用法：
#   bash download-worker.sh               # 公开仓库，直接下载
#   bash download-worker.sh <TOKEN>       # 私有仓库，传入 GitHub Personal Access Token
#
# 若目标目录已存在，脚本会覆盖其中的三个文件（不会删除其他文件）。

set -euo pipefail

# ── 配置 ──────────────────────────────────────────────────────────────────────
REPO="oj8kr/music_upload"
TARGET_DIR="music-worker"
# .env 在 release 中以 worker.env 发布（GitHub 不允许下载以 . 开头的 asset 文件名）
declare -A FILES=(
  ["music-worker.js"]="music-worker.js"
  ["worker.env"]=".env"
  ["music-upload-tampermonkey.user.js"]="music-upload-tampermonkey.user.js"
)
# ─────────────────────────────────────────────────────────────────────────────

# 颜色输出（不支持时降级）
if [ -t 1 ] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  GREEN=$(tput setaf 2); YELLOW=$(tput setaf 3); RED=$(tput setaf 1); RESET=$(tput sgr0)
else
  GREEN=''; YELLOW=''; RED=''; RESET=''
fi

info()  { echo "${GREEN}[✓]${RESET} $*"; }
warn()  { echo "${YELLOW}[!]${RESET} $*"; }
error() { echo "${RED}[✗]${RESET} $*" >&2; exit 1; }

# ── 检查依赖 ─────────────────────────────────────────────────────────────────
command -v curl &>/dev/null || error "缺少依赖命令：curl，请先安装后重试。"

# ── 处理可选 Token 参数 ───────────────────────────────────────────────────────
TOKEN="${1:-}"
if [ -n "$TOKEN" ]; then
  AUTH_HEADER="Authorization: Bearer ${TOKEN}"
  warn "使用 Token 认证（私有仓库模式）"
else
  AUTH_HEADER=""
fi

# ── 获取最新 Release 信息 ─────────────────────────────────────────────────────
echo "正在查询 ${REPO} 最新 Release 版本..."

API_URL="https://api.github.com/repos/${REPO}/releases/latest"
if [ -n "$AUTH_HEADER" ]; then
  RELEASE_JSON=$(curl -fsSL -H "$AUTH_HEADER" -H "Accept: application/vnd.github+json" "$API_URL")
else
  RELEASE_JSON=$(curl -fsSL -H "Accept: application/vnd.github+json" "$API_URL")
fi

# 提取 tag_name（兼容有无 jq 两种情况）
if command -v jq &>/dev/null; then
  TAG=$(echo "$RELEASE_JSON" | jq -r '.tag_name')
else
  TAG=$(echo "$RELEASE_JSON" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/')
fi

[ -z "$TAG" ] && error "无法获取最新 Release 版本号，请检查仓库名称或 Token 是否正确。"
info "最新版本：${TAG}"

BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"

# ── 创建目标目录 ──────────────────────────────────────────────────────────────
if [ -d "$TARGET_DIR" ]; then
  warn "目录 ./${TARGET_DIR} 已存在，将覆盖其中的文件。"
else
  mkdir "$TARGET_DIR"
  info "已创建目录 ./${TARGET_DIR}"
fi

# ── 下载文件 ──────────────────────────────────────────────────────────────────
echo ""
echo "正在下载文件..."

for ASSET in "${!FILES[@]}"; do
  DEST_NAME="${FILES[$ASSET]}"
  DEST="${TARGET_DIR}/${DEST_NAME}"
  URL="${BASE_URL}/${ASSET}"
  echo -n "  ${ASSET} → ${DEST_NAME} ... "

  CURL_OPTS=(-fsSL -o "$DEST" -w "%{http_code}" --retry 3 --retry-delay 2)
  [ -n "$AUTH_HEADER" ] && CURL_OPTS+=(-H "$AUTH_HEADER")

  HTTP_CODE=$(curl "${CURL_OPTS[@]}" "$URL")

  if [ "$HTTP_CODE" = "200" ]; then
    SIZE=$(wc -c < "$DEST" | tr -d ' ')
    echo "${GREEN}完成${RESET}（${SIZE} bytes）"
  else
    echo ""
    error "下载失败：${ASSET}（HTTP ${HTTP_CODE}）\n  URL: ${URL}"
  fi
done

# ── 创建下载目录 ──────────────────────────────────────────────────────────────
ENV_FILE="${TARGET_DIR}/.env"
DOWNLOAD_DIR=""
RED_FILL_DOWNLOAD_DIR=""
if [ -f "$ENV_FILE" ]; then
  DOWNLOAD_DIR=$(grep -E '^DOWNLOAD_DIR=' "$ENV_FILE" | head -1 | sed 's/^DOWNLOAD_DIR=//' | tr -d '"'"'"' ')
  RED_FILL_DOWNLOAD_DIR=$(grep -E '^RED_FILL_DOWNLOAD_DIR=' "$ENV_FILE" | head -1 | sed 's/^RED_FILL_DOWNLOAD_DIR=//' | tr -d '"'"'"' ')
fi

if [ -n "$DOWNLOAD_DIR" ]; then
  mkdir -p "$DOWNLOAD_DIR"
  info "下载目录已就绪：${DOWNLOAD_DIR}"
else
  warn "未在 .env 中找到 DOWNLOAD_DIR，跳过创建下载目录。"
fi

# 若 .env 未配置 RED_FILL_DOWNLOAD_DIR，自动基于 DOWNLOAD_DIR 派生 <DOWNLOAD_DIR>/red-fill
# 并把新增行追加到 .env，避免用户手动补齐。
if [ -z "$RED_FILL_DOWNLOAD_DIR" ] && [ -n "$DOWNLOAD_DIR" ] && [ -f "$ENV_FILE" ]; then
  RED_FILL_DOWNLOAD_DIR="${DOWNLOAD_DIR%/}/red-fill"
  {
    echo ""
    echo "# RED MP3 补全专用种子下载目录（由 start.sh 自动生成）"
    echo "RED_FILL_DOWNLOAD_DIR=${RED_FILL_DOWNLOAD_DIR}"
  } >> "$ENV_FILE"
  info ".env 已追加 RED_FILL_DOWNLOAD_DIR=${RED_FILL_DOWNLOAD_DIR}"
fi

if [ -n "$RED_FILL_DOWNLOAD_DIR" ]; then
  mkdir -p "$RED_FILL_DOWNLOAD_DIR"
  info "RED 补全目录已就绪：${RED_FILL_DOWNLOAD_DIR}"
else
  warn "未在 .env 中找到 RED_FILL_DOWNLOAD_DIR 且 DOWNLOAD_DIR 缺失，跳过创建 RED 补全目录（若不需要 RED 补全功能可忽略）。"
fi

# ── 完成提示 ─────────────────────────────────────────────────────────────────
echo ""
info "全部文件已下载到 ./${TARGET_DIR}/"
echo ""
echo "文件列表："
ls -lah "${TARGET_DIR}/"
echo ""
if [ -n "$DOWNLOAD_DIR" ]; then
  echo "下载目录：${GREEN}${DOWNLOAD_DIR}${RESET}"
  echo ""
fi
echo "下一步："
echo "  1. 编辑配置文件："
echo "     ${YELLOW}nano ./${TARGET_DIR}/.env${RESET}"
echo ""
echo "  2. 启动 Worker："
echo "     ${YELLOW}cd ${TARGET_DIR} && node music-worker.js${RESET}"
echo ""
echo "  3. （可选）使用 PM2 后台运行（delete 在首次无该进程时会忽略错误）："
echo "     ${YELLOW}pm2 delete music-upload-worker 2>/dev/null || true${RESET}"
echo "     ${YELLOW}cd ${TARGET_DIR} && pm2 start music-worker.js --name music-upload-worker${RESET}"
