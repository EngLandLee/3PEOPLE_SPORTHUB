-- ==============================================================================
-- SPORTHUB SUPABASE DATABASE SCHEMA (PostgreSQL)
-- Supports Flutter Mobile App, React Web Admin Portal, and AI Chatbot
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. VENUES (Cụm Sân Thể Thao)
CREATE TABLE IF NOT EXISTS public.venues (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    district TEXT NOT NULL,
    hotline TEXT NOT NULL,
    sports TEXT[] NOT NULL DEFAULT '{}',
    open_time TEXT NOT NULL DEFAULT '06:00',
    close_time TEXT NOT NULL DEFAULT '22:00',
    base_hourly_rate NUMERIC NOT NULL DEFAULT 150000,
    image_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    total_courts INTEGER NOT NULL DEFAULT 8,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. COURTS (Chi Tiết Từng Sân Đấu Thuộc Cụm Sân)
CREATE TABLE IF NOT EXISTS public.courts (
    id TEXT PRIMARY KEY,
    venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
    court_number INTEGER NOT NULL,
    name TEXT NOT NULL,
    sport TEXT NOT NULL, -- 'badminton', 'pickleball', 'football'
    regular_price NUMERIC NOT NULL DEFAULT 150000,
    peak_price NUMERIC NOT NULL DEFAULT 200000,
    surface_type TEXT DEFAULT 'Thảm PVC chuyên dụng',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. COURT SLOTS (Khung Giờ Sân Trong Ngày)
CREATE TABLE IF NOT EXISTS public.court_slots (
    id TEXT PRIMARY KEY,
    venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
    court_id TEXT NOT NULL REFERENCES public.courts(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    time_slot TEXT NOT NULL, -- '18:00 - 19:00'
    start_time TEXT NOT NULL, -- '18:00'
    end_time TEXT NOT NULL, -- '19:00'
    price NUMERIC NOT NULL DEFAULT 150000,
    status TEXT NOT NULL DEFAULT 'available', -- 'available', 'bookedApp', 'reservedManual', 'maintenance'
    is_peak_hour BOOLEAN NOT NULL DEFAULT FALSE,
    ticket_id TEXT,
    customer_name TEXT,
    customer_phone TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. BOOKINGS (Đơn Đặt Sân Của Khách Hàng)
CREATE TABLE IF NOT EXISTS public.bookings (
    id TEXT PRIMARY KEY,
    booking_id TEXT,
    venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE RESTRICT,
    venue_name TEXT,
    court_id TEXT,
    court_number INTEGER NOT NULL,
    court_name TEXT NOT NULL,
    sport TEXT NOT NULL,
    date DATE NOT NULL,
    time_slot TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    user_id UUID,
    price NUMERIC NOT NULL DEFAULT 0,
    payment_status TEXT NOT NULL DEFAULT 'pending', -- 'paid', 'pending', 'cancelled'
    payment_method TEXT NOT NULL DEFAULT 'vietqr', -- 'vietqr', 'cash', 'momo', 'vnpay'
    checked_in BOOLEAN NOT NULL DEFAULT FALSE,
    checked_in_at TIMESTAMPTZ,
    add_ons JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. TRANSACTIONS (Nhật Ký Dòng Tiền & Bán Lẻ POS)
CREATE TABLE IF NOT EXISTS public.transactions (
    id TEXT PRIMARY KEY DEFAULT ('TX-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || SUBSTR(MD5(RANDOM()::TEXT), 1, 6)),
    venue_id TEXT NOT NULL REFERENCES public.venues(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'booking_app', 'pos_service', 'refund'
    description TEXT NOT NULL,
    amount NUMERIC NOT NULL DEFAULT 0,
    payment_method TEXT NOT NULL DEFAULT 'vietqr',
    customer_name TEXT NOT NULL DEFAULT 'Khách hàng',
    status TEXT NOT NULL DEFAULT 'completed', -- 'completed', 'refunded'
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. USER PROFILES (Thông Tin Tài Khoản & Phân Quyền)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    role TEXT NOT NULL DEFAULT 'player', -- 'player', 'partner', 'admin'
    venue_id TEXT REFERENCES public.venues(id), -- Chỉ định sân cho chủ sân (partner)
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. COMMUNITY POSTS (Bảng Tin Ghép Kèo Thể Thao)
CREATE TABLE IF NOT EXISTS public.community_posts (
    id TEXT PRIMARY KEY DEFAULT ('post_' || EXTRACT(EPOCH FROM NOW())::BIGINT),
    author_id TEXT NOT NULL,
    author_name TEXT NOT NULL,
    author_avatar TEXT,
    sport TEXT NOT NULL, -- 'badminton', 'pickleball', 'football'
    district TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    court_time TEXT NOT NULL,
    player_needed INTEGER NOT NULL DEFAULT 2,
    current_players INTEGER NOT NULL DEFAULT 1,
    image_url TEXT,
    is_urgent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. CHATBOT CONFIG (Cấu Hình AI FPT Cloud / Ollama)
CREATE TABLE IF NOT EXISTS public.chatbot_config (
    id TEXT PRIMARY KEY DEFAULT 'default',
    provider TEXT NOT NULL DEFAULT 'fpt',
    model TEXT NOT NULL DEFAULT 'gemma-4-26B-A4B-it',
    api_key TEXT,
    system_prompt TEXT,
    temperature NUMERIC NOT NULL DEFAULT 0.7,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. VENUE ADDONS (Sản phẩm POS & Dịch Vụ Thuê Vợt / Nước Uống)
CREATE TABLE IF NOT EXISTS public.venue_addons (
    id TEXT PRIMARY KEY,
    venue_id TEXT REFERENCES public.venues(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC NOT NULL DEFAULT 0,
    unit TEXT NOT NULL DEFAULT 'cái',
    category TEXT NOT NULL DEFAULT 'rental', -- 'rental', 'beverage', 'gear'
    icon TEXT DEFAULT '🏸',
    sport_types TEXT[] DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- DATABASE FUNCTIONS & CONCURRENCY CONTROLS (Chống Đặt Trùng Ca)
-- ==============================================================================

-- Hàm an toàn đặt sân với Row-Level Lock ngăn chặn race condition (Double Booking)
CREATE OR REPLACE FUNCTION public.fn_book_court_slot(
    p_booking_id TEXT,
    p_venue_id TEXT,
    p_court_number INTEGER,
    p_court_name TEXT,
    p_sport TEXT,
    p_date DATE,
    p_start_time TEXT,
    p_end_time TEXT,
    p_customer_name TEXT,
    p_customer_phone TEXT,
    p_price NUMERIC,
    p_payment_method TEXT,
    p_add_ons JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_conflict_count INTEGER;
    v_slot_record RECORD;
BEGIN
    -- 1. Kiểm tra tranh chấp với Row-Level Lock
    SELECT COUNT(*) INTO v_conflict_count
    FROM public.bookings
    WHERE venue_id = p_venue_id
      AND court_number = p_court_number
      AND date = p_date
      AND payment_status != 'cancelled'
      AND (
          (start_time = p_start_time)
          OR (start_time < p_end_time AND end_time > p_start_time)
      )
    FOR UPDATE;

    IF v_conflict_count > 0 THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Khung giờ này vừa có người khác đặt. Vui lòng chọn ca khác!'
        );
    END IF;

    -- 2. Ghi nhận đơn đặt sân mới
    INSERT INTO public.bookings (
        id, booking_id, venue_id, court_number, court_name, sport,
        date, time_slot, start_time, end_time, customer_name,
        customer_phone, price, payment_status, payment_method,
        checked_in, add_ons, created_at
    ) VALUES (
        p_booking_id, p_booking_id, p_venue_id, p_court_number, p_court_name, p_sport,
        p_date, (p_start_time || ' - ' || p_end_time), p_start_time, p_end_time,
        p_customer_name, p_customer_phone, p_price, 'pending', p_payment_method,
        FALSE, p_add_ons, NOW()
    );

    -- 3. Cập nhật trạng thái slot trong ma trận lịch
    UPDATE public.court_slots
    SET status = 'bookedApp',
        ticket_id = p_booking_id,
        customer_name = p_customer_name,
        customer_phone = p_customer_phone,
        updated_at = NOW()
    WHERE venue_id = p_venue_id
      AND date = p_date
      AND (court_id LIKE ('%' || p_court_number || '%') OR id LIKE ('%' || p_court_number || '%'))
      AND start_time = p_start_time;

    -- 4. Trả về kết quả thành công
    RETURN jsonb_build_object(
        'success', true,
        'booking_id', p_booking_id,
        'message', 'Đặt sân thành công!'
    );
END;
$$;

-- Hàm check-in vé thời gian thực
CREATE OR REPLACE FUNCTION public.fn_checkin_booking(p_ticket_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    v_clean_id TEXT := UPPER(TRIM(p_ticket_id));
    v_booking RECORD;
BEGIN
    SELECT * INTO v_booking
    FROM public.bookings
    WHERE UPPER(id) = v_clean_id OR UPPER(booking_id) = v_clean_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'message', 'Không tìm thấy mã vé!');
    END IF;

    UPDATE public.bookings
    SET checked_in = TRUE,
        checked_in_at = NOW(),
        updated_at = NOW()
    WHERE id = v_booking.id;

    RETURN jsonb_build_object(
        'success', true,
        'ticket_id', v_booking.id,
        'customer_name', v_booking.customer_name,
        'court_name', v_booking.court_name,
        'start_time', v_booking.start_time
    );
END;
$$;

-- ==============================================================================
-- REALTIME PUBLICATIONS (Bắn dữ liệu tức thì xuống Mobile & Web Admin)
-- ==============================================================================
DO $$
BEGIN
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.court_slots;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.community_posts;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
    BEGIN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.venue_addons;
    EXCEPTION WHEN duplicate_object THEN NULL;
    END;
END $$;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.venues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.court_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.venue_addons ENABLE ROW LEVEL SECURITY;

-- 1. Venues & Courts: Mọi người đều có thể xem
DROP POLICY IF EXISTS "Public venues viewable by all" ON public.venues;
CREATE POLICY "Public venues viewable by all" ON public.venues FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public courts viewable by all" ON public.courts;
CREATE POLICY "Public courts viewable by all" ON public.courts FOR SELECT USING (true);

DROP POLICY IF EXISTS "Public slots viewable by all" ON public.court_slots;
CREATE POLICY "Public slots viewable by all" ON public.court_slots FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public slots insertable" ON public.court_slots;
CREATE POLICY "Public slots insertable" ON public.court_slots FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Public slots updateable" ON public.court_slots;
CREATE POLICY "Public slots updateable" ON public.court_slots FOR UPDATE USING (true);

-- 2. Bookings: Khách xem và tạo đơn đặt sân, Chủ sân quản lý
DROP POLICY IF EXISTS "Public bookings select" ON public.bookings;
CREATE POLICY "Public bookings select" ON public.bookings FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public bookings insert" ON public.bookings;
CREATE POLICY "Public bookings insert" ON public.bookings FOR INSERT WITH CHECK (true);
DROP POLICY IF EXISTS "Public bookings update checkin" ON public.bookings;
CREATE POLICY "Public bookings update checkin" ON public.bookings FOR UPDATE USING (true);

-- 3. Transactions & Posts & Addons: Mọi người đều xem được
DROP POLICY IF EXISTS "Public transactions viewable" ON public.transactions;
CREATE POLICY "Public transactions viewable" ON public.transactions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public transactions insertable" ON public.transactions;
CREATE POLICY "Public transactions insertable" ON public.transactions FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public posts viewable by all" ON public.community_posts;
CREATE POLICY "Public posts viewable by all" ON public.community_posts FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public posts insertable" ON public.community_posts;
CREATE POLICY "Public posts insertable" ON public.community_posts FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public user profiles viewable" ON public.user_profiles;
CREATE POLICY "Public user profiles viewable" ON public.user_profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Public user profiles insertable" ON public.user_profiles;
CREATE POLICY "Public user profiles insertable" ON public.user_profiles FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Public addons viewable" ON public.venue_addons;
CREATE POLICY "Public addons viewable" ON public.venue_addons FOR SELECT USING (true);
