import React, { useState } from 'react';
import {
  Building2,
  Calendar,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';
import { useAuthStore } from '../../store/authStore';
import { SlotActionModal } from '../../components/schedule/SlotActionModal';
import { CourtSlot } from '../../types';
import { getTodayDateString } from '../../store/seedData';

type SportFilter = 'all' | 'badminton' | 'pickleball';
type ShiftFilter = 'all' | 'morning' | 'afternoon' | 'evening';

const HOURS = Array.from({ length: 16 }, (_, i) => i + 6); // 6 to 21

const getFormattedVietnameseDate = (dateStr: string) => {
  try {
    const [y, m, d] = dateStr.split('-').map(Number);
    const dateObj = new Date(y, m - 1, d);
    const dayOfWeek = dateObj.getDay();
    const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
    const pad = (n: number) => String(n).padStart(2, '0');
    return `${days[dayOfWeek]}, ${pad(d)}/${pad(m)}/${y}`;
  } catch {
    return dateStr;
  }
};

export const ScheduleMatrixView: React.FC = () => {
  const { courts, slots, venues, bookings } = useVenueStore();
  const { activeVenueId } = useAuthStore();
  const currentVenueId = activeVenueId || 'venue_01';
  const currentVenue = venues.find((v) => v.id === currentVenueId) || venues[0];

  const venueCourts = courts.filter((c) => c.venueId === currentVenueId);

  const [sportFilter, setSportFilter] = useState<SportFilter>('all');
  const [shiftFilter, setShiftFilter] = useState<ShiftFilter>('all');
  const [selectedDate, setSelectedDate] = useState<string>(() => getTodayDateString(0));
  const [activeSlotId, setActiveSlotId] = useState<string | null>(null);

  // Filtered courts based on sport
  const displayedCourts = venueCourts.filter((c) => {
    if (sportFilter === 'badminton') return c.sport === 'badminton';
    if (sportFilter === 'pickleball') return c.sport === 'pickleball';
    return true;
  });

  // Filtered hours based on shift
  const displayedHours = HOURS.filter((hour) => {
    if (shiftFilter === 'morning') return hour >= 6 && hour < 12;
    if (shiftFilter === 'afternoon') return hour >= 12 && hour < 17;
    if (shiftFilter === 'evening') return hour >= 17 && hour < 22;
    return true;
  });

  // Map slots by slotId for O(1) lookup
  const slotMap = new Map<string, CourtSlot>();
  slots.forEach((s) => {
    if (s.venueId === currentVenueId && (!s.date || s.date === selectedDate)) {
      slotMap.set(s.id, s);
    }
  });

  // Dynamically overlay confirmed bookings for selectedDate & currentVenueId
  bookings.forEach((b) => {
    const isVenueMatch =
      b.venueId === currentVenueId ||
      (currentVenueId === 'venue_01' && (b.venueId === 'venue_q1_04' || b.venueName?.includes('Tao Đàn')));

    const isDateMatch =
      Boolean(b.date && (b.date === selectedDate || b.date.split('T')[0] === selectedDate));

    if (isVenueMatch && isDateMatch && b.paymentStatus !== 'cancelled') {
      const courtNumber = (b as any).courtNumber || (b.courtName ? parseInt(b.courtName.replace(/\D/g, ''), 10) : 1);
      const court =
        venueCourts.find((c) => c.id === b.courtId) ||
        venueCourts.find((c) => (courtNumber && c.name.includes(String(courtNumber))) || (courtNumber && c.id === `court_0${courtNumber}`));

      const courtId = court ? court.id : (b.courtId || `court_0${courtNumber || 1}`);
      const rawStart = b.startTime || b.timeSlot?.split(' - ')[0] || '19:00';
      const startHourStr = rawStart.split(':')[0].padStart(2, '0');
      const rawEnd = b.endTime || b.timeSlot?.split(' - ')[1] || `${(parseInt(startHourStr, 10) + 1).toString().padStart(2, '0')}:00`;

      const startH = parseInt(startHourStr, 10) || 19;
      const endH = parseInt(rawEnd.split(':')[0], 10) || (startH + 1);

      for (let h = startH; h < endH; h++) {
        const curHourStr = h.toString().padStart(2, '0');
        const nextHourStr = (h + 1).toString().padStart(2, '0');
        const curSlotId = `${courtId}_${curHourStr}_00`;
        const existingSlot = slotMap.get(curSlotId);
        const isPeak = h >= 17 && h < 21;

        slotMap.set(curSlotId, {
          id: curSlotId,
          courtId,
          courtName: court ? court.name : b.courtName,
          venueId: currentVenueId,
          date: selectedDate,
          startTime: `${curHourStr}:00`,
          endTime: `${nextHourStr}:00`,
          price: b.price || (court ? (isPeak ? court.peakPrice : court.regularPrice) : 180000),
          isPeak,
          status: 'bookedApp',
          ticketId: b.id,
          customerName: b.customerName,
          customerPhone: b.customerPhone,
          note: existingSlot?.note,
        });
      }
    }
  });

  const activeSlot = activeSlotId ? slotMap.get(activeSlotId) || null : null;

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <Building2 className="w-3.5 h-3.5" />
              {currentVenue ? currentVenue.name : 'CLB Tao Đàn'}
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Lịch Sân Master
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Ma trận lịch sân 16 khung giờ trực quan với tính năng đặt lịch và khóa bảo trì.
          </p>
        </div>

        {/* Date Selector & Realtime Summary */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <div className="flex items-center gap-1 glass-pill p-1 rounded-full">
            <button
              type="button"
              onClick={() => setSelectedDate(getTodayDateString(0))}
              className={`px-3 py-1.5 text-xs font-bold rounded-full transition-all ${
                selectedDate === getTodayDateString(0)
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Hôm nay
            </button>
            <button
              type="button"
              onClick={() => setSelectedDate(getTodayDateString(1))}
              className={`px-3 py-1.5 text-xs font-bold rounded-full transition-all ${
                selectedDate === getTodayDateString(1)
                  ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Ngày mai
            </button>
          </div>

          <label className="glass-pill flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-bold text-slate-700 dark:text-slate-200 shadow-xs cursor-pointer hover:border-emerald-500/50 transition-colors">
            <Calendar className="w-4 h-4 text-emerald-500 shrink-0" />
            <span>{getFormattedVietnameseDate(selectedDate)}</span>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => e.target.value && setSelectedDate(e.target.value)}
              className="sr-only"
              title="Chọn ngày"
            />
          </label>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 p-4 rounded-[28px] glass-card shadow-xs">
        {/* Sport Filter Tabs */}
        <div className="flex items-center gap-2">
          <span className="text-[11px] font-extrabold text-slate-400 uppercase tracking-wider hidden sm:inline mr-1">
            Môn:
          </span>
          <div className="glass-pill p-1 rounded-full flex items-center gap-1">
            <button
              type="button"
              onClick={() => setSportFilter('all')}
              className={`px-3.5 py-1.5 text-xs font-bold rounded-full transition-all ${
                sportFilter === 'all'
                  ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Tất cả
            </button>
            <button
              type="button"
              onClick={() => setSportFilter('badminton')}
              className={`px-3.5 py-1.5 text-xs font-bold rounded-full transition-all ${
                sportFilter === 'badminton'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              🏸 Cầu Lông 1-4
            </button>
            <button
              type="button"
              onClick={() => setSportFilter('pickleball')}
              className={`px-3.5 py-1.5 text-xs font-bold rounded-full transition-all ${
                sportFilter === 'pickleball'
                  ? 'bg-amber-600 text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              🏓 Pickleball 5-8
            </button>
          </div>
        </div>

        {/* Shift Filter Chips */}
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[11px] font-extrabold text-slate-400 uppercase tracking-wider hidden sm:inline mr-1">
            Ca thi đấu:
          </span>
          <div className="glass-pill p-1 rounded-full flex items-center gap-1">
            <button
              type="button"
              onClick={() => setShiftFilter('all')}
              className={`px-3 py-1 text-xs font-bold rounded-full transition-all ${
                shiftFilter === 'all'
                  ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Tất cả
            </button>
            <button
              type="button"
              onClick={() => setShiftFilter('morning')}
              className={`px-3 py-1 text-xs font-bold rounded-full transition-all ${
                shiftFilter === 'morning'
                  ? 'bg-emerald-600 text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Sáng 06-12h
            </button>
            <button
              type="button"
              onClick={() => setShiftFilter('afternoon')}
              className={`px-3 py-1 text-xs font-bold rounded-full transition-all ${
                shiftFilter === 'afternoon'
                  ? 'bg-amber-600 text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Chiều 12-17h
            </button>
            <button
              type="button"
              onClick={() => setShiftFilter('evening')}
              className={`px-3 py-1 text-xs font-bold rounded-full transition-all ${
                shiftFilter === 'evening'
                  ? 'bg-purple-600 text-white shadow-xs'
                  : 'text-slate-500 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
              }`}
            >
              Tối 17-22h
            </button>
          </div>
        </div>

        {/* Legend */}
        <div className="flex items-center gap-3 text-[11px] text-slate-500 dark:text-slate-400 flex-wrap">
          <span className="flex items-center gap-1.5 font-medium">
            <span className="w-2.5 h-2.5 rounded-full bg-slate-200 dark:bg-slate-700 border border-slate-300 dark:border-slate-600" />
            Trống
          </span>
          <span className="flex items-center gap-1.5 font-medium">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 animate-pulse" />
            Đặt qua App
          </span>
          <span className="flex items-center gap-1.5 font-medium">
            <span className="w-2.5 h-2.5 rounded-full bg-amber-500" />
            Giữ chỗ thủ công
          </span>
          <span className="flex items-center gap-1.5 font-medium">
            <span className="w-2.5 h-2.5 rounded-full bg-rose-500" />
            Khóa bảo trì
          </span>
        </div>
      </div>

      {/* 16h x 8 Courts High-Density Matrix Table */}
      <div className="glass-card rounded-[28px] overflow-hidden">
        <div className="overflow-x-auto">
          <table
            role="grid"
            aria-label="Ma trận lịch sân 16 khung giờ"
            className="w-full border-collapse text-left min-w-[950px]"
          >
            <thead>
              <tr
                role="row"
                className="border-b border-slate-200/60 dark:border-slate-800/60 bg-slate-50/60 dark:bg-slate-900/60 backdrop-blur-md"
              >
                <th
                  scope="col"
                  role="columnheader"
                  className="py-3 px-3 w-28 text-center text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 border-r border-slate-200/60 dark:border-slate-800/60 sticky left-0 bg-white/90 dark:bg-[#111827]/90 z-10 backdrop-blur-md"
                >
                  Khung giờ
                </th>
                {displayedCourts.map((court, colIdx) => (
                  <th
                    key={court.id}
                    scope="col"
                    role="columnheader"
                    aria-colindex={colIdx + 2}
                    className="py-3 px-3 text-center border-r border-slate-200/60 dark:border-slate-800/60 last:border-r-0 min-w-[125px]"
                  >
                    <div className="text-xs font-bold text-slate-900 dark:text-white">
                      {court.name}
                    </div>
                    <div className="text-[11px] text-slate-500 dark:text-slate-400 uppercase font-semibold">
                      {court.sport === 'badminton' ? 'Cầu lông' : 'Pickleball'}
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100/70 dark:divide-slate-800/60">
              {displayedHours.map((hour, rowIdx) => {
                const hourStr = hour.toString().padStart(2, '0');
                const nextHourStr = (hour + 1).toString().padStart(2, '0');
                const isPeak = hour >= 17 && hour < 21;

                return (
                  <tr
                    key={hour}
                    role="row"
                    aria-rowindex={rowIdx + 1}
                    className="hover:bg-slate-50/40 dark:hover:bg-slate-800/20 transition-colors"
                  >
                    {/* Time Column Header */}
                    <td className="py-2 px-3 text-center border-r border-slate-200/60 dark:border-slate-800/60 sticky left-0 bg-white/90 dark:bg-[#111827]/90 z-10 font-mono text-xs font-bold text-slate-700 dark:text-slate-300 backdrop-blur-md">
                      <div>{hourStr}:00</div>
                      <div className="text-[11px] text-slate-500 dark:text-slate-400 font-normal">
                        {hourStr}:00 - {nextHourStr}:00
                      </div>
                      {isPeak && (
                        <span className="inline-block mt-0.5 px-1.5 py-0.5 rounded text-[10px] font-bold bg-amber-500/15 text-amber-700 dark:text-amber-400 border border-amber-500/30">
                          Giờ Vàng
                        </span>
                      )}
                    </td>

                    {/* Court Slots for this Hour */}
                    {displayedCourts.map((court, colIdx) => {
                      const slotId = `${court.id}_${hourStr}_00`;
                      const slot = slotMap.get(slotId) || {
                        id: slotId,
                        courtId: court.id,
                        courtName: court.name,
                        venueId: court.venueId,
                        date: selectedDate,
                        startTime: `${hourStr}:00`,
                        endTime: `${nextHourStr}:00`,
                        price: isPeak ? court.peakPrice : court.regularPrice,
                        isPeak,
                        status: 'available' as const,
                      };

                      const statusText =
                        slot.status === 'bookedApp'
                          ? 'Đã đặt qua App'
                          : slot.status === 'reservedManual'
                          ? `Giữ chỗ tại quầy (${slot.customerName || 'Khách'})`
                          : slot.status === 'maintenance'
                          ? 'Bảo trì khóa sân'
                          : 'Còn trống';

                      const slotAriaLabel = `${court.name}, khung giờ ${hourStr}:00 đến ${nextHourStr}:00, trạng thái: ${statusText}, giá: ${slot.price.toLocaleString('vi-VN')} đồng`;

                      return (
                        <td
                          key={court.id}
                          role="gridcell"
                          aria-colindex={colIdx + 2}
                          className="p-1 border-r border-slate-200/50 dark:border-slate-800/50 last:border-r-0"
                        >
                          <button
                            type="button"
                            data-testid={`slot-cell-${slot.id}`}
                            aria-label={slotAriaLabel}
                            onClick={() => setActiveSlotId(slot.id)}
                            className={`w-full h-14 p-1.5 rounded-xl text-left text-xs transition-all duration-150 border flex flex-col justify-between overflow-hidden cursor-pointer focus:outline-none focus:ring-2 focus:ring-emerald-500 hover:scale-[1.02] active:scale-[0.98] ${
                              slot.status === 'bookedApp'
                                ? 'bg-emerald-500/15 hover:bg-emerald-500/25 border-emerald-500/40 text-emerald-950 dark:text-emerald-200 shadow-xs backdrop-blur-xs'
                                : slot.status === 'reservedManual'
                                ? 'bg-amber-500/15 hover:bg-amber-500/25 border-amber-500/40 text-amber-950 dark:text-amber-200 shadow-xs backdrop-blur-xs'
                                : slot.status === 'maintenance'
                                ? 'bg-rose-500/15 hover:bg-rose-500/25 border-rose-500/40 text-rose-950 dark:text-rose-200 border-dashed backdrop-blur-xs'
                                : 'bg-white/40 hover:bg-emerald-500/15 dark:bg-slate-900/40 dark:hover:bg-slate-800/80 border-slate-200/70 dark:border-slate-800 hover:border-emerald-500/40 backdrop-blur-xs'
                            }`}
                          >
                            {/* Top row in cell */}
                            <div className="flex items-center justify-between gap-1 w-full">
                              {slot.status === 'bookedApp' && (
                                <>
                                  <span className="font-mono font-bold text-[11px] text-emerald-700 dark:text-emerald-300 truncate">
                                    {slot.ticketId || 'APP'}
                                  </span>
                                  <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-emerald-500/20 text-emerald-700 dark:text-emerald-300 uppercase shrink-0">
                                    App
                                  </span>
                                </>
                              )}

                              {slot.status === 'reservedManual' && (
                                <>
                                  <span className="font-bold text-[11px] text-amber-700 dark:text-amber-300 truncate">
                                    {slot.customerName || 'Giữ chỗ'}
                                  </span>
                                  <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-700 dark:text-amber-300 uppercase shrink-0">
                                    Quầy
                                  </span>
                                </>
                              )}

                              {slot.status === 'maintenance' && (
                                <>
                                  <span className="font-bold text-[11px] text-rose-700 dark:text-rose-300 truncate">
                                    Bảo trì
                                  </span>
                                  <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-rose-500/20 text-rose-700 dark:text-rose-300 uppercase shrink-0">
                                    Khóa
                                  </span>
                                </>
                              )}

                              {slot.status === 'available' && (
                                <>
                                  <span className="text-[11px] font-semibold text-slate-600 dark:text-slate-400">
                                    Trống
                                  </span>
                                  {slot.isPeak && (
                                    <span className="text-[10px] font-bold text-amber-600 dark:text-amber-400 shrink-0">
                                      ★
                                    </span>
                                  )}
                                </>
                              )}
                            </div>

                            {/* Bottom row in cell */}
                            <div className="flex items-center justify-between gap-1 w-full text-[11px]">
                              {slot.status === 'bookedApp' ? (
                                <span className="text-slate-700 dark:text-slate-300 truncate font-medium">
                                  {slot.customerName}
                                </span>
                              ) : slot.status === 'reservedManual' ? (
                                <span className="text-slate-700 dark:text-slate-300 truncate font-medium">
                                  {slot.customerPhone || 'Tại quầy'}
                                </span>
                              ) : slot.status === 'maintenance' ? (
                                <span className="text-rose-700 dark:text-rose-400 truncate italic">
                                  {slot.note || 'Bảo dưỡng'}
                                </span>
                              ) : (
                                <span className="font-bold text-slate-700 dark:text-slate-300">
                                  {(slot.price / 1000).toLocaleString('vi-VN')}k
                                </span>
                              )}
                            </div>
                          </button>
                        </td>
                      );
                    })}
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Slot Action Modal */}
      <SlotActionModal
        slot={activeSlot}
        isOpen={Boolean(activeSlot)}
        onClose={() => setActiveSlotId(null)}
      />
    </div>
  );
};

export default ScheduleMatrixView;
