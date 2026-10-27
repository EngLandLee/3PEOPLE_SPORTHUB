# 🏆 KỊCH BẢN THUYẾT TRÌNH & DEMO ĐỒ ÁN CUỐI KỲ (FINAL SEMESTER DEMO SCRIPT)
## HỆ THỐNG QUẢN LÝ & ĐẶT SÂN THỂ THAO ĐA NỀN TẢNG SPORTHUB

---

## 📌 THÔNG TIN ĐỀ TÀI & THÀNH VIÊN
- **Tên đề tài:** Nền tảng Đặt sân thể thao thông minh, Kết nối cộng đồng & Quản lý vận hành tích hợp Trí tuệ nhân tạo (SportHub Ecosystem).
- **Kiến trúc:** Flutter Mobile App + React 19 Web Admin + Supabase Cloud PostgreSQL Realtime + FPT Cloud AI (Gemma 26B).
- **Danh sách thành viên nhóm (4 sinh viên):**
  1. **Lê Quốc Anh (Trưởng nhóm)** - MSSV: `2380600052` - Full-stack & Kiến trúc CSDL Cloud (Supabase PostgreSQL / Realtime / Concurrency Lock).
  2. **Đỗ Minh Nhật** - MSSV: `2380614792` - Kiến trúc Phân hệ AI Chatbot Multi-Agent, Vision Matchmaking & Guardrails.
  3. **Tưởng Hoàn Thiện** - MSSV: `2380602117` - Web Admin Portal (React 19, TS), State Management & Check-in Doanh thu.
  4. **Nguyễn Phan Ngọc Trưởng** - MSSV: `2380602415` - Flutter UI/UX, Sơ đồ ma trận sân & Luồng thanh toán VietQR.

---

## 🌐 LINK HỆ THỐNG LIVE ĐANG CHẠY SẴN SÀNG DEMO
- **Flutter Web App:** `http://localhost:8080` (hoặc chạy trực tiếp trên Android Emulator / Thiết bị thật).
- **Web Admin Portal:** `http://localhost:5173` (React 19 + TypeScript + Tailwind CSS).
- **Supabase Cloud Dashboard:** `https://supabase.com/dashboard/project/avlizwimxvgnzqdmxily`
  - *Project ID:* `avlizwimxvgnzqdmxily`
  - *Dữ liệu đã nạp:* 8 Cụm sân, 26 Sân thể thao, 128 Khung giờ, 8 Đơn đặt, 7 Giao dịch VietQR, 11 Dịch vụ phụ (Add-ons).
- **Tài khoản Demo có sẵn trên hệ thống:**
  - **Khách hàng (Customer):** `0909 123 456` (hoặc email `nguyenvanan@gmail.com`) / Mật khẩu: `123456` (Nguyễn Văn An).
  - **Chủ sân Tao Đàn (Partner):** `0988 888 777` (hoặc email `partner@taodan.vn`) / Mật khẩu: `123456` (Chủ Sân Tao Đàn).
  - **Quản trị viên (Super Admin):** `0900 000 001` (hoặc email `admin@sporthub.vn`) / Mật khẩu: `123456` (Super Admin SportHub).

---

## 🎬 5 CHẶNG DEMO TRỰC TIẾP TRƯỚC HỘI ĐỒNG (10-15 PHÚT)

### ⏱️ CHẶNG 1: TRẢI NGHIỆM KHÁCH HÀNG — TÌM SÂN & ĐẶT SÂN VIETQR (3 PHÚT)
> **Mục tiêu:** Chứng minh trải nghiệm người dùng mượt mà, trực quan, không giật lag và thanh toán chuẩn quốc gia.

1. **Đăng nhập:**
   - Mở app Flutter, tại màn hình Auth, bấm vào gợi ý tài khoản **"Người chơi"** hoặc nhập `0909 123 456` / `123456`.
   - Bấm **"Đăng nhập"** -> Vào ngay màn hình chính mang thương hiệu SportHub.
2. **Khám phá & Bộ lọc động:**
   - Bấm pill chọn Quận (ví dụ: *Quận 1* hoặc *Bình Thạnh*), số lượng cụm sân hiển thị cập nhật tức thì.
   - Chọn bộ lọc môn thể thao: *Cầu lông*, *Pickleball*, *Bóng đá*.
3. **Chi tiết sân & Ma trận giờ linh hoạt:**
   - Chọn cụm sân **"CLB Cầu Lông Tao Đàn"**.
   - Thao tác chuyển ca: Ca Sáng (06:00 - 12:00), Ca Chiều (12:00 - 17:00), Ca Tối (17:00 - 23:00).
   - Thao tác đổi bước nhảy giờ: `:00` (17:00 - 18:00) hoặc `:30` (17:30 - 18:30).
   - Chuyển đổi giữa chế độ **"Ma trận giờ"** và **"Sơ đồ sân 2D"** để xem trực quan từng sân.
4. **Chọn dịch vụ đi kèm (Add-ons) & Đặt sân:**
   - Chọn 1 slot sân trống (ví dụ: Sân 2, 19:00 - 20:00).
   - Chọn thêm dịch vụ phụ: *Nước suối Aquafina (+10.000đ)*, *Thuê vợt Yonex (+30.000đ)*.
   - Thanh Sticky Bottom Bar tự động tính tổng tiền theo thời gian thực.
   - Bấm **"Thanh toán VietQR"** -> Xuất hiện Modal thanh toán chuẩn NAPAS 247 với mã QR động VietQR sinh theo tiêu chuẩn ngân hàng Việt Nam.
   - Bấm **"Xác nhận đã chuyển khoản"** -> Vé tạo thành công, tự động lưu vào CSDL Cloud Supabase.
   - Vào tab **"Vé của tôi"** -> Xuất hiện thẻ vé `SPORTHUB PASS` với mã vé `SH-...`, mã vạch QR check-in và trạng thái **"Chờ check-in"**.

---

### ⏱️ CHẶNG 2: ĐỒNG BỘ THỜI GIAN THỰC ĐA NỀN TẢNG (REALTIME SYNC) (3 PHÚT)
> **Mục tiêu:** Chứng minh dữ liệu đồng bộ 100% giữa Mobile App, Web Admin và Supabase Cloud qua WebSockets.

1. **Mở song song 2 màn hình:**
   - Màn hình 1: Mobile App (vừa đặt sân xong).
   - Màn hình 2: Trình duyệt mở Web Admin `http://localhost:5173`.
2. **Đăng nhập Chủ sân Tao Đàn trên Web Admin:**
   - Đăng nhập tài khoản `partner@taodan.vn` / `123456`.
   - Vào mục **"Lịch sân" (Schedule)** của cụm sân Tao Đàn.
3. **Quan sát trực quan:**
   - Khung giờ khách hàng vừa đặt trên Mobile ngay lập tức đổi màu sang **Đã đặt (Màu đỏ)** trên Web Admin.
   - Vào mục **"Doanh thu" (Revenue)**: Tổng doanh thu và số lượng đơn hàng tự động tăng lên tương ứng số tiền vừa thanh toán.
4. **Kiểm chứng tại CSDL Supabase:**
   - Mở Supabase Table Editor: bảng `bookings` có thêm 1 dòng mới với đầy đủ thông tin: `ticket_code`, `venue_id`, `court_number`, `total_price`, `payment_method: vietqr`.

---

### ⏱️ CHẶNG 3: CHỦ SÂN SOÁT VÉ CHECK-IN KHÁCH VÀO SÂN (2 PHÚT)
> **Mục tiêu:** Chứng minh quy trình vận hành khép kín O2O (Online-to-Offline).

1. **Thao tác Soát vé:**
   - Trên Web Admin (hoặc trên Mobile khi chuyển sang "Chế độ Chủ sân"): Chọn tab **"Soát vé Check-in" (POS)**.
   - Nhập mã vé của khách (hoặc quét mã QR trên vé `SH-...`).
   - Bấm **"Kiểm tra & Check-in"**.
2. **Kết quả:**
   - Hệ thống gọi Stored Procedure `fn_checkin_booking` trên Supabase:
     + Trả về `success: true`.
     + Cập nhật `checked_in = true` và lưu mốc thời gian `checked_in_at = NOW()`.
   - Giao diện hiển thị Popup thông báo: *"Check-in thành công: Khách Nguyễn Văn An - Sân 2 - 19:00"*.
   - Khách mở tab "Vé của tôi" trên Mobile: Trạng thái vé lập tức đổi thành **"ĐÃ NHẬN SÂN"** màu xanh lá.

---

### ⏱️ CHẶNG 4: TRỢ LÝ AI CHATBOT ĐA TÁC VỤ & BẢO MẬT GUARDRAILS (4 PHÚT)
> **Mục tiêu:** Điểm sáng công nghệ của đồ án - Chatbot kết hợp LLM FPT Cloud với CSDL thật, có Guardrails và HITL.

1. **Mở Trợ lý AI:**
   - Bấm vào bong bóng chat AI nổi ở góc phải màn hình Mobile.
2. **Tác vụ 1: Tra cứu giá & Đặt sân thông minh (Context-Aware Grounding)**
   - Nhập câu hỏi: *"Sân Tao Đàn giá bao nhiêu 1 giờ?"*
     -> AI trích xuất giá chuẩn xác từ CSDL: *120.000đ/giờ*.
   - Nhập câu hỏi: *"Đặt sân cầu lông tối nay lúc 19h"*
     -> AI kiểm tra sân trống, trả về thẻ tương tác **`ChatBookingCard`** hiển thị Sân 1, giá tiền và 2 nút:
     + Bấm nút **"🔍 Xem trên sơ đồ"** -> Tự động chuyển đến đúng sân và khung giờ trên ma trận sân.
     + Bấm nút **"⚡ Đặt & Thanh toán VietQR ngay"** -> Tự động kích hoạt luồng thanh toán.
3. **Tác vụ 2: Trợ lý Báo cáo Doanh thu cho Chủ Sân (Role-Based AI)**
   - Đăng nhập tài khoản Chủ sân Tao Đàn (`partner@taodan.vn`), mở Chatbot AI.
   - Nhập câu hỏi: *"Hôm nay doanh thu của sân tôi thế nào?"*
     -> AI phân tích dữ liệu thật từ Supabase: *Báo cáo doanh thu hơn 4.2 triệu VNĐ từ 18 lượt đặt, 100% qua cổng VietQR!*
   - Nhập câu hỏi: *"Có bao nhiêu vé đang chờ check-in?"*
     -> AI liệt kê danh sách mã vé chưa check-in và mã vé vừa nhận sân chi tiết.
4. **Tác vụ 3: Bảo mật & Hàng rào kiểm soát (AI Safety Guardrails)**
   - Nhập câu hỏi ngoài luồng: *"Viết cho tôi một bài thơ tình"* hoặc *"Thời tiết Hà Nội hôm nay thế nào?"*
     -> **Guardrails kích hoạt:** AI từ chối khéo léo và hướng dẫn người dùng quay lại các nghiệp vụ liên quan đến sân bãi thể thao.
5. **Tác vụ 4: Ghép kèo & Giám sát con người (Human-in-the-Loop - HITL)**
   - Gửi ảnh hoặc nhập: *"Tôi muốn tìm 2 bạn đánh đôi cầu lông tối nay"*
     -> AI đề xuất thẻ ghép kèo (`ActionProposalCard`). Người dùng được quyền chỉnh sửa trình độ, số lượng người trước khi bấm **"Xác nhận duyệt"** để đăng lên Bảng tin cộng đồng.

---

### ⏱️ CHẶNG 5: PHÂN QUYỀN RBAC & TÙY BIẾN GIAO DIỆN (THEME SWITCHER) (2 PHÚT)
> **Mục tiêu:** Thể hiện độ hoàn thiện của sản phẩm theo tiêu chuẩn thương mại.

1. **Phân quyền 3 vai trò (RBAC):**
   - **Người chơi (Customer):** Chỉ xem sân, đặt sân, xem vé cá nhân, giao lưu cộng đồng.
   - **Chủ sân (Partner):** Quản lý sân của mình, khóa/mở sân bảo trì, tra cứu doanh thu và soát vé check-in.
   - **Super Admin:** Toàn quyền quản trị danh sách đối tác, cấu hình prompt Chatbot AI, xem biểu đồ doanh thu toàn sàn.
2. **Chế độ Giao diện Sáng / Tối (Light / Dark Mode):**
   - Bấm nút icon Mặt trời / Mặt trăng trên Header (cả Mobile và Web Admin).
   - Toàn bộ bảng màu chuyển đổi tức thì, màu tương phản cao, dịu mắt, tối ưu trải nghiệm khi sử dụng ban đêm.

---

## 💡 BỘ CÂU HỎI THƯỜNG GẶP CỦA HỘI ĐỒNG & CÂU TRẢ LỜI MẪU (Q&A DEFENSE)

### ❓ Câu hỏi 1: "Cơ sở dữ liệu của các bạn lưu ở đâu? SQLite offline hay Cloud?"
> **Trả lời:**
> *"Dạ thưa Thầy/Cô, ban đầu nhóm dùng SQLite local để làm mockup, nhưng để đáp ứng bài toán thực tế đặt sân trực tuyến đa người dùng, nhóm đã nâng cấp toàn diện lên **Supabase Cloud PostgreSQL**. Hiện tại toàn bộ dữ liệu (8 cụm sân, 26 sân, các khung giờ, đơn đặt và lịch sử check-in) đều được lưu trữ tập trung trên Supabase. Mobile App và Web Admin đồng bộ dữ liệu thời gian thực qua WebSockets."*

### ❓ Câu hỏi 2: "Nếu 2 người dùng cùng lúc bấm đặt 1 sân tại cùng 1 khung giờ thì hệ thống xử lý thế nào?"
> **Trả lời:**
> *"Dạ nhóm đã giải quyết triệt để lỗi Double-Booking bằng **Stored Procedure `fn_book_court_slot`** viết bằng PL/pgSQL chạy trực tiếp trên Supabase. Hàm này áp dụng cơ chế **Row-Level Locking (`SELECT id ... FOR UPDATE`)**. Khi Transaction thứ nhất đang giữ lock để ghi nhận đơn đặt, Transaction thứ hai cố gắng đặt cùng sân/giờ đó sẽ bị chặn lại và nhận về thông báo lỗi: 'Khung giờ này vừa có người khác đặt. Vui lòng chọn ca khác!'. Nhờ vậy tính toàn vẹn dữ liệu (ACID) được bảo đảm 100%."*

### ❓ Câu hỏi 3: "Chatbot AI của các bạn có bị bịa số liệu (Hallucination) không? Làm sao đảm bảo an toàn?"
> **Trả lời:**
> *"Dạ Chatbot của nhóm áp dụng kiến trúc **Grounding dữ liệu thật kết hợp Guardrails**:
> 1. Mọi câu hỏi về giá sân, tình trạng sân trống hay doanh thu của chủ sân đều được hệ thống truy vấn trực tiếp từ CSDL Supabase rồi đưa vào ngữ cảnh (Context) trước khi LLM trả lời, tuyệt đối không để LLM tự đoán số.
> 2. Nhóm xây dựng tầng **Guardrails** để ngăn chặn Prompt Injection và chặn các câu hỏi ngoài phạm vi thể thao (ví dụ thơ văn, chính trị, code web).
> 3. Cơ chế **Human-In-The-Loop (HITL)** yêu cầu người dùng xác nhận thông tin trước khi thực thi các tác vụ tạo đơn hoặc đăng bài."*

### ❓ Câu hỏi 4: "Mã VietQR thanh toán trong ứng dụng có phải mã giả lập không?"
> **Trả lời:**
> *"Dạ mã VietQR được sinh động theo đúng **Đặc tả kỹ thuật chuẩn VietQR/EMVCo của NAPAS và Ngân hàng Nhà nước**. Nhóm mã hóa đầy đủ mã định danh ngân hàng (BIN), số tài khoản thụ hưởng, số tiền chính xác theo từng đơn và nội dung chuyển khoản chứa mã vé `SH-...`. Giám khảo có thể dùng bất kỳ ứng dụng ngân hàng nào (Vietcombank, MB Bank, Techcombank...) quét mã QR trên màn hình là app ngân hàng sẽ tự điền đúng số tiền và thông tin chuyển khoản."*

### ❓ Câu hỏi 5: "Độ tin cậy và kiểm thử của phần mềm ra sao?"
> **Trả lời:**
> *"Dạ toàn bộ hệ thống đã được viết Unit Test, Widget Test và E2E Test tự động:
> - Phía Flutter Mobile: **370/370 tests PASS 100%**, lệnh `flutter analyze` đạt **0 issues**.
> - Phía Web Admin: **104/104 tests Vitest PASS 100%**, build production `tsc && vite build` không có lỗi Type."*

---

## 🎯 DANH MỤC LỆNH CHUẨN BỊ MÔI TRƯỜNG TRƯỚC KHI BẮT ĐẦU BUỔI BẢO VỆ
Mở 2 Terminal trước khi bước lên bàn thuyết trình:
```bash
# Terminal 1: Chạy Web Admin Portal (Port 5173)
cd admin-web && npm run dev -- --host 0.0.0.0 --port 5173

# Terminal 2: Chạy Flutter Web App (Port 8080)
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```
Sau đó mở trình duyệt ở 2 tab:
- Tab 1: `http://localhost:8080` (SportHub Mobile Web)
- Tab 2: `http://localhost:5173` (SportHub Partner & Admin Portal)

Chúc nhóm thuyết trình tự tin, mạch lạc và đạt điểm tối đa! 🚀
