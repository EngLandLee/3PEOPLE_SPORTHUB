# 🏆 KỊCH BẢN THUYẾT TRÌNH & LIVE DEMO CUỐI KỲ (4 THÀNH VIÊN)
**Đồ án môn học:** Lập trình trên thiết bị di động (Mobile App Development - CMP177)  
**Tên dự án:** SportHub - Ứng Dụng Đặt Sân Thể Thao & Ghép Kèo AI  
**Thời lượng khuyến nghị:** 10 - 12 phút (Đảm bảo 100% thành viên đều có phần nói và thao tác demo)  
**Phiên bản:** v1.0.0 (Bảo vệ Cuối kỳ)

---

## 📋 MỤC LỤC
1. [BƯỚC 0: CHECKLIST CHUẨN BỊ MÔI TRƯỜNG TRƯỚC GIỜ G](#bước-0-checklist-chuẩn-bị-môi-trường-trước-giờ-g)
2. [BẢNG PHÂN BỔ THỜI GIAN & VAI TRÒ 4 THÀNH VIÊN](#bảng-phân-bổ-thời-gian--vai-trò-4-thành-viên)
3. [KỊCH BẢN CHI TIẾT TỪNG THÀNH VIÊN (LỜI THOẠI & DEMO)](#kịch-bản-chi-tiết-từng-thành-viên-lời-thoại--demo)
   - [👤 Bạn 1: Tổng quan Đồ án, Bài toán & Kiến trúc Hệ thống](#-bạn-1-tổng-quan-đồ-án-bài-toán--kiến-trúc-hệ-thống)
   - [👤 Bạn 2: Giao diện UI/UX Mobile, Ma trận Giờ & Thanh toán VietQR](#-bạn-2-giao-diện-uiux-mobile-ma-trận-giờ--thanh-toán-vietqr)
   - [👤 Bạn 3: Bảng tin Ghép kèo Cộng đồng & Phân hệ Quản trị Chủ sân](#-bạn-3-bảng-tin-ghép-kèo-cộng-đồng--phân-hệ-quản-trị-chủ-sân)
   - [👤 Bạn 4: Trợ lý ảo AI Chatbot Đa kênh, Bảo mật & Kết luận](#-bạn-4-trợ-lý-ảo-ai-chatbot-đa-kênh-bảo-mật--kết-luận)
4. [BỘ CÂU HỎI PHẢN BIỆN CỦA HỘI ĐỒNG (Q&A DEFENSE)](#bộ-câu-hỏi-phản-biện-của-hội-đồng-qa-defense)
5. [KẾ HOẠCH DỰ PHÒNG XỬ LÝ SỰ CỐ TẠI HỘI TRƯỜNG](#kế-hoạch-dự-phòng-xử-lý-sự-cố-tại-hội-trường)

---

## 🛠️ BƯỚC 0: CHECKLIST CHUẨN BỊ MÔI TRƯỜNG TRƯỚC GIỜ G

Trước khi bước lên bục thuyết trình 5 phút, Bạn 1 chuẩn bị máy tính trình chiếu:

### 1. Khởi động các tiến trình (Mở 2 Terminal)
```bash
# Terminal 1: Khởi động Backend Web Admin & API Sync Gateway
cd admin-web
npm run dev
# -> Kiểm tra: Server sẵn sàng tại http://localhost:5173

# Terminal 2: Chạy ứng dụng Flutter Mobile (Chạy trên Chrome để máy chiếu hiển thị sắc nét nhất)
flutter run -d chrome
```

### 2. Tab trình duyệt cần mở sẵn trên màn hình
* **Cửa sổ 1:** Tab ứng dụng Flutter Mobile (`http://localhost:XXXXX`).
* **Cửa sổ 2:** Tab Web Admin Portal (`http://localhost:5173`).
* **Cửa sổ 3:** Slide thuyết trình PowerPoint / Canva / PDF.

---

## 👥 BẢNG PHÂN BỔ THỜI GIAN & VAI TRÒ 4 THÀNH VIÊN

| STT | Thành viên | Vai trò & Chủ đề | Thao tác Live Demo thực tế | Thời lượng |
| :---: | :--- | :--- | :--- | :---: |
| **1** | **Bạn 1 (Trưởng nhóm)** | **Đặt vấn đề & Kiến trúc Công nghệ** | Trình chiếu slide kiến trúc, show kết quả chạy Unit Test tự động (100% Pass). | 2.5 phút |
| **2** | **Bạn 2** | **UI/UX Mobile & Luồng Đặt sân trực quan** | Thao tác trên app Flutter: Đổi Theme, lọc sân, chọn slot ma trận, chọn Add-on, thanh toán VietQR, mở tab Vé Offline. | 3.0 phút |
| **3** | **Bạn 3** | **Cộng đồng Ghép kèo & Phân hệ Chủ sân** | Tạo bài đăng ghép kèo, chuyển Role Chủ sân (doanh thu, quét vé QR), đối soát thời gian thực trên Web Admin. | 3.0 phút |
| **4** | **Bạn 4** | **Trí tuệ Nhân tạo AI Chatbot & Kết luận** | Mở Chatbot: Đặt sân bằng khẩu ngữ tự nhiên, thêm dịch vụ qua chat, tải poster ghép kèo, test an toàn & kết luận. | 3.0 phút |

---

## 🎙️ KỊCH BẢN CHI TIẾT TỪNG THÀNH VIÊN (LỜI THOẠI & DEMO)

---

### 👤 BẠN 1: TỔNG QUAN ĐỒ ÁN, BÀI TOÁN & KIẾN TRÚC HỆ THỐNG
*(Thời lượng: ~2.5 phút | Trọng tâm: Đặt vấn đề, Tech Stack, Kiến trúc Clean Architecture, Tiêu chuẩn kỹ thuật)*

#### 💬 Lời thoại thuyết trình:
> *"Kính thưa Thầy/Cô trong Hội đồng chấm thi và các bạn sinh viên,*  
> *Em xin đại diện cho nhóm phát triển dự án **SportHub - Nền tảng Đặt sân thể thao thông minh và Ghép kèo thi đấu AI**. Nhóm chúng em gồm 4 thành viên:*
> - *Em là **[Tên Bạn 1]** - Phụ trách Kiến trúc hệ thống và Tích hợp Backend.*
> - ***[Tên Bạn 2]** - Phụ trách Giao diện UI/UX Flutter và Luồng đặt sân.*
> - ***[Tên Bạn 3]** - Phụ trách Module Cộng đồng và Phân hệ Quản trị Chủ sân.*
> - ***[Tên Bạn 4]** - Phụ trách Hệ thống Trợ lý ảo AI Chatbot Đa kênh.*
>
> *Thưa Thầy/Cô, hiện nay phong trào thể thao (Cầu lông, Pickleball, Bóng đá) tại TP.HCM đang bùng nổ, nhưng người chơi gặp phải 2 nghịch lý lớn: Một là rất khó tìm được sân trống vào khung giờ vàng (17h - 21h), hai là đặt được sân nhưng lại thiếu chân đấu hoặc bị bùng kèo phút chót. Về phía các chủ cụm sân, việc quản lý sổ sách thủ công dẫn đến tình trạng chồng chéo lịch và thất thoát doanh thu.*
>
> *Để giải quyết triệt để vấn đề này, nhóm chúng em đã xây dựng hệ sinh thái **SportHub** với các nền tảng kỹ thuật cốt lõi:*
> 1. * **Mobile Client (Flutter / Dart 3):** Tuân thủ nghiêm ngặt **Clean Architecture** (phân tầng Domain - Data - Presentation rõ ràng), kết hợp quản lý trạng thái Reactive bằng **BLoC** và **ValueNotifier** siêu nhẹ.*
> 2. * **Cơ sở dữ liệu & Đồng bộ:** Tích hợp CSDL cục bộ **SQLite** (`sporthub_local.db`) phục vụ xuất trình vé offline khi mất mạng, kết hợp cổng **Sync Gateway** đồng bộ 2 chiều thời gian thực giữa Web Admin và Mobile App.*
> 3. * **Trí tuệ Nhân tạo Đa kênh:** Mô hình **Dual-Mode Hybrid AI** chạy trên hạ tầng **FPT Cloud AI Datacenter** kết hợp cơ chế dự phòng nội bộ.*
>
> *Để đảm bảo tính ổn định tối đa cho sản phẩm, nhóm em đã thiết lập bộ kiểm thử tự động với 27 test Flutter và 81 test Web đạt tỉ lệ Pass tuyệt đối 100%.*  
> *Sau đây, em xin nhường lời cho **Bạn [Tên Bạn 2]** trình bày và demo trực tiếp trải nghiệm đặt sân trực quan trên thiết bị di động!"*

---

### 👤 BẠN 2: GIAO DIỆN UI/UX MOBILE, MA TRẬN GIỜ & THANH TOÁN VIETQR
*(Thời lượng: ~3.0 phút | Trọng tâm: Material 3, Dark/Light Mode, Visual Court Matrix, Dynamic Pricing, VietQR, SQLite Offline)*

#### 🎬 Thao tác Demo & 💬 Lời thoại song song:

* **Bước 1: Chuyển đổi giao diện & Bộ lọc thể thao**
  * **Thao tác màn hình:** Mở app Flutter. Bấm icon đổi **Dark Mode / Light Mode** trên thanh điều hướng. Tại màn hình Khám phá, bấm chọn chip môn **Pickleball**, chọn Quận **Bình Thạnh**, chọn cụm sân *"Thảo Điền Pickleball Hub"*.
  * **Lời thoại:**
    > *"Em xin chào Thầy/Cô. Như Thầy/Cô đang quan sát, SportHub được thiết kế hoàn toàn theo tiêu chuẩn **Material 3 Design**, hỗ trợ chuyển đổi mượt mà giữa Dark và Light theme để bảo vệ mắt người dùng khi chơi thể thao ban đêm. Bộ lọc đa năng cho phép tìm kiếm tức thì theo môn thể thao và khu vực địa lý."*

* **Bước 2: Ma trận khung giờ & Thuật toán tính giá linh hoạt**
  * **Thao tác màn hình:** Cuộn xuống phần **Visual Court Matrix**. Nhấp chọn Sân số 2, chọn khung giờ **19:00 - 20:00**. Đánh dấu chọn thêm 2 dịch vụ phụ: **2 chai nước bù khoáng Pocari** và **1 cặp vợt thi đấu**.
  * **Lời thoại:**
    > *"Điểm nhấn kỹ thuật quan trọng của SportHub là **Ma trận khung giờ trực quan (Visual Court Matrix)**. Giao diện trực quan hóa trạng thái từng slot: Ô xám là slot đã có người đặt, ô xanh lá là slot đang mở sẵn. Ứng dụng tích hợp thuật toán **Dynamic Tiered Pricing** tự động nhận diện khung giờ cao điểm (Peak Hours: 17h - 21h) để áp dụng bảng giá tương ứng. Khi em tick chọn thêm nước uống hay thuê vợt, hệ thống lập tức cộng dồn phụ phí vào tổng thanh toán theo thời gian thực."*

* **Bước 3: Thanh toán VietQR & CSDL Vé Offline**
  * **Thao tác màn hình:** Bấm nút **"Tiếp tục thanh toán"** -> Popup VietQR hiện ra với mã QR động và đồng hồ đếm ngược. Bấm nút giả lập *"Xác nhận đã thanh toán"* -> Chuyển sang Tab **"Vé của tôi" (My Tickets)** hiển thị chiếc vé vừa mua kèm mã QR soát vé.
  * **Lời thoại:**
    > *"SportHub tích hợp thư viện `qr_flutter` tạo mã **VietQR chuẩn NAPAS 247** với nội dung chuyển khoản động chứa mã đơn đặt sân. Ngay khi giao dịch được xác nhận, vé điện tử lập tức được tạo và lưu trữ. Nhờ cơ chế CSDL cục bộ **SQLite**, khi khách hàng đến sân thi đấu dù điện thoại có mất sóng 4G/WiFi thì mã vé QR vẫn mở lên bình thường để nhân viên quét mã vào sân.*  
    > *Tiếp theo, xin mời **Bạn [Tên Bạn 3]** trình bày về phân hệ Ghép kèo cộng đồng và Cổng quản trị dành cho Chủ sân!"*

---

### 👤 BẠN 3: BẢNG TIN GHÉP KÈO CỘNG ĐỒNG & PHÂN HỆ QUẢN TRỊ CHỦ SÂN
*(Thời lượng: ~3.0 phút | Trọng tâm: Matchmaking, Phân quyền Role Isolation, Doanh thu POS, Đồng bộ thời gian thực Web Admin)*

#### 🎬 Thao tác Demo & 💬 Lời thoại song song:

* **Bước 1: Bảng tin Ghép kèo thi đấu (Matchmaking)**
  * **Thao tác màn hình:** Chuyển sang Tab **"Cộng đồng" (Community)** trên app. Lướt qua các bài đăng tìm người chơi. Bấm nút *"Xin tham gia"* tại một bài tuyển cầu lông lúc 19h.
  * **Lời thoại:**
    > *"Kính thưa Thầy/Cô, một trong những tính năng giữ chân người dùng nhiều nhất của SportHub là **Bảng tin Ghép kèo Cộng đồng**. Người chơi có sân nhưng thiếu người có thể đăng bài tuyển thành viên, công khai trình độ thi đấu (Skill Level từ 2.0 đến 3.5) và chi phí chia đều. Người xem chỉ cần 1 chạm để gửi yêu cầu tham gia (Join Request) và người tạo bài có quyền duyệt hoặc từ chối trực tiếp trên app."*

* **Bước 2: Phân hệ Quản trị Chủ sân (Owner Management trên Mobile)**
  * **Thao tác màn hình:** Bấm chuyển sang chế độ **Chủ sân (Owner Mode)** trên thanh điều hướng dưới. Mở tab **Doanh thu (Revenue)** và tab **Soát vé (Check-in POS)**.
  * **Lời thoại:**
    > *"Bên cạnh khách chơi, SportHub hỗ trợ phân quyền tài khoản chặt chẽ (**Role Isolation**) dành riêng cho Đối tác Chủ cụm sân:*
    > - *Tab Doanh thu: Tự động tổng hợp doanh thu theo ngày, tách biệt rõ ràng giữa tiền sân đặt qua app VietQR và phụ phí thu tại quầy.*
    > - *Tab Check-in: Danh sách khách đã đặt sân hôm nay. Nhân viên chỉ cần quét mã QR trên vé của khách để chuyển trạng thái sang Đã check-in."*

* **Bước 3: Đồng bộ 2 chiều thời gian thực với Web Admin Portal**
  * **Thao tác màn hình:** Chuyển nhanh sang tab trình duyệt Web Admin `http://localhost:5173`. Chỉ vào màn hình Dashboard và Sơ đồ ma trận sân trên Web.
  * **Lời thoại:**
    > *"Đặc biệt, hệ thống sở hữu cổng **Web Admin Portal** xây dựng bằng **React 19 + TypeScript + Vite**. Toàn bộ lịch đặt, trạng thái đóng/mở sân và doanh thu được **đồng bộ hai chiều thời gian thực (Real-time Sync)** với Mobile App thông qua Sync Gateway. Khi khách đặt sân trên điện thoại, slot trên Web Admin lập tức đổi màu, đảm bảo triệt tiêu hoàn toàn rủi ro trùng lịch (Overbooking).*  
    > *Sau đây, xin mời **Bạn [Tên Bạn 4]** trình diễn tính năng đột phá nhất của dự án: Trợ lý ảo AI Chatbot Đa kênh!"*

---

### 👤 BẠN 4: TRỢ LÝ ẢO AI CHATBOT ĐA KÊNH, BẢO MẬT & KẾT LUẬN
*(Thời lượng: ~3.0 phút | Trọng tâm: Dual-Mode Hybrid AI, Action Card Protocol, Realtime Clock, Guardrails An toàn, Tổng kết & Q&A)*

#### 🎬 Thao tác Demo & 💬 Lời thoại song song:

* **Bước 1: Đặt sân qua ngôn ngữ tự nhiên (Action Card Protocol)**
  * **Thao tác màn hình:** Bấm vào nút bóng chat tròn màu xanh để mở khung chat. Gõ câu lệnh bằng tiếng Việt không dấu tự nhiên:  
    `"dat san cau long tao dan toi nay 7h toi"`  
    -> Chatbot phản hồi và hiện ngay thẻ **`ChatBookingCard`** màu sắc đẹp mắt có kèm mã VietQR và nút bấm.
  * **Lời thoại:**
    > *"Kính thưa Thầy/Cô, đây là **Trợ lý ảo SportHub AI**. Điểm cốt lõi kỹ thuật của nhóm là không làm chatbot dạng sinh text markdown đơn thuần dễ bị vỡ giao diện trên điện thoại, mà nhóm tự thiết kế giao thức **Action Card Protocol**.*  
    > *Dù người dùng nhắn tin bằng khẩu ngữ, giờ giấc tự nhiên hay không dấu như 'dat san cau long tao dan toi nay 7h toi', AI tự động bóc tách thực thể (Entity Extraction) và sinh ra một **Thẻ Đặt Sân Tương Tác Native (`ChatBookingCard`)** với đầy đủ thông tin sân, giờ chơi và mã VietQR thanh toán tức thì."*

* **Bước 2: Đối thoại đa bước thêm dịch vụ & Phân tích hình ảnh (Vision)**
  * **Thao tác màn hình:** Gõ tiếp vào ô chat:  
    `"Lay cho minh them 2 chai Pocari va 1 ong cau nhe"`  
    -> Thẻ đặt sân trên màn hình chat lập tức tự động cộng thêm phụ phí vào tổng tiền.  
    Bấm biểu tượng camera/ảnh -> Chọn ảnh poster thể thao -> Chatbot phân tích và trả về thẻ tuyển người **`RecruitmentCard`**.
  * **Lời thoại:**
    > *"Chatbot có khả năng duy trì ngữ cảnh nhiều bước (Context-Aware). Khi người dùng yêu cầu lấy thêm nước hay ống cầu, bot tự động nhận diện và cập nhật trực tiếp vào thẻ đang mở.*  
    > *Hơn thế nữa, tính năng **Multimodal Vision** cho phép người dùng chỉ cần chụp áp phích hoặc poster giải đấu, AI sẽ tự động trích xuất ngày giờ, địa điểm để tạo ngay một bài đăng ghép kèo cộng đồng."*

* **Bước 3: Cơ chế chống ảo giác thời gian & Hàng rào bảo vệ (Guardrails)**
  * **Thao tác màn hình:**  
    1. Gõ: `"Hom nay la thu may ngay bao nhieu?"` -> Bot trả lời chính xác ngày giờ thực tế hiện tại của máy tính.  
    2. Gõ: `"Viet cho toi mot bai tho tinh"` hoặc hỏi linh tinh -> Bot từ chối lịch sự và hướng dẫn quay lại chủ đề sân bãi.
  * **Lời thoại:**
    > *"Để đưa AI vào hoạt động thực tế, nhóm đã giải quyết 2 bài toán hóc búa của mô hình ngôn ngữ lớn:*
    > 1. * **Realtime Clock Context Injection:** Tự động tiêm đồng hồ thực tế của hệ thống vào System Prompt, triệt tiêu 100% hiện tượng ảo giác năm cũ của LLM.*
    > 2. * **Guardrail 2 lớp:** Ngăn chặn các câu hỏi phá hoại, từ chối các yêu cầu ngoài phạm vi thể thao và bảo vệ dữ liệu bí mật của hệ thống.*
    >
    > *Đồng thời, kiến trúc **Dual-Mode Hybrid** đảm bảo nếu mạng Cloud có sự cố, hệ thống sẽ tự động fallback sang **Local Intent Engine** viết bằng Dart thuần để phản hồi chỉ trong 50ms mà không bao giờ bị đơ ứng dụng.*
    >
    > *Tóm lại, dự án SportHub là một sản phẩm hoàn thiện từ Trải nghiệm người dùng Mobile, Kiến trúc phần mềm phân tầng, CSDL đồng bộ cho đến Trí tuệ Nhân tạo thực chiến.*  
    > *Nhóm chúng em xin chân thành cảm ơn Thầy/Cô đã chú ý lắng nghe! Chúng em rất mong nhận được những câu hỏi phản biện từ Hội đồng!"*

---

## 🎯 BỘ CÂU HỎI PHẢN BIỆN CỦA HỘI ĐỒNG (Q&A DEFENSE)

### ❓ Câu 1 (Dành cho Bạn 1): *"Tại sao trong dự án có cả SQLite (`DatabaseHelper`) lẫn file `sync_store.json`? Vai trò của từng cái là gì?"*
> **👉 Bạn 1 trả lời:**  
> *"Dạ thưa Thầy/Cô, về mặt kiến trúc phần mềm:*  
> *- **SQLite (`DatabaseHelper`):** Là CSDL cục bộ trên thiết bị di động (Android/iOS) để lưu trữ vé điện tử cá nhân (`tickets`). Vai trò là đảm bảo tính năng **Offline-First**, giúp người dùng ra sân thể thao dù mất mạng 4G/WiFi vẫn mở được mã QR soát vé.*  
> *- **Sync JSON Store (`sync_store.json`):** Là kho lưu trữ dữ liệu trung gian ở tầng Gateway để phục vụ đồng bộ dữ liệu thời gian thực giữa Web Admin của chủ sân và App di động. Ngoài ra, việc sử dụng cơ chế này giúp nhóm dễ dàng kiểm thử và demo ứng dụng mượt mà trên nền tảng Web Chrome mà không bị lỗi môi trường thư viện FFI của SQLite."*

### ❓ Câu 2 (Dành cho Bạn 2): *"Ứng dụng giải quyết bài toán tranh chấp giữ sân khi 2 người cùng bấm đặt 1 slot như thế nào (Concurrency Handling)?"*
> **👉 Bạn 2 trả lời:**  
> *"Dạ thưa Thầy/Cô, hệ thống áp dụng cơ chế **Optimistic Concurrency Control kết hợp Trạng thái Giữ chỗ Tạm thời (Hold-Lock with 5-minute Timeout)**:*  
> *Khi người dùng A nhấp chọn slot và tiến tới bước thanh toán, slot đó sẽ chuyển sang trạng thái 'Holding' (Màu vàng) kèm bộ đếm ngược 5 phút và đồng bộ lên Gateway. Lúc này, người dùng B sẽ thấy slot đó đã bận (Màu xám) và không thể bấm vào. Nếu sau 5 phút người dùng A không hoàn tất thanh toán VietQR, hệ thống sẽ tự động nhả slot về lại trạng thái trống cho người khác đặt."*

### ❓ Câu 3 (Dành cho Bạn 3): *"Làm sao đảm bảo dữ liệu giữa Web Admin của Chủ sân và Mobile App của Khách không bị lệch pha?"*
> **👉 Bạn 3 trả lời:**  
> *"Dạ thưa Thầy/Cô, nhóm xây dựng service `VenueSyncService` hoạt động theo cơ chế **Polling & Reactive Event Bus**:*  
> *Mobile App duy trì một timer đồng bộ ngầm định kỳ hoặc kích hoạt ngay khi có hành vi đặt sân/hủy vé. Phía Web Admin sử dụng Custom Vite Plugin Middleware (`apiSyncPlugin.ts`) lắng nghe và phản hồi dữ liệu tức thì. Nhờ đó, trạng thái khóa sân bảo trì từ chủ sân sẽ phản ánh lên app di động gần như ngay lập tức."*

### ❓ Câu 4 (Dành cho Bạn 4): *"Nếu máy người dùng mất kết nối Internet hoặc API Cloud AI bị nghẽn thì Chatbot có hoạt động được không?"*
> **👉 Bạn 4 trả lời:**  
> *"Dạ thưa Thầy/Cô, Chatbot vẫn hoạt động bình thường nhờ kiến trúc **Dual-Mode Hybrid Intelligence**:*  
> *Nhóm thiết lập timeout 3.5 giây cho API FPT Cloud. Nếu đường truyền mạng chập chờn hoặc API Cloud gặp sự cố, hệ thống sẽ tự động kích hoạt **Local Smart Intent Engine** được viết bằng Dart thuần chạy ngay trên máy. Engine này sử dụng bộ phân tích Regex NLP để nhận diện địa điểm, giờ chơi, các món phụ phí và sinh ra Thẻ Đặt Sân chỉ trong vòng 50ms, đảm bảo ứng dụng luôn sẵn sàng 99.9%."*

---

## 🚑 KẾ HOẠCH DỰ PHÒNG XỬ LÝ SỰ CỐ TẠI HỘI TRƯỜNG

1. **Sự cố WiFi trường học chập chờn/mất mạng:**  
   * Bật ngay Hotspot 4G/5G từ điện thoại cá nhân.
   * Do app có sẵn chế độ **Local Fallback Engine** và **Offline Ticket Store**, Chatbot và Tab Vé vẫn hoạt động bình thường kể cả khi mất hẳn Internet.
2. **Sự cố port 5173 bị chiếm dụng:**  
   * Chạy lệnh `lsof -ti:5173 | xargs kill -9` trước khi chạy `npm run dev`.
3. **Phân công hỗ trợ nhau khi quên bài:**  
   * Nếu thành viên nào bị ngập ngừng quá 5 giây, Bạn 1 (Trưởng nhóm) sẽ chủ động đỡ lời bằng câu: *"Để bổ sung thêm cho ý của bạn [Tên], em xin làm rõ thêm về mặt kỹ thuật..."*.
