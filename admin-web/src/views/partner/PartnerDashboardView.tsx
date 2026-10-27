import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  DollarSign,
  CalendarCheck,
  Percent,
  UserCheck,
  TrendingUp,
  ArrowRight,
  PlusCircle,
  QrCode,
  CalendarRange,
  Search,
  Bell,
  SunMedium,
  ArrowUpRight,
  Sparkles,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';
import { useAuthStore } from '../../store/authStore';
import { AddCourtModal } from '../../components/courts/AddCourtModal';

export const PartnerDashboardView: React.FC = () => {
  const { courts, slots, bookings, transactions, venues } = useVenueStore();
  const { activeVenueId } = useAuthStore();
  const currentVenueId = activeVenueId || 'venue_01';
  const currentVenue = venues.find((v) => v.id === currentVenueId) || venues[0];

  const venueCourts = courts.filter((c) => c.venueId === currentVenueId);
  const venueSlots = slots.filter((s) => s.venueId === currentVenueId);
  const venueBookings = bookings.filter((b) => b.venueId === currentVenueId);
  const venueTransactions = transactions.filter((t) => t.venueId === currentVenueId);

  const [isAddCourtModalOpen, setIsAddCourtModalOpen] = useState(false);
  const [chartMetric, setChartMetric] = useState<'slots' | 'revenue'>('slots');
  const [chartTab, setChartTab] = useState<'hours' | 'minutes'>('hours');
  const [dashboardTab, setDashboardTab] = useState<'overview' | 'courts' | 'revenue'>('overview');
  const [searchQuery, setSearchQuery] = useState('');

  // 1. Doanh thu hôm nay
  const bookingRevenue = venueBookings.reduce((sum, b) => sum + b.price, 0);
  const txRevenue = venueTransactions.reduce(
    (sum, tx) => sum + (tx.status === 'completed' ? tx.amount : 0),
    0
  );
  const totalRevenueToday = bookingRevenue + txRevenue;

  // 2. Số ca đã đặt (app + manual)
  const bookedSlots = venueSlots.filter(
    (s) => s.status === 'bookedApp' || s.status === 'reservedManual'
  );
  const bookedSlotsCount = bookedSlots.length;
  const appBookedCount = venueSlots.filter((s) => s.status === 'bookedApp').length;
  const manualBookedCount = venueSlots.filter((s) => s.status === 'reservedManual').length;

  // 3. Tỷ lệ lấp đầy
  const occupancyRate =
    venueSlots.length > 0 ? Math.round((bookedSlotsCount / venueSlots.length) * 100) : 0;

  // 4. Khách đã check-in
  const checkedInCount = venueBookings.filter((b) => b.checkedIn).length;

  // 5. Môn thể thao tỷ lệ lấp đầy thực tế
  const badmintonCourts = venueCourts.filter((c) => c.sport === 'badminton');
  const badmintonSlots = venueSlots.filter((s) =>
    badmintonCourts.some((c) => c.id === s.courtId)
  );
  const badmintonBooked = badmintonSlots.filter(
    (s) => s.status === 'bookedApp' || s.status === 'reservedManual'
  ).length;
  const badmintonRate =
    badmintonSlots.length > 0 ? Math.round((badmintonBooked / badmintonSlots.length) * 100) : 0;

  const pickleballCourts = venueCourts.filter((c) => c.sport === 'pickleball');
  const pickleballSlots = venueSlots.filter((s) =>
    pickleballCourts.some((c) => c.id === s.courtId)
  );
  const pickleballBooked = pickleballSlots.filter(
    (s) => s.status === 'bookedApp' || s.status === 'reservedManual'
  ).length;
  const pickleballRate =
    pickleballSlots.length > 0 ? Math.round((pickleballBooked / pickleballSlots.length) * 100) : 0;

  // Determine current court live status badge
  const getCourtLiveStatus = (courtId: string) => {
    const courtSlots = venueSlots.filter((s) => s.courtId === courtId);
    const courtBooked = courtSlots.filter(
      (s) => s.status === 'bookedApp' || s.status === 'reservedManual'
    ).length;
    const percent =
      courtSlots.length > 0 ? Math.round((courtBooked / courtSlots.length) * 100) : 0;

    if (!courtSlots.length) return { label: 'Trống', color: 'slate', percent: 0 };

    const currentHour = new Date().getHours();
    const currentHourStr = String(currentHour).padStart(2, '0');
    let activeSlot = courtSlots.find((s) => s.startTime.startsWith(currentHourStr));

    if (!activeSlot) {
      activeSlot =
        courtSlots.find((s) => s.status === 'maintenance') ||
        courtSlots.find((s) => s.startTime.startsWith('18:00')) ||
        courtSlots.find((s) => s.status === 'bookedApp') ||
        courtSlots.find((s) => s.status === 'reservedManual') ||
        courtSlots[0];
    }

    if (activeSlot.status === 'maintenance') {
      return { label: 'Bảo trì', color: 'rose', percent };
    }
    if (activeSlot.status === 'bookedApp') {
      return { label: 'Có khách', color: 'emerald', percent };
    }
    if (activeSlot.status === 'reservedManual') {
      return { label: 'Giữ chỗ', color: 'amber', percent };
    }
    return { label: 'Trống', color: 'slate', percent };
  };

  const filteredCourts = venueCourts.filter(
    (c) =>
      c.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      c.sport.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="space-y-6 pb-16">
      {/* 1. Header & Pill Controls Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Hi {currentVenue ? currentVenue.name : 'Quản lý Tao Đàn'} 🏄‍♂️
            </span>
            <span className="text-xs text-slate-400">• Vận hành trực tiếp</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Tổng quan Cụm Sân
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Chào mừng bạn trở lại! Hôm nay có {bookedSlotsCount} ca đặt sân & {venueCourts.length} cụm sân sẵn sàng.
          </p>
        </div>

        {/* Floating Glassy Action Pills Bar */}
        <div className="flex items-center flex-wrap gap-2.5">
          {/* Quick Reserve Pill */}
          <Link
            to="/partner/schedule"
            className="glass-pill px-3.5 py-2 rounded-full text-xs font-bold text-slate-700 dark:text-slate-200 hover:text-amber-600 dark:hover:text-amber-400 flex items-center gap-1.5 transition-all shadow-xs"
          >
            <CalendarRange className="w-3.5 h-3.5 text-amber-500" />
            <span>+ Giữ chỗ</span>
          </Link>

          {/* Add Court Pill */}
          <button
            type="button"
            onClick={() => setIsAddCourtModalOpen(true)}
            className="glass-pill px-3.5 py-2 rounded-full text-xs font-bold text-slate-700 dark:text-slate-200 hover:text-emerald-600 dark:hover:text-emerald-400 flex items-center gap-1.5 transition-all shadow-xs"
          >
            <PlusCircle className="w-3.5 h-3.5 text-emerald-500" />
            <span>+ Thêm sân</span>
          </button>

          {/* Search Pill */}
          <div className="glass-pill px-3 py-1.5 rounded-full flex items-center gap-2 w-48 sm:w-56 focus-within:ring-2 focus-within:ring-emerald-500/30">
            <Search className="w-3.5 h-3.5 text-slate-400 shrink-0" />
            <input
              type="text"
              placeholder="Tìm kiếm sân, ca..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="bg-transparent text-xs text-slate-800 dark:text-slate-200 placeholder-slate-400 outline-hidden w-full"
            />
          </div>

          {/* Notification Pill */}
          <div className="glass-pill p-2 rounded-full text-slate-600 dark:text-slate-300 relative cursor-pointer hover:bg-slate-100 dark:hover:bg-slate-800">
            <Bell className="w-4 h-4" />
            <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-rose-500 ring-2 ring-white dark:ring-slate-900" />
          </div>

          {/* Live Weather & Time Widget Pill */}
          <div className="glass-pill px-3.5 py-1.5 rounded-full text-xs font-semibold text-slate-600 dark:text-slate-300 flex items-center gap-2">
            <SunMedium className="w-4 h-4 text-amber-500 animate-spin-slow" />
            <span>{new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })}</span>
            <span className="text-slate-300 dark:text-slate-600">•</span>
            <span className="text-[11px] text-slate-500 dark:text-slate-400">Nắng ráo 29°C</span>
          </div>
        </div>
      </div>

      {/* 2. 4 Hero KPI Cards with Wave Gradients & Glassmorphism */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        {/* Card 1: Doanh thu hôm nay (Lime Green Wave Gradient) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#d9f99d]/90 via-[#bef264]/80 to-[#a3e635]/60 dark:from-[#14532d]/80 dark:via-[#166534]/70 dark:to-[#052e16]/90 border border-lime-300/60 dark:border-lime-700/40 shadow-lg shadow-lime-500/10 hover:-translate-y-1 transition-all group">
          {/* Organic Wave SVG Background */}
          <div className="absolute -right-6 -bottom-6 w-36 h-36 opacity-30 pointer-events-none group-hover:scale-110 transition-transform">
            <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
              <path
                fill="#4d7c0f"
                d="M44.7,-76.4C58.8,-69.2,71.8,-59.1,79.6,-45.8C87.4,-32.6,90,-16.3,88.5,-0.9C86.9,14.6,81.2,29.1,72.7,41.9C64.2,54.7,52.8,65.8,39.3,72.9C25.8,80.1,10.2,83.3,-4.8,81.6C-19.8,79.9,-34.2,73.3,-47.4,64.7C-60.6,56.1,-72.6,45.5,-79.8,32.1C-87,18.7,-89.4,2.5,-86.6,-12.7C-83.8,-27.9,-75.8,-42.1,-64.3,-50.1C-52.8,-58.1,-37.8,-59.9,-23.8,-67.2C-9.8,-74.5,3.2,-87.3,17.4,-88.2C31.6,-89.1,47,-78.1,44.7,-76.4Z"
                transform="translate(100 100)"
              />
            </svg>
          </div>

          <div className="flex items-center justify-between relative z-10">
            <div className="w-10 h-10 rounded-2xl bg-black/10 dark:bg-black/30 backdrop-blur-md flex items-center justify-center text-slate-900 dark:text-white font-bold">
              <DollarSign className="w-5 h-5" />
            </div>
            <span className="inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-full bg-black/10 dark:bg-black/30 text-slate-900 dark:text-lime-200 backdrop-blur-xs">
              <Sparkles className="w-3 h-3 text-amber-500" /> +18.5%
            </span>
          </div>

          <div className="mt-5 relative z-10">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-800/80 dark:text-lime-300">
              Doanh thu hôm nay
            </div>
            <div className="mt-1 flex items-baseline gap-1">
              <span className="text-3xl sm:text-4xl font-black tracking-tight text-slate-950 dark:text-white">
                {totalRevenueToday.toLocaleString('vi-VN')}
              </span>
              <span className="text-base font-bold text-slate-800/90 dark:text-lime-200">đ</span>
            </div>
            <div className="mt-2 text-xs font-medium text-slate-800/80 dark:text-slate-300 flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5" />
              <span>Tăng trưởng mạnh khung giờ tối</span>
            </div>
          </div>
        </div>

        {/* Card 2: Số ca đã đặt (Peach / Coral Wave Gradient) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#ffedd5]/90 via-[#fed7aa]/80 to-[#fdba74]/60 dark:from-[#7c2d12]/80 dark:via-[#9a3412]/70 dark:to-[#431407]/90 border border-orange-300/60 dark:border-orange-700/40 shadow-lg shadow-orange-500/10 hover:-translate-y-1 transition-all group">
          {/* Organic Wave SVG Background */}
          <div className="absolute -right-6 -bottom-6 w-36 h-36 opacity-30 pointer-events-none group-hover:scale-110 transition-transform">
            <svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">
              <path
                fill="#ea580c"
                d="M48.7,-81.4C63.4,-75.3,75.9,-63.3,84.1,-48.7C92.3,-34.1,96.2,-17,94.4,-0.9C92.7,15.1,85.2,30.2,75.7,43.2C66.1,56.2,54.4,67.1,40.7,74.7C27,82.3,11.3,86.6,-4.2,85.1C-19.7,83.6,-34.9,76.3,-48.1,67.3C-61.2,58.2,-72.3,47.4,-78.9,34.2C-85.5,21,-87.7,5.5,-85.2,-9.2C-82.8,-23.9,-75.7,-37.8,-65.4,-48.3C-55.2,-58.8,-41.8,-65.9,-28.3,-72.8C-14.7,-79.8,0.9,-86.6,17.2,-87.8C33.6,-89,51.8,-84.6,48.7,-81.4Z"
                transform="translate(100 100)"
              />
            </svg>
          </div>

          <div className="flex items-center justify-between relative z-10">
            <div className="w-10 h-10 rounded-2xl bg-black/10 dark:bg-black/30 backdrop-blur-md flex items-center justify-center text-slate-900 dark:text-white font-bold">
              <CalendarCheck className="w-5 h-5" />
            </div>
            <span className="text-[11px] font-bold px-2.5 py-1 rounded-full bg-black/10 dark:bg-black/30 text-slate-900 dark:text-orange-200 backdrop-blur-xs">
              Hôm nay
            </span>
          </div>

          <div className="mt-5 relative z-10">
            <div className="text-xs font-bold uppercase tracking-wider text-slate-800/80 dark:text-orange-300">
              Số ca đã đặt
            </div>
            <div className="mt-1 flex items-baseline gap-2">
              <span className="text-3xl sm:text-4xl font-black tracking-tight text-slate-950 dark:text-white">
                {bookedSlotsCount} ca
              </span>
              <span className="text-xs font-bold text-slate-700/80 dark:text-orange-200">
                / {venueSlots.length || 32} ca
              </span>
            </div>
            <div className="mt-2 text-xs font-medium text-slate-800/80 dark:text-slate-300">
              {appBookedCount} qua App • {manualBookedCount} tại quầy
            </div>
          </div>
        </div>

        {/* Card 3: Dashed Translucent Add Widget / Court Card */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-white/70 dark:bg-slate-900/60 backdrop-blur-md border-2 border-dashed border-slate-300 dark:border-slate-700 flex flex-col justify-between hover:border-emerald-500/70 dark:hover:border-emerald-500/70 transition-all group cursor-pointer shadow-xs"
          onClick={() => setIsAddCourtModalOpen(true)}
        >
          <div>
            <div className="text-xs text-slate-400 font-medium">
              Bạn có thể tạo thêm tiện ích hoặc sân mới ngay tại đây:
            </div>
            <div className="text-sm font-bold text-slate-800 dark:text-slate-200 mt-1">
              Thêm sân / cụm sân mới
            </div>
          </div>

          <div className="mt-4 flex items-center justify-center">
            <div className="w-12 h-12 rounded-full bg-lime-400/30 dark:bg-lime-500/20 text-lime-600 dark:text-lime-400 border border-lime-400/50 flex items-center justify-center group-hover:scale-110 transition-transform shadow-xs">
              <PlusCircle className="w-6 h-6" />
            </div>
          </div>

          <div className="mt-3 text-center">
            <span className="text-xs font-bold text-slate-700 dark:text-slate-300 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
              + Thêm tiện ích / sân mới
            </span>
          </div>
        </div>

        {/* Card 4: SportHub Partner Pro (Vibrant Orange Card) */}
        <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-br from-[#fb923c] to-[#ea580c] text-white shadow-lg shadow-orange-500/20 hover:-translate-y-1 transition-all group flex flex-col justify-between">
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="text-xs font-semibold text-orange-100 uppercase tracking-wider">
                Gói vận hành
              </div>
              <div className="text-lg font-black tracking-tight">SportHub Partner Pro</div>
            </div>
            <div className="w-8 h-8 rounded-full bg-white/20 backdrop-blur-md flex items-center justify-center group-hover:rotate-45 transition-transform">
              <ArrowUpRight className="w-4 h-4 text-white" />
            </div>
          </div>

          <div className="my-3 flex items-center gap-2">
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/20 text-white backdrop-blur-xs">
              Mới
            </span>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-white/20 text-white backdrop-blur-xs">
              Tự động hóa 100%
            </span>
          </div>

          <div className="pt-2 border-t border-white/20 flex items-center justify-between text-xs text-orange-100">
            <span>Đang kích hoạt</span>
            <span className="font-semibold text-white">Hỗ trợ 24/7</span>
          </div>
        </div>
      </div>

      {/* 3. Middle Section: Spline Bezier Curve Chart & Side Widgets */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Spline Bezier Chart Card (2 Cols) */}
        <div className="lg:col-span-2 glass-card rounded-[28px] p-6 flex flex-col justify-between space-y-4">
          {/* Header & Switcher */}
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
            <div>
              <div className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Biểu đồ tần suất hoạt động
              </div>
              <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
                <span>Phân tích công suất & Giờ cao điểm</span>
              </h2>
            </div>

            {/* Filter Toggle Pill: Ca đặt | Doanh thu */}
            <div className="glass-pill p-1 rounded-full flex items-center gap-1 self-start sm:self-auto">
              <button
                type="button"
                onClick={() => setChartMetric('slots')}
                className={`px-3 py-1 rounded-full text-xs font-bold transition-all ${
                  chartMetric === 'slots'
                    ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                    : 'text-slate-600 dark:text-slate-300 hover:text-slate-900'
                }`}
              >
                Ca đặt
              </button>
              <button
                type="button"
                onClick={() => setChartMetric('revenue')}
                className={`px-3 py-1 rounded-full text-xs font-bold transition-all ${
                  chartMetric === 'revenue'
                    ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                    : 'text-slate-600 dark:text-slate-300 hover:text-slate-900'
                }`}
              >
                Doanh thu
              </button>
            </div>
          </div>

          {/* Days Indicator Row */}
          <div className="grid grid-cols-7 text-center text-xs font-bold text-slate-400 dark:text-slate-500 pt-2 border-b border-slate-100 dark:border-slate-800 pb-2">
            <span>Mon</span>
            <span>Tue</span>
            <span>Wed</span>
            <span>Thu</span>
            <span>Fri</span>
            <span className="text-emerald-600 dark:text-emerald-400 font-extrabold">Sat</span>
            <span className="text-emerald-600 dark:text-emerald-400 font-extrabold">Sun</span>
          </div>

          {/* Interactive Spline Bezier Curve Canvas */}
          <div className="relative w-full h-56 sm:h-64 my-2">
            {/* Background dashed vertical lines */}
            <div className="absolute inset-0 grid grid-cols-7 pointer-events-none">
              {[0, 1, 2, 3, 4, 5, 6].map((i) => (
                <div
                  key={i}
                  className="h-full border-r border-dashed border-slate-200/70 dark:border-slate-800/70 first:border-l"
                />
              ))}
            </div>

            {/* SVG Bezier Curves */}
            <svg
              className="w-full h-full overflow-visible"
              viewBox="0 0 700 240"
              preserveAspectRatio="none"
            >
              <defs>
                <linearGradient id="curveGradOrange" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#f97316" stopOpacity="0.35" />
                  <stop offset="100%" stopColor="#f97316" stopOpacity="0.0" />
                </linearGradient>
                <linearGradient id="curveGradLime" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#84cc16" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#84cc16" stopOpacity="0.0" />
                </linearGradient>
              </defs>

              {/* Area Under Orange Spline */}
              <path
                d="M 50,170 C 110,130 180,185 240,150 C 300,115 370,50 440,70 C 510,90 580,190 650,180 L 650,240 L 50,240 Z"
                fill="url(#curveGradOrange)"
              />

              {/* Area Under Lime Spline */}
              <path
                d="M 50,200 C 130,190 190,130 270,120 C 350,110 420,160 500,140 C 570,120 620,180 650,195 L 650,240 L 50,240 Z"
                fill="url(#curveGradLime)"
              />

              {/* Primary Orange Spline Stroke */}
              <path
                d="M 50,170 C 110,130 180,185 240,150 C 300,115 370,50 440,70 C 510,90 580,190 650,180"
                fill="none"
                stroke="#f97316"
                strokeWidth="3.5"
                strokeLinecap="round"
              />

              {/* Secondary Lime Spline Stroke */}
              <path
                d="M 50,200 C 130,190 190,130 270,120 C 350,110 420,160 500,140 C 570,120 620,180 650,195"
                fill="none"
                stroke="#84cc16"
                strokeWidth="3"
                strokeDasharray="4 4"
                strokeLinecap="round"
              />
            </svg>

            {/* Floating Black Node Badges (Matching "Dashboards V2" style) */}
            {/* Node 1: Mon */}
            <div className="absolute left-[6%] top-[68%] -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-slate-900 dark:bg-black text-white text-[11px] font-black flex items-center justify-center shadow-lg border border-slate-700/60 hover:scale-125 transition-transform cursor-pointer">
              4h
            </div>

            {/* Node 2: Tue */}
            <div className="absolute left-[24%] top-[62%] -translate-x-1/2 -translate-y-1/2 px-2 py-1 rounded-full bg-slate-900 dark:bg-black text-white text-[11px] font-black flex items-center justify-center shadow-lg border border-slate-700/60 hover:scale-125 transition-transform cursor-pointer">
              6 ca
            </div>

            {/* Node 3: Wed */}
            <div className="absolute left-[34%] top-[50%] -translate-x-1/2 -translate-y-1/2 px-2.5 py-1 rounded-full bg-slate-900 dark:bg-black text-white text-[11px] font-black flex items-center justify-center shadow-lg border border-slate-700/60 hover:scale-125 transition-transform cursor-pointer">
              8h
            </div>

            {/* Central Floating Glass Tooltip Modal ("Track time" style) */}
            <div className="absolute left-[62%] top-[25%] -translate-x-1/2 -translate-y-1/2 glass-card rounded-2xl p-3 shadow-xl border border-white/80 dark:border-slate-700 text-center min-w-[140px]">
              <div className="text-[10px] font-bold text-slate-400 uppercase">Khung giờ vàng</div>
              <div className="text-xs font-black text-slate-900 dark:text-white">18:00 - 21:00</div>
              <div className="mt-1 flex items-center justify-center gap-1 bg-slate-100 dark:bg-slate-800 rounded-lg p-0.5 text-[10px]">
                <button
                  type="button"
                  onClick={() => setChartTab('hours')}
                  className={`px-1.5 py-0.5 rounded-md font-bold transition-all ${
                    chartTab === 'hours'
                      ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-xs'
                      : 'text-slate-400'
                  }`}
                >
                  Giờ
                </button>
                <button
                  type="button"
                  onClick={() => setChartTab('minutes')}
                  className={`px-1.5 py-0.5 rounded-md font-bold transition-all ${
                    chartTab === 'minutes'
                      ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-white shadow-xs'
                      : 'text-slate-400'
                  }`}
                >
                  Phút
                </button>
              </div>
            </div>

            {/* Node 4: Fri Peak */}
            <div className="absolute left-[72%] top-[72%] -translate-x-1/2 -translate-y-1/2 px-2.5 py-1 rounded-full bg-slate-900 dark:bg-black text-white text-[11px] font-black flex items-center justify-center shadow-lg border border-slate-700/60 hover:scale-125 transition-transform cursor-pointer">
              12 ca
            </div>

            {/* Node 5: Sun */}
            <div className="absolute left-[92%] top-[74%] -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-slate-900 dark:bg-black text-white text-[11px] font-black flex items-center justify-center shadow-lg border border-slate-700/60 hover:scale-125 transition-transform cursor-pointer">
              1h
            </div>
          </div>

          <div className="flex items-center justify-between text-xs text-slate-400 pt-2 border-t border-slate-100 dark:border-slate-800">
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-orange-500" />
              Đường cong công suất thực tế (Ca đặt)
            </span>
            <span className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-lime-500" />
              Đường trung bình tuần trước
            </span>
          </div>
        </div>

        {/* Right Column: 2 Widgets (Progress & Teamwork/Check-in) */}
        <div className="space-y-6">
          {/* Widget 1: Tỷ lệ lấp đầy theo môn (Lime Progress Theme) */}
          <div className="rounded-[28px] p-6 bg-gradient-to-br from-[#d9f99d]/70 via-[#bef264]/50 to-white/80 dark:from-[#14532d]/40 dark:via-[#166534]/30 dark:to-slate-900/60 border border-lime-300/60 dark:border-lime-700/30 glass-card space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-lime-300">
                  Hiệu suất khai thác
                </div>
                <h3 className="text-base font-black text-slate-900 dark:text-white">
                  Tỷ lệ lấp đầy
                </h3>
              </div>
              <div className="w-8 h-8 rounded-full bg-lime-500/20 text-lime-700 dark:text-lime-300 flex items-center justify-center">
                <Percent className="w-4 h-4" />
              </div>
            </div>

            {/* Pill Progress Bars */}
            <div className="space-y-3">
              {/* Badminton */}
              <div>
                <div className="flex items-center justify-between text-xs font-semibold mb-1 text-slate-700 dark:text-slate-200">
                  <span>Cầu lông ({badmintonCourts.length} sân)</span>
                  <span className="font-bold">{badmintonRate}%</span>
                </div>
                <div className="w-full h-3 rounded-full bg-white/80 dark:bg-slate-800 p-0.5 shadow-inner">
                  <div
                    className="h-full rounded-full bg-lime-500 transition-all"
                    style={{ width: `${badmintonRate}%` }}
                  />
                </div>
              </div>

              {/* Pickleball */}
              <div>
                <div className="flex items-center justify-between text-xs font-semibold mb-1 text-slate-700 dark:text-slate-200">
                  <span>Pickleball ({pickleballCourts.length} sân)</span>
                  <span className="font-bold">{pickleballRate}%</span>
                </div>
                <div className="w-full h-3 rounded-full bg-white/80 dark:bg-slate-800 p-0.5 shadow-inner">
                  <div
                    className="h-full rounded-full bg-lime-500 transition-all"
                    style={{ width: `${pickleballRate}%` }}
                  />
                </div>
              </div>

              {/* Peak Hour */}
              <div>
                <div className="flex items-center justify-between text-xs font-semibold mb-1 text-slate-700 dark:text-slate-200">
                  <span>Khung giờ vàng</span>
                  <span className="font-bold">{occupancyRate}%</span>
                </div>
                <div className="w-full h-3 rounded-full bg-white/80 dark:bg-slate-800 p-0.5 shadow-inner">
                  <div
                    className="h-full rounded-full bg-lime-500 transition-all"
                    style={{ width: `${occupancyRate}%` }}
                  />
                </div>
              </div>
            </div>

            <Link
              to="/partner/revenue"
              className="inline-flex items-center justify-between w-full p-2.5 rounded-2xl bg-white/80 dark:bg-slate-800/80 text-xs font-bold text-slate-800 dark:text-slate-100 hover:bg-white dark:hover:bg-slate-800 transition-all shadow-xs"
            >
              <span>Xem chi tiết hiệu suất</span>
              <ArrowRight className="w-4 h-4 text-lime-600 dark:text-lime-400" />
            </Link>
          </div>

          {/* Widget 2: Quầy soát vé & Check-in (Peach Theme Card) */}
          <div className="rounded-[28px] p-6 bg-gradient-to-br from-[#ffedd5]/70 via-[#fed7aa]/50 to-white/80 dark:from-[#7c2d12]/40 dark:via-[#9a3412]/30 dark:to-slate-900/60 border border-orange-300/60 dark:border-orange-700/30 glass-card space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-slate-600 dark:text-orange-300">
                  Vận hành tại chỗ
                </div>
                <h3 className="text-base font-black text-slate-900 dark:text-white">
                  Khách đã check-in
                </h3>
              </div>
              <div className="w-8 h-8 rounded-full bg-orange-500/20 text-orange-700 dark:text-orange-300 flex items-center justify-center">
                <UserCheck className="w-4 h-4" />
              </div>
            </div>

            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-black text-slate-900 dark:text-white">
                {checkedInCount}
              </span>
              <span className="text-xs font-bold text-slate-500 dark:text-slate-400">
                / {venueBookings.length} khách
              </span>
            </div>

            <div className="text-xs text-slate-600 dark:text-slate-300 flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Soát vé mã QR tại quầy</span>
            </div>

            <div className="pt-2 border-t border-orange-200/60 dark:border-orange-800/60 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-full bg-slate-900 text-white text-[10px] font-bold flex items-center justify-center">
                  TA
                </div>
                <div className="text-[11px] text-slate-600 dark:text-slate-300">
                  NV: <span className="font-bold">Tuấn Anh (Cổng A)</span>
                </div>
              </div>
              <Link
                to="/partner/pos"
                className="px-3 py-1.5 rounded-full bg-orange-500 text-white text-xs font-bold hover:bg-orange-600 transition-colors shadow-xs flex items-center gap-1"
              >
                <QrCode className="w-3.5 h-3.5" />
                <span>Quét vé</span>
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* 4. Bottom Table: "Lịch đặt sân & Trạng thái các cụm sân" (Last notes style) */}
      <div className="glass-card rounded-[28px] p-6 space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
          <div>
            <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
              <span>Lịch đặt sân & Trạng thái {venueCourts.length} cụm sân {currentVenue ? currentVenue.name : 'Tao Đàn'}</span>
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Cập nhật trực tiếp tình trạng vận hành của từng sân thi đấu
            </p>
          </div>

          <div className="flex items-center gap-2">
            <Link
              to="/partner/schedule"
              className="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline flex items-center gap-1"
            >
              Xem ma trận lịch đầy đủ <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Glass Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-200/60 dark:border-slate-800 text-slate-400 uppercase font-bold text-[11px]">
                <th className="py-3 px-3">Cụm sân</th>
                <th className="py-3 px-3">Môn thể thao</th>
                <th className="py-3 px-3">Công suất ngày</th>
                <th className="py-3 px-3">Đơn giá giờ</th>
                <th className="py-3 px-3">Trạng thái hiện tại</th>
                <th className="py-3 px-3 text-right">Tác vụ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
              {filteredCourts.map((court) => {
                const liveStatus = getCourtLiveStatus(court.id);
                return (
                  <tr
                    key={court.id}
                    className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors"
                  >
                    {/* Court Name */}
                    <td className="py-3.5 px-3">
                      <div className="font-bold text-slate-900 dark:text-white">{court.name}</div>
                      <div className="text-[11px] text-slate-400">{court.surfaceType}</div>
                    </td>

                    {/* Sport Badge */}
                    <td className="py-3.5 px-3">
                      <span
                        className={`inline-flex items-center gap-1 text-[11px] font-bold px-2.5 py-1 rounded-full ${
                          court.sport === 'badminton'
                            ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400'
                            : 'bg-amber-500/10 text-amber-600 dark:text-amber-400'
                        }`}
                      >
                        {court.sport === 'badminton' ? '🏸 Cầu lông' : '🏓 Pickleball'}
                      </span>
                    </td>

                    {/* Progress Percentage Pill */}
                    <td className="py-3.5 px-3">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-slate-800 dark:text-slate-200 min-w-[32px]">
                          {liveStatus.percent}%
                        </span>
                        <div className="w-24 h-2 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                          <div
                            className={`h-full rounded-full ${
                              liveStatus.percent >= 80
                                ? 'bg-emerald-500'
                                : liveStatus.percent >= 50
                                ? 'bg-amber-500'
                                : 'bg-slate-400'
                            }`}
                            style={{ width: `${liveStatus.percent}%` }}
                          />
                        </div>
                      </div>
                    </td>

                    {/* Price */}
                    <td className="py-3.5 px-3 text-slate-700 dark:text-slate-300 font-bold">
                      {court.regularPrice.toLocaleString('vi-VN')} đ/h
                    </td>

                    {/* Live Status Badge */}
                    <td className="py-3.5 px-3">
                      <span
                        className={`inline-flex items-center gap-1.5 text-[11px] font-bold px-3 py-1 rounded-full border ${
                          liveStatus.color === 'emerald'
                            ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                            : liveStatus.color === 'amber'
                            ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20'
                            : liveStatus.color === 'rose'
                            ? 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20'
                            : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border-slate-200 dark:border-slate-700'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            liveStatus.color === 'emerald'
                              ? 'bg-emerald-500 animate-pulse'
                              : liveStatus.color === 'amber'
                              ? 'bg-amber-500'
                              : liveStatus.color === 'rose'
                              ? 'bg-rose-500'
                              : 'bg-slate-400'
                          }`}
                        />
                        {liveStatus.label}
                      </span>
                    </td>

                    {/* Action */}
                    <td className="py-3.5 px-3 text-right">
                      <Link
                        to="/partner/schedule"
                        className="px-3 py-1.5 rounded-full bg-slate-100 dark:bg-slate-800 hover:bg-emerald-500 hover:text-white dark:hover:bg-emerald-500 text-slate-700 dark:text-slate-300 text-xs font-bold transition-all shadow-xs"
                      >
                        Lên lịch
                      </Link>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* 5. Bottom Floating Switcher Pill (Matching bottom pill bar in Dashboards V2) */}
      <div className="fixed bottom-5 left-1/2 -translate-x-1/2 z-40">
        <div className="p-1.5 rounded-full bg-slate-900/90 dark:bg-slate-950/90 backdrop-blur-xl border border-white/20 shadow-2xl flex items-center gap-1.5">
          <button
            type="button"
            onClick={() => setDashboardTab('overview')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${
              dashboardTab === 'overview'
                ? 'bg-white text-slate-900 shadow-md scale-105'
                : 'text-slate-300 hover:text-white'
            }`}
          >
            Tổng quan
          </button>
          <Link
            to="/partner/schedule"
            onClick={() => setDashboardTab('courts')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${
              dashboardTab === 'courts'
                ? 'bg-white text-slate-900 shadow-md scale-105'
                : 'text-slate-300 hover:text-white'
            }`}
          >
            Sơ đồ 8 sân
          </Link>
          <Link
            to="/partner/revenue"
            onClick={() => setDashboardTab('revenue')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all ${
              dashboardTab === 'revenue'
                ? 'bg-white text-slate-900 shadow-md scale-105'
                : 'text-slate-300 hover:text-white'
            }`}
          >
            Doanh thu & POS
          </Link>
        </div>
      </div>

      {/* Add Court Modal */}
      <AddCourtModal
        isOpen={isAddCourtModalOpen}
        onClose={() => setIsAddCourtModalOpen(false)}
        venueId={currentVenueId}
      />
    </div>
  );
};

export default PartnerDashboardView;
