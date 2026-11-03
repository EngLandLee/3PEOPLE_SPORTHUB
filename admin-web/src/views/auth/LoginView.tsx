import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Flame, Shield, Store, Lock, Mail, ArrowRight, Sparkles } from 'lucide-react';
import { useAuthStore, authStore } from '../../store/authStore';
import { UserRole } from '../../types';

export const LoginView: React.FC = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { login } = useAuthStore();
  const navigate = useNavigate();

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    const cleanEmail = email.trim();
    if (!cleanEmail) {
      setError('Vui lòng nhập địa chỉ email');
      return;
    }

    const { partnerAccounts, customerAccounts } = authStore.getSnapshot();
    const isCustomer = customerAccounts?.some(
      (c) => c.email.toLowerCase() === cleanEmail.toLowerCase(),
    ) || cleanEmail.toLowerCase() === 'nguyenvanan@gmail.com';

    if (isCustomer) {
      setError(
        'Tài khoản này là Khách hàng (Player). Vui lòng đăng nhập trên App di động SportHub để đặt sân, hoặc dùng tài khoản Quản trị / Đối tác Chủ sân để vào trang quản trị.',
      );
      return;
    }

    const partner = partnerAccounts.find(
      (p) => p.email.toLowerCase() === cleanEmail.toLowerCase(),
    );
    const role: UserRole = partner || cleanEmail.toLowerCase().includes('partner') ? 'partner' : 'superadmin';
    login(cleanEmail, role);
    navigate(role === 'partner' ? '/partner' : '/admin');
  };

  const handleQuickLogin = (emailTarget: string, role: UserRole) => {
    login(emailTarget, role);
    navigate(role === 'partner' ? '/partner' : '/admin');
  };

  return (
    <div className="min-h-screen bg-slate-50/70 dark:bg-[#0B0F19] bg-ambient-mesh flex items-center justify-center p-4 transition-colors">
      <div className="w-full max-w-md">
        {/* Header Branding */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-3xl bg-gradient-to-tr from-emerald-500 to-teal-400 text-white shadow-xl shadow-emerald-500/25 mb-4 hover:scale-105 transition-transform">
            <Flame className="w-7 h-7" />
          </div>
          <div className="flex items-center justify-center gap-1.5 mb-1">
            <span className="glass-pill px-3 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider text-emerald-600 dark:text-emerald-400 flex items-center gap-1">
              <Sparkles className="w-3 h-3 text-amber-500" />
              Dashboards V2 Platform
            </span>
          </div>
          <h1 className="text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            SportHub <span className="text-emerald-500">Portal</span>
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1 font-medium">
            Đăng nhập Hệ thống Quản trị & Cổng Đối tác Cụm Sân
          </p>
        </div>

        {/* Login Glass Card */}
        <div className="glass-card rounded-[32px] p-6 sm:p-8 shadow-2xl border border-white/80 dark:border-slate-800/80">
          {error && (
            <div role="alert" className="mb-4 p-3 rounded-2xl bg-rose-50/80 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800 text-xs font-semibold text-rose-700 dark:text-rose-300">
              {error}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label htmlFor="login-email" className="block text-[11px] font-extrabold text-slate-600 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Email tài khoản
              </label>
              <div className="relative">
                <div className="glass-pill flex items-center gap-2.5 px-3.5 py-2.5 rounded-2xl focus-within:ring-2 focus-within:ring-emerald-500/40">
                  <Mail className="w-4 h-4 text-slate-400 shrink-0" />
                  <input
                    id="login-email"
                    data-testid="input-login-email"
                    type="email"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value);
                      setError('');
                    }}
                    placeholder="admin@sporthub.vn hoặc partner@taodan.vn"
                    className="w-full bg-transparent text-xs text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden font-medium"
                  />
                </div>
              </div>
            </div>

            <div>
              <label htmlFor="login-password" className="block text-[11px] font-extrabold text-slate-600 dark:text-slate-300 uppercase tracking-wider mb-1.5">
                Mật khẩu
              </label>
              <div className="relative">
                <div className="glass-pill flex items-center gap-2.5 px-3.5 py-2.5 rounded-2xl focus-within:ring-2 focus-within:ring-emerald-500/40">
                  <Lock className="w-4 h-4 text-slate-400 shrink-0" />
                  <input
                    id="login-password"
                    data-testid="input-login-password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="w-full bg-transparent text-xs text-slate-900 dark:text-white placeholder-slate-400 focus:outline-hidden font-medium"
                  />
                </div>
              </div>
            </div>

            <button
              type="submit"
              data-testid="btn-submit-login"
              className="w-full py-3.5 px-4 rounded-2xl bg-emerald-600 hover:bg-emerald-500 active:scale-[0.98] text-white text-xs font-bold transition-all flex items-center justify-center gap-2 shadow-lg shadow-emerald-600/30 cursor-pointer mt-3"
            >
              <span>Đăng nhập hệ thống</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* Quick Access Divider */}
          <div className="relative my-6">
            <div className="absolute inset-0 flex items-center">
              <div className="w-full border-t border-slate-200/60 dark:border-slate-800" />
            </div>
            <div className="relative flex justify-center text-xs">
              <span className="glass-pill px-3 py-0.5 rounded-full text-slate-400 font-bold uppercase tracking-wider text-[10px]">
                Hoặc đăng nhập nhanh (1-Click)
              </span>
            </div>
          </div>

          {/* Quick Login Buttons */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
            <button
              type="button"
              data-testid="btn-quick-admin"
              onClick={() => handleQuickLogin('admin@sporthub.vn', 'superadmin')}
              className="glass-pill p-3 rounded-2xl border border-indigo-200/80 dark:border-indigo-900/60 bg-indigo-50/70 hover:bg-indigo-100 dark:bg-indigo-950/40 dark:hover:bg-indigo-900/60 transition-all text-left flex items-center gap-2.5 cursor-pointer group"
            >
              <div className="p-2 rounded-xl bg-indigo-600 text-white shrink-0 shadow-xs group-hover:scale-110 transition-transform">
                <Shield className="w-4 h-4" />
              </div>
              <div className="overflow-hidden">
                <p className="text-xs font-bold text-indigo-950 dark:text-indigo-200">Super Admin</p>
                <p className="text-[10px] text-indigo-700 dark:text-indigo-400 truncate font-medium">Toàn quyền hệ thống</p>
              </div>
            </button>

            <button
              type="button"
              data-testid="btn-quick-partner"
              onClick={() => handleQuickLogin('partner@taodan.vn', 'partner')}
              className="glass-pill p-3 rounded-2xl border border-emerald-200/80 dark:border-emerald-900/60 bg-emerald-50/70 hover:bg-emerald-100 dark:bg-emerald-950/40 dark:hover:bg-emerald-900/60 transition-all text-left flex items-center gap-2.5 cursor-pointer group"
            >
              <div className="p-2 rounded-xl bg-emerald-600 text-white shrink-0 shadow-xs group-hover:scale-110 transition-transform">
                <Store className="w-4 h-4" />
              </div>
              <div className="overflow-hidden">
                <p className="text-xs font-bold text-emerald-950 dark:text-emerald-200">Chủ Sân Tao Đàn</p>
                <p className="text-[10px] text-emerald-700 dark:text-emerald-400 truncate font-medium">Quận 1 • Tao Đàn</p>
              </div>
            </button>

            <button
              type="button"
              onClick={() => handleQuickLogin('quoc.vo@namsaigonfootball.vn', 'partner')}
              className="glass-pill p-3 rounded-2xl border border-blue-200/80 dark:border-blue-900/60 bg-blue-50/70 hover:bg-blue-100 dark:bg-blue-950/40 dark:hover:bg-blue-900/60 transition-all text-left flex items-center gap-2.5 cursor-pointer group"
            >
              <div className="p-2 rounded-xl bg-blue-600 text-white shrink-0 shadow-xs group-hover:scale-110 transition-transform">
                <Store className="w-4 h-4" />
              </div>
              <div className="overflow-hidden">
                <p className="text-xs font-bold text-blue-950 dark:text-blue-200">Sân Nam Sài Gòn</p>
                <p className="text-[10px] text-blue-700 dark:text-blue-400 truncate font-medium">Quận 7 • Bóng đá</p>
              </div>
            </button>

            <button
              type="button"
              onClick={() => handleQuickLogin('quan.le@thaodienpickleball.vn', 'partner')}
              className="glass-pill p-3 rounded-2xl border border-amber-200/80 dark:border-amber-900/60 bg-amber-50/70 hover:bg-amber-100 dark:bg-amber-950/40 dark:hover:bg-amber-900/60 transition-all text-left flex items-center gap-2.5 cursor-pointer group"
            >
              <div className="p-2 rounded-xl bg-amber-600 text-white shrink-0 shadow-xs group-hover:scale-110 transition-transform">
                <Store className="w-4 h-4" />
              </div>
              <div className="overflow-hidden">
                <p className="text-xs font-bold text-amber-950 dark:text-amber-200">Thảo Điền Hub</p>
                <p className="text-[10px] text-amber-700 dark:text-amber-400 truncate font-medium">Thủ Đức • Pickleball</p>
              </div>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginView;
