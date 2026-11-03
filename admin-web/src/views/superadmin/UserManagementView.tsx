import React, { useState, useEffect } from 'react';
import {
  Users,
  UserPlus,
  Search,
  Mail,
  Phone,
  Power,
  Edit2,
  Trash2,
  X,
  CheckCircle2,
  MapPin,
  Trophy,
} from 'lucide-react';
import { useAuthStore, authStore } from '../../store/authStore';
import { CustomerAccount } from '../../types';

export const UserManagementView: React.FC = () => {
  const {
    customerAccounts,
    addCustomerAccount,
    updateCustomerAccount,
    deleteCustomerAccount,
    toggleCustomerStatus,
  } = useAuthStore();

  useEffect(() => {
    void authStore.fetchCustomerAccounts();
  }, []);

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedSport, setSelectedSport] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');

  // Modal States
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<CustomerAccount | null>(null);
  const [deletingUser, setDeletingUser] = useState<CustomerAccount | null>(null);

  // Form state
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [preferredSport, setPreferredSport] = useState('Cầu lông');
  const [skillLevel, setSkillLevel] = useState('Trung bình');
  const [district, setDistrict] = useState('Quận 1');
  const [error, setError] = useState('');

  const filteredUsers = (customerAccounts || []).filter((user) => {
    const term = searchTerm.toLowerCase();
    const matchesSearch =
      user.fullName.toLowerCase().includes(term) ||
      user.email.toLowerCase().includes(term) ||
      user.phone.toLowerCase().includes(term) ||
      user.district.toLowerCase().includes(term);

    const matchesSport =
      selectedSport === 'all' ||
      user.preferredSport.toLowerCase().includes(selectedSport.toLowerCase());

    const matchesStatus =
      selectedStatus === 'all' ||
      (selectedStatus === 'active' ? user.isActive : !user.isActive);

    return matchesSearch && matchesSport && matchesStatus;
  });

  const handleOpenAddModal = () => {
    setFullName('');
    setEmail('');
    setPhone('');
    setPreferredSport('Cầu lông');
    setSkillLevel('Trung bình');
    setDistrict('Quận 1');
    setError('');
    setIsAddModalOpen(true);
  };

  const handleOpenEditModal = (user: CustomerAccount) => {
    setEditingUser(user);
    setFullName(user.fullName);
    setEmail(user.email);
    setPhone(user.phone);
    setPreferredSport(user.preferredSport);
    setSkillLevel(user.skillLevel);
    setDistrict(user.district);
    setError('');
  };

  const handleCreateUser = (e: React.FormEvent) => {
    e.preventDefault();
    if (!fullName.trim()) {
      setError('Vui lòng nhập họ và tên người dùng');
      return;
    }
    if (!email.trim()) {
      setError('Vui lòng nhập email');
      return;
    }
    if (!phone.trim()) {
      setError('Vui lòng nhập số điện thoại');
      return;
    }

    addCustomerAccount({
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      preferredSport,
      skillLevel,
      district,
      isActive: true,
      matchesPlayed: 0,
    });

    setIsAddModalOpen(false);
  };

  const handleSaveEditUser = (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingUser) return;
    if (!fullName.trim()) {
      setError('Vui lòng nhập họ và tên');
      return;
    }
    if (!email.trim()) {
      setError('Vui lòng nhập email');
      return;
    }
    if (!phone.trim()) {
      setError('Vui lòng nhập số điện thoại');
      return;
    }

    updateCustomerAccount(editingUser.id, {
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone.trim(),
      preferredSport,
      skillLevel,
      district,
    });

    setEditingUser(null);
  };

  const handleConfirmDelete = () => {
    if (deletingUser) {
      deleteCustomerAccount(deletingUser.id);
      setDeletingUser(null);
    }
  };

  // Stats
  const totalUsers = (customerAccounts || []).length;
  const activeUsers = (customerAccounts || []).filter((u) => u.isActive).length;
  const inactiveUsers = totalUsers - activeUsers;
  const totalMatches = (customerAccounts || []).reduce(
    (acc, u) => acc + (u.matchesPlayed || 0),
    0
  );

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-200 dark:border-slate-800 pb-5">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white flex items-center gap-2">
            <Users className="w-6 h-6 text-lime-500" />
            Quản lý Tài khoản Người dùng
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Quản lý danh sách khách hàng đặt sân, thông tin cá nhân và quyền truy cập ứng dụng SportHub.
          </p>
        </div>
        <button
          onClick={handleOpenAddModal}
          data-testid="btn-add-customer"
          className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-lime-500 hover:bg-lime-600 text-slate-950 font-semibold text-sm transition-all shadow-sm hover:shadow-lime-500/20 shadow-transparent"
        >
          <UserPlus className="w-4 h-4" />
          Thêm Người dùng mới
        </button>
      </div>

      {/* Metrics Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-4 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-medium">
            <span>Tổng người dùng</span>
            <Users className="w-4 h-4 text-lime-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-slate-900 dark:text-white">
            {totalUsers}
          </div>
          <div className="text-xs text-slate-400 mt-1">Tài khoản khách hàng SportHub</div>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-medium">
            <span>Đang hoạt động</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-emerald-500">
            {activeUsers}
          </div>
          <div className="text-xs text-slate-400 mt-1">Có thể đặt sân & kết nối cộng đồng</div>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-medium">
            <span>Bị tạm khóa</span>
            <Power className="w-4 h-4 text-rose-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-rose-500">
            {inactiveUsers}
          </div>
          <div className="text-xs text-slate-400 mt-1">Hạn chế quyền giao dịch</div>
        </div>

        <div className="p-4 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between text-slate-500 dark:text-slate-400 text-xs font-medium">
            <span>Tổng trận đã tham gia</span>
            <Trophy className="w-4 h-4 text-amber-500" />
          </div>
          <div className="mt-2 text-2xl font-bold text-amber-500">
            {totalMatches}
          </div>
          <div className="text-xs text-slate-400 mt-1">Hoạt động thể thao đã hoàn tất</div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
          <input
            type="text"
            placeholder="Tìm theo tên, email, số điện thoại, khu vực..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white shadow-sm"
          />
        </div>

        <select
          value={selectedSport}
          onChange={(e) => setSelectedSport(e.target.value)}
          className="px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-white focus:outline-none focus:border-lime-500 shadow-sm"
        >
          <option value="all">Tất cả môn thể thao</option>
          <option value="cầu lông">Cầu lông</option>
          <option value="pickleball">Pickleball</option>
          <option value="bóng đá">Bóng đá</option>
          <option value="tennis">Tennis</option>
        </select>

        <select
          value={selectedStatus}
          onChange={(e) => setSelectedStatus(e.target.value)}
          className="px-3.5 py-2.5 rounded-xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-sm text-slate-900 dark:text-white focus:outline-none focus:border-lime-500 shadow-sm"
        >
          <option value="all">Tất cả trạng thái</option>
          <option value="active">Đang hoạt động</option>
          <option value="inactive">Đã tạm khóa</option>
        </select>
      </div>

      {/* Users Table */}
      <div className="rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 dark:bg-slate-900/50 border-b border-slate-200 dark:border-slate-800 text-slate-500 dark:text-slate-400 font-medium">
              <tr>
                <th className="py-3.5 px-4">Khách hàng</th>
                <th className="py-3.5 px-4">Số điện thoại</th>
                <th className="py-3.5 px-4">Môn & Trình độ</th>
                <th className="py-3.5 px-4">Khu vực</th>
                <th className="py-3.5 px-4">Trận chơi</th>
                <th className="py-3.5 px-4">Trạng thái</th>
                <th className="py-3.5 px-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800/60 text-slate-700 dark:text-slate-300">
              {filteredUsers.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-10 text-slate-400">
                    Không tìm thấy người dùng nào phù hợp với bộ lọc
                  </td>
                </tr>
              ) : (
                filteredUsers.map((user) => (
                  <tr
                    key={user.id}
                    className="hover:bg-slate-50/60 dark:hover:bg-slate-800/30 transition-colors"
                  >
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-lime-500/15 border border-lime-500/30 flex items-center justify-center font-bold text-lime-600 dark:text-lime-400 text-xs">
                          {user.fullName.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <div className="font-semibold text-slate-900 dark:text-white">
                            {user.fullName}
                          </div>
                          <div className="text-xs text-slate-400 flex items-center gap-1 mt-0.5">
                            <Mail className="w-3 h-3" />
                            {user.email}
                          </div>
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1.5 text-slate-600 dark:text-slate-300">
                        <Phone className="w-3.5 h-3.5 text-slate-400" />
                        {user.phone}
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div>
                        <span className="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-lime-500/10 text-lime-600 dark:text-lime-400 border border-lime-500/20">
                          {user.preferredSport}
                        </span>
                        <div className="text-xs text-slate-400 mt-1">
                          {user.skillLevel}
                        </div>
                      </div>
                    </td>

                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-1 text-slate-600 dark:text-slate-300 text-xs">
                        <MapPin className="w-3 h-3 text-slate-400" />
                        {user.district}
                      </div>
                    </td>

                    <td className="py-3.5 px-4 font-semibold text-slate-900 dark:text-white">
                      {user.matchesPlayed ?? 0}
                    </td>

                    <td className="py-3.5 px-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold ${
                          user.isActive
                            ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20'
                            : 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border border-rose-500/20'
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            user.isActive ? 'bg-emerald-500' : 'bg-rose-500'
                          }`}
                        />
                        {user.isActive ? 'Hoạt động' : 'Tạm khóa'}
                      </span>
                    </td>

                    <td className="py-3.5 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => handleOpenEditModal(user)}
                          data-testid={`btn-edit-user-${user.id}`}
                          title="Sửa thông tin"
                          className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>

                        <button
                          onClick={() => toggleCustomerStatus(user.id)}
                          data-testid={`btn-toggle-user-${user.id}`}
                          title={user.isActive ? 'Tạm khóa' : 'Kích hoạt lại'}
                          className={`p-1.5 rounded-lg transition-colors ${
                            user.isActive
                              ? 'text-rose-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30'
                              : 'text-emerald-400 hover:text-emerald-600 hover:bg-emerald-50 dark:hover:bg-emerald-950/30'
                          }`}
                        >
                          <Power className="w-4 h-4" />
                        </button>

                        <button
                          onClick={() => setDeletingUser(user)}
                          data-testid={`btn-delete-user-${user.id}`}
                          title="Xóa tài khoản"
                          className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-colors"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Thêm người dùng mới */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-2xl p-6 relative">
            <button
              onClick={() => setIsAddModalOpen(false)}
              className="absolute right-4 top-4 text-slate-400 hover:text-slate-600 dark:hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>

            <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <UserPlus className="w-5 h-5 text-lime-500" />
              Thêm Người dùng mới
            </h2>

            {error && (
              <div className="mt-3 p-3 rounded-lg bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800/50 text-rose-600 dark:text-rose-400 text-xs">
                {error}
              </div>
            )}

            <form onSubmit={handleCreateUser} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Họ và tên *
                </label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="VD: Nguyễn Văn Nam"
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Email tài khoản *
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="nam.nguyen@example.com"
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Số điện thoại *
                </label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="0912 345 678"
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                    Môn yêu thích
                  </label>
                  <select
                    value={preferredSport}
                    onChange={(e) => setPreferredSport(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                  >
                    <option value="Cầu lông">Cầu lông</option>
                    <option value="Pickleball">Pickleball</option>
                    <option value="Bóng đá">Bóng đá</option>
                    <option value="Tennis">Tennis</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                    Khu vực / Quận
                  </label>
                  <select
                    value={district}
                    onChange={(e) => setDistrict(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                  >
                    <option value="Quận 1">Quận 1</option>
                    <option value="Quận 7">Quận 7</option>
                    <option value="TP. Thủ Đức">TP. Thủ Đức</option>
                    <option value="Quận Bình Thạnh">Quận Bình Thạnh</option>
                    <option value="Quận Tân Bình">Quận Tân Bình</option>
                    <option value="Quận 10">Quận 10</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-2.5 pt-3 border-t border-slate-100 dark:border-slate-800/80">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-lime-500 hover:bg-lime-600 text-slate-950 font-semibold text-sm transition-all shadow-sm"
                >
                  Thêm Người dùng
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Sửa thông tin người dùng */}
      {editingUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="w-full max-w-md rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-2xl p-6 relative">
            <button
              onClick={() => setEditingUser(null)}
              className="absolute right-4 top-4 text-slate-400 hover:text-slate-600 dark:hover:text-white"
            >
              <X className="w-5 h-5" />
            </button>

            <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <Edit2 className="w-5 h-5 text-lime-500" />
              Chỉnh sửa Tài khoản Người dùng
            </h2>

            {error && (
              <div className="mt-3 p-3 rounded-lg bg-rose-50 dark:bg-rose-950/30 border border-rose-200 dark:border-rose-800/50 text-rose-600 dark:text-rose-400 text-xs">
                {error}
              </div>
            )}

            <form onSubmit={handleSaveEditUser} className="space-y-4 mt-4">
              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Họ và tên *
                </label>
                <input
                  type="text"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Email *
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div>
                <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                  Số điện thoại *
                </label>
                <input
                  type="text"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                    Môn yêu thích
                  </label>
                  <select
                    value={preferredSport}
                    onChange={(e) => setPreferredSport(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                  >
                    <option value="Cầu lông">Cầu lông</option>
                    <option value="Pickleball">Pickleball</option>
                    <option value="Bóng đá">Bóng đá</option>
                    <option value="Tennis">Tennis</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-500 dark:text-slate-400 mb-1">
                    Khu vực / Quận
                  </label>
                  <select
                    value={district}
                    onChange={(e) => setDistrict(e.target.value)}
                    className="w-full px-3.5 py-2 rounded-xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-800 text-sm focus:outline-none focus:border-lime-500 text-slate-900 dark:text-white"
                  >
                    <option value="Quận 1">Quận 1</option>
                    <option value="Quận 7">Quận 7</option>
                    <option value="TP. Thủ Đức">TP. Thủ Đức</option>
                    <option value="Quận Bình Thạnh">Quận Bình Thạnh</option>
                    <option value="Quận Tân Bình">Quận Tân Bình</option>
                    <option value="Quận 10">Quận 10</option>
                  </select>
                </div>
              </div>

              <div className="flex justify-end gap-2.5 pt-3 border-t border-slate-100 dark:border-slate-800/80">
                <button
                  type="button"
                  onClick={() => setEditingUser(null)}
                  className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-lime-500 hover:bg-lime-600 text-slate-950 font-semibold text-sm transition-all shadow-sm"
                >
                  Lưu thay đổi
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal: Xác nhận Xóa */}
      {deletingUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="w-full max-w-sm rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 shadow-2xl p-6 text-center">
            <div className="w-12 h-12 rounded-full bg-rose-500/15 text-rose-500 flex items-center justify-center mx-auto mb-4">
              <Trash2 className="w-6 h-6" />
            </div>

            <h3 className="text-base font-bold text-slate-900 dark:text-white">
              Xóa tài khoản người dùng?
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">
              Bạn có chắc chắn muốn xóa tài khoản{' '}
              <span className="font-semibold text-slate-800 dark:text-slate-200">
                "{deletingUser.fullName}"
              </span>
              ? Hành động này không thể hoàn tác.
            </p>

            <div className="flex justify-center gap-3 mt-6">
              <button
                type="button"
                onClick={() => setDeletingUser(null)}
                className="px-4 py-2 rounded-xl border border-slate-200 dark:border-slate-800 text-sm font-medium hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-700 dark:text-slate-300"
              >
                Hủy bỏ
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                data-testid="btn-confirm-delete-user"
                className="px-4 py-2 rounded-xl bg-rose-500 hover:bg-rose-600 text-white font-semibold text-sm transition-all shadow-sm"
              >
                Xác nhận Xóa
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UserManagementView;
