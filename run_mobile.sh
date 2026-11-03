#!/bin/bash
# Script khởi chạy Flutter Mobile Web giả lập hoặc Android Emulator trên Orca

echo "================================================="
echo "  CHỌN CHẾ ĐỘ CHẠY FLUTTER TRÊN ORCA:           "
echo "  1) Flutter Chrome Mobile Viewport (Siêu nhẹ)   "
echo "  2) Flutter Web Server (Nhúng vào tab Orca)     "
echo "  3) Khởi động Android Emulator & Chạy Flutter   "
echo "  4) Chạy Full: Web Admin (5173) + Flutter Chrome (8080)"
echo "  5) Chạy Điện thoại thật Android (USB: Web Admin 5173 + adb reverse + Flutter App)"
echo "================================================="
read -p "Nhập lựa chọn (1/2/3/4/5): " choice

case $choice in
  1)
    echo ">> Đang mở Flutter Chrome Mobile Viewport (412x915)..."
    flutter run -d chrome \
      --web-port 8080 \
      --web-hostname localhost \
      --web-browser-flag "--window-size=412,915" \
      --web-browser-flag "--user-agent=Mozilla/5.0 (Linux; Android 14; Pixel 7)"
    ;;
  2)
    echo ">> Đang mở Flutter Web Server tại cổng 8080..."
    echo ">> Trong terminal Orca khác, chạy lệnh: orca tab create --url http://localhost:8080"
    flutter run -d web-server --web-port 8080 --web-hostname localhost
    ;;
  3)
    echo ">> Kiểm tra danh sách máy ảo Android..."
    avd_name=$(emulator -list-avds 2>/dev/null | head -n 1)
    if [ -z "$avd_name" ]; then
      echo "[!] Không tìm thấy AVD nào! Hãy mở Android Studio để tạo máy ảo."
      exit 1
    fi
    echo ">> Đang khởi động AVD: $avd_name..."
    emulator @"$avd_name" >/dev/null 2>&1 &
    echo ">> Đang chờ máy ảo khởi động và kết nối adb..."
    adb wait-for-device
    sleep 3
    echo ">> Khởi chạy Flutter app lên máy ảo..."
    flutter run
    ;;
  4)
    echo ">> Đang khởi động Web Admin (Vite port 5173)..."
    (cd admin-web && npm run dev) &
    ADMIN_PID=$!
    trap "kill $ADMIN_PID 2>/dev/null" EXIT
    sleep 2
    echo ">> Đang mở Flutter Chrome Mobile Viewport (412x915)..."
    flutter run -d chrome \
      --web-port 8080 \
      --web-hostname localhost \
      --web-browser-flag "--window-size=412,915" \
      --web-browser-flag "--user-agent=Mozilla/5.0 (Linux; Android 14; Pixel 7)"
    ;;
  5)
    echo ">> Đang kiểm tra thiết bị Android cắm qua USB..."
    adb devices
    echo ">> Đang cấu hình chuyển tiếp cổng (adb reverse tcp:5173 tcp:5173)..."
    adb reverse tcp:5173 tcp:5173
    echo ">> Đang khởi động Web Admin & AI Backend (Port 5173)..."
    (cd admin-web && npm run dev -- --host 0.0.0.0 --port 5173) &
    ADMIN_PID=$!
    trap "kill $ADMIN_PID 2>/dev/null" EXIT
    sleep 2
    echo ">> Khởi chạy Flutter app lên thiết bị thật..."
    flutter run
    ;;
  *)
    echo "[!] Lựa chọn không hợp lệ."
    ;;
esac
