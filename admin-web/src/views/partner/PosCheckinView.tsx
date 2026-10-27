import React, { useState, useRef } from 'react';
import {
  QrCode,
  Search,
  CheckCircle2,
  Clock,
  ShoppingBag,
  Plus,
  Minus,
  RotateCcw,
  Check,
  AlertCircle,
  Sparkles,
  CreditCard,
  X,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';
import { useAuthStore } from '../../store/authStore';

const POS_PRODUCTS = [
  {
    id: 'pocari',
    name: 'Nước Pocari Sweat 500ml',
    price: 20000,
    category: 'Nước giải khát',
    testIdInc: 'btn-inc-pocari',
    testIdDec: 'btn-dec-pocari',
  },
  {
    id: 'water',
    name: 'Nước suối Aquafina 500ml',
    price: 10000,
    category: 'Nước giải khát',
    testIdInc: 'btn-inc-water',
    testIdDec: 'btn-dec-water',
  },
  {
    id: 'revive',
    name: 'Nước Revive Chanh Muối 500ml',
    price: 18000,
    category: 'Nước giải khát',
    testIdInc: 'btn-inc-revive',
    testIdDec: 'btn-dec-revive',
  },
  {
    id: 'racket',
    name: 'Thuê vợt thi đấu cao cấp',
    price: 50000,
    category: 'Dịch vụ thuê',
    testIdInc: 'btn-inc-racket',
    testIdDec: 'btn-dec-racket',
  },
  {
    id: 'balls',
    name: 'Hộp bóng Pickleball Franklin',
    price: 60000,
    category: 'Phụ kiện',
    testIdInc: 'btn-inc-balls',
    testIdDec: 'btn-dec-balls',
  },
];

export const PosCheckinView: React.FC = () => {
  const { bookings, checkInTicket, isCheckedIn, recordTransaction, venues } = useVenueStore();
  const { activeVenueId } = useAuthStore();
  const currentVenueId = activeVenueId || 'venue_01';
  const currentVenue = venues.find((v) => v.id === currentVenueId) || venues[0];

  const venueBookings = bookings.filter((b) => b.venueId === currentVenueId);

  // Rapid Check-in State
  const [ticketInput, setTicketInput] = useState('');
  const [toastMessage, setToastMessage] = useState<{
    type: 'success' | 'error';
    text: string;
  } | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  // POS Cart State
  const [cart, setCart] = useState<Record<string, number>>({});
  const [checkoutNotice, setCheckoutNotice] = useState<string | null>(null);

  // Handle Rapid Check-in
  const handleCheckIn = (codeToProcess?: string) => {
    const code = (codeToProcess || ticketInput).trim().toUpperCase();
    if (!code) return;

    const success = checkInTicket(code);
    if (success) {
      setToastMessage({
        type: 'success',
        text: `Check-in thành công vé ${code}`,
      });
      setTicketInput('');
      inputRef.current?.focus();
    } else {
      setToastMessage({
        type: 'error',
        text: `Không tìm thấy mã vé ${code} hoặc vé không hợp lệ`,
      });
      inputRef.current?.focus();
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      handleCheckIn();
    }
  };

  // 1-Click Check-in from List
  const handleTableCheckIn = (ticketId: string) => {
    handleCheckIn(ticketId);
  };

  // POS Cart Actions
  const incrementItem = (productId: string) => {
    setCart((prev) => ({
      ...prev,
      [productId]: (prev[productId] || 0) + 1,
    }));
    setCheckoutNotice(null);
  };

  const decrementItem = (productId: string) => {
    setCart((prev) => {
      const currentQty = prev[productId] || 0;
      if (currentQty <= 1) {
        const next = { ...prev };
        delete next[productId];
        return next;
      }
      return {
        ...prev,
        [productId]: currentQty - 1,
      };
    });
    setCheckoutNotice(null);
  };

  const resetCart = () => {
    setCart({});
    setCheckoutNotice(null);
  };

  // Calculate bill total
  const billTotal = Object.entries(cart).reduce((sum, [id, qty]) => {
    const product = POS_PRODUCTS.find((p) => p.id === id);
    return sum + (product ? product.price * qty : 0);
  }, 0);

  const cartItemsCount = Object.values(cart).reduce((sum, q) => sum + q, 0);

  const handleCheckout = () => {
    if (billTotal === 0) return;

    const itemsSummary = Object.entries(cart)
      .map(([id, qty]) => {
        const product = POS_PRODUCTS.find((p) => p.id === id);
        return `${product?.name || id} x${qty}`;
      })
      .join(', ');

    // Record transaction in store
    recordTransaction({
      venueId: currentVenueId,
      type: 'pos_service',
      description: `Bán lẻ quầy: ${itemsSummary}`,
      amount: billTotal,
      paymentMethod: 'cash',
      customerName: 'Khách thanh toán tại quầy',
      status: 'completed',
    });

    const amountFormatted = billTotal.toLocaleString('vi-VN');
    setCart({});
    setCheckoutNotice(`Thanh toán thành công ${amountFormatted} đ cho đơn hàng POS!`);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              {currentVenue ? currentVenue.name : 'CLB Tao Đàn'}
            </span>
            <span className="text-xs text-slate-400">• Bàn trực tiếp tân</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Quầy Lễ Tân & Soát Vé
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Soát vé bằng mã QR/Ticket ID, bán nước & phụ kiện thể thao, lập hóa đơn tức thì.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="glass-pill text-xs px-3.5 py-1.5 rounded-full font-bold text-slate-700 dark:text-slate-300 shadow-xs">
            Hôm nay: <span className="text-emerald-600 dark:text-emerald-400 font-black">{venueBookings.length}</span> lượt khách
          </div>
        </div>
      </div>

      {/* Toast Alert Banner */}
      {toastMessage && (
        <div
          role="status"
          className={`p-4 rounded-[22px] glass-card flex items-center justify-between gap-3 shadow-md transition-all ${
            toastMessage.type === 'success'
              ? 'bg-emerald-50/80 dark:bg-emerald-950/50 border border-emerald-500/30 text-emerald-800 dark:text-emerald-200'
              : 'bg-rose-50/80 dark:bg-rose-950/50 border border-rose-500/30 text-rose-800 dark:text-rose-200'
          }`}
        >
          <div className="flex items-center gap-3">
            {toastMessage.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400 shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-600 dark:text-rose-400 shrink-0" />
            )}
            <span className="text-xs font-bold">{toastMessage.text}</span>
          </div>
          <button
            type="button"
            onClick={() => setToastMessage(null)}
            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Checkout Success Notice */}
      {checkoutNotice && (
        <div
          role="status"
          className="p-4 rounded-[22px] glass-card bg-cyan-50/80 dark:bg-cyan-950/50 border border-cyan-500/30 text-cyan-800 dark:text-cyan-200 flex items-center justify-between gap-3 shadow-md"
        >
          <div className="flex items-center gap-3">
            <Sparkles className="w-5 h-5 text-cyan-600 dark:text-cyan-400 shrink-0" />
            <span className="text-xs font-bold">{checkoutNotice}</span>
          </div>
          <button
            type="button"
            onClick={() => setCheckoutNotice(null)}
            className="text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Rapid QR / Barcode Check-in Bar with Wave Styling */}
      <div className="relative overflow-hidden rounded-[28px] p-6 bg-gradient-to-r from-emerald-500/15 via-teal-500/10 to-blue-500/15 dark:from-emerald-950/40 dark:via-teal-950/30 dark:to-blue-950/40 border border-emerald-500/30 shadow-lg shadow-emerald-500/5 glass-card">
        <div className="max-w-3xl relative z-10">
          <label
            htmlFor="rapid-checkin-input"
            className="block text-sm font-black text-slate-900 dark:text-white mb-1.5 flex items-center gap-2"
          >
            <QrCode className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
            Soát vé siêu tốc (Mã vé hoặc Quét máy Barcode / QR)
          </label>
          <p className="text-xs text-slate-500 dark:text-slate-400 mb-4 font-medium">
            Quét mã vạch từ ứng dụng SportHub của người chơi hoặc nhập mã vé dạng BK-XXXX / SH-XXXX và ấn Enter.
          </p>

          <div className="flex flex-col sm:flex-row items-stretch gap-3">
            <div className="relative flex-1">
              <div className="glass-pill flex items-center gap-2 px-4 py-3 rounded-2xl focus-within:ring-2 focus-within:ring-emerald-500/40">
                <Search className="w-4 h-4 text-slate-400 shrink-0" />
                <input
                  id="rapid-checkin-input"
                  ref={inputRef}
                  autoFocus
                  type="text"
                  value={ticketInput}
                  onChange={(e) => setTicketInput(e.target.value)}
                  onKeyDown={handleKeyDown}
                  placeholder="Nhập mã vé hoặc quét QR (ví dụ: BK-20260907-312 hoặc SH-8291)..."
                  className="w-full bg-transparent text-slate-900 dark:text-white font-mono text-xs font-semibold placeholder-slate-400 focus:outline-hidden"
                />
              </div>
            </div>
            <button
              type="button"
              data-testid="btn-rapid-checkin"
              onClick={() => handleCheckIn()}
              className="glass-pill px-6 py-3 rounded-2xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-md hover:shadow-lg transition-all flex items-center justify-center gap-2 shrink-0 cursor-pointer"
            >
              <CheckCircle2 className="w-4 h-4" />
              Check-in ngay
            </button>
          </div>
        </div>
      </div>

      {/* Main Split: Today's Arrivals Table (Left 60%) & Add-on POS Counter (Right 40%) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        {/* Left Column: Today's Arrivals Table */}
        <div className="lg:col-span-7 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <Clock className="w-5 h-5 text-emerald-500" />
                Danh Sách Khách Đến Hôm Nay
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Toàn bộ ca đặt sân trong ngày từ ứng dụng và quầy
              </p>
            </div>
            <span className="text-xs font-semibold px-2.5 py-1 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
              {venueBookings.filter((b) => b.checkedIn).length} / {venueBookings.length} đã vào sân
            </span>
          </div>

          <div className="rounded-[28px] glass-card overflow-hidden p-2">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="border-b border-slate-200/60 dark:border-slate-800 text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                  <tr>
                    <th className="py-3.5 px-4">Mã Vé</th>
                    <th className="py-3.5 px-4">Khách Hàng</th>
                    <th className="py-3.5 px-4">Sân & Giờ</th>
                    <th className="py-3.5 px-4">Trạng Thái</th>
                    <th className="py-3.5 px-4 text-right">Thao Tác</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 font-medium">
                  {venueBookings.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="py-12 text-center text-slate-400 text-xs">
                        Không có lượt đặt sân nào trong hôm nay
                      </td>
                    </tr>
                  ) : (
                    venueBookings.map((ticket) => {
                      const checked = isCheckedIn(ticket.id) || ticket.checkedIn;
                      return (
                        <tr
                          key={ticket.id}
                          className="hover:bg-slate-50/50 dark:hover:bg-slate-800/30 transition-colors"
                        >
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span className="font-mono font-bold text-xs text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-950/40 px-2.5 py-1 rounded-full border border-emerald-500/20 whitespace-nowrap inline-block">
                              {ticket.id}
                            </span>
                          </td>
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <div className="font-bold text-slate-900 dark:text-white">
                              {ticket.customerName}
                            </div>
                            <div className="text-[11px] text-slate-400">{ticket.customerPhone}</div>
                          </td>
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <div className="font-semibold text-slate-800 dark:text-slate-200">
                              {ticket.courtName}
                            </div>
                            <div className="text-[11px] text-slate-400 flex items-center gap-1">
                              <Clock className="w-3 h-3" />
                              {ticket.timeSlot}
                            </div>
                          </td>
                          <td className="py-3.5 px-4 whitespace-nowrap">
                            <span
                              className={`inline-flex items-center gap-1.5 text-[10px] font-bold px-2.5 py-1 rounded-full border whitespace-nowrap ${
                                checked
                                  ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                                  : 'bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/20'
                              }`}
                            >
                              <span
                                className={`w-1.5 h-1.5 rounded-full ${
                                  checked ? 'bg-emerald-500 animate-pulse' : 'bg-amber-500'
                                }`}
                              />
                              {checked ? 'Đã vào sân' : 'Chờ check-in'}
                            </span>
                          </td>
                          <td className="py-3.5 px-4 text-right whitespace-nowrap">
                            {checked ? (
                              <span className="text-xs font-bold text-slate-400 inline-flex items-center gap-1">
                                <Check className="w-3.5 h-3.5 text-emerald-500" />
                                Đã soát
                              </span>
                            ) : (
                              <button
                                type="button"
                                data-testid={`btn-checkin-${ticket.id}`}
                                onClick={() => handleTableCheckIn(ticket.id)}
                                className="px-3.5 py-1.5 rounded-full bg-emerald-600 hover:bg-emerald-500 active:scale-95 text-white text-xs font-bold shadow-sm hover:shadow-md transition-all cursor-pointer inline-flex items-center gap-1.5 border border-emerald-500/30"
                              >
                                <CheckCircle2 className="w-3.5 h-3.5" />
                                Check-in
                              </button>
                            )}
                          </td>
                        </tr>
                      );
                    })
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Right Column: Add-on POS Quick Sales Counter */}
        <div className="lg:col-span-5 space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black text-slate-900 dark:text-white flex items-center gap-2">
                <ShoppingBag className="w-5 h-5 text-cyan-500" />
                Quầy Nước & Phụ Kiện (POS)
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Bán nhanh nước uống, thuê vợt & mua bóng tại quầy
              </p>
            </div>
            {cartItemsCount > 0 && (
              <button
                type="button"
                onClick={resetCart}
                className="glass-pill px-2.5 py-1 rounded-full text-[11px] text-slate-500 hover:text-rose-500 flex items-center gap-1 cursor-pointer font-bold"
              >
                <RotateCcw className="w-3 h-3" />
                Làm mới
              </button>
            )}
          </div>

          {/* Product Items List */}
          <div className="rounded-[28px] glass-card p-5 space-y-3">
            {POS_PRODUCTS.map((prod) => {
              const qty = cart[prod.id] || 0;
              return (
                <div
                  key={prod.id}
                  className="p-3.5 rounded-2xl bg-white/60 dark:bg-slate-900/60 border border-slate-100 dark:border-slate-800/80 flex items-center justify-between gap-3 shadow-xs hover:border-slate-300 dark:hover:border-slate-700 transition-all"
                >
                  <div className="flex-1 min-w-0">
                    <div className="text-xs font-bold text-slate-900 dark:text-white truncate">
                      {prod.name}
                    </div>
                    <div className="text-xs font-black text-emerald-600 dark:text-emerald-400 mt-0.5">
                      {prod.price.toLocaleString('vi-VN')} đ
                    </div>
                  </div>

                  {/* Quantity controls */}
                  <div className="flex items-center gap-2 shrink-0">
                    <button
                      type="button"
                      data-testid={prod.testIdDec}
                      disabled={qty === 0}
                      onClick={() => decrementItem(prod.id)}
                      className={`glass-pill w-7 h-7 rounded-full flex items-center justify-center transition-all ${
                        qty === 0
                          ? 'opacity-40 cursor-not-allowed text-slate-400'
                          : 'cursor-pointer text-slate-700 dark:text-slate-200'
                      }`}
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="w-6 text-center text-xs font-black text-slate-900 dark:text-white">
                      {qty}
                    </span>
                    <button
                      type="button"
                      data-testid={prod.testIdInc}
                      onClick={() => incrementItem(prod.id)}
                      className="glass-pill w-7 h-7 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white flex items-center justify-center transition-all cursor-pointer shadow-xs"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              );
            })}

            {/* Bill Summary & Checkout */}
            <div className="pt-4 border-t border-slate-200/60 dark:border-slate-800 space-y-3">
              <div className="flex items-center justify-between text-xs font-medium">
                <span className="text-slate-500 dark:text-slate-400">Số lượng mặt hàng:</span>
                <span className="font-bold text-slate-900 dark:text-white">{cartItemsCount}</span>
              </div>
              <div className="flex items-baseline justify-between">
                <span className="text-xs font-bold text-slate-700 dark:text-slate-300">
                  Tổng tiền thanh toán:
                </span>
                <span
                  data-testid="pos-bill-total"
                  className="text-2xl font-black text-emerald-600 dark:text-emerald-400 tracking-tight"
                >
                  {billTotal.toLocaleString('vi-VN')} đ
                </span>
              </div>

              <button
                type="button"
                data-testid="btn-pos-checkout"
                disabled={billTotal === 0}
                onClick={handleCheckout}
                className={`glass-pill w-full py-3.5 rounded-full font-bold text-xs shadow-md transition-all flex items-center justify-center gap-2 ${
                  billTotal === 0
                    ? 'opacity-40 cursor-not-allowed bg-slate-200 dark:bg-slate-800 text-slate-400'
                    : 'bg-emerald-600 hover:bg-emerald-500 text-white hover:shadow-lg cursor-pointer'
                }`}
              >
                <CreditCard className="w-4 h-4" />
                Thanh toán tại quầy
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PosCheckinView;
