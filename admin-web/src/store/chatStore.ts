import { useSyncExternalStore } from 'react';
import type { CustomerChatMessage } from '../types';

const CHAT_STORAGE_KEY = 'sporthub_admin_chat_store_v1';

const INITIAL_MESSAGES: CustomerChatMessage[] = [
  {
    id: 'msg_01',
    venueId: 'venue_01',
    venueName: 'CLB Cầu Lông Tao Đàn',
    customerId: 'user_player_01',
    customerName: 'Nguyễn Văn An',
    senderRole: 'customer',
    text: 'Dạ chào chủ sân, sân bên mình tối nay có sẵn vợt cho thuê không ạ?',
    createdAt: new Date(Date.now() - 45 * 60 * 1000).toISOString(),
    isRead: true,
  },
  {
    id: 'msg_02',
    venueId: 'venue_01',
    venueName: 'CLB Cầu Lông Tao Đàn',
    customerId: 'user_player_01',
    customerName: 'Nguyễn Văn An',
    senderRole: 'owner',
    text: 'Chào bạn An! Sân Tao Đàn luôn có sẵn vợt Yonex chính hãng và nước điện giải tại quầy lễ tân nhé. Bạn cứ ghé quầy nhận sân là có!',
    createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
    isRead: true,
  },
  {
    id: 'msg_03',
    venueId: 'venue_01',
    venueName: 'CLB Cầu Lông Tao Đàn',
    customerId: 'user_player_02',
    customerName: 'Trần Thị Mai',
    senderRole: 'customer',
    text: 'Shop cho em hỏi bên mình có giữ chỗ theo tháng giờ vàng 18h - 20h được không ạ?',
    createdAt: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
    isRead: false,
  },
  {
    id: 'msg_04',
    venueId: 'venue_bt_01',
    venueName: 'CLB Cầu Lông & Pickleball Bình Thạnh Sport',
    customerId: 'user_player_03',
    customerName: 'Lê Hoàng Nam',
    senderRole: 'customer',
    text: 'Bên mình có sân Pickleball mái che không admin ơi?',
    createdAt: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
    isRead: false,
  },
];

export interface ChatStoreState {
  messages: CustomerChatMessage[];
  activeCustomerId: string | null;
}

class ChatStoreEngine {
  private state: ChatStoreState;
  private listeners: Set<() => void> = new Set();

  constructor() {
    this.state = this.loadInitial();
    if (typeof window !== 'undefined') {
      void this.fetchMessages();
      setInterval(() => {
        void this.fetchMessages();
      }, 3000);
    }
  }

  public fetchMessages = async (): Promise<void> => {
    if (typeof window === 'undefined') return;
    try {
      const res = await fetch('/api/chat/messages');
      if (res.ok) {
        const serverMsgs: CustomerChatMessage[] = await res.json();
        if (Array.isArray(serverMsgs) && serverMsgs.length > 0) {
          const currentMap = new Map(this.state.messages.map((m) => [m.id, m]));
          for (const s of serverMsgs) {
            currentMap.set(s.id, s);
          }
          const merged = Array.from(currentMap.values());
          merged.sort(
            (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime(),
          );
          this.state = {
            ...this.state,
            messages: merged,
          };
          this.save();
          this.notify();
        }
      }
    } catch {
      // Fallback in test environment
    }
  };

  private loadInitial(): ChatStoreState {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        const stored = window.localStorage.getItem(CHAT_STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored);
          return {
            messages: Array.isArray(parsed.messages) ? parsed.messages : INITIAL_MESSAGES,
            activeCustomerId: parsed.activeCustomerId ?? 'user_player_02',
          };
        }
      } catch {
        // fallback
      }
    }
    return {
      messages: INITIAL_MESSAGES,
      activeCustomerId: 'user_player_02',
    };
  }

  private save(): void {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.setItem(CHAT_STORAGE_KEY, JSON.stringify(this.state));
      } catch {
        // ignore
      }
    }
  }

  private notify(): void {
    this.listeners.forEach((listener) => listener());
  }

  public subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  };

  public getSnapshot = (): ChatStoreState => {
    return this.state;
  };

  public setActiveCustomerId = (id: string | null): void => {
    const updatedMessages = id
      ? this.state.messages.map((m: CustomerChatMessage) =>
          m.customerId === id ? { ...m, isRead: true } : m
        )
      : this.state.messages;

    this.state = {
      ...this.state,
      activeCustomerId: id,
      messages: updatedMessages,
    };
    this.save();
    this.notify();
  };

  public sendMessage = (payload: {
    venueId: string;
    venueName: string;
    customerId: string;
    customerName: string;
    text: string;
    senderRole?: 'owner' | 'admin';
  }): void => {
    const newMsg: CustomerChatMessage = {
      id: `msg_${Date.now()}`,
      venueId: payload.venueId,
      venueName: payload.venueName,
      customerId: payload.customerId,
      customerName: payload.customerName,
      senderRole: payload.senderRole ?? 'owner',
      text: payload.text.trim(),
      createdAt: new Date().toISOString(),
      isRead: true,
    };

    this.state = {
      ...this.state,
      messages: [...this.state.messages, newMsg],
    };
    this.save();
    this.notify();

    if (typeof window !== 'undefined') {
      fetch('/api/chat/messages', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newMsg),
      }).catch(() => {});
    }
  };

  public markThreadAsRead = (customerId: string): void => {
    this.state = {
      ...this.state,
      messages: this.state.messages.map((m: CustomerChatMessage) =>
        m.customerId === customerId ? { ...m, isRead: true } : m
      ),
    };
    this.save();
    this.notify();
  };
}

export const chatStore = new ChatStoreEngine();

export function useChatStore() {
  const data = useSyncExternalStore(
    chatStore.subscribe,
    chatStore.getSnapshot,
    chatStore.getSnapshot
  );

  return {
    ...data,
    setActiveCustomerId: chatStore.setActiveCustomerId,
    sendMessage: chatStore.sendMessage,
    markThreadAsRead: chatStore.markThreadAsRead,
  };
}
