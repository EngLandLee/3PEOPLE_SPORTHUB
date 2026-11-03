import React, { useState } from 'react';
import {
  Store,
  Plus,
  Layers,
  Sparkles,
  ToggleLeft,
  ToggleRight,
  Building2,
  Activity,
  CheckCircle2,
} from 'lucide-react';
import { useVenueStore, venueStore } from '../../store/venueStore';
import { useAuthStore } from '../../store/authStore';
import { AddCourtModal } from '../../components/courts/AddCourtModal';

export const CourtsManagementView: React.FC = () => {
  const { courts, venues } = useVenueStore();
  const { activeVenueId } = useAuthStore();
  const currentVenueId = activeVenueId || 'venue_01';
  const currentVenue = venues.find((v) => v.id === currentVenueId) || venues[0];

  const venueCourts = courts.filter((c) => c.venueId === currentVenueId);

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [filterSport, setFilterSport] = useState<'all' | 'badminton' | 'pickleball'>('all');

  const filteredCourts = venueCourts.filter((c) => {
    if (filterSport === 'all') return true;
    return c.sport === filterSport;
  });

  const badmintonCount = venueCourts.filter((c) => c.sport === 'badminton').length;
  const pickleballCount = venueCourts.filter((c) => c.sport === 'pickleball').length;
  const activeCourtsCount = venueCourts.filter((c) => c.isActive).length;

  const handleToggleActive = (courtId: string, currentStatus: boolean) => {
    venueStore.updateCourt(courtId, { isActive: !currentStatus });
  };

  return (
    <div className="space-y-6 pb-12">
      {/* 1. Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <Building2 className="w-3.5 h-3.5" />
              {currentVenue ? currentVenue.name : 'CLB Tao Đàn'}
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Quản lý Sân
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Cấu hình danh sách sân thể thao, loại mặt sân, và bảng giá theo khung giờ.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            data-testid="btn-add-court"
            onClick={() => setIsAddModalOpen(true)}
            className="px-5 py-2.5 rounded-full text-xs font-bold bg-emerald-600 hover:bg-emerald-500 active:scale-95 text-white shadow-lg shadow-emerald-600/20 transition-all flex items-center gap-2 cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Thêm Sân Mới</span>
          </button>
        </div>
      </div>

      {/* 2. 4 Hero KPI Cards with Dashboards V2 Wave Styling */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        {/* KPI 1: Tổng số sân */}
        <div className="relative overflow-hidden rounded-[26px] p-5 bg-gradient-to-br from-[#d9f99d]/80 via-[#bef264]/60 to-white/70 dark:from-[#14532d]/60 dark:via-[#166534]/40 dark:to-slate-900/60 border border-lime-300/60 dark:border-lime-700/40 glass-card">
          <div className="text-xs text-slate-600 dark:text-lime-300 font-bold uppercase tracking-wider">
            Tổng số sân
          </div>
          <div className="mt-2 text-3xl font-black text-slate-950 dark:text-white">
            {venueCourts.length}
          </div>
          <div className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 font-medium">
            Sân thuộc cụm Tao Đàn
          </div>
        </div>

        {/* KPI 2: Đang hoạt động */}
        <div className="relative overflow-hidden rounded-[26px] p-5 bg-gradient-to-br from-[#ffedd5]/80 via-[#fed7aa]/60 to-white/70 dark:from-[#7c2d12]/60 dark:via-[#9a3412]/40 dark:to-slate-900/60 border border-orange-300/60 dark:border-orange-700/40 glass-card">
          <div className="text-xs text-slate-600 dark:text-orange-300 font-bold uppercase tracking-wider">
            Đang hoạt động
          </div>
          <div className="mt-2 text-3xl font-black text-emerald-600 dark:text-emerald-400">
            {activeCourtsCount}
          </div>
          <div className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 font-medium flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3 text-emerald-500" />
            <span>Sẵn sàng nhận khách</span>
          </div>
        </div>

        {/* KPI 3: Sân Cầu Lông */}
        <div className="relative overflow-hidden rounded-[26px] p-5 bg-gradient-to-br from-blue-100/80 via-sky-100/60 to-white/70 dark:from-blue-950/60 dark:via-sky-950/40 dark:to-slate-900/60 border border-blue-300/60 dark:border-blue-700/40 glass-card">
          <div className="text-xs text-blue-700 dark:text-blue-300 font-bold uppercase tracking-wider">
            Sân Cầu Lông
          </div>
          <div className="mt-2 text-3xl font-black text-blue-700 dark:text-blue-400">
            {badmintonCount}
          </div>
          <div className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 font-medium">
            Thảm Yonex chuẩn BWF
          </div>
        </div>

        {/* KPI 4: Sân Pickleball */}
        <div className="relative overflow-hidden rounded-[26px] p-5 bg-gradient-to-br from-amber-100/80 via-orange-100/60 to-white/70 dark:from-amber-950/60 dark:via-orange-950/40 dark:to-slate-900/60 border border-amber-300/60 dark:border-amber-700/40 glass-card">
          <div className="text-xs text-amber-700 dark:text-amber-300 font-bold uppercase tracking-wider">
            Sân Pickleball
          </div>
          <div className="mt-2 text-3xl font-black text-amber-700 dark:text-amber-400">
            {pickleballCount}
          </div>
          <div className="text-[11px] text-slate-500 dark:text-slate-400 mt-1 font-medium">
            Sơn Acrylic US Open
          </div>
        </div>
      </div>

      {/* 3. Filter Pills */}
      <div className="flex items-center justify-between gap-4">
        <div className="glass-pill p-1 rounded-full flex items-center gap-1">
          <button
            type="button"
            onClick={() => setFilterSport('all')}
            className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
              filterSport === 'all'
                ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            Tất cả ({venueCourts.length})
          </button>
          <button
            type="button"
            onClick={() => setFilterSport('badminton')}
            className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
              filterSport === 'badminton'
                ? 'bg-blue-600 text-white shadow-xs'
                : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            🏸 Cầu lông ({badmintonCount})
          </button>
          <button
            type="button"
            onClick={() => setFilterSport('pickleball')}
            className={`px-4 py-1.5 text-xs font-bold rounded-full transition-all ${
              filterSport === 'pickleball'
                ? 'bg-amber-600 text-white shadow-xs'
                : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            🏓 Pickleball ({pickleballCount})
          </button>
        </div>

        <span className="text-xs text-slate-400 hidden sm:inline font-semibold">
          Hiển thị {filteredCourts.length} sân
        </span>
      </div>

      {/* 4. Courts Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {filteredCourts.map((court) => (
          <div
            key={court.id}
            className={`p-5 rounded-[28px] glass-card transition-all flex flex-col justify-between hover:-translate-y-1 ${
              court.isActive
                ? 'border border-white/70 dark:border-slate-800'
                : 'opacity-70 border-slate-300 dark:border-slate-800'
            }`}
          >
            <div>
              {/* Header inside card */}
              <div className="flex items-start justify-between gap-2 mb-3">
                <div>
                  <span
                    className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                      court.sport === 'badminton'
                        ? 'bg-blue-500/10 text-blue-600 dark:text-blue-400 border border-blue-500/20'
                        : 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border border-amber-500/20'
                    }`}
                  >
                    {court.sport === 'badminton' ? '🏸 Cầu lông' : court.sport === 'pickleball' ? '🏓 Pickleball' : court.sport}
                  </span>
                  <h3 className="text-base font-black text-slate-900 dark:text-white mt-2 line-clamp-1">
                    {court.name}
                  </h3>
                </div>

                <button
                  type="button"
                  onClick={() => handleToggleActive(court.id, court.isActive)}
                  title={court.isActive ? 'Tạm ngưng hoạt động' : 'Kích hoạt sân'}
                  className="cursor-pointer hover:scale-110 transition-transform"
                >
                  {court.isActive ? (
                    <ToggleRight className="w-7 h-7 text-emerald-500" />
                  ) : (
                    <ToggleLeft className="w-7 h-7 text-slate-400" />
                  )}
                </button>
              </div>

              {/* Surface & Facility Details */}
              <div className="space-y-2 py-3 border-y border-slate-100 dark:border-slate-800/80 text-xs">
                <div className="flex items-center justify-between text-slate-500 dark:text-slate-400">
                  <span className="flex items-center gap-1.5">
                    <Layers className="w-3.5 h-3.5 text-slate-400" />
                    Mặt sân:
                  </span>
                  <span className="font-bold text-slate-800 dark:text-slate-200 truncate max-w-[140px]">
                    {court.surfaceType}
                  </span>
                </div>

                <div className="flex items-center justify-between text-slate-500 dark:text-slate-400">
                  <span className="flex items-center gap-1.5">
                    <Store className="w-3.5 h-3.5 text-slate-400" />
                    Khu vực:
                  </span>
                  <span className="font-bold text-slate-800 dark:text-slate-200">
                    {court.facilityType === 'indoor' ? 'Trong nhà' : 'Ngoài trời'}
                  </span>
                </div>

                <div className="flex items-center justify-between text-slate-500 dark:text-slate-400">
                  <span className="flex items-center gap-1.5">
                    <Activity className="w-3.5 h-3.5 text-slate-400" />
                    Trạng thái:
                  </span>
                  <span
                    className={`font-bold ${
                      court.isActive
                        ? 'text-emerald-600 dark:text-emerald-400'
                        : 'text-slate-400'
                    }`}
                  >
                    {court.isActive ? 'Đang hoạt động' : 'Tạm dừng'}
                  </span>
                </div>
              </div>
            </div>

            {/* Pricing Footer */}
            <div className="pt-3 mt-3 space-y-1.5">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400 font-medium">Giờ thường:</span>
                <span className="font-bold text-slate-800 dark:text-slate-100">
                  {court.regularPrice.toLocaleString('vi-VN')} đ/h
                </span>
              </div>
              <div className="flex items-center justify-between text-xs">
                <span className="text-amber-500 font-bold flex items-center gap-1">
                  <Sparkles className="w-3 h-3" />
                  Giờ cao điểm:
                </span>
                <span className="font-black text-amber-600 dark:text-amber-400">
                  {court.peakPrice.toLocaleString('vi-VN')} đ/h
                </span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Add Court Modal */}
      <AddCourtModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        venueId={currentVenueId}
      />
    </div>
  );
};

export default CourtsManagementView;
