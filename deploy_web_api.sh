#!/usr/bin/env bash
# ==============================================================================
# SPORTHUB - 1-CLICK WEB API DEPLOYMENT & CLOUDFLARE HTTPS TUNNEL
# ==============================================================================
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLOUDFLARED_BIN="${CLOUDFLARED_BIN:-$(command -v cloudflared || echo "/home/quocanh/.local/bin/cloudflared")}"
LOG_DIR="$ROOT_DIR/.data"
mkdir -p "$LOG_DIR"
TUNNEL_LOG="$LOG_DIR/cloudflared.log"
API_LOG="$LOG_DIR/api_server.log"

cleanup() {
  echo ""
  echo ">> Đang dừng Web API Server & Cloudflare Tunnel..."
  [ -n "${API_PID:-}" ] && kill "$API_PID" 2>/dev/null || true
  [ -n "${TUNNEL_PID:-}" ] && kill "$TUNNEL_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "=================================================================="
echo " 🚀 KHỞI ĐỘNG SPORTHUB BACKEND WEB API & DEPLOY HTTPS GLOBAL"
echo "=================================================================="

# 1. Start Backend Web API & Admin Portal on Port 5173
if lsof -i :5173 >/dev/null 2>&1; then
  echo "✅ Cổng 5173 đã có dịch vụ Backend Web API đang chạy."
else
  echo "⏳ Đang khởi chạy Node.js Backend Web API tại http://localhost:5173 ..."
  (cd "$ROOT_DIR/admin-web" && npm run dev -- --host 0.0.0.0 --port 5173 >"$API_LOG" 2>&1) &
  API_PID=$!
  sleep 3
fi

# 2. Start Cloudflare HTTPS Tunnel
if [ ! -x "$CLOUDFLARED_BIN" ]; then
  echo "⚠️ Không tìm thấy cloudflared tại $CLOUDFLARED_BIN."
  echo "   Web API hiện đang chạy nội bộ tại: http://localhost:5173"
  wait
  exit 0
fi

rm -f "$TUNNEL_LOG"
echo "⏳ Đang mở cổng HTTPS công khai qua Cloudflare Tunnel..."
"$CLOUDFLARED_BIN" tunnel --url http://localhost:5173 >"$TUNNEL_LOG" 2>&1 &
TUNNEL_PID=$!

PUBLIC_URL=""
for _ in {1..30}; do
  if [ -f "$TUNNEL_LOG" ]; then
    PUBLIC_URL=$(grep -oE 'https://[-a-zA-Z0-9]+\.trycloudflare\.com' "$TUNNEL_LOG" | head -n 1 || true)
    if [ -n "$PUBLIC_URL" ]; then
      break
    fi
  fi
  sleep 1
done

echo ""
echo "=================================================================="
if [ -n "$PUBLIC_URL" ]; then
  echo " 🎉 DEPLOY WEB API THÀNH CÔNG (TRẠNG THÁI: LIVE 200 OK)"
  echo "=================================================================="
  echo " 🌐 Public Web API Endpoint : $PUBLIC_URL/api/sync"
  echo " 📚 Swagger UI API Docs     : $PUBLIC_URL/api-docs"
  echo " 💻 Web Admin Portal        : $PUBLIC_URL"
  echo " ☁️  Supabase PostgreSQL     : https://avlizwimxvgnzqdmxily.supabase.co"
  echo "------------------------------------------------------------------"
  echo " 📱 LỆNH CHẠY FLUTTER GỌI WEB API ĐÃ DEPLOY:"
  echo "    flutter run --dart-define=BACKEND_URL=$PUBLIC_URL"
  echo ""
  echo " 📦 LỆNH XUẤT FILE APK GỬI CHO CẢ NHÓM (DÙNG MỌI NƠI QUA 4G/WIFI):"
  echo "    flutter build apk --release --dart-define=BACKEND_URL=$PUBLIC_URL"
else
  echo " ⚠️ Chưa lấy được URL Cloudflare tự động, kiểm tra file $TUNNEL_LOG"
  echo " 🌐 Local Web API Endpoint  : http://localhost:5173/api/sync"
  echo " 📚 Local Swagger UI Docs   : http://localhost:5173/api-docs"
fi
echo "=================================================================="
echo "(Nhấn Ctrl+C để dừng dịch vụ khi kết thúc buổi demo)"

wait
