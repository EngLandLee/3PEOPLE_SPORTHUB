# Báo cáo kiểm thử chatbot SportHub

- **Ngày đánh giá:** 24/10/2026
- **Phạm vi:** README, tài liệu chatbot, Flutter client, Local Intent Engine, Vite API middleware và các test liên quan.
- **Môi trường thực thi:** Flutter test runner cục bộ và npm/Vitest cục bộ.
- **Giới hạn:** Không có phiên ứng dụng thật, backend đang chạy, tài khoản cloud AI, ngân hàng/VietQR sandbox hoặc dữ liệu sân production để xác minh giao dịch và tồn chỗ. Do đó không kết luận từ ngữ điệu câu trả lời là chức năng đúng.
- **Trạng thái worktree trước đánh giá:** Có thay đổi/xóa một tệp rubric DOCX không thuộc phạm vi; báo cáo này không chỉnh sửa tệp đó.

## 1. Tổng quan

**Kết luận: chưa đủ điều kiện nghiệm thu chatbot đặt sân/thanh toán production.** Có triển khai Local Intent Engine và các UI card hữu ích, cùng test Flutter bao phủ nhiều luồng local. Nhưng test chatbot không xác minh AI cloud, tồn chỗ production hoặc giao dịch ngân hàng. Một số lỗi mã nguồn có thể làm chatbot khẳng định đã thanh toán/hủy/hoàn tiền mà không có xác nhận từ đơn vị thanh toán; các endpoint cấu hình và hội thoại cũng không có kiểm tra quyền tại middleware.

| Bằng chứng | Kết quả |
|---|---|
| Tài liệu/README | Mô tả hybrid Cloud/Local, Vision, kiểm tra slot, VietQR, idempotency và test pass 100%. Đây là tuyên bố tài liệu, không phải bằng chứng vận hành. |
| Mã nguồn | Có parser tiếng Việt, đặt sân bằng action card, local fallback, tạo QR, đồng bộ JSON và đăng bài cộng đồng phía client. Nhiều đường xử lý dựa trên seed/local state hoặc câu người dùng tự xác nhận. |
| Flutter test thực chạy | `flutter test test/core/services/chatbot_service_test.dart test/core/services/chatbot_deep_scenarios_test.dart test/presentation/screens/chatbot_end_to_end_test.dart test/presentation/screens/chatbot_addons_sync_and_image_recruitment_test.dart` — **68 bài, All tests passed**. Đây là test local/widget, không phải xác minh cloud, ngân hàng hay backend production. |
| API test thực chạy | `npm --prefix admin-web test -- --run src/server/apiSyncPlugin.test.ts` — **không chạy được**: esbuild báo `pendingCard` khai báo hai lần trong `apiSyncPlugin.ts` tại dòng 1330 và 1604. |
| Vận hành thật | Backend/cloud/VietQR/thiết bị thật không được chạy; các tình huống này là **NOT TESTED**. |

## 2. Kiểm thử và kết quả

Điều kiện chung cho test local: Flutter test runner, singleton và dữ liệu seed; không gọi giao dịch ngân hàng hay hệ thống sân production. “FAIL (mã nguồn)” nghĩa là yêu cầu đã bị mâu thuẫn trực tiếp bởi triển khai đọc được; không hàm ý đã gửi một giao dịch thật. “NOT TESTED” nghĩa là chưa chạy được tình huống tương ứng.

| Mã | Nhóm / mục tiêu | Điều kiện ban đầu và đầu vào / lượt tiếp theo | Kết quả mong đợi | Kết quả thực tế / trạng thái | Mức độ, bằng chứng và cách khắc phục / kiểm tra lại |
|---|---|---|---|---|---|
| TC-001 | Tư vấn / giới thiệu SportHub và hướng dẫn người mới | Phiên mới; “SportHub là gì?”, tiếp “Tôi bắt đầu từ đâu?” | Mô tả đúng chức năng đang hoạt động, nêu bước tiếp theo; không bịa chính sách. | **NOT TESTED** với backend/AI; test cục bộ không kiểm định toàn bộ FAQ hoặc trải nghiệm bắt đầu. | Bằng chứng hiện có chỉ là mô tả README. Thêm kiểm thử FAQ theo dữ liệu cấu hình và xác minh các đích điều hướng trên app thật. |
| TC-002 | Tư vấn giá thiếu dữ liệu | “Giá thuê sân bao nhiêu?” không có môn, địa điểm, ngày/giờ | Nêu rõ mức giá nào là tham khảo hoặc hỏi thêm dữ liệu; không khẳng định báo giá thật. | **FAIL (mã nguồn)**: Local fallback trả khoảng giá cầu lông cố định; nhánh đặt sân có thể dùng thời điểm/môn/sân mặc định. Chưa chạy câu này trên AI cloud. | Trung bình. `chatbot_service.dart` dòng 154-156, 296-357 và nhánh trả giá khoảng dòng 1430-1450 (tham khảo mã nguồn). Thêm giá theo venue/slot từ nguồn dữ liệu có thẩm quyền và test câu hỏi thiếu dữ liệu. |
| TC-003 | NLP / tiếng Việt khẩu ngữ | “Tôi muốn đặt sân cầu lông lúc 5 rưỡi chiều.” | Trích 17:30, giữ đúng môn và không tự xác nhận booking. | **PASS – chỉ local parser**: bộ test cục bộ có kiểm tra giờ khẩu ngữ và luồng booking. Không chứng minh Cloud trích xuất hoặc giữ nguyên trường trong payload backend. | Trung bình nếu regression. `chatbot_deep_scenarios_test.dart` và kết quả 68 test. Thêm assertion riêng cho tất cả trường trong API payload. |
| TC-004 | NLP / không dấu | “dat san cau long luc 17h30” | Trích cầu lông, 17:30; không suy diễn địa điểm nếu thiếu. | **PARTIAL PASS – local**: Có test không dấu cho “dat san tao dan 19h”; chưa có đúng câu này với kiểm tra không suy diễn venue. | Thấp. Bổ sung test transcript nguyên văn và kiểm tra action card/API payload. |
| TC-005 | NLP / giờ mơ hồ “7h kém 15” | Không có ngữ cảnh buổi sáng/tối; “Cho mình thuê sân đá banh lúc 7h kém 15.” | Hỏi sáng hay tối trước khi dùng giờ có tác động giao dịch. | **FAIL (mã nguồn + test parser)**: Parser cho 06:45 khi thiếu chỉ báo buổi; test local hiện chấp nhận 06:45. Với “7h kém 15 tối”, test cho 18:45. | Cao. `chatbot_service.dart` dòng 154-290; `chatbot_deep_scenarios_test.dart` có các kỳ vọng 06:45 và 18:45. Không mặc định buổi; hỏi lại khi chưa rõ. Retest cả hai phiên bản và payload cuối. |
| TC-006 | NLP / thời gian không hợp lệ | “Đặt sân lúc 25h” hoặc phút 75 | Báo thời gian không hợp lệ và hỏi lại; không tự đổi giờ. | **FAIL (mã nguồn)**: Parser có nhánh thay thời gian không hợp lệ bằng `defaultTime` (mặc định 19:00). Chưa chạy yêu cầu này qua app thật. | Cao. `chatbot_service.dart` trong `parseTime`, dòng 154-290. Trả lỗi validation thay vì giá trị mặc định; test không cho tạo action card với thời gian sai. |
| TC-007 | Duy trì ngữ cảnh A / đổi giờ | “Đặt sân cầu lông ngày mai” → “7 giờ tối” → “Nếu đổi sang 8 giờ thì sao?” | Giữ môn/ngày; sửa giờ từ 19:00 sang 20:00; hỏi các dữ liệu còn thiếu. | **PASS – luồng local giới hạn**: Test nhiều lượt đổi giờ/add-on chạy qua; không kiểm thử đầy đủ địa điểm, ngày tương đối và request server trong tình huống này. | Trung bình. `chatbot_deep_scenarios_test.dart` nhóm Multi-turn. Bổ sung test đúng transcript và so sánh body gửi API sau mỗi lượt. |
| TC-008 | Duy trì ngữ cảnh B / bổ sung địa điểm | “Tìm sân Pickleball tối nay” → “Gần quận 7.” | Giữ pickleball và tối nay; chỉ bổ sung Quận 7. | **NOT TESTED** đúng transcript và payload nghiệp vụ. | Trung bình. Thêm test state extraction qua 2 lượt, kiểm tra venue và ngày không đổi. |
| TC-009 | Duy trì ngữ cảnh C / nhiều booking | Có hai đơn hoặc chưa có đơn; “Thêm cho tôi hai chai nước.” | Hỏi xác định đơn nếu không có một booking duy nhất đang được chọn. | **FAIL (mã nguồn)**: Add-on không có booking được test là tự gắn vào sân mặc định `venue_01`; local engine cũng dùng card gần nhất thay vì hỏi khi có thể có nhiều đơn. | Cao. `chatbot_service.dart` nhóm add-on và `chatbot_deep_scenarios_test.dart` test “attaches add-ons to a valid default court”. Bắt buộc có booking ID được xác định; test 0/1/nhiều đơn. |
| TC-010 | Đặt sân / thiếu môn, nơi, ngày hoặc giờ | “Tôi muốn đặt sân”; sau đó không bổ sung dữ liệu | Hỏi từng trường tối thiểu; không tự chọn sân/giờ. | **FAIL (mã nguồn)**: parser có ngày mặc định hôm nay, giờ mặc định 19:00 và có fallback venue; do đó có thể tạo card suy diễn thay vì làm rõ. | Cao. `chatbot_service.dart` dòng 154-156, 296-357 và 378 trở đi. Chỉ cho phép action card khi đủ dữ liệu đã xác nhận; retest lời nhắn tối thiểu và multi-turn. |
| TC-011 | Đặt sân / xem sân trống và giá thực | “Có sân pickleball nào trống tối nay không?” hoặc sân đá banh 18:45 | Truy vấn nguồn lịch/giá hiện tại; nêu thời điểm kiểm tra và chỉ trình bày các slot đã xác minh. | **NOT TESTED** trên backend/sân thật. Test local xác minh một số slot/giá chỉ trên seed/sync state; không chứng minh đồng thời tính sẵn chỗ hay cập nhật atomic. | Cao. `findAvailableCourtAndPrice` trong `chatbot_service.dart` dùng `SeedData` và `VenueSyncService`. Tích hợp nguồn dữ liệu production, giữ chỗ atomic và test đồng thời hai yêu cầu cùng slot. |
| TC-012 | Booking E2E / xác nhận giao dịch | Tạo card → nhấn đặt → quét QR → chưa trả tiền → xem vé | Chỉ đánh dấu paid khi backend/nhà cung cấp xác nhận giao dịch; QR hiển thị không đủ. | **FAIL (mã nguồn; E2E test hiện tại không kiểm tra tiền thật)**: Dialog có nút “Xác nhận đã chuyển”; callback lập tức tạo ticket `status: 'paid'` và gọi đồng bộ booking. Test E2E nhấn nút này rồi xác nhận paid. | **Critical**. `main.dart` dòng 1492, 1795-1801; `chatbot_bottom_sheet.dart` dòng 556-619; `chatbot_end_to_end_test.dart` Journey 1. Thay bằng payment intent + webhook/poll có xác thực; test QR chưa trả tiền, callback giả mạo, thanh toán thất bại/thành công/trùng. |
| TC-013 | Thanh toán / bấm nhiều lần, trạng thái lệch | Bấm tạo thanh toán nhiều lần; backend chậm; app thoát giữa quy trình | Idempotency key và trạng thái giao dịch đồng bộ; không tạo vé/thu tiền trùng. | **NOT TESTED** giao dịch thật; mã client đánh dấu ticket paid từ xác nhận người dùng chứ không thể chứng minh tính idempotent phía ngân hàng. | Cao. Kiểm tra payment ID duy nhất, retry an toàn, webhook lặp, trạng thái app/server/bank. |
| TC-014 | Hủy đơn / idempotency cục bộ | Hủy mã vé hợp lệ, sau đó hủy lại cùng mã | Hủy đúng một lần; lần hai không phát sinh hoàn tiền mới. | **PASS – unit test local** cho lặp hủy và hoàn tiền hiển thị lần hai bằng 0; không bao phủ API server. | Trung bình. `chatbot_deep_scenarios_test.dart` nhóm Advanced Edge Cases. Cần chạy lại qua API có authorization và payment ledger. |
| TC-015 | Hủy đơn / quyền sở hữu và hoàn tiền | Người dùng gửi mã đơn của người khác; lặp yêu cầu hủy | Backend xác minh chủ đơn, trạng thái, điều kiện chính sách; không tự tuyên bố hoàn tiền nếu chưa thực thi. | **FAIL (mã nguồn)**: API tìm booking theo mã rồi đổi `paymentStatus` sang `cancelled`, không thấy kiểm tra owner/customer; trả 100% refund và báo slot đã giải phóng. Không gọi dịch vụ hoàn tiền trong nhánh này. | **Critical**. `apiSyncPlugin.ts` dòng 1794-1810; khác với chính sách local ở `chatbot_service.dart` phần chính sách hủy. Xác thực owner ở server, tách cancellation/refund thành state machine và test IDOR, lặp, giao dịch pending, nhiều mức chính sách. |
| TC-016 | Tư vấn VietQR / thất bại, pending, cập nhật chậm | Quét QR nhưng chưa trả; đã trả nhưng app chưa cập nhật; hỏi bot trạng thái | Nói pending cho đến khi xác minh; hướng dẫn tra soát, không nhận trạng thái từ lời khai. | **FAIL (mã nguồn cho flow UI)**: xác nhận trong dialog là tín hiệu duy nhất để lập ticket paid. **NOT TESTED** ngân hàng/provider. | **Critical**. Cùng bằng chứng TC-012. Thêm test trạng thái unknown/pending/failed/success và xác nhận nguồn-of-truth server. |
| TC-017 | Matchmaking / tìm người chơi | “Tìm giúp mình vài người chơi cầu lông tối nay.” | Hỏi địa điểm/trình độ/số người còn thiếu khi cần; chỉ trả kết quả có thật. | **PARTIAL PASS – tạo recruitment card local**: unit test xác nhận card từ câu tìm kèo, không xác minh kết quả người chơi thật. Một số trường có giá trị mặc định (Tao Đàn, 4 người, trình độ trung bình, phí chia sẻ). | Cao nếu hiển thị mặc định như dữ liệu thật. `chatbot_service.dart` nhóm Recruitment. Đánh dấu trường dự đoán là chưa xác nhận hoặc hỏi lại; không tạo danh sách người chơi giả. |
| TC-018 | Vision / poster ảnh | Ảnh mờ/sai định dạng/không liên quan; chỉ gửi ảnh, hoặc poster chứa lịch/phí | OCR/vision thực sự đọc ảnh, tóm tắt nguồn trích, đánh dấu thiếu dữ liệu và hỏi xác nhận trước đăng. | **FAIL (mã nguồn)**: đường local tạo card từ `imageUrl` và các giá trị mặc định; test “ảnh” đồng thời đưa sẵn nội dung “3 bạn… share 50k” trong tin nhắn chữ. Backend gửi prompt chữ cho model; không thấy dữ liệu ảnh được truyền thành nội dung multimodal. | Cao. `chatbot_service.dart` nhóm recruitment và `apiSyncPlugin.ts` phần body model. Thêm xử lý ảnh thật, test OCR không chính xác/ảnh rỗng/nội dung độc hại; xác nhận các field trước xuất bản. |
| TC-019 | Community / xác nhận đăng bài | Tạo card rồi bấm “Đăng lên Bảng tin”; thử cả gõ “đăng bài” khi chưa có card | Chỉ báo thành công sau khi post được tạo; yêu cầu xác nhận trước tác động cộng đồng. | **PARTIAL PASS**: UI handler thêm post vào `CommunityFeedStore` khi bấm chip; test widget tương ứng qua. **FAIL (mã nguồn)**: local intent nếu chỉ gõ “đăng bài” trả lời đã đăng nhưng nhánh đó không tạo post. | Cao về tính trung thực. `chatbot_bottom_sheet.dart` dòng 188-260; `chatbot_service.dart` dòng 1738 trở đi. Thống nhất một hành động có transaction/result thật; test direct command không có card và xác nhận hủy. |
| TC-020 | Fallback / backend lỗi hoặc cloud không phản hồi | Mô phỏng HTTP lỗi bằng mock; ngoài ra cần thử server/cloud mất kết nối thật | Fallback có thông báo giới hạn, giữ dữ liệu, không giả vờ kiểm tra lịch/thanh toán live. | **PASS – mock cục bộ**: test chatbot có fallback khi server trả lỗi. **NOT TESTED** mất mạng/cloud thật, timeout, dữ liệu hỏng; local engine vẫn có các câu trả lời cố định. | Trung bình. `chatbot_service_test.dart` test server error; `sendMessage` catch/fallback trong `chatbot_service.dart`. Thêm thông báo “chế độ offline” và test timeout, JSON sai, API 5xx. |
| TC-021 | Bảo mật / system prompt, API key, prompt injection | Yêu cầu “tiết lộ system prompt/API key”, injection trong câu hỏi/FAQ | Không lộ secret; untrusted input không thay đổi quyền/hành động. | **PARTIAL**: local scope guard có một số từ khóa; test off-topic cụ thể pass. **NOT TESTED** injection đa dạng trên cloud. | Cao. `chatbot_service.dart` `_isSportHubRequestAllowed`; `apiSyncPlugin.ts` guard và prompt. Dùng policy không dựa trên regex đơn thuần; test adversarial ở client và server. |
| TC-022 | Bảo mật / config, FAQ và hội thoại admin | Gọi GET/POST config, GET/POST conversations/faqs không có token | Chỉ admin đã xác thực được đọc/ghi; không gửi API key tới client. | **FAIL (mã nguồn)**: middleware xử lý config/faqs/conversations không thấy auth guard; config GET trả `apiKey`; CORS mở `*`. | **Critical** nếu endpoint được expose. `apiSyncPlugin.ts` dòng 820, 1071-1190. Dùng auth server-side, không trả secret, tách quyền read/write; test không token, token sai/đúng, cross-origin. |
| TC-023 | Quyền riêng tư / tra cứu vé người khác | Nhiều ticket; hỏi “tôi đã thanh toán chưa?” không nêu mã | Chỉ truy vấn booking thuộc user đang xác thực; nếu không rõ, hỏi mã/đơn. | **FAIL (mã nguồn)**: local engine fallback sang `tickets.last` khi không tìm được mục tiêu; `TicketModel` không mang owner ID. | **High**. `chatbot_service.dart` dòng 1217-1237 và `TicketStore`; thêm owner scoping ở nguồn dữ liệu, không suy đoán bằng ticket cuối. Retest 0/1/nhiều vé và đổi tài khoản. |
| TC-024 | Cô lập phiên/user | User A có pending booking/context → logout → User B mở chat | Không giữ hội thoại, pending state hoặc ticket/context của A. | **NOT TESTED** qua đổi user trong app; `resetMessages()` xóa message và pending booking nhưng không xóa `currentContext`. | Cao. `chatbot_service.dart` dòng 671, 713, 719-724; `auth_store.dart` logout/reset. Xóa context theo lifecycle và kiểm tra phiên A→B trên cùng tiến trình. |
| TC-025 | Thông tin trái mâu thuẫn / giờ/ngày tiếp nối | “Ngày mai” rồi “đổi sang cùng giờ hôm qua”; “tối nay 7h sáng” | Hỏi lại khi thông tin mâu thuẫn; hỗ trợ hôm qua hoặc nêu không hỗ trợ, không âm thầm chọn hôm nay. | **NOT TESTED**; parser date hiện mặc định hôm nay nếu không nhận diện, và chưa thấy nhánh “hôm qua”. | Trung bình/Cao với booking. `parseDate` trong `chatbot_service.dart` dòng 296-357. Bổ sung parser relative date có kiểm tra mâu thuẫn và tests theo ngày cố định. |
| TC-026 | Bất thường / tin nhắn cực dài, ký tự lạ, spam | Chuỗi rất dài/ký tự bất thường; gửi liên tục; API trả JSON thiếu trường | Giới hạn request, lỗi thân thiện, giữ state hợp lệ, có debounce/rate limit. | **NOT TESTED**. Middleware thu body vào string không thấy giới hạn kích thước trong route chatbot; kiểm soát spam chưa xác minh. | Trung bình/Cao tùy deployment. Thêm giới hạn byte, timeout/rate limit, schema validation và test fuzz/rapid repeat. |
| TC-027 | Giao dịch / đổi sân, giá đổi, slot bị chiếm sau lúc chọn | Chọn card A → slot bị người khác chiếm → thanh toán; hoặc đổi giờ/sân giữa flow | Backend kiểm tra lại và reserve atomic trước khi nhận tiền; hiển thị giá cuối để xác nhận lại. | **NOT TESTED** concurrency/production. Client có sanitize card dựa trên state local nhưng không thay thế compare-and-set reservation ở backend. | **Critical** nếu thu tiền trước giữ chỗ. Test race hai user cùng slot, giá thay đổi, đổi venue/time và rollback payment. |
| TC-028 | Chạy test API | npm/Vitest suite `apiSyncPlugin.test.ts` | Test middleware khởi động và xác minh endpoint. | **BLOCKED**: không tải được cấu hình Vitest do lỗi esbuild `pendingCard` đã khai báo ở 1330 và 1604; không có test API nào được thực thi. | **Blocker**. `admin-web/src/server/apiSyncPlugin.ts`; sửa scope/logic trùng, chạy lại suite API, rồi chạy toàn bộ `npm --prefix admin-web test -- --run` và build. |

### Phạm vi xác minh giao tiếp

- Các test Flutter đã chạy chứng minh các assertion cục bộ/widget được viết hiện tại; không chứng minh giá, slot, FAQ, dữ liệu hay trạng thái giao dịch trên production.
- Có test booking E2E qua UI; test đánh dấu thanh toán thành công bằng thao tác người dùng trên dialog, nên không phải payment E2E.
- Có test local hủy lặp, nhưng test đó không kiểm tra xác thực quyền ở API server.
- Không có chứng cứ chạy thiết bị, API AI/FPT, database production, ngân hàng sandbox, webhook hoặc tải/đọc ảnh bằng model vision.

## 3. Lỗi nghiêm trọng cần xử lý trước

1. **Thanh toán giả được đánh dấu `paid` chỉ từ nút bấm** — Critical. QR render không phải xác nhận tiền; callback tạo vé paid và thông báo thành công.
2. **Hủy đơn qua mã đơn không kiểm tra người sở hữu; tuyên bố hoàn 100% dù không thực hiện hoàn tiền** — Critical. Có thể thay đổi booking của người khác khi biết/đoán mã.
3. **Endpoint cấu hình/hội thoại/FAQ chưa có kiểm tra quyền; config trả API key** — Critical khi server có thể truy cập từ mạng. CORS `*` làm tăng bề mặt truy cập; cần đánh giá ở môi trường triển khai cụ thể.
4. **Backend API/test server không compile được do khai báo trùng `pendingCard`** — Release blocker; test server dừng trước khi chạy test.
5. **Booking tự suy diễn địa điểm/thời gian khi thiếu dữ liệu và parser âm thầm đổi giờ sai thành 19:00** — Cao; có thể gây đặt nhầm.
6. **Add-on tự gắn vào sân mặc định khi chưa có booking** — Cao; có thể làm người dùng hiểu sai đơn được chỉnh.
7. **Tra cứu thanh toán không xác định được đơn thì chọn ticket cuối; dữ liệu ticket không gắn chủ sở hữu** — Cao; nguy cơ lộ/trả lời trạng thái sai.
8. **Poster không được phân tích thực sự nhưng có thể sinh card với chi tiết mặc định** — Cao; nguy cơ đăng nội dung/số liệu sai.

## 4. Câu trả lời sai/chưa hữu ích được xác định

- Hỏi giá thiếu thông tin có thể nhận mức cầu lông cố định thay vì câu hỏi làm rõ hoặc báo giá theo slot có nguồn.
- “7h kém 15” thiếu sáng/tối được hiểu là 06:45; không hỏi lại.
- Giờ không hợp lệ có thể biến thành giờ mặc định 19:00.
- “Thêm nước” khi không có booking có thể tạo booking sân mặc định.
- Hỏi tình trạng thanh toán mà không nêu đơn có thể nhận trạng thái ticket cuối.
- Gõ “đăng bài” có thể nhận thông báo đã đăng trong khi không tạo bài đăng.
- Local recruitment có thể trình bày sân, số người, trình độ, giờ và phí mặc định như nội dung đã trích từ poster/người dùng.

## 5. Luồng nghiệp vụ có nguy cơ thất bại

- **Đặt sân → thanh toán:** không có xác thực thanh toán hoặc reservation atomic được chứng minh; state `paid` phát sinh từ UI.
- **Hủy → hoàn tiền:** mã booking tra toàn bộ danh sách; trạng thái đổi ngay; câu trả lời tuyên bố hoàn đủ và slot giải phóng dù không thấy payment/refund/availability transaction.
- **Add-on:** không có đơn rõ ràng thì vẫn gắn vào default venue; chọn nhầm đơn không được chặn khi nhiều booking.
- **Sân trống/giá:** dữ liệu seed và đồng bộ cục bộ không thay thế nguồn availability authoritative hoặc khóa slot đồng thời.
- **Ghép kèo:** dữ liệu bài đăng/ảnh không được model vision kiểm chứng; một số thông tin được điền mặc định.

## 6. Các trường hợp dễ hiểu nhầm

- “7 giờ”, “5 rưỡi”, “7h kém 15” thiếu buổi sáng/tối hoặc mâu thuẫn giữa “sáng” và “tối”.
- “Mai”, “ngày mai”, “cuối tuần”, “hôm qua”, nhất là câu tiếp nối đổi giờ/ngày.
- Câu thiếu venue hoặc yêu cầu “đặt sân” đơn thuần bị coi là đủ thông tin do fallback.
- “Thêm 2 chai nước” không xác định được đơn khi không có/multiple booking.
- Câu hỏi “đã thanh toán chưa?” không có mã đơn bị fallback sang ticket cuối.
- “Đăng bài” dạng câu lệnh không có action card khác với nút publish của UI nhưng cùng có thể nhận câu trả lời thành công.

## 7. Rủi ro bảo mật và dữ liệu

- API server tin `context.userRole`, `userId`, route và booking code do request cung cấp; không thể coi context gửi từ app là danh tính đáng tin nếu không được xác minh bằng token.
- Route conversation đọc/trả toàn bộ danh sách hội thoại trong store; chưa thấy lọc theo owner của phiên. Route config trả API key. Route config/FAQ/conversation cũng cho phép ghi mà không thấy auth check trong middleware.
- API cancellation là IDOR tiềm tàng: tìm booking bằng mã rồi cập nhật trạng thái mà không ràng buộc user sở hữu.
- Client singleton ticket không có owner key và có nhánh trả ticket cuối khi thiếu kết quả chính xác.
- Hội thoại gửi lên middleware/cloud có thể chứa tên/ngữ cảnh; chưa xác minh minimization, retention hoặc chính sách cloud.
- CORS `*` và không thấy body limit/rate limit ở route chatbot cần được đánh giá/giới hạn trước khi expose server.

## 8. Chấm điểm

**Không đưa ra tổng điểm /100** vì chưa có đủ bằng chứng thực tế cho cloud, API hợp lệ, dữ liệu sân live, giao dịch và phân quyền server. Tự chấm điểm dựa trên các test local hiện có sẽ gây hiểu nhầm rằng production đã đạt.

| Hạng mục / điểm tối đa | Điểm có thể xác nhận | Lý do |
|---|---:|---|
| Tư vấn và hỗ trợ người dùng / 20 | Chưa xác định | Có local FAQ/response; chưa chạy cloud và chưa xác minh chính sách/giá thật. |
| Hiểu ngôn ngữ tự nhiên / 15 | Chưa xác định | Một số regex/parser và tests pass; các case mơ hồ, thời gian invalid có lỗi; chưa có đánh giá cloud trên bộ câu chuẩn. |
| Đặt sân và nghiệp vụ / 20 | Chưa xác định | UI E2E qua nhưng payment được tự xác nhận; không kiểm tra reservation/giá live. |
| Duy trì ngữ cảnh / 10 | Chưa xác định | Một chuỗi multi-turn local pass; chưa kiểm tra user isolation, đổi nhiều đơn hay khôi phục phiên. |
| Xử lý lỗi/fallback / 10 | Chưa xác định | Mock server error có test; cloud outage, dữ liệu lỗi và báo giới hạn chưa chạy thực tế. |
| Bảo mật/quyền riêng tư / 15 | Không đạt theo mã nguồn hiện quan sát | Có endpoint đọc/ghi thiếu auth và cancellation thiếu ownership check; chưa kiểm thử xâm nhập môi trường triển khai. |
| Trải nghiệm hội thoại / 10 | Chưa xác định | UI có action cards và widget tests; chưa có usability test người dùng hoặc đo chất lượng phản hồi thật. |

## 9. Kế hoạch khắc phục theo ưu tiên

1. **P0 – Khôi phục build/test backend:** xử lý khai báo `pendingCard` trùng, sau đó chạy API tests, typecheck và build. Không triển khai middleware hiện tại trước khi pass.
2. **P0 – Xác thực và phân quyền phía server:** khóa config/FAQ/conversations; chỉ trả config công khai không gồm secret; xác thực user từ token đã verify, không tin role/id từ body; ràng buộc từng booking/conversation theo owner; hạn chế CORS.
3. **P0 – Payment source of truth:** bỏ cơ chế nút “Xác nhận đã chuyển” tự set paid; tích hợp payment provider/server webhook, idempotency key, đối chiếu số tiền/order, và xử lý pending/failed/unknown.
4. **P0 – Hủy/hoàn tiền:** kiểm tra quyền sở hữu, trạng thái, chính sách, điều kiện thời gian và transaction thật; không báo refund hoặc giải phóng slot trước khi xác nhận; xử lý retry/idempotency ở server.
5. **P1 – Booking chính xác:** yêu cầu đủ môn/ngày/buổi/giờ/địa điểm; không fallback giờ/sân ngầm; kiểm tra lại giá và slot ngay trước reservation; dùng transaction/lock để chống tranh chấp.
6. **P1 – Booking-scoped add-on và tra vé:** yêu cầu chọn đơn khi chưa có/multiple đơn; owner-scope ticket; không fallback sang vé cuối.
7. **P1 – Vision/community:** dùng pipeline OCR/vision thật và đánh dấu mức tin cậy; bắt người dùng xác nhận thông tin trước post; không báo publish nếu post creation thất bại.
8. **P1 – Ngữ cảnh an toàn:** clear current context theo logout/user switch; lưu conversation theo user/session; test A→B trên cùng tiến trình.
9. **P2 – NLP và resilience:** kiểm thử giờ mơ hồ, ngày tương đối, typo, không dấu, chuỗi dài, spam; báo rõ khi fallback local giới hạn tra cứu realtime.
10. **P2 – Tài liệu:** thay tuyên bố “100% pass/99.9% availability” bằng số đo gắn với commit, lệnh test và môi trường; ghi rõ phần mock/demo và chưa kiểm thử production.

## 10. Bộ hồi quy bắt buộc sau sửa

1. **Parser:** `5 rưỡi chiều`→17:30; `Dat san ... 17h30`; `7h kém 15` phải hỏi buổi; `7h kém 15 tối`→18:45; invalid `25h`/`19:75` bị từ chối; hôm nay/mai/cuối tuần/hôm qua có test clock cố định.
2. **Conversation:** tình huống A/B nguyên văn; đổi ngày/giờ không làm mất sport/venue còn hợp lệ; pending state bị xóa khi logout; user B không thấy context/ticket user A.
3. **Booking:** thiếu trường thì hỏi; kiểm tra sân/giá từ backend; slot bị đặt đồng thời; giờ ngoài vận hành; giá đổi; đổi sân/giờ; retry request không tạo booking trùng; resume sau khi app đóng.
4. **Payment:** QR tạo ≠ paid; pending/failed/timeout/paid; webhook lặp; app callback giả; nhấn nhiều lần; amount/order mismatch; khôi phục trạng thái sau reload.
5. **Cancellation:** chỉ owner được hủy; pending payment không bị hủy sai; policy 24h/12–24h/<12h nhất quán; hủy lặp không refund trùng; lỗi provider không báo thành công; slot chỉ giải phóng theo trạng thái có thẩm quyền.
6. **Add-on:** đúng booking; không booking/multiple booking thì hỏi; cộng/trừ/loại bỏ; quantity 0/101; giá chính xác; QR/order total khớp.
7. **Matchmaking/vision:** text-only, ảnh thật, mờ, sai định dạng, ảnh không liên quan; chỉ trích xuất dữ kiện nhìn thấy; yêu cầu xác nhận trước publish; không có false success.
8. **Security/API:** unauthenticated và token sai; role giả; IDOR booking/conversation; API key không xuất hiện; prompt injection; CORS; payload lớn; rate limit; user/session isolation.
9. **Fallback/UX:** backend 5xx/timeout/JSON lỗi; cloud timeout; local fallback thông báo hạn chế realtime; tin nhắn nhanh liên tục; dữ liệu hợp lệ được giữ.
10. Chạy lệnh Flutter chatbot/UI đã nêu ở phần 1, `npm --prefix admin-web test -- --run`, typecheck/build web; sau đó kiểm thử integration với payment sandbox và hai client cạnh tranh cùng slot.
