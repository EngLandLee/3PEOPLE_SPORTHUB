-- ==============================================================================
-- SPORTHUB SEED DATA SCRIPT FOR SUPABASE
-- Run this in Supabase SQL Editor after running schema.sql
-- ==============================================================================

-- 1. VENUES SEED
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
)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    sports = EXCLUDED.sports,
    base_hourly_rate = EXCLUDED.base_hourly_rate;

-- 2. COURTS FOR TAO ĐÀN (Courts 1-4 Badminton, Courts 5-8 Pickleball)
INSERT INTO public.courts (id, venue_id, court_number, name, sport, regular_price, peak_price, surface_type, is_active)
VALUES
('court_01_tao_dan', 'venue_01', 1, 'Sân Cầu Lông 01', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_02_tao_dan', 'venue_01', 2, 'Sân Cầu Lông 02', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_03_tao_dan', 'venue_01', 3, 'Sân Cầu Lông 03', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_04_tao_dan', 'venue_01', 4, 'Sân Cầu Lông 04', 'badminton', 120000, 180000, 'Thảm PVC Yonex', true),
('court_05_tao_dan', 'venue_01', 5, 'Sân Pickleball 05', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_06_tao_dan', 'venue_01', 6, 'Sân Pickleball 06', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_07_tao_dan', 'venue_01', 7, 'Sân Pickleball 07', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true),
('court_08_tao_dan', 'venue_01', 8, 'Sân Pickleball 08', 'pickleball', 150000, 240000, 'Sơn Acrylic 5 lớp', true)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    regular_price = EXCLUDED.regular_price,
    peak_price = EXCLUDED.peak_price;

-- 3. SEEDED BOOKINGS (SH-8291, SH-8292, SH-7714)
INSERT INTO public.bookings (
    id, booking_id, venue_id, venue_name, court_id, court_number, court_name, sport,
    date, time_slot, start_time, end_time, customer_name, customer_phone,
    price, payment_status, payment_method, checked_in, add_ons
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
    '09:00 - 10:00',
    '09:00',
    '10:00',
    'Nguyễn Văn An',
    '0909 123 456',
    80000,
    'paid',
    'vietqr',
    false,
    '[{"id":"drink_water","name":"Nước suối Aquafina","quantity":2,"unitPrice":10000,"total":20000}]'::jsonb
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
    '0912 345 678',
    180000,
    'paid',
    'vietqr',
    false,
    '[{"id":"drink_pocari","name":"Pocari Sweat Bù Khoáng","quantity":2,"unitPrice":15000,"total":30000}]'::jsonb
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
    '0988 777 666',
    240000,
    'paid',
    'vietqr',
    false,
    '[{"id":"rent_pickleball","name":"Thuê vợt Pickleball Franklin","quantity":1,"unitPrice":50000,"total":50000}]'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
    customer_name = EXCLUDED.customer_name,
    payment_status = EXCLUDED.payment_status;

-- 4. TRANSACTIONS
INSERT INTO public.transactions (id, venue_id, type, description, amount, payment_method, customer_name, status)
VALUES
('TX-20261027-01', 'venue_01', 'booking_app', 'Đặt sân SH-8291 - Sân Cầu Lông 01 (09:00 - 10:00)', 80000, 'vietqr', 'Nguyễn Văn An', 'completed'),
('TX-20261027-02', 'venue_01', 'booking_app', 'Đặt sân SH-8292 - Sân Cầu Lông 02 (18:00 - 19:00)', 180000, 'vietqr', 'Trần Thị Mai', 'completed'),
('TX-20261027-03', 'venue_01', 'booking_app', 'Đặt sân SH-7714 - Sân Pickleball 05 (19:00 - 20:00)', 240000, 'vietqr', 'Lê Quốc Bảo', 'completed'),
('TX-20261027-04', 'venue_01', 'pos_service', 'Bán lẻ quầy: 3x Nước suối Aquafina, 2x Pocari Sweat', 60000, 'cash', 'Khách thanh toán tại quầy', 'completed')
ON CONFLICT (id) DO NOTHING;

-- 5. CHATBOT CONFIG SEED
INSERT INTO public.chatbot_config (id, provider, model, is_active)
VALUES ('default', 'fpt', 'gemma-4-26B-A4B-it', true)
ON CONFLICT (id) DO NOTHING;
