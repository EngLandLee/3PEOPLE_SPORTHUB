# TÀI LIỆU BÁO CÁO GIỮA KỲ: CHATBOT AI SPORTHUB
**Môn học:** Lập trình trên thiết bị di động  
**Đồ án:** SportHub - Đặt Sân Thể Thao & Ghép Kèo AI  
**Thời lượng báo cáo:** 3 - 5 phút (Kèm Demo)

---

## 1. CÔNG NGHỆ CHÍNH ĐÃ SỬ DỤNG
- **Nền tảng:** Flutter (Dart SDK 3.x) & Node.js (Web Admin Sync Gateway).
- **Thư viện kết nối mạng:** Duy nhất `package:http` (^1.6.0) - nhẹ, không phụ thuộc SDK cồng kềnh.
- **Mô hình AI:** **Gemma 26B** trên hạ tầng **FPT Cloud AI** (Datacenter TP.HCM, phản hồi siêu nhanh < 0.4s).
- **Thanh toán & Giao diện:** `qr_flutter` (sinh mã VietQR động trực tiếp trên thẻ chat) và `intl` (định dạng tiền tệ VNĐ và thời gian thực).

---

## 2. KIẾN TRÚC 3 AGENT CỐT LÕI (PHÂN THEO VAI TRÒ)

Thay vì chatbot chỉ trả lời văn bản thông thường, hệ thống chia thành 3 Agent tương tác trực tiếp với dữ liệu ứng dụng:

```
┌─────────────────────────────────────────────────────────────┐
│                 CHATBOT HYBRID CORE ENGINE                  │
├──────────────────────────────┬──────────────────────────────┤
│ 1. Agent Đặt Sân & Dịch Vụ   │ • Tìm sân, nhận diện giờ     │
│    (Customer Booking Agent)  │ • Tính giá cao điểm          │
│                              │ • Thêm / bớt nước, thuê vợt  │
│                              │ • Sinh thẻ VietQR 1 chạm     │
├──────────────────────────────┼──────────────────────────────┤
│ 2. Agent Ghép Kèo AI         │ • Phân tích poster ảnh       │
│    (Matchmaking Agent)       │ • Trích xuất số người, phí   │
│                              │ • Đăng lên Bảng tin          │
├──────────────────────────────┼──────────────────────────────┤
│ 3. Agent Quản Trị Chủ Sân    │ • Tra cứu doanh thu hôm nay  │
│    (Owner Management Agent)  │ • Danh sách vé chờ check-in  │
│                              │ • Ma trận sân trống          │
└──────────────────────────────┴──────────────────────────────┘
```

---

## 3. CÁC TÌNH HUỐNG XỬ LÝ NỔI BẬT (ĐIỂM ĂN TIỀN VỚI GIẢNG VIÊN)
1. **Xử lý ngôn ngữ tự nhiên & Không dấu:**
   - Gõ *"dat san cau long tao dan 5 ruoi chieu"* $\rightarrow$ Bot tự hiểu tiếng Việt không dấu, bóc tách giờ 17:30, tính đúng giá ca tối.
2. **Cơ chế phòng thủ khi mất mạng (Dual-Mode):**
   - Có mạng $\rightarrow$ Gọi FPT Cloud AI trả lời tự nhiên.
   - Mất mạng $\rightarrow$ Tự động chuyển sang Local Smart Intent Engine (viết bằng Dart) phản hồi ngay trong 0.05s mà không bị văng lỗi.
3. **Tự động đổi sân khi bị trùng lịch:**
   - Nếu Sân 1 khung giờ đó đã có người cọc $\rightarrow$ Bot tự đổi sang Sân 2 còn trống và đồng bộ lại giá tiền trên thẻ.
4. **Đồng bộ thanh toán thời gian thực:**
   - Khách bấm thanh toán VietQR $\rightarrow$ Thẻ trong khung chat tự đổi sang màu xanh lá **"ĐÃ GIỮ CHỖ"** mà không cần tải lại trang.

---

## 4. KỊCH BẢN THUYẾT TRÌNH TỪNG BƯỚC (3 PHÚT)

### 🎙️ Lời nói:
> *"Kính thưa Thầy/Cô, nhóm em phát triển Chatbot SportHub theo mô hình **Trí tuệ lai (Dual-Mode)**. 
> Chatbot không chỉ trả lời text đơn thuần mà render trực tiếp thành các **Thẻ hành động Native** (Action Cards) kết nối thẳng vào database của ứng dụng.
> 
> Hệ thống gồm 3 Agent phục vụ đúng nhu cầu thực tế:
> 1. **Agent Đặt Sân:** Hiểu ngôn ngữ tự nhiên, tính giá cao điểm, cộng trừ nước uống và sinh mã VietQR.
> 2. **Agent Ghép Kèo:** Nhận diện ảnh poster để đăng bài tuyển người chơi lên Cộng đồng.
> 3. **Agent Chủ Sân:** Cho phép chủ sân tra nhanh doanh thu trong ngày và danh sách khách chuẩn bị đến check-in.
> 
> Sau đây em xin phép demo 3 trường hợp thực tế trên app ạ!"*

### 📱 Các bước thao tác Live Demo:
1. **Bước 1 (Đặt sân & Tiếng Việt không dấu):**  
   Nhập: *"dat san cau long tao dan 5 ruoi chieu"*  
   $\rightarrow$ Thẻ đặt sân hiện ra: Sân Tao Đàn, 17:30, giá 180.000đ kèm mã VietQR.
2. **Bước 2 (Thêm/Bớt dịch vụ):**  
   Nhập: *"Cho mình thêm 2 chai Pocari"* $\rightarrow$ Thẻ cập nhật tổng tiền +30.000đ.  
   Nhập: *"Bỏ bớt 1 chai Pocari ra nhé"* $\rightarrow$ Thẻ tự giảm tiền còn +15.000đ.
3. **Bước 3 (Thanh toán):**  
   Bấm nút *"Xác nhận đã thanh toán VietQR"*  
   $\rightarrow$ Thẻ chuyển sang màu xanh **"ĐÃ GIỮ CHỖ"** kèm mã vé `BK-xxxx`.
