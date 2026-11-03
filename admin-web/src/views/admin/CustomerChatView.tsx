import { useState, useMemo } from 'react';
import {
  MessageSquare,
  Search,
  Send,
  Building2,
  CheckCheck,
  Sparkles,
} from 'lucide-react';
import { useChatStore } from '../../store/chatStore';
import type { CustomerChatMessage } from '../../types';

export function CustomerChatView() {
  const { messages, activeCustomerId, setActiveCustomerId, sendMessage } = useChatStore();
  const [searchQuery, setSearchQuery] = useState('');
  const [replyText, setReplyText] = useState('');
  const [filterMode, setFilterMode] = useState<'all' | 'unread'>('all');

  // Group threads by customerId
  const threads = useMemo(() => {
    const map = new Map<string, CustomerChatMessage[]>();
    for (const msg of messages) {
      if (!map.has(msg.customerId)) {
        map.set(msg.customerId, []);
      }
      map.get(msg.customerId)!.push(msg);
    }

    const list = Array.from(map.entries()).map(([customerId, threadMsgs]) => {
      threadMsgs.sort(
        (a: CustomerChatMessage, b: CustomerChatMessage) =>
          new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      );
      const lastMsg = threadMsgs[threadMsgs.length - 1];
      const unreadCount = threadMsgs.filter(
        (m: CustomerChatMessage) => m.senderRole === 'customer' && !m.isRead
      ).length;

      return {
        customerId,
        customerName: lastMsg.customerName,
        venueId: lastMsg.venueId,
        venueName: lastMsg.venueName,
        lastMessage: lastMsg,
        unreadCount,
      };
    });

    list.sort(
      (a, b) =>
        new Date(b.lastMessage.createdAt).getTime() - new Date(a.lastMessage.createdAt).getTime()
    );

    return list.filter((t) => {
      if (filterMode === 'unread' && t.unreadCount === 0) return false;
      if (searchQuery) {
        const q = searchQuery.toLowerCase();
        return (
          t.customerName.toLowerCase().includes(q) ||
          t.venueName.toLowerCase().includes(q) ||
          t.lastMessage.text.toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [messages, searchQuery, filterMode]);

  const activeThread = threads.find((t) => t.customerId === activeCustomerId) || threads[0];
  const activeMessages = useMemo(() => {
    if (!activeThread) return [];
    return messages
      .filter((m: CustomerChatMessage) => m.customerId === activeThread.customerId)
      .sort(
        (a: CustomerChatMessage, b: CustomerChatMessage) =>
          new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
      );
  }, [messages, activeThread]);

  const handleSend = () => {
    if (!replyText.trim() || !activeThread) return;
    sendMessage({
      venueId: activeThread.venueId,
      venueName: activeThread.venueName,
      customerId: activeThread.customerId,
      customerName: activeThread.customerName,
      text: replyText.trim(),
    });
    setReplyText('');
  };

  const quickTemplates = [
    'Dạ sân bên mình luôn có sẵn vợt và nước uống tại quầy lễ tân nhé bạn!',
    'Dạ khung giờ 19h-21h tối nay bên mình còn 2 sân trống ạ, bạn có thể giữ chỗ ngay trên app nhé.',
    'Dạ hiện tại bên mình có chính sách đặt cố định theo tháng giảm 10% bạn nhé.',
  ];

  return (
    <div className="flex h-[calc(100vh-80px)] flex-col gap-4">
      {/* Page Title */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="flex items-center gap-2.5 text-2xl font-bold tracking-tight text-white">
            <MessageSquare className="h-6 w-6 text-lime-400" />
            Hộp thư Tin nhắn Trực tiếp
          </h1>
          <p className="mt-1 text-sm text-zinc-400">
            Trao đổi và phản hồi khách hàng theo thời gian thực giữa Khách đặt sân và Chủ cơ sở
          </p>
        </div>
      </div>

      {/* Main Chat Grid */}
      <div className="grid flex-1 grid-cols-12 overflow-hidden rounded-2xl border border-zinc-800 bg-zinc-950/70 shadow-2xl backdrop-blur-xl">
        {/* Left Column: Conversations List */}
        <div className="col-span-4 flex flex-col border-r border-zinc-800/80 bg-zinc-900/40">
          {/* Search & Filter Header */}
          <div className="space-y-3 p-4 border-b border-zinc-800/80">
            <div className="relative">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-zinc-400" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Tìm khách hàng hoặc CLB..."
                className="w-full rounded-xl border border-zinc-800 bg-zinc-900/90 pl-9 pr-3 py-2 text-sm text-zinc-200 placeholder-zinc-500 focus:border-lime-500/50 focus:outline-none focus:ring-1 focus:ring-lime-500/30"
              />
            </div>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setFilterMode('all')}
                className={`flex-1 rounded-lg py-1.5 text-xs font-semibold transition ${
                  filterMode === 'all'
                    ? 'bg-lime-500/20 text-lime-400 border border-lime-500/30'
                    : 'bg-zinc-800/60 text-zinc-400 hover:text-zinc-200'
                }`}
              >
                Tất cả ({threads.length})
              </button>
              <button
                type="button"
                onClick={() => setFilterMode('unread')}
                className={`flex-1 rounded-lg py-1.5 text-xs font-semibold transition ${
                  filterMode === 'unread'
                    ? 'bg-lime-500/20 text-lime-400 border border-lime-500/30'
                    : 'bg-zinc-800/60 text-zinc-400 hover:text-zinc-200'
                }`}
              >
                Chưa đọc
              </button>
            </div>
          </div>

          {/* Threads Scrollable List */}
          <div className="flex-1 overflow-y-auto divide-y divide-zinc-800/40">
            {threads.length === 0 ? (
              <div className="p-8 text-center text-sm text-zinc-500">
                Không tìm thấy cuộc trò chuyện nào
              </div>
            ) : (
              threads.map((t) => {
                const isSelected = activeThread?.customerId === t.customerId;
                const timeStr = new Date(t.lastMessage.createdAt).toLocaleTimeString('vi-VN', {
                  hour: '2-digit',
                  minute: '2-digit',
                });

                return (
                  <button
                    key={t.customerId}
                    type="button"
                    onClick={() => setActiveCustomerId(t.customerId)}
                    className={`w-full p-4 text-left transition flex items-start gap-3.5 ${
                      isSelected
                        ? 'bg-lime-500/10 border-l-4 border-lime-400'
                        : 'hover:bg-zinc-800/30'
                    }`}
                  >
                    <div className="relative flex-shrink-0">
                      <div className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-lime-500/20 to-emerald-500/10 border border-lime-500/30 text-lime-400 font-bold text-sm">
                        {t.customerName.charAt(0).toUpperCase()}
                      </div>
                      {t.unreadCount > 0 && (
                        <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-lime-500 text-[10px] font-bold text-black ring-2 ring-zinc-950">
                          {t.unreadCount}
                        </span>
                      )}
                    </div>

                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <span className="truncate text-sm font-semibold text-white">
                          {t.customerName}
                        </span>
                        <span className="text-[11px] text-zinc-500">{timeStr}</span>
                      </div>
                      <div className="mt-0.5 flex items-center gap-1.5 text-xs text-lime-400/90 truncate">
                        <Building2 className="h-3 w-3 flex-shrink-0" />
                        <span className="truncate">{t.venueName}</span>
                      </div>
                      <p className="mt-1 truncate text-xs text-zinc-400">
                        {t.lastMessage.senderRole !== 'customer' && (
                          <span className="text-zinc-500">Bạn: </span>
                        )}
                        {t.lastMessage.text}
                      </p>
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>

        {/* Right Column: Chat View */}
        {activeThread ? (
          <div className="col-span-8 flex flex-col bg-zinc-950/40">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-zinc-800/80 px-6 py-4 bg-zinc-900/30">
              <div className="flex items-center gap-3.5">
                <div className="flex h-10 w-10 items-center justify-center rounded-full bg-lime-500/20 text-lime-400 font-bold text-sm border border-lime-500/30">
                  {activeThread.customerName.charAt(0).toUpperCase()}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-sm font-bold text-white">{activeThread.customerName}</h3>
                    <span className="flex items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-medium text-emerald-400">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald-400"></span>
                      Khách hàng trực tuyến
                    </span>
                  </div>
                  <p className="text-xs text-zinc-400 flex items-center gap-1 mt-0.5">
                    <Building2 className="h-3 w-3 text-zinc-500" />
                    Cơ sở: <span className="text-zinc-300 font-medium">{activeThread.venueName}</span>
                  </p>
                </div>
              </div>
            </div>

            {/* Message Stream */}
            <div className="flex-1 space-y-4 overflow-y-auto p-6">
              {activeMessages.map((m: CustomerChatMessage) => {
                const isMe = m.senderRole !== 'customer';
                const time = new Date(m.createdAt).toLocaleTimeString('vi-VN', {
                  hour: '2-digit',
                  minute: '2-digit',
                });

                return (
                  <div
                    key={m.id}
                    className={`flex flex-col ${isMe ? 'items-end' : 'items-start'}`}
                  >
                    <div className="mb-1 flex items-center gap-1.5 text-[11px] text-zinc-500">
                      <span>{isMe ? 'Bạn (Chủ sân / Admin)' : m.customerName}</span>
                      <span>•</span>
                      <span>{time}</span>
                    </div>

                    <div
                      className={`max-w-[70%] rounded-2xl px-4 py-2.5 text-sm shadow-sm ${
                        isMe
                          ? 'bg-lime-500 text-black font-medium rounded-tr-sm'
                          : 'bg-zinc-800 text-zinc-100 rounded-tl-sm border border-zinc-700/60'
                      }`}
                    >
                      {m.text}
                    </div>

                    {isMe && (
                      <span className="mt-1 flex items-center gap-1 text-[10px] text-zinc-500">
                        <CheckCheck className="h-3 w-3 text-lime-400" />
                        Đã gửi
                      </span>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Quick Templates */}
            <div className="border-t border-zinc-800/60 bg-zinc-900/30 px-6 py-2.5 flex items-center gap-2 overflow-x-auto">
              <span className="flex items-center gap-1 text-[11px] font-semibold text-zinc-400 flex-shrink-0">
                <Sparkles className="h-3 w-3 text-lime-400" />
                Mẫu nhanh:
              </span>
              {quickTemplates.map((tpl, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => setReplyText(tpl)}
                  className="truncate max-w-[260px] rounded-lg border border-zinc-800 bg-zinc-900/80 px-2.5 py-1 text-xs text-zinc-300 hover:border-lime-500/40 hover:text-white transition"
                >
                  {tpl}
                </button>
              ))}
            </div>

            {/* Input Bar */}
            <div className="border-t border-zinc-800/80 p-4 bg-zinc-900/50">
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  handleSend();
                }}
                className="flex items-center gap-3"
              >
                <input
                  type="text"
                  value={replyText}
                  onChange={(e) => setReplyText(e.target.value)}
                  placeholder={`Gửi phản hồi cho ${activeThread.customerName}... (Enter để gửi)`}
                  className="flex-1 rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-2.5 text-sm text-zinc-100 placeholder-zinc-500 focus:border-lime-500/50 focus:outline-none focus:ring-1 focus:ring-lime-500/30"
                />
                <button
                  type="submit"
                  disabled={!replyText.trim()}
                  className="flex items-center gap-2 rounded-xl bg-lime-500 px-5 py-2.5 text-sm font-bold text-black transition hover:bg-lime-400 disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-lime-500/10"
                >
                  <Send className="h-4 w-4" />
                  Gửi
                </button>
              </form>
            </div>
          </div>
        ) : (
          <div className="col-span-8 flex items-center justify-center text-sm text-zinc-500">
            Chọn một cuộc hội thoại để bắt đầu trao đổi
          </div>
        )}
      </div>
    </div>
  );
}
