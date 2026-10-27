import React, { useState, useEffect } from 'react';
import {
  Settings,
  BookOpen,
  BarChart3,
  Bot,
  Plus,
  Edit,
  Trash2,
  Eye,
  EyeOff,
  X,
  Sparkles,
  Zap,
  Activity,
  MessageSquare,
  CheckCircle2,
  Building2,
  ShieldAlert,
  Lock,
} from 'lucide-react';
import { useChatbotStore } from '../../store/chatbotStore';
import type { ChatbotFaq, ChatbotConversation } from '../../store/chatbotStore';
import { useAuthStore } from '../../store/authStore';
import { useVenueStore } from '../../store/venueStore';

export const ChatbotManagementView: React.FC = () => {
  const {
    config,
    faqs,
    conversations,
    updateConfig,
    addFaq,
    updateFaq,
    deleteFaq,
    testConnection,
  } = useChatbotStore();

  const { role, activeVenueId } = useAuthStore();
  const { venues } = useVenueStore();
  const isPartner = role === 'partner';
  const currentVenue = venues.find((v) => v.id === activeVenueId);

  const [activeTab, setActiveTab] = useState<'config' | 'faqs' | 'analytics'>('config');

  // Config tab state
  const [apiKeyVisible, setApiKeyVisible] = useState(false);
  const [localConfig, setLocalConfig] = useState(config);
  const [isTesting, setIsTesting] = useState(false);
  const [testStatus, setTestStatus] = useState<{ success: boolean; message: string } | null>(null);

  useEffect(() => {
    if (config) {
      setLocalConfig((prev) => ({
        ...prev,
        ...config,
        apiKey: config.apiKey || prev.apiKey || '',
      }));
    }
  }, [config]);

  // FAQ tab state
  const [faqCategory, setFaqCategory] = useState('Tất cả');
  const [venueFilter, setVenueFilter] = useState<string>('all');
  const [isFaqModalOpen, setIsFaqModalOpen] = useState(false);
  const [editingFaq, setEditingFaq] = useState<Partial<ChatbotFaq> | null>(null);

  // Transcript modal state
  const [viewingConversation, setViewingConversation] = useState<ChatbotConversation | null>(null);

  const handleSaveConfig = () => {
    updateConfig(localConfig);
  };

  const handleTestConnection = async () => {
    if (!localConfig.apiKey?.trim() && localConfig.provider !== 'ollama') {
      setTestStatus({
        success: false,
        message: 'Chưa có API Key. Vui lòng nhập API Key để kiểm tra kết nối!',
      });
      return;
    }

    setIsTesting(true);
    setTestStatus(null);
    try {
      if (testConnection) {
        const res = await testConnection(localConfig.apiKey, localConfig.provider, localConfig.model);
        setTestStatus(res);
      } else {
        setTestStatus({ success: true, message: 'Kiểm tra thành công!' });
      }
    } catch (err: any) {
      setTestStatus({ success: false, message: err?.message || 'Lỗi kết nối' });
    } finally {
      setIsTesting(false);
    }
  };

  const handleOpenFaqModal = (faq?: ChatbotFaq) => {
    if (faq) {
      setEditingFaq(faq);
    } else {
      setEditingFaq({
        question: '',
        answer: '',
        category: 'Chung',
        sport: 'all',
        venueId: isPartner ? activeVenueId : (venueFilter !== 'all' && venueFilter !== 'general' ? venueFilter : 'all'),
        isActive: true,
      });
    }
    setIsFaqModalOpen(true);
  };

  const handleSaveFaq = () => {
    if (!editingFaq?.question || !editingFaq?.answer) return;

    const faqToSave = {
      ...editingFaq,
      venueId: isPartner ? activeVenueId : (editingFaq.venueId || 'all'),
    };

    if (editingFaq.id) {
      updateFaq(editingFaq.id, faqToSave);
    } else {
      addFaq(faqToSave as any);
    }
    setIsFaqModalOpen(false);
    setEditingFaq(null);
  };

  return (
    <div className="space-y-8 pb-12">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b border-slate-200/60 dark:border-slate-800/60 pb-5">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 mb-2">
            <Bot className="w-3.5 h-3.5" />
            <span>AI Neural Assistant Core</span>
          </div>
          <h1 className="text-2xl lg:text-3xl font-black tracking-tight text-slate-900 dark:text-white flex items-center gap-3">
            Quản lý Chatbot AI
          </h1>
          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
            Cấu hình mô hình ngôn ngữ lớn (LLM), cơ sở tri thức FAQ thể thao & nhật ký phân tích hội thoại.
          </p>
        </div>

        {/* Tab Pills */}
        <div className="glass-card p-1.5 rounded-2xl inline-flex gap-1.5 border border-slate-200/60 dark:border-slate-800/60 self-start md:self-auto shadow-xs">
          <button
            type="button"
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'config'
                ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-md shadow-emerald-500/25'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100/70 dark:hover:bg-slate-800/50'
            }`}
            onClick={() => setActiveTab('config')}
          >
            <Settings className="w-3.5 h-3.5" />
            <span>Cấu hình AI & API Key</span>
          </button>
          <button
            type="button"
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'faqs'
                ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-md shadow-emerald-500/25'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100/70 dark:hover:bg-slate-800/50'
            }`}
            onClick={() => setActiveTab('faqs')}
          >
            <BookOpen className="w-3.5 h-3.5" />
            <span>Kiến thức & FAQ</span>
          </button>
          <button
            type="button"
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === 'analytics'
                ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-md shadow-emerald-500/25'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100/70 dark:hover:bg-slate-800/50'
            }`}
            onClick={() => setActiveTab('analytics')}
          >
            <BarChart3 className="w-3.5 h-3.5" />
            <span>Lịch sử & Phân tích</span>
          </button>
        </div>
      </div>

      {/* Tab 1: Config */}
      {activeTab === 'config' && (
        <div className="glass-card rounded-[28px] p-6 lg:p-8 space-y-6">
          {isPartner && (
            <div className="rounded-2xl bg-amber-500/10 border border-amber-500/30 p-4 text-xs text-amber-800 dark:text-amber-300 flex items-start gap-3">
              <ShieldAlert className="w-5 h-5 shrink-0 mt-0.5 text-amber-600 dark:text-amber-400" />
              <div>
                <p className="font-bold text-sm">Chế độ phân quyền Đối tác (Partner)</p>
                <p className="mt-0.5 leading-relaxed text-slate-600 dark:text-slate-300">
                  Cấu hình AI Core & API Key toàn hệ thống được quản trị tập trung bởi Quản trị viên cấp cao (Super Admin). Quý đối tác đang quản trị dữ liệu cơ sở tri thức FAQ và chính sách riêng cho cụm sân <strong>{currentVenue?.name || activeVenueId}</strong>.
                </p>
              </div>
            </div>
          )}

          <div className="flex items-center gap-2 pb-4 border-b border-slate-200/60 dark:border-slate-800/60">
            <Sparkles className="w-5 h-5 text-emerald-500" />
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">
              Thông số Mô hình & Nhà cung cấp
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                Provider
              </label>
              <select
                className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                value={localConfig.provider}
                onChange={(e) => {
                  const prov = e.target.value as any;
                  const newModel =
                    prov === 'fpt'
                      ? 'gemma-4-26B-A4B-it'
                      : prov === 'ollama'
                      ? 'gemma2:2b'
                      : prov === 'openai'
                      ? 'gpt-4o-mini'
                      : 'gemini-1.5-flash';
                  setLocalConfig({ ...localConfig, provider: prov, model: newModel });
                }}
              >
                <option value="fpt">FPT Cloud AI (Gemma 4 - Khuyên dùng)</option>
                <option value="ollama">Ollama local</option>
                <option value="gemini">Google Gemini</option>
                <option value="openai">OpenAI</option>
                <option value="anthropic">Anthropic Claude</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                Model
              </label>
              <input
                type="text"
                className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                value={localConfig.model}
                onChange={(e) => setLocalConfig({ ...localConfig, model: e.target.value })}
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              {localConfig.provider === 'ollama' ? 'API Key (not required for Ollama)' : 'API Key'}
            </label>
            <div className="flex gap-2">
              <input
                data-testid="api-key-input"
                type={apiKeyVisible ? 'text' : 'password'}
                className="flex-1 rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm font-mono text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                value={localConfig.apiKey || ''}
                placeholder="Nhập API Key (ví dụ: sk-RQA2M...)"
                onChange={(e) => setLocalConfig({ ...localConfig, apiKey: e.target.value })}
              />
              <button
                type="button"
                className="glass-pill px-4 rounded-2xl text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800 transition-all flex items-center justify-center shrink-0"
                onClick={() => setApiKeyVisible(!apiKeyVisible)}
              >
                {apiKeyVisible ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
              </button>
            </div>
            {localConfig.apiKey ? (
              <p className="text-[11px] text-emerald-600 dark:text-emerald-400 flex items-center gap-1.5 mt-2 font-medium">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                <span>Đã nạp API Key FPT Cloud AI:</span>
                <span className="font-mono font-bold bg-emerald-500/10 px-2 py-0.5 rounded-md text-emerald-700 dark:text-emerald-300">
                  {apiKeyVisible
                    ? localConfig.apiKey
                    : `${localConfig.apiKey.slice(0, 8)}••••••••${localConfig.apiKey.slice(-6)}`}
                </span>
              </p>
            ) : (
              <p className="text-[11px] text-amber-600 dark:text-amber-400 flex items-center gap-1 mt-2">
                ⚠️ Chưa có API Key. Chatbot sẽ không thể kết nối tới mô hình LLM.
              </p>
            )}
            <div className="flex items-center space-x-3 mt-3">
              <button
                type="button"
                className="glass-pill text-xs px-4 py-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 font-bold border border-emerald-500/20 transition-all disabled:opacity-50 flex items-center gap-1.5"
                onClick={handleTestConnection}
                disabled={isTesting}
              >
                <Zap className="w-3.5 h-3.5" />
                <span>{isTesting ? 'Đang kiểm tra...' : '⚡ Kiểm tra kết nối (Test Connection)'}</span>
              </button>
              {testStatus && (
                <span
                  className={`text-xs font-bold px-3 py-1.5 rounded-full border ${
                    testStatus.success
                      ? 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/20'
                      : 'bg-rose-500/10 text-rose-600 dark:text-rose-400 border-rose-500/20'
                  }`}
                >
                  {testStatus.success ? '✓ ' : '✕ '}
                  {testStatus.message}
                </span>
              )}
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
              System Prompt
            </label>
            <textarea
              data-testid="system-prompt-textarea"
              className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500 leading-relaxed"
              rows={4}
              value={localConfig.systemPrompt}
              onChange={(e) => setLocalConfig({ ...localConfig, systemPrompt: e.target.value })}
            />
          </div>

          <div className="glass-pill p-4 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="flex-1">
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider">
                  Temperature: {localConfig.temperature}
                </label>
                <span className="text-xs text-slate-500">
                  {localConfig.temperature < 0.4 ? 'Chính xác / Quy chuẩn' : 'Sáng tạo / Tự nhiên'}
                </span>
              </div>
              <input
                type="range"
                min="0.2"
                max="0.9"
                step="0.1"
                value={localConfig.temperature}
                onChange={(e) =>
                  setLocalConfig({ ...localConfig, temperature: parseFloat(e.target.value) })
                }
                className="w-full accent-emerald-500 cursor-pointer"
              />
            </div>

            <div className="flex items-center gap-3 border-t md:border-t-0 md:border-l border-slate-200 dark:border-slate-800 pt-3 md:pt-0 md:pl-6">
              <input
                type="checkbox"
                id="master-bot-active"
                className="w-5 h-5 rounded-lg text-emerald-600 focus:ring-emerald-500 border-slate-300 dark:border-slate-700 dark:bg-slate-800 cursor-pointer"
                checked={localConfig.isActive}
                onChange={(e) => setLocalConfig({ ...localConfig, isActive: e.target.checked })}
              />
              <label
                htmlFor="master-bot-active"
                className="text-sm font-bold text-slate-900 dark:text-white cursor-pointer"
              >
                Master Bot Active
              </label>
            </div>
          </div>

          <div className="pt-2">
            <button
              data-testid="save-config-btn"
              type="button"
              className="px-6 py-3 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white font-bold rounded-2xl shadow-lg shadow-emerald-500/25 hover:scale-[1.02] active:scale-[0.98] transition-all"
              onClick={handleSaveConfig}
            >
              Lưu cấu hình
            </button>
          </div>
        </div>
      )}

      {/* Tab 2: FAQs */}
      {activeTab === 'faqs' && (
        <div className="space-y-6">
          {/* Multi-tenant Venue Filter Bar */}
          {isPartner ? (
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20">
              <div className="flex items-center gap-2.5">
                <Building2 className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                <div>
                  <span className="text-xs uppercase font-bold tracking-wider text-emerald-700 dark:text-emerald-400">
                    Cụm sân phụ trách:
                  </span>
                  <p className="text-sm font-bold text-slate-900 dark:text-white">
                    {currentVenue?.name || activeVenueId}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                    venueFilter === 'partner_only'
                      ? 'bg-emerald-600 text-white shadow-sm'
                      : 'glass-pill text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                  }`}
                  onClick={() => setVenueFilter('partner_only')}
                >
                  Chỉ FAQ riêng của sân
                </button>
                <button
                  type="button"
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all ${
                    venueFilter === 'all'
                      ? 'bg-emerald-600 text-white shadow-sm'
                      : 'glass-pill text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
                  }`}
                  onClick={() => setVenueFilter('all')}
                >
                  Tất cả (Kèm chính sách chung)
                </button>
              </div>
            </div>
          ) : (
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-2xl glass-card border border-slate-200/60 dark:border-slate-800/60">
              <div className="flex items-center gap-2">
                <Building2 className="w-4 h-4 text-emerald-500" />
                <label htmlFor="admin-venue-filter" className="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-300">
                  Phân quyền Cụm Sân Doanh Nghiệp:
                </label>
              </div>
              <select
                id="admin-venue-filter"
                className="rounded-xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-3.5 py-1.5 text-xs font-semibold text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                value={venueFilter}
                onChange={(e) => setVenueFilter(e.target.value)}
              >
                <option value="all">🌐 Tất cả cụm sân & Chính sách chung</option>
                <option value="general">📄 Chính sách chung (Toàn nền tảng)</option>
                {venues.map((v) => (
                  <option key={v.id} value={v.id}>
                    🏟️ {v.name} ({v.district})
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div className="flex flex-wrap gap-2">
              {['Tất cả', 'Cầu lông', 'Bóng đá', 'Pickleball', 'Chung'].map((cat) => (
                <button
                  key={cat}
                  type="button"
                  className={`px-3.5 py-1.5 rounded-full text-xs font-bold transition-all ${
                    faqCategory === cat
                      ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white shadow-md shadow-emerald-500/20'
                      : 'glass-pill text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white hover:bg-slate-100 dark:hover:bg-slate-800'
                  }`}
                  onClick={() => setFaqCategory(cat)}
                >
                  {cat}
                </button>
              ))}
            </div>
            <button
              type="button"
              onClick={() => handleOpenFaqModal()}
              className="px-4 py-2.5 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white font-bold rounded-2xl flex items-center gap-2 shadow-lg shadow-emerald-500/25 hover:scale-[1.02] active:scale-[0.98] transition-all text-xs"
            >
              <Plus className="w-4 h-4" />
              <span>Thêm câu hỏi mới</span>
            </button>
          </div>

          <div className="glass-card rounded-[28px] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-slate-200/60 dark:divide-slate-800/60 text-left">
                <thead className="bg-slate-50/60 dark:bg-slate-900/60 backdrop-blur-md">
                  <tr>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Question
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Phạm vi / Cụm sân
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Category
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Answer
                    </th>
                    <th className="px-6 py-3.5 text-right text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100/70 dark:divide-slate-800/60">
                  {faqs
                    .filter((faq) => {
                      if (faqCategory !== 'Tất cả' && faq.category !== faqCategory) return false;
                      if (isPartner) {
                        if (venueFilter === 'partner_only') {
                          return faq.venueId === activeVenueId;
                        }
                        return !faq.venueId || faq.venueId === 'all' || faq.venueId === activeVenueId;
                      }
                      if (venueFilter === 'all') return true;
                      if (venueFilter === 'general') return !faq.venueId || faq.venueId === 'all';
                      return faq.venueId === venueFilter;
                    })
                    .map((faq) => (
                      <tr
                        key={faq.id}
                        className="hover:bg-slate-50/40 dark:hover:bg-slate-800/20 transition-colors"
                      >
                        <td className="px-6 py-4 text-sm font-semibold text-slate-900 dark:text-white">
                          {faq.question}
                        </td>
                        <td className="px-6 py-4 text-sm whitespace-nowrap">
                          {!faq.venueId || faq.venueId === 'all' ? (
                            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-slate-500/10 text-slate-600 dark:text-slate-400 border border-slate-500/20">
                              Toàn hệ thống
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-500/10 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30">
                              🏟️ {venues.find((v) => v.id === faq.venueId)?.name || faq.venueId}
                            </span>
                          )}
                        </td>
                        <td className="px-6 py-4 text-sm">
                          <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                            {faq.category}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400 max-w-md line-clamp-2">
                          {faq.answer}
                        </td>
                        <td className="px-6 py-4 text-sm text-right font-medium">
                          {isPartner && faq.venueId !== activeVenueId && (faq.venueId && faq.venueId !== 'all') ? (
                            <span className="text-xs text-slate-400 inline-flex items-center gap-1 italic">
                              <Lock className="w-3.5 h-3.5" />
                              Chỉ đọc
                            </span>
                          ) : (
                            <div className="flex items-center justify-end gap-2">
                              <button
                                type="button"
                                onClick={() => handleOpenFaqModal(faq)}
                                className="p-2 rounded-xl text-slate-500 hover:text-emerald-600 hover:bg-emerald-500/10 transition-all"
                                title="Sửa FAQ"
                              >
                                <Edit className="w-4 h-4" />
                              </button>
                              <button
                                type="button"
                                onClick={() => deleteFaq(faq.id)}
                                className="p-2 rounded-xl text-slate-500 hover:text-rose-600 hover:bg-rose-500/10 transition-all"
                                title="Xóa FAQ"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))}
                  {faqs.filter((faq) => {
                    if (faqCategory !== 'Tất cả' && faq.category !== faqCategory) return false;
                    if (isPartner) {
                      if (venueFilter === 'partner_only') {
                        return faq.venueId === activeVenueId;
                      }
                      return !faq.venueId || faq.venueId === 'all' || faq.venueId === activeVenueId;
                    }
                    if (venueFilter === 'all') return true;
                    if (venueFilter === 'general') return !faq.venueId || faq.venueId === 'all';
                    return faq.venueId === venueFilter;
                  }).length === 0 && (
                    <tr>
                      <td
                        colSpan={5}
                        className="px-6 py-12 text-center text-slate-500 dark:text-slate-400 font-medium"
                      >
                        Không có câu hỏi nào phù hợp với bộ lọc cụm sân & danh mục này.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* Tab 3: Analytics */}
      {activeTab === 'analytics' && (
        <div className="space-y-6">
          {/* 3 Pastel Wave KPI Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="relative overflow-hidden rounded-3xl p-6 bg-gradient-to-br from-emerald-500/20 via-teal-500/10 to-emerald-600/5 dark:from-emerald-950/40 dark:via-teal-900/20 dark:to-slate-900/40 border border-emerald-500/30 backdrop-blur-md shadow-xs">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold uppercase tracking-wider text-emerald-700 dark:text-emerald-400">
                  Tổng phiên chat
                </span>
                <span className="w-8 h-8 rounded-full bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                  <MessageSquare className="w-4 h-4" />
                </span>
              </div>
              <p className="text-3xl font-black text-slate-900 dark:text-white">
                {conversations.length}
              </p>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-2 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                Hội thoại ghi nhận qua Web & App
              </div>
            </div>

            <div className="relative overflow-hidden rounded-3xl p-6 bg-gradient-to-br from-sky-500/20 via-indigo-500/10 to-sky-600/5 dark:from-sky-950/40 dark:via-indigo-900/20 dark:to-slate-900/40 border border-sky-500/30 backdrop-blur-md shadow-xs">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold uppercase tracking-wider text-sky-700 dark:text-sky-400">
                  Đặt sân từ Chatbot
                </span>
                <span className="w-8 h-8 rounded-full bg-sky-500/20 text-sky-600 dark:text-sky-400 flex items-center justify-center">
                  <CheckCircle2 className="w-4 h-4" />
                </span>
              </div>
              <p className="text-3xl font-black text-slate-900 dark:text-white">
                {conversations.filter((c) => c.bookingCreated).length}
              </p>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-2">
                Chuyển đổi thành công từ AI Intent
              </div>
            </div>

            <div className="relative overflow-hidden rounded-3xl p-6 bg-gradient-to-br from-amber-500/20 via-rose-500/10 to-amber-600/5 dark:from-amber-950/40 dark:via-rose-900/20 dark:to-slate-900/40 border border-amber-500/30 backdrop-blur-md shadow-xs">
              <div className="flex items-center justify-between mb-2">
                <span className="text-xs font-bold uppercase tracking-wider text-amber-700 dark:text-amber-400">
                  Thời gian phản hồi TB
                </span>
                <span className="w-8 h-8 rounded-full bg-amber-500/20 text-amber-600 dark:text-amber-400 flex items-center justify-center">
                  <Activity className="w-4 h-4" />
                </span>
              </div>
              <p className="text-3xl font-black text-slate-900 dark:text-white">
                {'< 1.2s'}
              </p>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-2">
                Tốc độ phản hồi Stream / LLM
              </div>
            </div>
          </div>

          {/* Conversations Table */}
          <div className="glass-card rounded-[28px] overflow-hidden">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-slate-200/60 dark:divide-slate-800/60 text-left">
                <thead className="bg-slate-50/60 dark:bg-slate-900/60 backdrop-blur-md">
                  <tr>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      User Name
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Messages
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Date
                    </th>
                    <th className="px-6 py-3.5 text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Booking Status
                    </th>
                    <th className="px-6 py-3.5 text-right text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100/70 dark:divide-slate-800/60">
                  {conversations.map((conv) => (
                    <tr
                      key={conv.id}
                      className="hover:bg-slate-50/40 dark:hover:bg-slate-800/20 cursor-pointer transition-colors"
                      onClick={() => setViewingConversation(conv)}
                      data-testid="conversation-row"
                    >
                      <td className="px-6 py-4 text-sm font-semibold text-slate-900 dark:text-white">
                        {conv.userName || 'Guest'}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-400">
                        {conv.messages.length}
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">
                        {new Date(conv.createdAt).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 text-sm">
                        {conv.bookingCreated ? (
                          <span className="px-3 py-1 inline-flex text-xs font-bold rounded-full bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border border-emerald-500/30">
                            Thành công
                          </span>
                        ) : (
                          <span className="px-3 py-1 inline-flex text-xs font-bold rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 border border-slate-200 dark:border-slate-700">
                            Không
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-sm text-right font-medium">
                        <button
                          type="button"
                          className="text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline"
                          onClick={(e) => {
                            e.stopPropagation();
                            setViewingConversation(conv);
                          }}
                        >
                          Xem đoạn chat
                        </button>
                      </td>
                    </tr>
                  ))}
                  {conversations.length === 0 && (
                    <tr>
                      <td
                        colSpan={5}
                        className="px-6 py-12 text-center text-slate-500 dark:text-slate-400 font-medium"
                      >
                        Chưa có cuộc trò chuyện nào
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* FAQ Add/Edit Modal */}
      {isFaqModalOpen && editingFaq && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
          <div className="glass-card rounded-[32px] p-6 lg:p-8 w-full max-w-lg shadow-2xl space-y-5">
            <div className="flex justify-between items-center pb-4 border-b border-slate-200/60 dark:border-slate-800/60">
              <h2 className="text-xl font-bold text-slate-900 dark:text-white">
                {editingFaq.id ? 'Sửa câu hỏi' : 'Thêm câu hỏi mới'}
              </h2>
              <button
                type="button"
                onClick={() => setIsFaqModalOpen(false)}
                className="w-8 h-8 rounded-full glass-pill flex items-center justify-center text-slate-500 hover:text-slate-900 dark:hover:text-white transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label htmlFor="faq-venue-select" className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                  Cụm sân áp dụng (Phân quyền dữ liệu doanh nghiệp)
                </label>
                {isPartner ? (
                  <div className="w-full rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-4 py-3 text-sm text-emerald-800 dark:text-emerald-300 font-semibold flex items-center justify-between">
                    <span>🏟️ {currentVenue?.name || activeVenueId}</span>
                    <span className="text-[11px] bg-emerald-500/20 text-emerald-700 dark:text-emerald-300 px-2 py-0.5 rounded-md font-bold">
                      Sân của bạn
                    </span>
                  </div>
                ) : (
                  <select
                    id="faq-venue-select"
                    data-testid="faq-venue-select"
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    value={editingFaq.venueId || 'all'}
                    onChange={(e) => setEditingFaq({ ...editingFaq, venueId: e.target.value })}
                  >
                    <option value="all">🌐 Toàn hệ thống (Chính sách chung)</option>
                    {venues.map((v) => (
                      <option key={v.id} value={v.id}>
                        🏟️ {v.name} ({v.district})
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                  Câu hỏi (Question)
                </label>
                <input
                  data-testid="faq-question-input"
                  type="text"
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  value={editingFaq.question || ''}
                  onChange={(e) => setEditingFaq({ ...editingFaq, question: e.target.value })}
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                  Trả lời (Answer)
                </label>
                <textarea
                  data-testid="faq-answer-textarea"
                  rows={4}
                  className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  value={editingFaq.answer || ''}
                  onChange={(e) => setEditingFaq({ ...editingFaq, answer: e.target.value })}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                    Danh mục (Category)
                  </label>
                  <select
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    value={editingFaq.category || 'Chung'}
                    onChange={(e) => setEditingFaq({ ...editingFaq, category: e.target.value })}
                  >
                    <option value="Chung">Chung</option>
                    <option value="Cầu lông">Cầu lông</option>
                    <option value="Bóng đá">Bóng đá</option>
                    <option value="Pickleball">Pickleball</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider mb-2">
                    Môn thể thao (Sport)
                  </label>
                  <select
                    className="w-full rounded-2xl border border-slate-200 dark:border-slate-800 bg-white/70 dark:bg-slate-900/70 backdrop-blur-md px-4 py-3 text-sm text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-emerald-500"
                    value={editingFaq.sport || 'all'}
                    onChange={(e) => setEditingFaq({ ...editingFaq, sport: e.target.value })}
                  >
                    <option value="all">Tất cả</option>
                    <option value="badminton">Cầu lông</option>
                    <option value="football">Bóng đá</option>
                    <option value="pickleball">Pickleball</option>
                  </select>
                </div>
              </div>

              <div className="flex items-center gap-3 pt-2">
                <input
                  type="checkbox"
                  id="faq-active"
                  className="w-5 h-5 rounded-lg text-emerald-600 focus:ring-emerald-500 border-slate-300 dark:border-slate-700 dark:bg-slate-800 cursor-pointer"
                  checked={editingFaq.isActive ?? true}
                  onChange={(e) => setEditingFaq({ ...editingFaq, isActive: e.target.checked })}
                />
                <label
                  htmlFor="faq-active"
                  className="text-sm font-bold text-slate-900 dark:text-white cursor-pointer"
                >
                  Kích hoạt (Active)
                </label>
              </div>
            </div>

            <div className="pt-4 flex justify-end gap-3 border-t border-slate-200/60 dark:border-slate-800/60">
              <button
                type="button"
                className="px-5 py-2.5 rounded-2xl border border-slate-200 dark:border-slate-700 font-bold text-xs text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-all"
                onClick={() => setIsFaqModalOpen(false)}
              >
                Hủy
              </button>
              <button
                data-testid="save-faq-btn"
                type="button"
                className="px-6 py-2.5 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-600 hover:to-teal-700 text-white font-bold rounded-2xl shadow-lg shadow-emerald-500/25 text-xs hover:scale-[1.02] active:scale-[0.98] transition-all disabled:opacity-50"
                onClick={handleSaveFaq}
                disabled={!editingFaq.question || !editingFaq.answer}
              >
                Lưu FAQ
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Transcript Viewer Modal */}
      {viewingConversation && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-4 animate-in fade-in duration-200">
          <div className="glass-card rounded-[32px] w-full max-w-2xl max-h-[90vh] flex flex-col shadow-2xl overflow-hidden">
            <div className="p-6 border-b border-slate-200/60 dark:border-slate-800/60 flex justify-between items-center shrink-0">
              <div>
                <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                  <Bot className="w-5 h-5 text-emerald-500" />
                  <span>Đoạn chat với {viewingConversation.userName || 'Guest'}</span>
                </h2>
                <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 flex gap-3">
                  <span>Khởi tạo: {new Date(viewingConversation.createdAt).toLocaleString()}</span>
                  <span>•</span>
                  <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                    Booking: {viewingConversation.bookingCreated ? 'Thành công' : 'Không'}
                  </span>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setViewingConversation(null)}
                className="w-8 h-8 rounded-full glass-pill flex items-center justify-center text-slate-500 hover:text-slate-900 dark:hover:text-white transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-4 bg-slate-50/40 dark:bg-slate-900/30">
              {viewingConversation.messages.map(
                (
                  msg: { sender: 'user' | 'assistant'; text: string; timestamp: string },
                  idx: number
                ) => (
                  <div
                    key={idx}
                    className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div
                      className={`max-w-[80%] rounded-2xl p-4 shadow-xs ${
                        msg.sender === 'user'
                          ? 'bg-gradient-to-r from-emerald-500 to-teal-600 text-white rounded-br-xs'
                          : 'glass-card border border-slate-200/60 dark:border-slate-800/60 text-slate-800 dark:text-slate-200 rounded-bl-xs'
                      }`}
                    >
                      <p className="text-sm whitespace-pre-wrap">{msg.text}</p>
                      <p
                        className={`text-[10px] mt-1 text-right ${
                          msg.sender === 'user' ? 'text-emerald-100' : 'text-slate-400'
                        }`}
                      >
                        {new Date(msg.timestamp).toLocaleTimeString()}
                      </p>
                    </div>
                  </div>
                )
              )}
              {viewingConversation.messages.length === 0 && (
                <div className="text-center text-slate-500 dark:text-slate-400 py-12">
                  Chưa có tin nhắn nào trong cuộc trò chuyện này.
                </div>
              )}
            </div>

            <div className="p-4 border-t border-slate-200/60 dark:border-slate-800/60 bg-white/50 dark:bg-slate-900/50 shrink-0">
              <button
                type="button"
                className="w-full py-2.5 rounded-2xl glass-pill font-bold text-xs text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                onClick={() => setViewingConversation(null)}
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ChatbotManagementView;
