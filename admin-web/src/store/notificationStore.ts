import { useSyncExternalStore } from 'react';
import { useAuthStore } from './authStore';

export type NotificationType = 'booking' | 'checkin' | 'maintenance' | 'revenue';

export interface AdminNotification {
  id: string;
  title: string;
  message: string;
  timestamp: string;
  type: NotificationType;
  isRead: boolean;
  venueId?: string;
}

const INITIAL_NOTIFICATIONS: AdminNotification[] = [
  {
    id: 'notif_01',
    title: 'Đặt sân mới qua App',
    message: 'Khách vừa đặt Sân 02 ca 18:00 - 19:00 (Mã vé: #BK-8821)',
    timestamp: 'Vừa xong',
    type: 'booking',
    isRead: false,
    venueId: 'venue_01',
  },
  {
    id: 'notif_02',
    title: 'Check-in thành công tại quầy',
    message: 'Nguyễn Văn Nam đã check-in ca 17:00 Sân Pickleball 06',
    timestamp: '5 phút trước',
    type: 'checkin',
    isRead: false,
    venueId: 'venue_01',
  },
  {
    id: 'notif_03',
    title: 'Lịch nhắc bảo trì sân',
    message: 'Sân Cầu Lông 04 cần kiểm tra bóng đèn chiếu sáng lúc 21:00',
    timestamp: '20 phút trước',
    type: 'maintenance',
    isRead: false,
    venueId: 'venue_01',
  },
  {
    id: 'notif_04',
    title: 'Báo cáo doanh thu ca chiều',
    message: 'Doanh thu hôm nay vượt mốc 3.850.000 đ (+18% so với hôm qua)',
    timestamp: '1 giờ trước',
    type: 'revenue',
    isRead: true,
    venueId: 'venue_01',
  },
];

const NOTIFICATIONS_STORAGE_KEY = 'sporthub_notifications_store_v1';

class NotificationStoreEngine {
  private notifications: AdminNotification[] = this.loadInitial();
  private listeners: Set<() => void> = new Set();
  private cachedSnapshot: AdminNotification[] = this.notifications;

  private loadInitial(): AdminNotification[] {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        const stored = window.localStorage.getItem(NOTIFICATIONS_STORAGE_KEY);
        if (stored) {
          const parsed = JSON.parse(stored);
          if (Array.isArray(parsed)) return parsed;
        }
      } catch {
        // Ignore parse error
      }
    }
    return JSON.parse(JSON.stringify(INITIAL_NOTIFICATIONS));
  }

  private save(): void {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.setItem(
          NOTIFICATIONS_STORAGE_KEY,
          JSON.stringify(this.notifications)
        );
      } catch {
        // Ignore save error
      }
    }
  }

  private notify(): void {
    this.cachedSnapshot = [...this.notifications];
    this.listeners.forEach((listener) => listener());
  }

  public subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };

  public getSnapshot = (): AdminNotification[] => {
    return this.cachedSnapshot;
  };

  public getNotifications = (): AdminNotification[] => {
    return this.notifications;
  };

  public getUnreadCount = (): number => {
    return this.notifications.filter((n) => !n.isRead).length;
  };

  public markAsRead = (id: string): void => {
    const item = this.notifications.find((n) => n.id === id);
    if (item && !item.isRead) {
      item.isRead = true;
      this.save();
      this.notify();
    }
  };

  public markAllAsRead = (): void => {
    let changed = false;
    this.notifications.forEach((n) => {
      if (!n.isRead) {
        n.isRead = true;
        changed = true;
      }
    });
    if (changed) {
      this.save();
      this.notify();
    }
  };

  public addNotification = (
    notif: Omit<AdminNotification, 'id' | 'isRead'> & { id?: string; isRead?: boolean }
  ): AdminNotification => {
    const newNotif: AdminNotification = {
      id: notif.id || `notif_${Date.now()}`,
      title: notif.title,
      message: notif.message,
      timestamp: notif.timestamp,
      type: notif.type,
      isRead: notif.isRead || false,
      venueId: notif.venueId,
    };
    this.notifications.unshift(newNotif);
    this.save();
    this.notify();
    return newNotif;
  };

  public repairBookingNotification = (
    bookingId: string,
    venueId: string,
    venueName: string
  ): void => {
    let changed = false;
    for (const item of this.notifications) {
      if (bookingId && item.message.includes(bookingId)) {
        if (item.venueId !== venueId) {
          item.venueId = venueId;
          changed = true;
        }
        if (
          venueName &&
          item.message.includes('CLB Cầu Lông & Pickleball Tao Đàn') &&
          !venueName.includes('Tao Đàn')
        ) {
          item.message = item.message.replace(
            'CLB Cầu Lông & Pickleball Tao Đàn',
            venueName
          );
          changed = true;
        }
      }
    }
    if (changed) {
      this.save();
      this.notify();
    }
  };

  public reset = (): void => {
    this.notifications = JSON.parse(JSON.stringify(INITIAL_NOTIFICATIONS));
    this.save();
    this.notify();
  };
}

export const notificationStore = new NotificationStoreEngine();

export function useNotificationStore() {
  const allNotifications = useSyncExternalStore(
    notificationStore.subscribe,
    notificationStore.getSnapshot,
    notificationStore.getSnapshot
  );
  const { role, activeVenueId } = useAuthStore();

  const notifications =
    role === 'partner' && activeVenueId
      ? allNotifications.filter((n) => !n.venueId || n.venueId === activeVenueId)
      : allNotifications;

  return {
    notifications,
    unreadCount: notifications.filter((n) => !n.isRead).length,
    markAsRead: notificationStore.markAsRead,
    markAllAsRead: notificationStore.markAllAsRead,
    addNotification: notificationStore.addNotification,
    repairBookingNotification: notificationStore.repairBookingNotification,
    reset: notificationStore.reset,
  };
}
