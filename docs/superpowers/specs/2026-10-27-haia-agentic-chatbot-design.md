# Thiết kế Kỹ thuật: Hệ thống Chatbot Agentic SportHub theo Chuẩn Kiến trúc HAIA

- **Ngày ban hành:** 27/10/2026
- **Trạng thái:** Đã phê duyệt (Approved)
- **Tác giả:** SportHub Engineering Team
- **Tham chiếu kiến trúc:** Hệ thống HAIA (`anhnguyen888/chatbot-hutech`)

---

## 1. Mục tiêu & Bối cảnh (Goal & Context)

Hệ thống Chatbot hiện tại của SportHub đã hỗ trợ trả lời tin nhắn, kết nối FPT Cloud LLM và cung cấp thông tin sân bãi. Tuy nhiên, hệ thống còn thiếu các cơ chế bảo vệ an ninh cấp độ doanh nghiệp và cơ chế kiểm soát các tác vụ thay đổi dữ liệu (Mutations).

Lấy cảm hứng từ hệ thống trợ lý học thuật **HAIA (HUTECH AI Assistant)**, dự án này nâng cấp Chatbot của SportHub theo mô hình **Agentic AI với Human-In-The-Loop (HITL)**:
1. **Bảo mật đa tầng (Dual-layer Guardrails):** Ngăn chặn Prompt Injection, Jailbreak, và rò rỉ dữ liệu nhạy cảm (PII).
2. **Kiểm soát tác vụ ghi bằng Human-In-The-Loop (HITL):** Khi người dùng yêu cầu đặt sân, Chatbot không tự ý lưu vào CSDL mà xuất ra một `ActionProposal` (Đề xuất hành động). Người dùng phải bấm duyệt trên giao diện mới tạo vé.
3. **Chống gian lận qua Form Allowlist & Giá bất biến:** Chỉ cho phép người dùng sửa các trường trong allowlist (giờ, ghi chú); các trường nhạy cảm như giá tiền và mã sân được server tính toán độc lập từ DB.
4. **Hiển thị thẻ dữ liệu xác định (Deterministic Cards):** Thẻ sân bãi, lịch trống và giá tiền được trích xuất trực tiếp từ CSDL thực tế, loại bỏ hoàn toàn hiện tượng AI bịa đặt số liệu (Hallucination).

---

## 2. Kiến trúc Tổng thể & Ranh giới Thành phần

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER MOBILE CLIENT                           │
│  - ChatbotBottomSheet / ChatMessageBubble                              │
│  - ActionProposalCard (Widget hiển thị thẻ duyệt tương tác)             │
│  - ChatbotService (Điều phối tin nhắn, ngữ cảnh động, API approve/cancel)│
└───────────────────▲──────────────────────────────┬─────────────────────┘
                    │                              │
    HTTP / JSON     │ Responses + Proposals        │ POST /api/chatbot/message
                    │                              │ POST /api/chatbot/action/execute
                    │                              │ POST /api/chatbot/action/cancel
                    │                              │
┌───────────────────┴──────────────────────────────▼─────────────────────┐
│                    BACKEND (admin-web / API Server)                    │
│                                                                        │
│  1. Guardrails Layer (guardrails.ts):                                  │
│     - guardrailIn: Chặn Prompt Injection tiếng Việt & tiếng Anh         │
│     - guardrailOut: Khử PII, dọn dẹp văn bản                           │
│                                                                        │
│  2. Intent & Proposal Router:                                          │
│     - Read Queries: Truy xuất DB thật -> Deterministic Cards            │
│     - Write Queries: Sinh ActionProposal (Status: pending)              │
│                                                                        │
│  3. HITL Action Controller:                                            │
│     - /api/chatbot/action/execute: Validate Allowlist, verify price,   │
│       thực thi tạo vé trong TicketStore / Database                     │
│     - /api/chatbot/action/cancel: Hủy đề xuất                          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Đặc tả Kỹ thuật API (API Specifications)

### 3.1. `POST /api/chatbot/message`
Nhận tin nhắn của người dùng kèm ngữ cảnh động của ứng dụng, trả về câu trả lời tự nhiên kèm Cards hoặc Action Proposal.

#### Request Body:
```typescript
interface ChatMessageRequest {
  message: string;
  context?: {
    userId?: string;
    userName?: string;
    currentVenueId?: string;
    preferredSport?: string;
    screen?: string;
  };
  conversationId?: string;
}
```

#### Pipeline xử lý Backend:
1. **Chạy `guardrailIn(message)`:**
   - Kiểm tra các mẫu regex injection:
     - Tiếng Việt: `bỏ qua mọi hướng dẫn`, `quên hết chỉ thị`, `in ra system prompt`, `đặt giá 0đ`...
     - Tiếng Anh: `ignore previous instructions`, `reveal system prompt`, `you are now`, `bypass`...
   - Nếu vi phạm: Trả về HTTP 200 kèm `violation: true` và lời từ chối lịch sự, **không chuyển tiếp sang LLM**.
2. **Nhận diện Ý định (Intent Classification):**
   - **Ý định ĐỌC (Tra cứu sân, giờ, giá, quy định):**
     - Truy vấn danh sách sân từ `VenueStore` và tính lịch rảnh từ `CourtSlotStore`.
     - Dựng `deterministicCards` từ dữ liệu thô.
     - Gọi LLM viết lời chào & giải thích thân thiện.
   - **Ý định GHI (Đặt sân, giữ chỗ):**
     - Trích xuất thông tin: Sân, Ngày, Giờ.
     - Sinh `ActionProposal` với trạng thái `pending`.
     - Lưu đề xuất tạm thời vào memory cache (hết hạn sau 15 phút).
     - **Không gọi hàm tạo vé vào CSDL.**
3. **Chạy `guardrailOut(reply)`:**
   - Khử các chuỗi nhạy cảm (API keys, số tài khoản kỹ thuật, PII).
   - Chuẩn hóa khoảng trắng.

#### Response Body (Thành công - Đề xuất đặt sân):
```json
{
  "reply": "Em đã lên thông tin đặt sân cho bạn. Bạn vui lòng kiểm tra lại chi tiết dưới đây và bấm 'Xác nhận đặt sân' nhé!",
  "proposal": {
    "id": "prop_1730000001",
    "tool": "create_court_booking",
    "status": "pending",
    "target": {
      "venueId": "venue_chao_lua",
      "venueName": "CLB Thể Thao Chảo Lửa",
      "courtId": "court_badminton_01",
      "courtName": "Sân Cầu Lông 1",
      "date": "2026-10-27",
      "timeSlot": "18:00 - 19:30",
      "price": 180000
    },
    "form": [
      {
        "key": "timeSlot",
        "label": "Khung giờ chơi",
        "type": "text",
        "required": true,
        "currentValue": "18:00 - 19:30"
      },
      {
        "key": "note",
        "label": "Ghi chú cho chủ sân",
        "type": "textarea",
        "required": false,
        "maxLength": 200,
        "currentValue": ""
      }
    ],
    "expiresAt": 1730000901000
  },
  "deterministicCards": [],
  "quickSuggestions": ["Đổi sang 19h", "Hủy yêu cầu"]
}
```

---

### 3.2. `POST /api/chatbot/action/execute`
Thực thi đề xuất sau khi người dùng bấm "Xác nhận đặt sân" trên ứng dụng.

#### Request Body:
```typescript
interface ActionExecuteRequest {
  proposalId: string;
  approved: boolean;
  edits?: {
    timeSlot?: string;
    note?: string;
  };
}
```

#### Quy tắc xác thực Backend:
1. **Kiểm tra tồn tại & Hạn hiệu lực:**
   - Nếu `proposalId` không tìm thấy hoặc đã quá thời gian `expiresAt` (15 phút) $\rightarrow$ Trả về lỗi `proposal_expired`.
2. **Kiểm tra Form Allowlist (`hitl_edits` logic):**
   - Chỉ các trường có mặt trong `proposal.form` (`timeSlot`, `note`) mới được chấp nhận cập nhật.
   - Bất kỳ trường nào khác (ví dụ client cố tình chèn `price: 0`, `courtId: ...`) **sẽ bị loại bỏ hoặc từ chối ngay lập tức**.
   - Kiểm tra kiểu dữ liệu và giới hạn ký tự (`maxLength: 200`).
3. **Xác thực Giá tiền Độc lập (Price Re-verification):**
   - Server lấy `courtId` từ bản ghi proposal gốc, tra cứu bảng giá hiện hành trong CSDL để tính toán `totalPrice`.
   - Tuyệt đối không lấy giá tiền từ client gửi lên.
4. **Kiểm tra Trùng lịch (Slot Collision Check):**
   - Kiểm tra xem sân tại khung giờ đã chọn có bị ai khác giữ chỗ trong lúc chờ duyệt không.
   - Nếu đã bị đặt: Trả về lỗi `slot_unavailable` để người dùng chọn giờ khác.
5. **Thực thi Ghi dữ liệu:**
   - Tạo bản ghi `Ticket` mới với trạng thái `pending` (hoặc `confirmed`).
   - Cập nhật trạng thái của proposal thành `executed`.

#### Response Body (Thành công):
```json
{
  "success": true,
  "message": "Đặt sân thành công! Mã vé của bạn đã được lưu vào hệ thống.",
  "ticket": {
    "id": "ticket_1730000002",
    "venueName": "CLB Thể Thao Chảo Lửa",
    "courtName": "Sân Cầu Lông 1",
    "date": "2026-10-27",
    "timeSlot": "18:00 - 19:30",
    "totalPrice": 180000,
    "status": "pending",
    "note": "Chuẩn bị 2 chai Pocari lạnh"
  }
}
```

---

### 3.3. `POST /api/chatbot/action/cancel`
Hủy bỏ đề xuất khi người dùng bấm "Hủy" trên Card.

#### Request Body:
```json
{
  "proposalId": "prop_1730000001"
}
```

#### Response Body:
```json
{
  "success": true,
  "message": "Đã hủy đề xuất đặt sân."
}
```

---

## 4. Thiết kế Phía Client (Flutter Mobile)

### 4.1. Thực thể Dữ liệu (Entity Model)
Cập nhật `ChatMessage` để hỗ trợ đề xuất hành động:
```dart
class ActionProposal {
  final String id;
  final String tool;
  String status; // 'pending' | 'approved' | 'rejected' | 'executed'
  final Map<String, dynamic> target;
  final List<FormFieldSpec> form;
  final int expiresAt;

  ActionProposal({
    required this.id,
    required this.tool,
    this.status = 'pending',
    required this.target,
    required this.form,
    required this.expiresAt,
  });
}

class FormFieldSpec {
  final String key;
  final String label;
  final String type;
  final bool required;
  final int? maxLength;
  String currentValue;

  FormFieldSpec({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.maxLength,
    required this.currentValue,
  });
}
```

### 4.2. Giao diện Người dùng: `ActionProposalCard`
* **Vị trí hiển thị:** Xuất hiện ngay bên dưới bong bóng tin nhắn của Chatbot khi có `message.proposal != null`.
* **Khối thông tin cố định (Read-Only):**
  - Tên sân & Cụm sân (`venueName`, `courtName`).
  - Ngày chơi (`date`).
  - Giá tiền dự kiến (`price` format tiền tệ VND).
* **Khối thông tin chỉnh sửa (Editable Allowlist):**
  - Khung giờ chơi (Text input hoặc dropdown).
  - Ô nhập ghi chú cho chủ sân (TextField với bộ đếm ký tự 0/200).
* **Khối hành động:**
  - Nút **"Hủy"**: Gọi API cancel, chuyển trạng thái card thành mờ xám ("Đã hủy đề xuất").
  - Nút **"Xác nhận đặt sân"**: Hiện loading spinner, gửi API execute. Khi thành công, card chuyển sang trạng thái xanh lá với biểu tượng checkmark ("✅ Đã đặt sân thành công").

---

## 5. Xử lý Lỗi & Phòng ngừa Rủi ro (Edge Cases & Resilience)

| Kịch bản | Cách hệ thống xử lý |
| :--- | :--- |
| **Người dùng cố tình thử Jailbreak** | `guardrailIn` phát hiện và trả về cảnh báo an toàn lập tức, không tốn token LLM. |
| **Đề xuất hết hạn (Sau 15 phút)** | Nút "Xác nhận" bị vô hiệu hóa trên app; server từ chối với mã lỗi `proposal_expired`. |
| **Trùng khung giờ trong lúc chờ duyệt** | Server kiểm tra lại tình trạng sân rảnh trước khi insert vé; nếu trùng sẽ thông báo để khách chọn giờ khác. |
| **Người dùng sửa lậu payload giá tiền** | Server bỏ qua toàn bộ giá từ client; giá được tính lại từ công thức giá gốc trong CSDL. |
| **Mất mạng khi đang gọi execute** | Flutter app hiển thị snackbar thông báo lỗi kết nối và cho phép bấm "Thử lại" mà không làm mất thông tin đã nhập trên form. |

---

## 6. Chiến lược Kiểm thử & Bảo toàn Chất lượng (Testing Strategy)

1. **Kiểm thử Backend (Vitest trong `admin-web`):**
   - `test/guardrails.test.ts`: Kiểm thử chặn 10+ mẫu câu injection tiếng Việt/tiếng Anh, kiểm thử khử PII.
   - `test/actionExecution.test.ts`: Kiểm thử tạo proposal, duyệt proposal thành công, từ chối sửa giá lậu, xử lý hết hạn proposal.
2. **Kiểm thử Frontend (Flutter Unit & Widget Tests):**
   - `test/presentation/widgets/chat/action_proposal_card_test.dart`: Kiểm thử hiển thị widget, nhập ghi chú, kích hoạt nút Hủy và Xác nhận.
   - `test/core/services/chatbot_service_hitl_test.dart`: Kiểm thử tích hợp từ nhận proposal đến duyệt vé và lưu vào `TicketStore`.
3. **Cổng kiểm thử hồi quy (Zero Regressions):**
   - 343 bài test Flutter hiện tại phải tiếp tục vượt qua 100%.
   - 84 bài test Vitest của Admin Web tiếp tục vượt qua 100%.
