# Thiết Kế Trang Tài Liệu API Bằng Swagger UI Cho SportHub

- **Dự án:** SportHub Platform (Mobile + Web Admin + AI Gateway)
- **Tác giả:** Antigravity Pairing
- **Ngày tạo:** 2026-10-28
- **Trạng thái:** Approved / Draft Design

---

## 1. Tổng Quan Mục Tiêu
Cung cấp trang tài liệu API tương tác trực quan chuẩn **OpenAPI 3.0** và **Swagger UI** cho toàn bộ hệ thống API backend SportHub (hiện đang được điều phối bởi middleware `apiSyncPlugin.ts` trên Vite server tại cổng `5173`).

### Mục tiêu kỹ thuật:
1. **Chuẩn hóa OpenAPI 3.0.3:** Tài liệu hóa đầy đủ 16+ API RESTful hiện có, phân loại theo tag rõ ràng, có đầy đủ schema dữ liệu request/response, mô tả lỗi, ví dụ mẫu (examples).
2. **Swagger UI độc lập:** Phục vụ giao diện Swagger UI tại URL `/api-docs` và `/api-docs/`, hỗ trợ tính năng **"Try it out"** gọi trực tiếp API thật vào backend đang hoạt động.
3. **Tích hợp Web Admin Portal:** Thêm mục điều hướng **"Tài liệu API" (Swagger)** trên thanh Sidebar của Web Admin (dành cho cả Super Admin và Partner) giúp truy cập thuận tiện.
4. **Không phụ thuộc thư viện xung đột:** Sử dụng Swagger UI bản phân phối chuẩn (CDN / static bundle) để đảm bảo tương thích tuyệt đối với React 19 mà không gây lỗi peer-dependencies.

---

## 2. Kiến Trúc & Cấu Trúc Tệp Tin

```
admin-web/
├── public/
│   └── api-docs/
│       ├── index.html        # Giao diện Swagger UI (nhúng CDN Swagger UI bundle + CSS tùy biến SportHub)
│       └── openapi.json      # Đặc tả kỹ thuật OpenAPI 3.0.3 chi tiết
├── src/
│   ├── components/layout/
│   │   └── Sidebar.tsx       # Bổ sung menu điều hướng "Tài liệu API"
│   └── server/
│       └── apiSyncPlugin.ts  # Cấu hình middleware Vite tự động chuyển hướng /api-docs về trang Swagger UI
```

---

## 3. Đặc Tả Chi Tiết OpenAPI 3.0.3 (`openapi.json`)

### 3.1. Thông Tin Chung (Info & Servers)
- **Title:** `SportHub REST API & AI Gateway Documentation`
- **Version:** `1.0.0`
- **Description:** Hệ thống API Quản lý Sân thể thao, Đặt chỗ VietQR, Soát vé POS và AI Agent Gateway phục vụ ứng dụng Mobile SportHub & Web Admin.
- **Servers:**
  - `http://localhost:5173`: Local Development Gateway
  - `/`: Current Host Origin

### 3.2. Bảo Mật (Security Schemes)
- **AdminBearerAuth:**
  - Type: `http`
  - Scheme: `bearer`
  - Description: Token quản trị viên hệ thống (`SPORT_HUB_ADMIN_TOKEN` cấu hình trong `.env`).

### 3.3. Danh Mục Các Tags & API Endpoints

#### Tag: 🏟️ Venues (Quản lý Cụm Sân)
1. `GET /api/sync`: Lấy danh sách toàn bộ cụm sân và thông tin chung.
2. `POST /api/venues`: Tạo cụm sân thể thao mới.
   - Body: `name`, `address`, `district`, `sports`, `baseHourlyRate`, `imageUrl`, v.v.
3. `PATCH /api/venues/{id}`: Cập nhật thông tin cụm sân.
4. `DELETE /api/venues/{id}`: Xóa cụm sân khỏi hệ thống.

#### Tag: 🏸 Courts (Quản lý Sân & Bảng Giá)
5. `GET /api/courts`: Tra cứu danh sách sân chi tiết, hỗ trợ query `?venueId=...`.
6. `PATCH /api/courts/{courtId}`: Bật/tắt trạng thái bảo trì (`isActive`), cập nhật `regularPrice` và `peakPrice`.

#### Tag: 🎟️ Bookings & POS (Đặt Sân & Soát Vé)
7. `GET /api/bookings`: Danh sách các lượt đặt sân, hỗ trợ lọc theo `venueId`, `date`.
8. `POST /api/bookings`: Tạo đơn đặt sân mới với cơ chế chống trùng giờ (overlap check) và hỗ trợ add-ons (nước, vợt).
9. `PATCH /api/bookings/{id}`: Cập nhật thông tin vé đặt hoặc hủy đơn (`paymentStatus: 'cancelled'`).
10. `POST /api/checkin`: Quét QR/Check-in vé vào sân tại quầy lễ tân.

#### Tag: 🔄 Sync & Storage (Đồng Bộ Dữ Liệu)
11. `GET /api/sync`: Tải dữ liệu toàn bộ hệ thống (Courts, Venues, Bookings, Chatbot config, FAQs).
12. `POST /api/sync/reset`: Khôi phục CSDL về trạng thái dữ liệu mẫu chuẩn ban đầu.

#### Tag: 🤖 AI Chatbot & Agentic Gateway
13. `GET /api/chatbot/config`: Lấy cấu hình LLM hiện tại (Provider, Model, System Prompt, Temperature).
14. `POST /api/chatbot/config`: Cập nhật cấu hình LLM.
15. `GET /api/chatbot/faqs`: Lấy danh mục câu hỏi thường gặp FAQ.
16. `POST /api/chatbot/faqs`: Thêm câu hỏi FAQ mới.
17. `DELETE /api/chatbot/faqs/{id}`: Xóa câu hỏi FAQ.
18. `GET /api/chatbot/conversations`: Danh sách các cuộc trò chuyện.
19. `POST /api/chatbot/message`: Gửi tin nhắn đến AI Chatbot (hỗ trợ phân tích ngữ cảnh, gợi ý đặt sân).
20. `POST /api/chatbot/action/execute`: Thực thi hành động HITL (xác nhận đặt sân tự động).
21. `POST /api/chatbot/action/cancel`: Hủy hành động HITL.
22. `POST /api/chatbot/test-connection`: Kiểm tra kết nối và độ trễ tới FPT Cloud AI Gateway.

---

## 4. Giao Diện Swagger UI (`public/api-docs/index.html`)

- Tích hợp qua CDN uy tín của Swagger UI (`swagger-ui-dist@5.18.2`):
  - `swagger-ui.css`
  - `swagger-ui-bundle.js`
  - `swagger-ui-standalone-preset.js`
- Tùy chỉnh CSS:
  - Header thương hiệu SportHub màu xanh Navy thể thao (`#0B0F19` / `#1E293B`).
  - Font chữ hiện đại, favicon SportHub.
  - Cấu hình SwaggerUI:
    - `url: './openapi.json'`
    - `dom_id: '#swagger-ui'`
    - `deepLinking: true`
    - `displayRequestDuration: true`
    - `docExpansion: 'list'`
    - `filter: true` (cho phép tìm kiếm nhanh API theo từ khóa).

---

## 5. Tích Hợp Web Admin Navigation (`Sidebar.tsx`)

- Trong `admin-web/src/components/layout/Sidebar.tsx`:
  - Import icon `FileCode2` từ `lucide-react`.
  - Thêm mục vào `superAdminNavItems` và `partnerNavItems`:
    ```ts
    {
      name: 'Tài liệu API (Swagger)',
      path: '/api-docs',
      icon: FileCode2,
      isExternal: true, // mở tab mới hoặc chuyển hướng
    }
    ```
  - Xử lý link mở tab mới an toàn với `target="_blank" rel="noopener noreferrer"`.

---

## 6. Kế Hoạch Kiểm Thử & Nghiệm Thu (Verification)
1. **Kiểm tra cú pháp OpenAPI:** File `openapi.json` hợp lệ, không có lỗi định dạng JSON.
2. **Kiểm tra phục vụ trang:** Truy cập `http://localhost:5173/api-docs` hiển thị đầy đủ giao diện Swagger UI SportHub.
3. **Kiểm thử Try It Out:**
   - Thực thi `GET /api/sync`: Trả về HTTP 200 kèm JSON dữ liệu.
   - Thực thi `GET /api/courts`: Trả về HTTP 200 kèm danh sách sân.
   - Thực thi `POST /api/chatbot/test-connection`: Trả về kết quả kiểm tra AI.
4. **Kiểm tra Sidebar:** Bấm vào mục "Tài liệu API (Swagger)" trên Sidebar mở chính xác trang tài liệu.
5. **Kiểm tra Test Suite hiện tại:** Chạy `npm test` trong `admin-web` để đảm bảo 104/104 tests vẫn pass 100%.
