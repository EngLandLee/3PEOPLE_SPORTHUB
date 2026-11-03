import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Shield,
  Store,
  Sun,
  Moon,
  ChevronDown,
  Bell,
  MapPin,
  Flame,
  Check,
  LogOut,
} from 'lucide-react';
import { useAuthStore, authStore } from '../../store/authStore';
import { useVenueStore } from '../../store/venueStore';
import { useNotificationStore } from '../../store/notificationStore';
import { useThemeStore } from '../../store/themeStore';
import { NotificationDropdown } from '../notifications/NotificationDropdown';
import { UserRole } from '../../types';

function formatVietnameseLiveDateTime(d: Date) {
  const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  const dayName = days[d.getDay()];
  const pad = (n: number) => String(n).padStart(2, '0');
  const dateStr = `${dayName}, ${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
  const timeStr = `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
  return `${dateStr} • ${timeStr}`;
}

export function Topbar() {
  const { role, activeVenueId, staffProfile } = useAuthStore();
  const { venues } = useVenueStore();
  const { unreadCount } = useNotificationStore();
  const { isDarkMode, toggleTheme } = useThemeStore();
  const navigate = useNavigate();

  const [currentTime, setCurrentTime] = useState<Date>(() => new Date());
  const [isRoleMenuOpen, setIsRoleMenuOpen] = useState(false);
  const [isVenueMenuOpen, setIsVenueMenuOpen] = useState(false);
  const [isNotifOpen, setIsNotifOpen] = useState(false);

  const roleMenuRef = useRef<HTMLDivElement>(null);
  const venueMenuRef = useRef<HTMLDivElement>(null);
  const notifMenuRef = useRef<HTMLDivElement>(null);

  // Live ticking clock
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Close menus when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (roleMenuRef.current && !roleMenuRef.current.contains(event.target as Node)) {
        setIsRoleMenuOpen(false);
      }
      if (venueMenuRef.current && !venueMenuRef.current.contains(event.target as Node)) {
        setIsVenueMenuOpen(false);
      }
      if (notifMenuRef.current && !notifMenuRef.current.contains(event.target as Node)) {
        setIsNotifOpen(false);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const handleRoleChange = (newRole: UserRole) => {
    authStore.setRole(newRole);
    setIsRoleMenuOpen(false);
    if (newRole === 'superadmin') {
      navigate('/admin');
    } else {
      navigate('/partner');
    }
  };

  const handleVenueChange = (venueId: string) => {
    authStore.setActiveVenueId(venueId);
    setIsVenueMenuOpen(false);
  };

  // Find active venue name
  const currentVenue = venues.find((v) => v.id === activeVenueId) || venues[0];
  const venueDisplayName = currentVenue ? currentVenue.name : 'CLB Tao Đàn';

  return (
    <header className="sticky top-0 z-30 h-16 w-full glass-topbar px-4 md:px-6 flex items-center justify-between transition-colors duration-200 shadow-xs">
      {/* Brand & Left Info */}
      <div className="flex items-center gap-3">
        <div className="flex items-center justify-center w-9 h-9 rounded-2xl bg-gradient-to-tr from-emerald-500 to-teal-400 text-white shadow-md shadow-emerald-500/20">
          <Flame className="w-5 h-5" />
        </div>
        <div className="hidden sm:block">
          <span className="font-black text-slate-900 dark:text-white tracking-tight text-base">
            SportHub <span className="text-emerald-500">Portal</span>
          </span>
          <span className="text-[10px] text-slate-400 dark:text-slate-500 block -mt-1 font-bold uppercase tracking-wider">
            Nhóm 3 người - App đặt sân cầu Lông (SportHub)
          </span>
        </div>

        {/* Partner Venue Badge / Selector */}
        {role === 'partner' && (
          <div className="relative ml-2 sm:ml-4" ref={venueMenuRef}>
            <button
              type="button"
              data-testid="venue-badge-or-selector"
              onClick={() => setIsVenueMenuOpen((prev) => !prev)}
              className="glass-pill flex items-center gap-1.5 px-3.5 py-1.5 text-xs font-bold rounded-full text-emerald-700 dark:text-emerald-300 transition-all cursor-pointer shadow-xs"
            >
              <MapPin className="w-3.5 h-3.5 text-emerald-500" />
              <span>{venueDisplayName}</span>
              <ChevronDown className="w-3 h-3 ml-0.5 opacity-70" />
            </button>

            {isVenueMenuOpen && (
              <div className="absolute left-0 mt-2 w-64 rounded-2xl glass-card p-2 z-50 animate-in fade-in zoom-in-95 duration-150">
                <div className="px-3 py-1.5 text-[10px] font-extrabold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                  Cụm sân phụ trách
                </div>
                {venues.map((venue) => {
                  const isSelected = venue.id === (activeVenueId || currentVenue?.id);
                  return (
                    <button
                      key={venue.id}
                      type="button"
                      onClick={() => handleVenueChange(venue.id)}
                      className={`w-full flex items-center justify-between px-3 py-2 text-left text-xs rounded-xl transition-all ${
                        isSelected
                          ? 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 font-bold border border-emerald-500/30'
                          : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100/80 dark:hover:bg-slate-800/70'
                      }`}
                    >
                      <div className="truncate pr-2">
                        <p className="font-semibold truncate">{venue.name}</p>
                        <p className="text-[10px] text-slate-400 dark:text-slate-500 truncate">
                          {venue.district}
                        </p>
                      </div>
                      {isSelected && <Check className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />}
                    </button>
                  );
                })}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Realtime Live Clock & Date Badge */}
        <div
          data-testid="topbar-live-clock"
          className="hidden md:flex items-center gap-2 glass-pill px-3.5 py-1.5 rounded-full text-xs font-mono font-bold shadow-xs text-slate-700 dark:text-slate-200"
          title="Thời gian thực hệ thống"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse shrink-0" />
          <span>{formatVietnameseLiveDateTime(currentTime)}</span>
        </div>

        {/* Role Switcher */}
        <div className="relative" ref={roleMenuRef}>
          <button
            type="button"
            data-testid="role-switcher-button"
            onClick={() => setIsRoleMenuOpen((prev) => !prev)}
            className="glass-pill flex items-center gap-2 px-3.5 py-1.5 text-xs font-bold rounded-full text-slate-800 dark:text-slate-100 transition-all cursor-pointer shadow-xs"
            aria-label="Switch Role"
          >
            {role === 'superadmin' ? (
              <>
                <Shield className="w-3.5 h-3.5 text-indigo-500" />
                <span>Super Admin</span>
              </>
            ) : (
              <>
                <Store className="w-3.5 h-3.5 text-emerald-500" />
                <span>Chủ Sân Tao Đàn</span>
              </>
            )}
            <ChevronDown className="w-3 h-3 text-slate-400 ml-0.5" />
          </button>

          {isRoleMenuOpen && (
            <div className="absolute right-0 mt-2 w-60 rounded-2xl glass-card p-2 z-50 animate-in fade-in zoom-in-95 duration-150">
              <div className="px-3 py-1.5 text-[10px] font-extrabold uppercase tracking-wider text-slate-400 dark:text-slate-500">
                Chuyển đổi vai trò
              </div>

              <button
                type="button"
                data-testid="role-option-superadmin"
                onClick={() => handleRoleChange('superadmin')}
                className={`w-full flex items-center gap-2.5 px-3 py-2 text-left text-xs transition-colors ${
                  role === 'superadmin'
                    ? 'bg-indigo-50 dark:bg-indigo-950/40 text-indigo-700 dark:text-indigo-300 font-semibold'
                    : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800/70'
                }`}
              >
                <div className="p-1 rounded-md bg-indigo-100 dark:bg-indigo-900/60 text-indigo-600 dark:text-indigo-300">
                  <Shield className="w-3.5 h-3.5" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold">Super Admin</p>
                  <p className="text-[10px] text-slate-400">Toàn quyền hệ thống</p>
                </div>
                {role === 'superadmin' && (
                  <Check className="w-4 h-4 text-indigo-600 dark:text-indigo-400" />
                )}
              </button>

              <button
                type="button"
                data-testid="role-option-partner"
                onClick={() => handleRoleChange('partner')}
                className={`w-full flex items-center gap-2.5 px-3 py-2 text-left text-xs transition-colors ${
                  role === 'partner'
                    ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 font-semibold'
                    : 'text-slate-700 dark:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800/70'
                }`}
              >
                <div className="p-1 rounded-md bg-emerald-100 dark:bg-emerald-900/60 text-emerald-600 dark:text-emerald-300">
                  <Store className="w-3.5 h-3.5" />
                </div>
                <div className="flex-1">
                  <p className="font-semibold">Chủ Sân Tao Đàn</p>
                  <p className="text-[10px] text-slate-400">Quản lý cụm sân & POS</p>
                </div>
                {role === 'partner' && (
                  <Check className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                )}
              </button>
            </div>
          )}
        </div>

        {/* Theme Toggle Button */}
        <button
          type="button"
          data-testid="theme-toggle-button"
          onClick={toggleTheme}
          title={isDarkMode ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối'}
          aria-label="Toggle Theme"
          className="glass-pill p-2 rounded-full text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-100 transition-all cursor-pointer shadow-xs"
        >
          {isDarkMode ? (
            <Sun className="w-4 h-4 text-amber-400 transition-transform hover:rotate-45" />
          ) : (
            <Moon className="w-4 h-4 text-slate-700 transition-transform hover:-rotate-12" />
          )}
        </button>

        {/* Notification Bell */}
        <div className="relative" ref={notifMenuRef}>
          <button
            type="button"
            data-testid="btn-notification-bell"
            aria-label={`Thông báo (${unreadCount} chưa đọc)`}
            onClick={() => setIsNotifOpen((prev) => !prev)}
            className="glass-pill relative p-2 rounded-full text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-100 transition-all cursor-pointer shadow-xs"
          >
            <Bell className="w-4 h-4" />
            {unreadCount > 0 && (
              <span
                data-testid="notif-badge-indicator"
                className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-emerald-500 ring-2 ring-white dark:ring-[#0E131F]"
              />
            )}
          </button>

          <NotificationDropdown
            isOpen={isNotifOpen}
            onClose={() => setIsNotifOpen(false)}
          />
        </div>

        {/* Staff Profile Avatar Badge */}
        <div className="flex items-center gap-2.5 pl-2 border-l border-slate-200/60 dark:border-slate-800/60">
          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-emerald-500 to-teal-400 text-white font-black text-xs flex items-center justify-center shadow-xs">
            {staffProfile.name.split(' ').map((n) => n[0]).join('').slice(0, 2).toUpperCase()}
          </div>
          <div className="hidden lg:block text-left">
            <p className="text-xs font-bold text-slate-800 dark:text-slate-200 leading-tight">
              {staffProfile.name}
            </p>
            <p className="text-[10px] text-slate-400 dark:text-slate-500 leading-tight">
              {staffProfile.title}
            </p>
          </div>
        </div>

        {/* Logout Button */}
        <button
          type="button"
          data-testid="btn-logout-topbar"
          onClick={() => {
            authStore.logout();
            navigate('/login');
          }}
          title="Đăng xuất khỏi hệ thống"
          aria-label="Đăng xuất"
          className="glass-pill p-2 rounded-full text-rose-500 hover:text-rose-600 dark:text-rose-400 bg-rose-50/50 hover:bg-rose-100/80 dark:bg-rose-950/30 transition-all cursor-pointer shadow-xs"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>
    </header>
  );
}

export default Topbar;
