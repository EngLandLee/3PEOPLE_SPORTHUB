import React, { useState } from 'react';
import {
  Users,
  UserPlus,
  Search,
  ShieldCheck,
  Building2,
  Mail,
  Phone,
  Power,
  X,
  CheckCircle2,
  Lock,
} from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { useVenueStore } from '../../store/venueStore';

export const PartnerAccountsView: React.FC = () => {
  const { partnerAccounts, toggleAccountStatus, addPartnerAccount } = useAuthStore();
  const { venues } = useVenueStore();

  const [searchTerm, setSearchTerm] = useState('');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);

  // New account form state
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [venueId, setVenueId] = useState(venues[0]?.id || 'venue_01');
  const [error, setError] = useState('');

  const filteredAccounts = partnerAccounts.filter((acc) => {
    const term = searchTerm.toLowerCase();
    return (
      acc.fullName.toLowerCase().includes(term) ||
      acc.email.toLowerCase().includes(term) ||
      acc.phone.toLowerCase().includes(term) ||
      acc.venueName.toLowerCase().includes(term)
    );
  });

  const handleCreateAccount = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim()) {
      setError('Vui lòng nhập họ và tên đối tác');
      return;
    }
    if (!email.trim()) {
      setError('Vui lòng nhập email tài khoản');
      return;
    }
    if (!phone.trim()) {
      setError('Vui lòng nhập số điện thoại');
      return;
    }

    const selectedVenue = venues.find((v) => v.id === venueId);
    const venueName = selectedVenue ? selectedVenue.name : 'Cụm Sân';

    addPartnerAccount({
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      venueId,
      venueName,
      role: 'partner',
      isActive: true,
    });

    // Reset and close
    setFullName('');
    setEmail('');
    setPhone('');
    setError('');
    setIsAddModalOpen(false);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Top Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-indigo-500/10 text-indigo-600 dark:text-indigo-400 border border-indigo-500/20">
              <Users className="w-3.5 h-3.5" />
              Quản trị viên & Đối tác
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Tài khoản Chủ Sân
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Quản lý danh sách tài khoản đối tác chủ sân và phân quyền hoạt động.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsAddModalOpen(true)}
          data-testid="btn-add-account"
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-600/20 transition-all cursor-pointer w-fit"
        >
          <UserPlus className="w-4 h-4" />
          <span>Cấp tài khoản mới</span>
        </button>
      </div>

      {/* Filter / Search Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="relative w-full sm:w-80">
          <div className="glass-pill flex items-center gap-2.5 px-3.5 py-2 rounded-full focus-within:ring-2 focus-within:ring-indigo-500/30">
            <Search className="w-4 h-4 text-slate-400 shrink-0" />
            <input
              type="text"
              placeholder="Tìm theo tên, email, sđt, cụm sân..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-transparent text-slate-900 dark:text-white placeholder-slate-400 text-xs font-medium focus:outline-hidden"
            />
          </div>
        </div>

        <div className="glass-pill px-4 py-1.5 rounded-full text-xs text-slate-600 dark:text-slate-300 font-semibold">
          Tổng cộng: <span className="font-black text-slate-900 dark:text-white">{filteredAccounts.length}</span> tài khoản
        </div>
      </div>

      {/* Accounts Table */}
      <div className="overflow-hidden rounded-[28px] glass-card p-2">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="border-b border-slate-200/60 dark:border-slate-800 text-[11px] font-bold uppercase tracking-wider text-slate-400">
                <th className="px-6 py-4">Họ & Tên</th>
                <th className="px-6 py-4">Email / Tài khoản</th>
                <th className="px-6 py-4">Cụm Sân Quản Lý</th>
                <th className="px-6 py-4">Vai Trò</th>
                <th className="px-6 py-4">Trạng Thái</th>
                <th className="px-6 py-4 text-right">Thao Tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/80 text-sm">
              {filteredAccounts.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-6 py-12 text-center text-slate-400">
                    <Users className="w-8 h-8 mx-auto mb-2 opacity-40" />
                    Không tìm thấy tài khoản đối tác nào
                  </td>
                </tr>
              ) : (
                filteredAccounts.map((account) => (
                  <tr
                    key={account.id}
                    className="hover:bg-slate-50/50 dark:hover:bg-slate-800/40 transition-colors"
                  >
                    {/* Full Name & Phone */}
                    <td className="px-6 py-4">
                      <div className="font-semibold text-slate-900 dark:text-white flex items-center gap-2.5">
                        <div className="w-8 h-8 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold text-xs">
                          {account.fullName.charAt(0)}
                        </div>
                        <div>
                          <div>{account.fullName}</div>
                          <div className="text-xs text-slate-400 font-normal flex items-center gap-1 mt-0.5">
                            <Phone className="w-3 h-3 text-slate-400" />
                            {account.phone}
                          </div>
                        </div>
                      </div>
                    </td>

                    {/* Email */}
                    <td className="px-6 py-4 text-slate-600 dark:text-slate-300">
                      <div className="flex items-center gap-1.5">
                        <Mail className="w-3.5 h-3.5 text-slate-400" />
                        <span className="font-mono text-xs">{account.email}</span>
                      </div>
                    </td>

                    {/* Venue */}
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-slate-800 dark:text-slate-200">
                        <Building2 className="w-4 h-4 text-emerald-500 shrink-0" />
                        <span className="font-medium text-xs sm:text-sm">{account.venueName}</span>
                      </div>
                    </td>

                    {/* Role */}
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-50 dark:bg-blue-950/50 text-blue-700 dark:text-blue-300 border border-blue-200/60 dark:border-blue-900/60">
                        <ShieldCheck className="w-3 h-3" />
                        {account.role === 'superadmin' ? 'Super Admin' : 'Chủ Cụm Sân'}
                      </span>
                    </td>

                    {/* Status */}
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${
                          account.isActive
                            ? 'bg-emerald-50 dark:bg-emerald-950/50 text-emerald-700 dark:text-emerald-300 border border-emerald-200/60 dark:border-emerald-900/60'
                            : 'bg-rose-50 dark:bg-rose-950/50 text-rose-700 dark:text-rose-300 border border-rose-200/60 dark:border-rose-900/60'
                        }`}
                      >
                        {account.isActive ? (
                          <>
                            <CheckCircle2 className="w-3 h-3 text-emerald-500" />
                            Hoạt động
                          </>
                        ) : (
                          <>
                            <Lock className="w-3 h-3 text-rose-500" />
                            Tạm khóa
                          </>
                        )}
                      </span>
                    </td>

                    {/* Actions */}
                    <td className="px-6 py-4 text-right">
                      <button
                        type="button"
                        onClick={() => toggleAccountStatus(account.id)}
                        data-testid={`toggle-account-${account.id}`}
                        title={account.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}
                        className={`glass-pill inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold transition-all shadow-xs cursor-pointer ${
                          account.isActive
                            ? 'text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40'
                            : 'text-emerald-600 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/40'
                        }`}
                      >
                        <Power className="w-3.5 h-3.5" />
                        {account.isActive ? 'Khóa' : 'Kích hoạt'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add Account */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
          <div className="relative w-full max-w-lg bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 rounded-3xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/40">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-500/20">
                  <UserPlus className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                    Cấp tài khoản Chủ Sân mới
                  </h2>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    Tạo tài khoản quản trị cụm sân cho đối tác SportHub
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsAddModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-slate-400 hover:text-slate-600 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateAccount} className="p-6 space-y-4">
              {error && (
                <div className="p-3 text-sm text-red-600 bg-red-50 dark:bg-red-950/40 border border-red-200 dark:border-red-900 rounded-xl">
                  {error}
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                  Họ & Tên Chủ Sân <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  data-testid="input-account-name"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="VD: Hoàng Văn Thao"
                  required
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                  Email Đăng Nhập <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  data-testid="input-account-email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="thao.hoang@example.com"
                  required
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                  Số Điện Thoại <span className="text-red-500">*</span>
                </label>
                <input
                  type="tel"
                  data-testid="input-account-phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="0912 345 678"
                  required
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20 text-sm"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                  Gán Quản Lý Cụm Sân <span className="text-red-500">*</span>
                </label>
                <select
                  data-testid="select-account-venue"
                  value={venueId}
                  onChange={(e) => setVenueId(e.target.value)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm focus:outline-hidden focus:border-emerald-500 focus:ring-2 focus:ring-emerald-500/20"
                >
                  {venues.map((v) => (
                    <option key={v.id} value={v.id} className="bg-white dark:bg-[#141B2D]">
                      {v.name} ({v.district})
                    </option>
                  ))}
                </select>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  data-testid="btn-submit-account"
                  className="px-5 py-2.5 rounded-xl text-sm font-semibold bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-600/20 transition-all"
                >
                  Kích Hoạt Tài Khoản
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
