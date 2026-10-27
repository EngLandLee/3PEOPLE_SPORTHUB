-- ==============================================================================
-- SPORTHUB FULL PRODUCTION SEED DATA SCRIPT FOR SUPABASE
-- Run this in Supabase SQL Editor (SQL Editor -> New Query -> Run)
-- ==============================================================================

-- 1. VENUES SEED (8 Cụm Sân Thể Thao Lớn Tại TP.HCM)
INSERT INTO public.venues (id, name, address, district, hotline, sports, open_time, close_time, base_hourly_rate, image_url, is_active, total_courts, description)
VALUES 
(
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'Số 1 Huyền Trân Công Chúa, Phường Bến Thành, Quận 1, TP. HCM',
    'Quận 1',
    '028 3822 4156',
    ARRAY['badminton', 'pickleball'],
    '06:00',
    '22:00',
    150000,
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
    true,
    8,
    'Tổ hợp thể thao trung tâm Quận 1 với 4 sân cầu lông thảm tiêu chuẩn và 4 sân Pickleball ngoài trời có mái che hiện đại.'
),
(
    'venue_bt_01',
    'CLB Cầu Lông & Pickleball Bình Thạnh Sport',
    '123 Chu Văn An, Phường 12, Quận Bình Thạnh, TP. HCM',
    'Bình Thạnh',
    '028 3511 8899',
    ARRAY['badminton', 'pickleball'],
    '06:00',
    '22:00',
    150000,
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
    true,
    6,
    'Cụm sân cầu lông và pickleball sôi động tại Bình Thạnh, thảm chuyên dụng chất lượng cao.'
),
(
    'venue_td_02',
    'Thảo Điền Pickleball Hub',
    '45 Quốc Hương, Phường Thảo Điền, TP. Thủ Đức, TP. HCM',
    'Thủ Đức',
    '0909 777 888',
    ARRAY['pickleball'],
    '06:00',
    '22:00',
    200000,
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
    true,
    8,
    'Trung tâm Pickleball tiêu chuẩn quốc tế tại Thảo Điền với 8 sân ngoài trời có mái che.'
),
(
    'venue_q7_03',
    'Sân Bóng Đá Mini Nam Sài Gòn',
    '78 Nguyễn Hữu Thọ, Phường Tân Hưng, Quận 7, TP. HCM',
    'Quận 7',
    '0918 333 777',
    ARRAY['football'],
    '06:00',
    '23:00',
    280000,
    'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800',
    true,
    4,
    'Cụm 4 sân bóng đá mini cỏ nhân tạo 5-7 người tiêu chuẩn thi đấu FIFA.'
),
(
    'venue_tb_05',
    'Khu Liên Hợp Thể Thao Tân Bình Arena',
    '448 Hoàng Văn Thụ, Phường 4, Quận Tân Bình, TP. HCM',
    'Tân Bình',
    '0903 888 999',
    ARRAY['badminton', 'football', 'pickleball'],
    '06:00',
    '22:00',
    180000,
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
    true,
    10,
    'Cụm liên hợp thể thao 10 sân đa năng, bãi đỗ ô tô lớn, căng tin thể thao hiện đại.'
),
(
    'venue_pn_06',
    'CLB Cầu Lông & Pickleball Phú Nhuận Club',
    '18A Phan Đăng Lưu, Phường 3, Quận Phú Nhuận, TP. HCM',
    'Phú Nhuận',
    '028 3995 1234',
    ARRAY['badminton', 'pickleball'],
    '06:00',
    '22:00',
    160000,
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=800',
    true,
    6,
    'Sân cầu lông & pickleball thảm PVC mới, máy lạnh, dịch vụ đan vợt lấy liền.'
),
(
    'venue_q2_07',
    'Sân Bóng Đá Cỏ Nhân Tạo An Phú - Quận 2',
    '88 Song Hành, Phường An Phú, TP. Thủ Đức, TP. HCM',
    'Thủ Đức',
    '0912 666 888',
    ARRAY['football'],
    '06:00',
    '23:00',
    270000,
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=800',
    true,
    4,
    'Sân cỏ nhân tạo kim cương, đèn LED chống chói, dịch vụ quay video trận đấu full HD.'
),
(
    'venue_q10_08',
    'Trung Tâm Thể Thao Kỳ Hòa - Quận 10',
    '796 Sư Vạn Hạnh, Phường 12, Quận 10, TP. HCM',
    'Quận 10',
    '028 3865 5678',
    ARRAY['badminton', 'pickleball'],
    '06:00',
    '22:00',
    170000,
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=800',
    true,
    8,
    'Khuôn viên thể thao râm mát trung tâm Q10, bãi đỗ ô tô miễn phí, phòng tắm nóng lạnh.'
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    sports = EXCLUDED.sports,
    base_hourly_rate = EXCLUDED.base_hourly_rate;

-- 2. COURTS SEED (Chi Tiết 48 Sân Đấu Tại Các Cụm Sân)
INSERT INTO public.courts (id, venue_id, court_number, name, sport, regular_price, peak_price, surface_type, is_active)
VALUES
-- Tao Đàn (venue_01): 4 sân cầu lông, 4 sân pickleball
('court_01_tao_dan', 'venue_01', 1, 'Sân Cầu Lông 01', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_02_tao_dan', 'venue_01', 2, 'Sân Cầu Lông 02', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_03_tao_dan', 'venue_01', 3, 'Sân Cầu Lông 03', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_04_tao_dan', 'venue_01', 4, 'Sân Cầu Lông 04', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_05_tao_dan', 'venue_01', 5, 'Sân Pickleball 05', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_06_tao_dan', 'venue_01', 6, 'Sân Pickleball 06', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_07_tao_dan', 'venue_01', 7, 'Sân Pickleball 07', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_08_tao_dan', 'venue_01', 8, 'Sân Pickleball 08', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),

-- Bình Thạnh Sport (venue_bt_01): 4 sân cầu lông, 2 sân pickleball
('court_bt_01', 'venue_bt_01', 1, 'Sân Cầu Lông BT-01', 'badminton', 130000, 170000, 'Thảm PVC Enlio', true),
('court_bt_02', 'venue_bt_01', 2, 'Sân Cầu Lông BT-02', 'badminton', 130000, 170000, 'Thảm PVC Enlio', true),
('court_bt_03', 'venue_bt_01', 3, 'Sân Cầu Lông BT-03', 'badminton', 130000, 170000, 'Thảm PVC Enlio', true),
('court_bt_04', 'venue_bt_01', 4, 'Sân Cầu Lông BT-04', 'badminton', 130000, 170000, 'Thảm PVC Enlio', true),
('court_bt_05', 'venue_bt_01', 5, 'Sân Pickleball BT-05', 'pickleball', 160000, 220000, 'Sơn Acrylic USAPA', true),
('court_bt_06', 'venue_bt_01', 6, 'Sân Pickleball BT-06', 'pickleball', 160000, 220000, 'Sơn Acrylic USAPA', true),

-- Thảo Điền Pickleball Hub (venue_td_02): 8 sân pickleball
('court_td_01', 'venue_td_02', 1, 'Sân Pickleball TD-01', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_02', 'venue_td_02', 2, 'Sân Pickleball TD-02', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_03', 'venue_td_02', 3, 'Sân Pickleball TD-03', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_04', 'venue_td_02', 4, 'Sân Pickleball TD-04', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_05', 'venue_td_02', 5, 'Sân Pickleball TD-05', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_06', 'venue_td_02', 6, 'Sân Pickleball TD-06', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_07', 'venue_td_02', 7, 'Sân Pickleball TD-07', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),
('court_td_08', 'venue_td_02', 8, 'Sân Pickleball TD-08', 'pickleball', 180000, 260000, 'Sân Nhám Chuyên Dụng', true),

-- Nam Sài Gòn (venue_q7_03): 4 sân bóng đá mini
('court_q7_01', 'venue_q7_03', 1, 'Sân Bóng Đá Mini 01', 'football', 250000, 320000, 'Cỏ nhân tạo FIFA 50mm', true),
('court_q7_02', 'venue_q7_03', 2, 'Sân Bóng Đá Mini 02', 'football', 250000, 320000, 'Cỏ nhân tạo FIFA 50mm', true),
('court_q7_03', 'venue_q7_03', 3, 'Sân Bóng Đá Mini 03', 'football', 250000, 320000, 'Cỏ nhân tạo FIFA 50mm', true),
('court_q7_04', 'venue_q7_03', 4, 'Sân Bóng Đá Mini 04', 'football', 250000, 320000, 'Cỏ nhân tạo FIFA 50mm', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    regular_price = EXCLUDED.regular_price,
    peak_price = EXCLUDED.peak_price;

-- 3. COURT SLOTS (Ma Trận 128 Ca Giờ Trong Ngày Của Cụm Sân Tao Đàn)
DO $$
DECLARE
    v_court RECORD;
    v_hour INT;
    v_start TEXT;
    v_end TEXT;
    v_time_slot TEXT;
    v_slot_id TEXT;
    v_is_peak BOOLEAN;
    v_price NUMERIC;
    v_today DATE := CURRENT_DATE;
BEGIN
    FOR v_court IN SELECT id, court_number, regular_price, peak_price FROM public.courts WHERE venue_id = 'venue_01' LOOP
        FOR v_hour IN 6..21 LOOP
            v_start := LPAD(v_hour::TEXT, 2, '0') || ':00';
            v_end := LPAD((v_hour + 1)::TEXT, 2, '0') || ':00';
            v_time_slot := v_start || ' - ' || v_end;
            v_slot_id := v_court.id || '_' || LPAD(v_hour::TEXT, 2, '0') || '_00';
            v_is_peak := (v_hour >= 17 AND v_hour <= 21);
            v_price := CASE WHEN v_is_peak THEN v_court.peak_price ELSE v_court.regular_price END;

            INSERT INTO public.court_slots (id, venue_id, court_id, date, time_slot, start_time, end_time, price, status, is_peak_hour)
            VALUES (v_slot_id, 'venue_01', v_court.id, v_today, v_time_slot, v_start, v_end, v_price, 'available', v_is_peak)
            ON CONFLICT (id) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- 4. BOOKINGS (Danh Sách Đơn Đặt Sân Đa Dạng Kèm Dịch Vụ)
INSERT INTO public.bookings (
    id, booking_id, venue_id, venue_name, court_id, court_number, court_name, sport,
    date, time_slot, start_time, end_time, customer_name, customer_phone,
    price, payment_status, payment_method, checked_in, checked_in_at, add_ons, created_at
) VALUES
(
    'SH-8291',
    'SH-8291',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_01_tao_dan',
    1,
    'Sân Cầu Lông 01',
    'badminton',
    CURRENT_DATE,
    '08:00 - 09:00',
    '08:00',
    '09:00',
    'Nguyễn Văn An',
    '0909 123 456',
    80000,
    'paid',
    'vietqr',
    false,
    NULL,
    '[{"name": "Nước Khoáng Aquafina", "quantity": 2, "unitPrice": 10000, "total": 20000}]'::jsonb,
    NOW() - INTERVAL '3 hours'
),
(
    'SH-8292',
    'SH-8292',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_02_tao_dan',
    2,
    'Sân Cầu Lông 02',
    'badminton',
    CURRENT_DATE,
    '18:00 - 19:00',
    '18:00',
    '19:00',
    'Trần Thị Mai',
    '0918 888 777',
    180000,
    'paid',
    'vietqr',
    false,
    NULL,
    '[{"name": "Ống Cầu Lông Hải Yến (12 quả)", "quantity": 1, "unitPrice": 240000, "total": 240000}]'::jsonb,
    NOW() - INTERVAL '2 hours'
),
(
    'SH-7714',
    'SH-7714',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_05_tao_dan',
    5,
    'Sân Pickleball 05',
    'pickleball',
    CURRENT_DATE,
    '19:00 - 20:00',
    '19:00',
    '20:00',
    'Lê Quốc Bảo',
    '0977 666 555',
    240000,
    'paid',
    'vietqr',
    false,
    NULL,
    '[{"name": "Vợt Pickleball Carbon Joola", "quantity": 2, "unitPrice": 40000, "total": 80000}]'::jsonb,
    NOW() - INTERVAL '1 hour'
),
(
    'SH-9901',
    'SH-9901',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_03_tao_dan',
    3,
    'Sân Cầu Lông 03',
    'badminton',
    CURRENT_DATE,
    '07:00 - 08:00',
    '07:00',
    '08:00',
    'Hoàng Nam',
    '0902 111 222',
    120000,
    'paid',
    'vietqr',
    true,
    NOW() - INTERVAL '4 hours',
    '[]'::jsonb,
    NOW() - INTERVAL '5 hours'
),
(
    'SH-9902',
    'SH-9902',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_06_tao_dan',
    6,
    'Sân Pickleball 06',
    'pickleball',
    CURRENT_DATE,
    '09:00 - 10:00',
    '09:00',
    '10:00',
    'Đặng Thu Thảo',
    '0933 444 555',
    150000,
    'paid',
    'vietqr',
    true,
    NOW() - INTERVAL '3 hours',
    '[{"name": "Pocari Sweat Bù Khoáng", "quantity": 3, "unitPrice": 15000, "total": 45000}]'::jsonb,
    NOW() - INTERVAL '4 hours'
),
(
    'SH-6621',
    'SH-6621',
    'venue_01',
    'CLB Cầu Lông & Pickleball Tao Đàn',
    'court_04_tao_dan',
    4,
    'Sân Cầu Lông 04',
    'badminton',
    CURRENT_DATE,
    '19:00 - 20:00',
    '19:00',
    '20:00',
    'Phạm Minh Đức',
    '0988 123 789',
    180000,
    'pending',
    'cash',
    false,
    NULL,
    '[]'::jsonb,
    NOW() - INTERVAL '30 minutes'
),
(
    'SH-4401',
    'SH-4401',
    'venue_bt_01',
    'CLB Cầu Lông & Pickleball Bình Thạnh Sport',
    'court_bt_01',
    1,
    'Sân Cầu Lông BT-01',
    'badminton',
    CURRENT_DATE,
    '18:00 - 19:00',
    '18:00',
    '19:00',
    'Lê Văn Hùng',
    '0908 999 888',
    170000,
    'paid',
    'vietqr',
    false,
    NULL,
    '[]'::jsonb,
    NOW() - INTERVAL '45 minutes'
),
(
    'SH-4402',
    'SH-4402',
    'venue_td_02',
    'Thảo Điền Pickleball Hub',
    'court_td_01',
    1,
    'Sân Pickleball TD-01',
    'pickleball',
    CURRENT_DATE,
    '19:00 - 20:00',
    '19:00',
    '20:00',
    'John Smith',
    '0909 333 444',
    260000,
    'paid',
    'vietqr',
    false,
    NULL,
    '[]'::jsonb,
    NOW() - INTERVAL '20 minutes'
)
ON CONFLICT (id) DO UPDATE SET
    payment_status = EXCLUDED.payment_status,
    checked_in = EXCLUDED.checked_in;

-- Đồng bộ trạng thái vào bảng court_slots cho các sân đã đặt
UPDATE public.court_slots SET status = 'bookedApp', ticket_id = 'SH-8291', customer_name = 'Nguyễn Văn An' WHERE id = 'court_01_tao_dan_08_00';
UPDATE public.court_slots SET status = 'bookedApp', ticket_id = 'SH-8292', customer_name = 'Trần Thị Mai' WHERE id = 'court_02_tao_dan_18_00';
UPDATE public.court_slots SET status = 'bookedApp', ticket_id = 'SH-7714', customer_name = 'Lê Quốc Bảo' WHERE id = 'court_05_tao_dan_19_00';
UPDATE public.court_slots SET status = 'bookedApp', ticket_id = 'SH-9901', customer_name = 'Hoàng Nam' WHERE id = 'court_03_tao_dan_07_00';
UPDATE public.court_slots SET status = 'bookedApp', ticket_id = 'SH-9902', customer_name = 'Đặng Thu Thảo' WHERE id = 'court_06_tao_dan_09_00';
UPDATE public.court_slots SET status = 'reservedManual', ticket_id = 'SH-6621', customer_name = 'Phạm Minh Đức' WHERE id = 'court_04_tao_dan_19_00';

-- 5. USER PROFILES (Thông Tin Tài Khoản Thực Tế)
INSERT INTO public.user_profiles (id, email, full_name, phone, role, venue_id, avatar_url)
VALUES
('a0000000-0000-0000-0000-000000000001'::uuid, 'nguyenvanan@gmail.com', 'Nguyễn Văn An', '0909 123 456', 'player', NULL, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'),
('a0000000-0000-0000-0000-000000000002'::uuid, 'quocanh@gmail.com', 'Lê Quốc Anh', '0901 234 567', 'player', NULL, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'),
('a0000000-0000-0000-0000-000000000003'::uuid, 'leminh@gmail.com', 'Lê Minh', '0918 888 999', 'player', NULL, 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'),
('a0000000-0000-0000-0000-000000000004'::uuid, 'thuylinh@gmail.com', 'Trần Thuỳ Linh', '0977 666 555', 'player', NULL, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200'),
('a0000000-0000-0000-0000-000000000005'::uuid, 'admin@sporthub.vn', 'Super Admin SportHub', '0900 000 001', 'admin', NULL, 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200'),
('a0000000-0000-0000-0000-000000000006'::uuid, 'partner@taodan.vn', 'Chủ Sân Tao Đàn', '0988 888 777', 'partner', 'venue_01', 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200'),
('a0000000-0000-0000-0000-000000000007'::uuid, 'chusan@gmail.com', 'Trần Văn Chủ Sân', '0988 888 666', 'partner', 'venue_01', 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200')
ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role;

-- 6. COMMUNITY POSTS (Bảng Tin Ghép Kèo Sôi Nổi)
INSERT INTO public.community_posts (id, author_id, author_name, author_avatar, sport, district, title, content, court_time, player_needed, current_players, image_url, is_urgent)
VALUES
(
    'post_match_01',
    'a0000000-0000-0000-0000-000000000001',
    'Trần Hoàng',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    'pickleball',
    'Bình Thạnh',
    'Tìm bạn đánh đôi Pickleball giao lưu vui vẻ',
    'Tìm cặp đánh đôi cọ xát kinh nghiệm tại CLB Bình Thạnh Sport, giao lưu vui vẻ nâng cao thể lực là chính.',
    '18:30 - 20:30 Thứ Sáu',
    2,
    2,
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=600',
    false
),
(
    'post_match_02',
    'a0000000-0000-0000-0000-000000000003',
    'Lê Minh',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    'pickleball',
    'Thủ Đức',
    'Tuyển 1 slot đánh Pickleball buổi tối Thảo Điền Hub',
    'Kèo trình độ DUPR 3.5+ đánh đôi tốc độ cao, sân ngoài trời có mái che mát mẻ.',
    '19:00 - 21:00 Thứ Bảy',
    1,
    3,
    'https://images.unsplash.com/photo-1599474924187-334a4ae5bd3c?w=600',
    true
),
(
    'post_match_03',
    'a0000000-0000-0000-0000-000000000002',
    'Phạm Đức',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'badminton',
    'Quận 1',
    'Giao lưu Cầu lông phong trào cuối tuần Tao Đàn',
    'Nhóm cầu lông trung cấp tuyển thêm 2 bạn đánh đôi tại Sân Tao Đàn Quận 1 sáng Chủ Nhật.',
    '08:00 - 10:00 Chủ Nhật',
    2,
    2,
    'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=600',
    false
),
(
    'post_match_04',
    'a0000000-0000-0000-0000-000000000002',
    'Võ Quốc',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    'football',
    'Quận 7',
    'Tìm đội đá bóng mini 5 người sân Nam Sài Gòn',
    'Đội bóng văn phòng cần tìm đội bạn thi đấu giao lưu sân cỏ nhân tạo Nam Sài Gòn, đá vui vẻ fair-play chia tiền sân.',
    '19:30 - 21:00 Thứ Tư',
    5,
    5,
    'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=600',
    false
),
(
    'post_match_05',
    'a0000000-0000-0000-0000-000000000004',
    'Trần Thuỳ Linh',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    'pickleball',
    'Quận 1',
    'Kèo Pickleball dưỡng sinh sáng Chủ Nhật Tao Đàn',
    'Vận động nhẹ nhàng đầu ngày cho các bạn mới tập làm quen với bóng pickleball, có sẵn bóng và vợt cho bạn mượn.',
    '06:30 - 08:30 Chủ Nhật',
    2,
    2,
    'https://images.unsplash.com/photo-1529900748604-07564a03e7a6?w=600',
    false
)
ON CONFLICT (id) DO UPDATE SET
    title = EXCLUDED.title,
    content = EXCLUDED.content,
    player_needed = EXCLUDED.player_needed;

-- 7. TRANSACTIONS (Lịch Sử Dòng Tiền & Bán Lẻ POS)
INSERT INTO public.transactions (id, venue_id, type, description, amount, payment_method, customer_name, status, created_at)
VALUES
('TX-20261027-01', 'venue_01', 'booking_app', 'Đặt sân SH-8291 - Sân Cầu Lông 01 (08:00 - 09:00)', 80000, 'vietqr', 'Nguyễn Văn An', 'completed', NOW() - INTERVAL '3 hours'),
('TX-20261027-02', 'venue_01', 'booking_app', 'Đặt sân SH-8292 - Sân Cầu Lông 02 (18:00 - 19:00)', 180000, 'vietqr', 'Trần Thị Mai', 'completed', NOW() - INTERVAL '2 hours'),
('TX-20261027-03', 'venue_01', 'booking_app', 'Đặt sân SH-7714 - Sân Pickleball 05 (19:00 - 20:00)', 240000, 'vietqr', 'Lê Quốc Bảo', 'completed', NOW() - INTERVAL '1 hour'),
('TX-20261027-04', 'venue_01', 'pos_service', 'Bán lẻ quầy: 3x Nước suối Aquafina, 2x Pocari Sweat', 60000, 'cash', 'Khách thanh toán tại quầy', 'completed', NOW() - INTERVAL '40 minutes'),
('TX-20261027-05', 'venue_01', 'pos_service', 'Thuê dụng cụ: 2x Vợt Pickleball Carbon Joola', 80000, 'vietqr', 'Lê Quốc Bảo', 'completed', NOW() - INTERVAL '50 minutes'),
('TX-20261027-06', 'venue_01', 'booking_app', 'Đặt sân SH-9901 - Sân Cầu Lông 03 (07:00 - 08:00)', 120000, 'vietqr', 'Hoàng Nam', 'completed', NOW() - INTERVAL '5 hours'),
('TX-20261027-07', 'venue_01', 'booking_app', 'Đặt sân SH-9902 - Sân Pickleball 06 (09:00 - 10:00)', 150000, 'vietqr', 'Đặng Thu Thảo', 'completed', NOW() - INTERVAL '4 hours')
ON CONFLICT (id) DO NOTHING;

-- 8. VENUE ADDONS (Sản Phẩm Bán Lẻ POS & Cho Thuê Dụng Cụ)
INSERT INTO public.venue_addons (id, venue_id, name, description, price, unit, category, icon, sport_types, is_active)
VALUES
('rent_badminton', 'venue_01', 'Vợt Cầu Lông Yonex Astrox', 'Dòng Astrox chuyên công căng sẵn 10.5kg', 30000, 'cây', 'rental', '🏸', ARRAY['badminton'], true),
('rent_machine', 'venue_01', 'Máy Bắn Cầu Tự Động', 'Luyện tập phản xạ và kỹ thuật đa hướng', 80000, 'giờ', 'rental', '🤖', ARRAY['badminton'], true),
('gear_shuttle_tube', 'venue_01', 'Ống Cầu Lông Hải Yến (12 quả)', 'Ống 12 quả bền đẹp chuẩn thi đấu', 240000, 'ống', 'gear', '🏸', ARRAY['badminton'], true),
('gear_shuttle_single', 'venue_01', 'Quả Cầu Lông Lẻ Hải Yến', 'Cầu lông thi đấu cánh thẳng đầm tay', 22000, 'quả', 'gear', '🏸', ARRAY['badminton'], true),
('rent_pickleball', 'venue_01', 'Vợt Pickleball Carbon Joola', 'Mặt nhám carbon chuẩn thi đấu USAPA', 40000, 'cây', 'rental', '🏓', ARRAY['pickleball'], true),
('gear_pickle_ball', 'venue_01', 'Bóng Pickleball Franklin X-40', 'Bóng ngoài trời 40 lỗ độ nảy chuẩn', 45000, 'quả', 'gear', '🟡', ARRAY['pickleball'], true),
('drink_pocari', 'venue_01', 'Pocari Sweat Bù Khoáng', 'Chai 500ml ướp lạnh bổ sung điện giải', 15000, 'chai', 'beverage', '🥤', ARRAY['badminton', 'pickleball', 'football'], true),
('drink_aquafina', 'venue_01', 'Nước Khoáng Aquafina', 'Chai 500ml tinh khiết mát lạnh', 10000, 'chai', 'beverage', '💧', ARRAY['badminton', 'pickleball', 'football'], true),
('drink_redbull', 'venue_01', 'Nước Tăng Lực Redbull', 'Lon 250ml nạp năng lượng nhanh', 20000, 'lon', 'beverage', '⚡', ARRAY['badminton', 'pickleball', 'football'], true),
('gear_grip', 'venue_01', 'Quấn Cán Vợt Thấm Mồ Hôi', 'Chống trơn trượt êm tay thấm hút tốt', 25000, 'cái', 'gear', '🎾', ARRAY['badminton', 'pickleball'], true),
('gear_cold_spray', 'venue_01', 'Bình Xịt Lạnh Giảm Đau Tức Thì', 'Xịt lạnh cấp tốc giảm sưng đau va chạm', 60000, 'chai', 'gear', '❄️', ARRAY['badminton', 'pickleball', 'football'], true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    price = EXCLUDED.price;

-- 9. CHATBOT CONFIG (Cấu hình AI Agent FPT Cloud / Ollama)
INSERT INTO public.chatbot_config (id, provider, model, api_key, system_prompt, temperature, is_active)
VALUES (
    'default',
    'fpt',
    'gemma-4-26B-A4B-it',
    NULL,
    'Bạn là trợ lý ảo AI thông minh của SportHub, hỗ trợ tìm kiếm sân trống, gợi ý ghép kèo thể thao và giải đáp dịch vụ sân.',
    0.7,
    true
)
ON CONFLICT (id) DO UPDATE SET
    model = EXCLUDED.model,
    provider = EXCLUDED.provider;
