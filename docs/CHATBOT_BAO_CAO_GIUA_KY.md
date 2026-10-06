# BÁO CÁO KỸ THUẬT & KỊCH BẢN THUYẾT TRÌNH GIỮA KỲ
## PHÂN HỆ: TRỢ LÝ ẢO THỂ THAO AI (SPORTHUB CHATBOT)
* **Môn học:** Lập trình trên thiết bị di động  
* **Đồ án:** SportHub - Đặt Sân Thể Thao & Ghép Kèo AI  
* **Thời lượng thuyết trình:** 5 – 7 phút (Bao gồm Live Demo)

---

## 1. ĐẶT VẤN ĐỀ: VÌ SAO KHÔNG DÙNG "PROMPT AI THUẦN TÚY"?

Nếu chỉ làm theo cách cơ bản: *Người dùng gõ gì $\rightarrow$ gửi thẳng lên OpenAI/Gemini $\rightarrow$ in text trả về*, ứng dụng sẽ gặp **3 thất bại kỹ thuật lớn**:
1. **Ảo giác dữ liệu (Hallucination):** LLM không nắm được trạng thái sân thực tế trong database. Nó có thể "tự bịa" ra Sân 1 còn trống lúc 19:30 trong khi sân đó đã có người cọc trước đó.
2. **Thiếu tính tương tác Native (UI/UX kém):** LLM chỉ trả về văn bản hoặc cố vẽ bảng markdown `| Sân | Giờ |` rất xấu và vỡ khung trên màn hình điện thoại; không thể tự bật mã VietQR cho khách quét trả tiền.
3. **Phụ thuộc 100% vào mạng:** Mất Internet hoặc server AI quốc tế bị nghẽn $\rightarrow$ Chatbot "chết" hoàn toàn.

> **Giải pháp kiến trúc của nhóm:** Xây dựng mô hình **Trí tuệ lai (Dual-Mode Hybrid Intelligence)**:
> - **AI Cloud (Gemma 26B):** Đảm nhận giao tiếp ngôn ngữ tự nhiên, nói chuyện linh hoạt, thân thiện.
> - **Local State Engine (Dart):** Kiểm soát 100% nghiệp vụ: kiểm tra lịch trống, tính giá cao điểm, sinh thẻ đặt sân Native (`ChatBookingCard`) có gắn mã VietQR động.

---

## 2. KIẾN TRÚC 4 PHÂN HỆ AGENT (MULTI-AGENT ARCHITECTURE)

Hệ thống điều phối toàn bộ luồng hội thoại qua **4 Agent chuyên trách**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 CHATBOT HYBRID CORE (DUAL-MODE ENGINE)                      │
├───────────────────────────────┬─────────────────────────────────────────────┤
│ 1. Orchestrator & Safety Guard│ • Phân loại Intent & Router                 │
│    Agent                      │ • Inject thời gian thực DateTime.now()      │
│                               │ • Role Isolation (ngăn khách xem KPI chủ)   │
├───────────────────────────────┼─────────────────────────────────────────────┤
│ 2. Smart Booking & Dynamic    │ • Bóc tách tiếng Việt có dấu & không dấu    │
│    Slot Agent                 │ • Giờ khẩu ngữ (5 rưỡi, 7h kém 15, cuối tuần│
│                               │ • Tính giá ca vàng (17h-21h) qua logic sân  │
├───────────────────────────────┼─────────────────────────────────────────────┤
│ 3. Add-on & Live Transaction  │ • Thêm / bớt nước Pocari, ống cầu, thuê vợt │
│    Sync Agent                 │ • Đồng bộ VietQR real-time qua Event Bus    │
│                               │ • Hủy vé & hoàn tiền Idempotent             │
├───────────────────────────────┼─────────────────────────────────────────────┤
│ 4. Multimodal Matchmaking     │ • Phân tích ảnh poster giao lưu thể thao    │
│    Vision Agent               │ • Bóc tách số slot, trình độ, chia tiền     │
│                               │ • Tự động đăng lên Bảng tin Cộng đồng       │
└───────────────────────────────┴─────────────────────────────────────────────┘
```

---

## 3. SO SÁNH CÔNG NGHỆ & TẠI SAO LẠI CHỌN? (TRADE-OFF ANALYSIS)

Nhóm đã nghiên cứu và so sánh 3 hướng tiếp cận công nghệ trước khi quyết định:

| Hướng tiếp cận | Ưu điểm | Nhược điểm chí mạng | Nhóm có chọn không? |
| :--- | :--- | :--- | :---: |
| **1. Rasa / Dialogflow (Rule-based NLP)** | Chạy local ổn định, quản lý flow chặt chẽ. | Rất cứng nhắc. Người dùng gõ sai cú pháp hoặc dùng từ lóng (*"5 rưỡi"*, *"kèo giao lưu"*) là bot không hiểu. | ❌ Không chọn |
| **2. LangChain / LlamaIndex** | Hệ sinh thái phong phú, nhiều plugin. | Quá nặng nề (bloated), thiết kế chủ yếu cho Python backend, không tối ưu khi đóng gói app mobile. | ❌ Không chọn |
| **3. OpenAI GPT-4o API Thuần** | Trả lời thông minh, câu từ mượt mà. | Server ở nước ngoài latency cao ($> 2\text{s}$), chi phí token đắt, đứt cáp hoặc mất mạng là app chết. | ❌ Không chọn |
| **4. SportHub Hybrid: FPT Cloud AI + Dart Engine** | • Latency siêu nhanh ($0.37\text{s}$) nhờ Datacenter FPT tại TP.HCM.<br>• Tối ưu sâu tiếng Việt bản địa.<br>• Mất mạng vẫn chạy được nhờ Local Engine. | Tốn công xây dựng bộ lọc và giao thức kết nối State riêng ở Client. | ✅ **LỰA CHỌN TỐI ƯU** |

### Danh mục thư viện thực tế (Zero-Bloat):
* **`package:http` (`^1.6.0`):** Thư viện mạng chuẩn duy nhất, gọi REST API FPT Cloud và Backend Sync.
* **`qr_flutter` (`^4.1.0`):** Render mã VietQR động trực tiếp trong thẻ chat.
* **`intl` (`^0.19.0`):** Xử lý tiền tệ VNĐ và thời gian thực hệ thống.
* **`dart:convert` & `dart:async`:** Xử lý JSON, giải mã UTF-8 và quản lý luồng bất đồng bộ.

---

## 4. CÁCH GIẢI QUYẾT CÁC BÀI TOÁN XUNG ĐỘT KỸ THUẬT

Để chứng minh nhóm có đầu tư chiều sâu, đây là **5 xung đột thực tế đã được giải quyết bằng thuật toán**:

1. **Xung đột Đa ý định (Multi-Intent Lookahead):**
   - *Tình huống:* Khách nhắn: *"Giá sân Tao Đàn bao nhiêu và đặt luôn cho mình lúc 19h"*.
   - *Xử lý:* Cờ `!hasBookingIntent` nhận diện có từ *"đặt luôn"* $\rightarrow$ Bỏ qua câu trả lời FAQ giá đơn thuần, chuyển thẳng sang luồng tạo thẻ đặt sân.
2. **Xung đột Trùng lịch sân (Slot Conflict Sanitizer):**
   - *Tình huống:* AI Cloud gợi ý Sân 1, nhưng thực tế Sân 1 lúc 19:30 đã có người đặt trước.
   - *Xử lý:* Hàm `sanitizeServerActionCard()` ở Client đối chiếu với `VenueSyncService`. Nếu Sân 1 bận, tự động chuyển sang Sân 2 còn trống và đồng bộ lại giá tiền.
3. **Thêm/Bớt dịch vụ hai chiều (Bi-directional Add-ons):**
   - *Tình huống:* Khách đặt thêm 2 nước, sau đó nhắn: *"Bỏ bớt 1 chai Pocari ra nhé"*.
   - *Xử lý:* Nhận diện cờ `isDecrement` để trừ số lượng `currentCount - qty` (kèm chặn biên $[1, 100]$ chống số âm), tự động tính lại tổng tiền thanh toán.
4. **Phân quyền vai trò (Role-Based Isolation):**
   - *Tình huống:* Khách hàng thường cố tình gõ: *"Báo cáo doanh thu hôm nay"*.
   - *Xử lý:* Agent 1 kiểm tra `userRole != 'owner'` $\rightarrow$ Chặn sinh bảng biểu tài chính, chỉ hướng dẫn xem giá dịch vụ.
5. **Chống gian lận hủy vé (Idempotent Cancellation):**
   - *Tình huống:* Khách gõ hủy vé lần 1 đã hoàn tiền, sau đó gõ hủy tiếp lần 2.
   - *Xử lý:* Kiểm tra trạng thái vé đã là `cancelled` $\rightarrow$ Giữ nguyên trạng thái, báo tiền hoàn thêm là **0đ**, ngăn chặn hoàn tiền lặp lại.

---

## 5. KỊCH BẢN NÓI KHI THUYẾT TRÌNH (5 PHÚT)

* **Phút 1: Đặt vấn đề & Tuyên ngôn thiết kế**
  > *"Kính thưa Thầy/Cô, khi làm Chatbot cho SportHub, nhóm em đặt ra nguyên tắc: **Nói không với Chatbot Wrapper gọi API đơn thuần**. Nếu chỉ gửi text lên AI rồi in ra màn hình, chatbot sẽ bị ảo giác giờ trống và không thể tương tác với database. Nhóm em tự thiết kế mô hình **Trí tuệ lai Dual-Mode** kết hợp **4 Phân hệ Agent chuyên trách**."*

* **Phút 2: Kiến trúc 4 Agent & Công nghệ**
  > *"Hệ thống gồm 4 Agent:
  > - **Agent 1:** Bảo mật, lọc prompt và phân quyền dữ liệu.
  > - **Agent 2:** Đặt sân, bóc tách tiếng Việt không dấu và giờ khẩu ngữ (5 rưỡi, 7h kém 15).
  > - **Agent 3:** Thêm bớt dịch vụ và đồng bộ thanh toán VietQR thời gian thực.
  > - **Agent 4:** Thị giác AI phân tích ảnh poster ghép kèo.  
  > Về hạ tầng, nhóm dùng mô hình **Gemma 26B** của **FPT Cloud AI** đặt tại TP.HCM cho tốc độ phản hồi chỉ 0.37 giây, kết nối qua thư viện `http` tiêu chuẩn."*

* **Phút 3 - 4: Live Demo 3 tính năng ăn tiền**
  > 1. **Demo Giờ khẩu ngữ & Không dấu:** Gõ *"dat san cau long tao dan 5 ruoi chieu"* $\rightarrow$ Thẻ `ChatBookingCard` xuất hiện lúc 17:30, tính đúng giá cao điểm 180k kèm mã VietQR.  
  > 2. **Demo Giảm dịch vụ:** Gõ *"Lấy 2 Pocari"*, sau đó gõ *"Bỏ bớt 1 chai Pocari ra nhé"* $\rightarrow$ Thẻ tự giảm tiền còn đúng 15k phụ phí.  
  > 3. **Demo Đồng bộ Realtime:** Bấm *"Xác nhận thanh toán"* $\rightarrow$ Thẻ chat tự động chuyển màu xanh **"ĐÃ GIỮ CHỖ"** theo thời gian thực nhờ Event Bus.

* **Phút 5: Kết luận & Chuyển sang phần Q&A**
  > *"Toàn bộ hệ thống Chatbot đã được kiểm chứng qua **80 bài test tự động trên Flutter và 81 bài test trên Web Admin đạt tỉ lệ Pass 100%**. Nhóm em xin cảm ơn Thầy/Cô và sẵn sàng trả lời câu hỏi phản biện ạ!"*

---

## 6. BỘ CÂU HỎI PHẢN BIỆN DỰ PHÒNG CỦA GIẢNG VIÊN

* **Câu 1: "Tại sao nhóm chọn FPT Cloud (Gemma 26B) mà không dùng OpenAI GPT-4o?"**
  - *Đáp:* FPT Cloud đặt máy chủ tại TP.HCM (SGN Datacenter), độ trễ thực tế chỉ **0.37s** (so với 2 - 3s của OpenAI). Đồng thời Gemma 26B hiểu rất sâu địa danh Việt Nam (Tao Đàn, Bình Thạnh, Thảo Điền) và tiếng lóng thể thao.
* **Câu 2: "Làm sao đảm bảo Chatbot không bị ảo giác sinh ra giá sân sai?"**
  - *Đáp:* AI Cloud chỉ có nhiệm vụ sinh lời thoại giao tiếp thân thiện. Toàn bộ thông tin trên thẻ (`ActionCard`) như số sân, giờ chơi, đơn giá VietQR đều do code Dart tại Client tính toán từ cơ sở dữ liệu thật, AI không được phép tự quyết định giá tiền.
* **Câu 3: "Nếu điện thoại bị mất mạng thì Chatbot có hoạt động được không?"**
  - *Đáp:* Dạ có. Khi mất kết nối mạng, hệ thống tự động fallback tức thì về **Local Smart Intent Engine** (viết bằng Dart) để tiếp tục phục vụ tìm sân và tính giá trong 50ms mà không hề bị văng lỗi.
