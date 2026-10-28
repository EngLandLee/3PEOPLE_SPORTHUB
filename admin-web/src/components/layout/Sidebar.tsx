import type { ComponentType } from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Building2,
  Users,
  Store,
  CalendarRange,
  QrCode,
  BarChart3,
  LogOut,
  Bot,
  FileCode2,
} from 'lucide-react';
import { useAuthStore, authStore } from '../../store/authStore';

interface NavItem {
  name: string;
  path: string;
  icon: ComponentType<{ className?: string }>;
  badge?: string;
  exact?: boolean;
  isExternal?: boolean;
}

export function Sidebar() {
  const { role } = useAuthStore();
  const navigate = useNavigate();

  const superAdminNavItems: NavItem[] = [
    {
      name: 'Tổng quan Sàn',
      path: '/admin',
      icon: LayoutDashboard,
      exact: true,
    },
    {
      name: 'Quản lý Cụm Sân',
      path: '/admin/venues',
      icon: Building2,
    },
    {
      name: 'Tài khoản Chủ Sân',
      path: '/admin/accounts',
      icon: Users,
    },
    {
      name: 'Trợ lý AI',
      path: '/admin/chatbot',
      icon: Bot,
    },
    {
      name: 'Tài liệu API (Swagger)',
      path: '/api-docs/index.html',
      icon: FileCode2,
      isExternal: true,
    },
  ];

  const partnerNavItems: NavItem[] = [
    {
      name: 'Tổng quan Cụm Sân',
      path: '/partner',
      icon: LayoutDashboard,
      exact: true,
    },
    {
      name: 'Quản lý Sân',
      path: '/partner/courts',
      icon: Store,
    },
    {
      name: 'Lịch Sân Master',
      path: '/partner/schedule',
      icon: CalendarRange,
    },
    {
      name: 'Quầy Lễ Tân & Soát Vé',
      path: '/partner/pos',
      icon: QrCode,
      badge: 'POS',
    },
    {
      name: 'Báo cáo Doanh thu',
      path: '/partner/revenue',
      icon: BarChart3,
    },
    {
      name: 'Trợ lý AI',
      path: '/partner/chatbot',
      icon: Bot,
    },
    {
      name: 'Tài liệu API (Swagger)',
      path: '/api-docs/index.html',
      icon: FileCode2,
      isExternal: true,
    },
  ];

  const currentNavItems = role === 'superadmin' ? superAdminNavItems : partnerNavItems;

  return (
    <aside
      className="w-[260px] min-w-[260px] shrink-0 sticky top-0 h-screen flex flex-col justify-between glass-sidebar text-slate-700 dark:text-slate-200 transition-colors duration-200 select-none z-20 shadow-sm"
      aria-label="Sidebar Navigation"
    >
      <div>
        {/* Sidebar Header / Role Tag */}
        <div className="p-4 border-b border-slate-100/80 dark:border-slate-800/60">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold tracking-wider uppercase text-slate-400 dark:text-slate-500">
              {role === 'superadmin' ? 'Hệ thống Quản trị' : 'Cổng Đối tác Cụm Sân'}
            </span>
            <span
              className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold ${
                role === 'superadmin'
                  ? 'bg-indigo-100 text-indigo-700 dark:bg-indigo-900/60 dark:text-indigo-300 border border-indigo-200/50'
                  : 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/60 dark:text-emerald-300 border border-emerald-200/50'
              }`}
            >
              {role === 'superadmin' ? 'SUPER' : 'PARTNER'}
            </span>
          </div>
        </div>

        {/* Navigation Items */}
        <nav className="p-3 space-y-1.5" aria-label="Main Navigation">
          {currentNavItems.map((item) => {
            const Icon = item.icon;
            if (item.isExternal) {
              return (
                <a
                  key={item.path}
                  href={item.path}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-xs font-semibold transition-all group text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-white/60 dark:hover:bg-slate-800/60"
                >
                  <div className="flex items-center gap-3 truncate">
                    <div className="w-7 h-7 rounded-xl flex items-center justify-center transition-all bg-slate-100 dark:bg-slate-800/80 text-slate-500 dark:text-slate-400 group-hover:scale-105">
                      <Icon className="w-3.5 h-3.5 shrink-0" />
                    </div>
                    <span className="truncate">{item.name}</span>
                  </div>
                  {item.badge && (
                    <span className="ml-auto px-2 py-0.5 text-[9px] font-bold uppercase rounded-full bg-emerald-100 dark:bg-emerald-900/60 text-emerald-800 dark:text-emerald-200">
                      {item.badge}
                    </span>
                  )}
                </a>
              );
            }

            return (
              <NavLink
                key={item.path}
                to={item.path}
                end={item.exact}
                className={({ isActive }) =>
                  `flex items-center justify-between px-3.5 py-2.5 rounded-2xl text-xs font-semibold transition-all group ${
                    isActive
                      ? role === 'superadmin'
                        ? 'bg-indigo-500/15 text-indigo-700 dark:text-indigo-300 shadow-sm border border-indigo-500/30'
                        : 'bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 shadow-sm border border-emerald-500/30'
                      : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-white/60 dark:hover:bg-slate-800/60'
                  }`
                }
              >
                {({ isActive }) => (
                  <>
                    <div className="flex items-center gap-3 truncate">
                      <div
                        className={`w-7 h-7 rounded-xl flex items-center justify-center transition-all ${
                          isActive
                            ? role === 'superadmin'
                              ? 'bg-indigo-500 text-white shadow-xs'
                              : 'bg-emerald-500 text-white shadow-xs'
                            : 'bg-slate-100 dark:bg-slate-800/80 text-slate-500 dark:text-slate-400 group-hover:scale-105'
                        }`}
                      >
                        <Icon className="w-3.5 h-3.5 shrink-0" />
                      </div>
                      <span className="truncate">{item.name}</span>
                    </div>

                    {item.badge && (
                      <span className="ml-auto px-2 py-0.5 text-[9px] font-bold uppercase rounded-full bg-emerald-100 dark:bg-emerald-900/60 text-emerald-800 dark:text-emerald-200">
                        {item.badge}
                      </span>
                    )}
                  </>
                )}
              </NavLink>
            );
          })}
        </nav>
      </div>

      {/* Sidebar Footer */}
      <div className="p-4 border-t border-slate-100/80 dark:border-slate-800/60">
        <div className="p-3 rounded-2xl glass-card border border-white/60 dark:border-slate-800">
          <div className="flex items-center gap-2 text-xs font-bold text-slate-800 dark:text-slate-200">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span>Hệ thống trực tuyến</span>
          </div>
          <p className="mt-1 text-[11px] text-slate-400 dark:text-slate-500">
            SportHub Dashboards V2
          </p>
        </div>

        {/* Sidebar Logout Button */}
        <button
          type="button"
          data-testid="btn-logout-sidebar"
          onClick={() => {
            authStore.logout();
            navigate('/login');
          }}
          className="w-full mt-3 flex items-center justify-center gap-2 py-2.5 px-3 rounded-2xl border border-rose-200/80 dark:border-rose-900/40 bg-rose-50/60 hover:bg-rose-100 dark:bg-rose-950/30 dark:hover:bg-rose-900/50 text-rose-600 dark:text-rose-400 text-xs font-bold transition-all cursor-pointer shadow-xs hover:scale-[1.02]"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span>Đăng xuất</span>
        </button>
      </div>
    </aside>
  );
}

export default Sidebar;
