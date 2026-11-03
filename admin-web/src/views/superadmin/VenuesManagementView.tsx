import React, { useState } from 'react';
import {
  Building2,
  Plus,
  Search,
  MapPin,
  Phone,
  Power,
  Trash2,
  Edit2,
  Layers,
  CheckCircle,
  XCircle,
  X,
} from 'lucide-react';
import { useVenueStore } from '../../store/venueStore';
import { AddVenueModal } from '../../components/venues/AddVenueModal';
import { Venue } from '../../types';

export const VenuesManagementView: React.FC = () => {
  const { venues, updateVenue, deleteVenue } = useVenueStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [sportFilter, setSportFilter] = useState<'all' | 'badminton' | 'pickleball' | 'football'>('all');
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [editingVenue, setEditingVenue] = useState<Venue | null>(null);

  // Filter venues by search term & sport
  const filteredVenues = venues.filter((venue) => {
    const term = searchTerm.toLowerCase();
    const matchesSearch =
      venue.name.toLowerCase().includes(term) ||
      venue.district.toLowerCase().includes(term) ||
      venue.address.toLowerCase().includes(term);

    const matchesSport =
      sportFilter === 'all' || venue.sports.includes(sportFilter);

    return matchesSearch && matchesSport;
  });

  const handleToggleStatus = (id: string, currentStatus: boolean) => {
    updateVenue(id, { isActive: !currentStatus });
  };

  const handleDeleteVenue = (id: string) => {
    deleteVenue(id);
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Top Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="flex items-center gap-2 mb-1">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
              <Building2 className="w-3.5 h-3.5" />
              Hệ thống {venues.length} Cụm Sân
            </span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-black tracking-tight text-slate-900 dark:text-white">
            Quản lý Cụm Sân
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 font-medium mt-1">
            Danh sách, thông tin liên hệ và trạng thái hoạt động các cụm sân trên hệ thống.
          </p>
        </div>

        <button
          type="button"
          onClick={() => setIsAddModalOpen(true)}
          data-testid="btn-add-venue"
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-600/20 transition-all cursor-pointer w-fit"
        >
          <Plus className="w-4 h-4" />
          <span>Thêm Cụm Sân</span>
        </button>
      </div>

      {/* Filter & Search Bar */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
        {/* Search input */}
        <div className="relative w-full sm:w-80">
          <div className="glass-pill flex items-center gap-2.5 px-3.5 py-2 rounded-full focus-within:ring-2 focus-within:ring-emerald-500/30">
            <Search className="w-4 h-4 text-slate-400 shrink-0" />
            <input
              type="text"
              placeholder="Tìm kiếm cụm sân..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-transparent text-slate-900 dark:text-white placeholder-slate-400 text-xs font-medium focus:outline-hidden"
            />
          </div>
        </div>

        {/* Sport filters */}
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          <button
            type="button"
            onClick={() => setSportFilter('all')}
            className={`glass-pill px-4 py-2 rounded-full text-xs font-bold transition-all whitespace-nowrap ${
              sportFilter === 'all'
                ? 'bg-slate-900 dark:bg-white text-white dark:text-slate-900 shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Tất cả ({venues.length})
          </button>
          <button
            type="button"
            onClick={() => setSportFilter('badminton')}
            className={`glass-pill px-4 py-2 rounded-full text-xs font-bold transition-all whitespace-nowrap ${
              sportFilter === 'badminton'
                ? 'bg-emerald-600 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            🏸 Cầu lông
          </button>
          <button
            type="button"
            onClick={() => setSportFilter('pickleball')}
            className={`glass-pill px-4 py-2 rounded-full text-xs font-bold transition-all whitespace-nowrap ${
              sportFilter === 'pickleball'
                ? 'bg-cyan-600 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            🏓 Pickleball
          </button>
          <button
            type="button"
            data-testid="filter-sport-football"
            onClick={() => setSportFilter('football')}
            className={`glass-pill px-4 py-2 rounded-full text-xs font-bold transition-all whitespace-nowrap ${
              sportFilter === 'football'
                ? 'bg-emerald-600 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            ⚽ Bóng đá
          </button>
        </div>
      </div>

      {/* Venues Grid */}
      {filteredVenues.length === 0 ? (
        <div className="p-12 text-center rounded-2xl bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 text-slate-400">
          <Building2 className="w-10 h-10 mx-auto mb-3 opacity-40 text-slate-400" />
          <p className="font-semibold text-slate-600 dark:text-slate-300">
            Không tìm thấy cụm sân nào phù hợp
          </p>
          <p className="text-xs text-slate-400 mt-1">
            Hãy thử tìm bằng từ khóa khác hoặc xóa bộ lọc.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-2 gap-6">
          {filteredVenues.map((venue) => (
            <div
              key={venue.id}
              className={`group relative rounded-[28px] glass-card transition-all duration-300 hover:-translate-y-1 overflow-hidden flex flex-col justify-between ${
                venue.isActive
                  ? 'border border-white/60 dark:border-slate-800'
                  : 'opacity-80 border-amber-300/50 dark:border-amber-900/40'
              }`}
            >
              <div>
                {/* Image Banner */}
                <div className="relative h-44 w-full overflow-hidden bg-slate-100 dark:bg-slate-800">
                  <img
                    src={venue.imageUrl}
                    alt={venue.name}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />

                  {/* Badges on top */}
                  <div className="absolute top-3 left-3 flex items-center gap-2">
                    <span className="px-2.5 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-black/60 backdrop-blur-md text-white border border-white/20">
                      {venue.district}
                    </span>
                  </div>

                  <div className="absolute top-3 right-3 flex items-center gap-1.5">
                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold backdrop-blur-md ${
                        venue.isActive
                          ? 'bg-emerald-500/90 text-white'
                          : 'bg-amber-500/90 text-white'
                      }`}
                    >
                      {venue.isActive ? (
                        <>
                          <CheckCircle className="w-3.5 h-3.5" />
                          Hoạt động
                        </>
                      ) : (
                        <>
                          <XCircle className="w-3.5 h-3.5" />
                          Tạm đóng
                        </>
                      )}
                    </span>
                  </div>

                  {/* Title and Courts Count on bottom of image */}
                  <div className="absolute bottom-3 left-3 right-3 text-white">
                    <h3 className="text-lg font-bold truncate leading-tight drop-shadow-xs">
                      {venue.name}
                    </h3>
                    <div className="flex items-center gap-3 text-xs text-white/80 mt-1">
                      <span className="flex items-center gap-1">
                        <Layers className="w-3.5 h-3.5 text-emerald-400" />
                        {venue.totalCourts || 0} Sân thi đấu
                      </span>
                      <span>•</span>
                      <span>
                        {venue.openTime} - {venue.closeTime}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Content body */}
                <div className="p-5 space-y-3.5">
                  {/* Address */}
                  <div className="flex items-start gap-2.5 text-xs text-slate-600 dark:text-slate-400">
                    <MapPin className="w-4 h-4 text-slate-400 shrink-0 mt-0.5" />
                    <span className="line-clamp-1">{venue.address}</span>
                  </div>

                  {/* Hotline */}
                  <div className="flex items-center gap-2.5 text-xs text-slate-600 dark:text-slate-400">
                    <Phone className="w-4 h-4 text-slate-400 shrink-0" />
                    <span>Hotline: {venue.hotline}</span>
                  </div>

                  {/* Sports tags & Hourly rate */}
                  <div className="flex items-center justify-between pt-2 border-t border-slate-100 dark:border-slate-800/80">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      {venue.sports.map((sport) => (
                        <span
                          key={sport}
                          className="px-2 py-0.5 rounded-md text-[11px] font-semibold bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 uppercase tracking-wide"
                        >
                          {sport === 'badminton'
                            ? 'Cầu lông'
                            : sport === 'pickleball'
                            ? 'Pickleball'
                            : sport === 'football'
                            ? 'Bóng đá'
                            : sport}
                        </span>
                      ))}
                    </div>

                    <div className="text-right">
                      <span className="text-xs text-slate-400">Giá cơ bản:</span>
                      <div className="text-sm font-bold text-emerald-600 dark:text-emerald-400">
                        {venue.baseHourlyRate.toLocaleString('vi-VN')} đ/h
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Action Bar */}
              <div className="px-5 py-3.5 bg-slate-50/50 dark:bg-slate-900/50 border-t border-slate-100 dark:border-slate-800/80 flex items-center justify-between gap-2">
                <div className="text-[11px] text-slate-400 font-mono">ID: {venue.id}</div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setEditingVenue(venue)}
                    data-testid={`btn-edit-${venue.id}`}
                    title="Chỉnh sửa thông tin cụm sân"
                    className="glass-pill p-2 rounded-full text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-all cursor-pointer shadow-xs"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>

                  <button
                    type="button"
                    onClick={() => handleToggleStatus(venue.id, venue.isActive)}
                    data-testid={`toggle-status-${venue.id}`}
                    title={venue.isActive ? 'Tạm ngưng cụm sân' : 'Kích hoạt cụm sân'}
                    className={`glass-pill px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer shadow-xs ${
                      venue.isActive
                        ? 'text-amber-700 dark:text-amber-400 hover:bg-amber-50 dark:hover:bg-amber-950/40'
                        : 'text-emerald-700 dark:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-950/40'
                    }`}
                  >
                    <Power className="w-3.5 h-3.5" />
                    <span>{venue.isActive ? 'Ngưng' : 'Kích hoạt'}</span>
                  </button>

                  <button
                    type="button"
                    onClick={() => handleDeleteVenue(venue.id)}
                    data-testid={`btn-delete-${venue.id}`}
                    title="Xóa cụm sân"
                    className="glass-pill p-2 rounded-full text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 transition-all cursor-pointer shadow-xs"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Add Venue */}
      <AddVenueModal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
      />

      {/* Modal Edit Venue */}
      {editingVenue && (
        <EditVenueDialog
          venue={editingVenue}
          onClose={() => setEditingVenue(null)}
          onSave={(updates) => {
            updateVenue(editingVenue.id, updates);
            setEditingVenue(null);
          }}
        />
      )}
    </div>
  );
};

interface EditVenueDialogProps {
  venue: Venue;
  onClose: () => void;
  onSave: (updates: Partial<Venue>) => void;
}

const EditVenueDialog: React.FC<EditVenueDialogProps> = ({ venue, onClose, onSave }) => {
  const [name, setName] = useState(venue.name);
  const [address, setAddress] = useState(venue.address);
  const [district, setDistrict] = useState(venue.district);
  const [hotline, setHotline] = useState(venue.hotline);
  const [baseHourlyRate, setBaseHourlyRate] = useState(venue.baseHourlyRate);
  const [description, setDescription] = useState(venue.description || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSave({
      name,
      address,
      district,
      hotline,
      baseHourlyRate: Number(baseHourlyRate),
      description,
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
      <div className="relative w-full max-w-lg bg-white dark:bg-[#141B2D] border border-slate-200 dark:border-slate-800 rounded-3xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div className="flex items-center justify-between px-6 py-5 border-b border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-slate-900/40">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-500/10 text-blue-600 dark:text-blue-400 flex items-center justify-center border border-blue-500/20">
              <Edit2 className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                Chỉnh Sửa Thông Tin Cụm Sân
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Cập nhật thông tin chi tiết và mức giá cơ bản
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Tên Cụm Sân
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                Quận / Huyện
              </label>
              <input
                type="text"
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                required
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
                Hotline
              </label>
              <input
                type="text"
                value={hotline}
                onChange={(e) => setHotline(e.target.value)}
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Địa Chỉ
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              required
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Giá Thuê Cơ Bản (VNĐ/Giờ)
            </label>
            <input
              type="number"
              value={baseHourlyRate}
              step={10000}
              onChange={(e) => setBaseHourlyRate(Number(e.target.value))}
              required
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-600 dark:text-slate-400 uppercase tracking-wider mb-1.5">
              Mô Tả / Ghi Chú
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900/60 text-slate-900 dark:text-white text-sm resize-none"
            />
          </div>

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100 dark:border-slate-800">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2.5 rounded-xl text-sm font-semibold text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
            >
              Hủy
            </button>
            <button
              type="submit"
              className="px-5 py-2.5 rounded-xl text-sm font-semibold bg-blue-600 hover:bg-blue-500 text-white shadow-lg shadow-blue-600/20 transition-all cursor-pointer"
            >
              Lưu Thay Đổi
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
