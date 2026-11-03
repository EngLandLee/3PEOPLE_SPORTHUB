import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AdminLayout } from './components/layout/AdminLayout';
import { useAuthStore } from './store/authStore';
import { SuperAdminDashboardView } from './views/superadmin/SuperAdminDashboardView';
import { VenuesManagementView } from './views/superadmin/VenuesManagementView';
import { PartnerAccountsView } from './views/superadmin/PartnerAccountsView';
import { UserManagementView } from './views/superadmin/UserManagementView';
import { PartnerDashboardView } from './views/partner/PartnerDashboardView';
import { CourtsManagementView } from './views/partner/CourtsManagementView';
import { ScheduleMatrixView } from './views/partner/ScheduleMatrixView';
import { PosCheckinView } from './views/partner/PosCheckinView';
import { RevenueAnalyticsView } from './views/partner/RevenueAnalyticsView';

export function SuperAdminDashboardPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Tổng quan Sàn
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Báo cáo tổng quan toàn bộ nền tảng SportHub và tình trạng hoạt động cụm sân.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Dashboard Super Admin sẽ được tích hợp tại Task 3
      </div>
    </div>
  );
}

export function VenuesManagementPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Quản lý Cụm Sân
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Danh sách, thông tin liên hệ và trạng thái hoạt động các cụm sân trên hệ thống.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Quản lý Cụm Sân sẽ được tích hợp tại Task 4
      </div>
    </div>
  );
}

export function AccountsManagementPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Tài khoản Chủ Sân
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Quản lý danh sách tài khoản đối tác chủ sân và phân quyền hoạt động.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Tài khoản Chủ Sân sẽ được tích hợp tại Task 4
      </div>
    </div>
  );
}

export function PartnerDashboardPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Tổng quan Cụm Sân
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Chỉ số hiệu suất, công suất sử dụng sân và doanh thu trong ngày.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Dashboard Đối Tác sẽ được tích hợp tại Task 3
      </div>
    </div>
  );
}

export function CourtsManagementPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Quản lý Sân
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Cấu hình danh sách sân thể thao, loại mặt sân, và bảng giá theo khung giờ.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Quản lý Sân sẽ được tích hợp tại Task 4
      </div>
    </div>
  );
}

export function ScheduleMasterPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Lịch Sân Master
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Ma trận lịch sân 16 khung giờ trực quan với tính năng đặt lịch và khóa bảo trì.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Lịch Sân Master sẽ được tích hợp tại Task 5
      </div>
    </div>
  );
}

export function PosReceptionPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Quầy Lễ Tân & Soát Vé
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Soát vé bằng mã QR/Ticket ID, bán nước & phụ kiện thể thao, lập hóa đơn tức thì.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Quầy Lễ Tân & POS sẽ được tích hợp tại Task 5
      </div>
    </div>
  );
}

export function RevenueReportPlaceholder() {
  return (
    <div className="space-y-4">
      <div className="border-b border-slate-200 dark:border-slate-800 pb-4">
        <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
          Báo cáo Doanh thu
        </h1>
        <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
          Báo cáo dòng tiền, phân chia nguồn thu tiền mặt / chuyển khoản và biểu đồ xu hướng.
        </p>
      </div>
      <div className="p-8 rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-center text-slate-400">
        Nội dung Báo cáo Doanh thu sẽ được tích hợp tại Task 5
      </div>
    </div>
  );
}

import { LoginView } from './views/auth/LoginView';
import ChatbotManagementView from './views/admin/ChatbotManagementView';
import { CustomerChatView } from './views/admin/CustomerChatView';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { isAuthenticated } = useAuthStore();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
}

export function RootRedirect() {
  const { isAuthenticated, role } = useAuthStore();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <Navigate to={role === 'partner' ? '/partner' : '/admin'} replace />;
}

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginView />} />
      <Route
        path="/"
        element={
          <ProtectedRoute>
            <AdminLayout />
          </ProtectedRoute>
        }
      >
        <Route index element={<RootRedirect />} />

        {/* Super Admin Routes */}
        <Route path="admin" element={<SuperAdminDashboardView />} />
        <Route path="admin/venues" element={<VenuesManagementView />} />
        <Route path="admin/accounts" element={<PartnerAccountsView />} />
        <Route path="admin/users" element={<UserManagementView />} />
        <Route path="admin/chat" element={<CustomerChatView />} />
        <Route path="admin/chatbot" element={<ChatbotManagementView />} />

        {/* Partner Routes */}
        <Route path="partner" element={<PartnerDashboardView />} />
        <Route path="partner/courts" element={<CourtsManagementView />} />
        <Route path="partner/schedule" element={<ScheduleMatrixView />} />
        <Route path="partner/pos" element={<PosCheckinView />} />
        <Route path="partner/revenue" element={<RevenueAnalyticsView />} />
        <Route path="partner/chat" element={<CustomerChatView />} />
        <Route path="partner/chatbot" element={<ChatbotManagementView />} />

        {/* Fallback */}
        <Route path="*" element={<RootRedirect />} />
      </Route>
    </Routes>
  );
}

export function App() {
  return (
    <BrowserRouter>
      <AppRoutes />
    </BrowserRouter>
  );
}

export default App;
