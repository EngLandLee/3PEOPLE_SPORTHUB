import { useSyncExternalStore } from 'react';
import { UserRole, PartnerAccount, CustomerAccount } from '../types';
import { INITIAL_PARTNER_ACCOUNTS, INITIAL_CUSTOMER_ACCOUNTS } from './seedData';

const AUTH_STORAGE_KEY = 'sporthub_auth_store_v1';

export interface AuthStoreState {
  isAuthenticated: boolean;
  role: UserRole;
  activeVenueId: string;
  partnerAccounts: PartnerAccount[];
  customerAccounts: CustomerAccount[];
  staffProfile: {
    name: string;
    title: string;
    avatarUrl?: string;
  };
}

function getInitialAuthState(): AuthStoreState {
  if (typeof window !== 'undefined' && window.localStorage) {
    try {
      const stored = window.localStorage.getItem(AUTH_STORAGE_KEY);
      if (stored) {
        const parsed = JSON.parse(stored);
        if (parsed && parsed.role) {
          return {
            ...parsed,
            customerAccounts:
              parsed.customerAccounts && parsed.customerAccounts.length > 0
                ? parsed.customerAccounts
                : JSON.parse(JSON.stringify(INITIAL_CUSTOMER_ACCOUNTS)),
            isAuthenticated: parsed.isAuthenticated !== undefined ? parsed.isAuthenticated : true,
          };
        }
      }
    } catch {
      // Fall back to default
    }
  }

  return {
    isAuthenticated: true,
    role: 'superadmin',
    activeVenueId: 'venue_01',
    partnerAccounts: JSON.parse(JSON.stringify(INITIAL_PARTNER_ACCOUNTS)),
    customerAccounts: JSON.parse(JSON.stringify(INITIAL_CUSTOMER_ACCOUNTS)),
    staffProfile: {
      name: 'Trần Văn',
      title: 'Quản lý ca',
    },
  };
}

class AuthStoreEngine {
  private state: AuthStoreState = getInitialAuthState();
  private listeners: Set<() => void> = new Set();
  private cachedSnapshot: AuthStoreState = this.state;

  constructor() {
    if (typeof window !== 'undefined') {
      window.addEventListener('storage', (e) => {
        if (e.key === AUTH_STORAGE_KEY && e.newValue) {
          try {
            this.state = JSON.parse(e.newValue);
            this.notify();
          } catch {
            // Ignore parse errors
          }
        }
      });
    }
  }

  private save(): void {
    if (typeof window !== 'undefined' && window.localStorage) {
      try {
        window.localStorage.setItem(AUTH_STORAGE_KEY, JSON.stringify(this.state));
      } catch (err) {
        console.warn('Failed to save authStore to localStorage', err);
      }
    }
  }

  private notify(): void {
    this.cachedSnapshot = {
      ...this.state,
      partnerAccounts: [...this.state.partnerAccounts],
      customerAccounts: [...(this.state.customerAccounts || [])],
    };

    if (typeof window !== 'undefined') {
      try {
        window.dispatchEvent(new Event('sporthub_store_change'));
        window.dispatchEvent(new Event('sporthub_auth_store_change'));
      } catch {
        // Ignore in simulated test environment
      }
    }

    this.listeners.forEach((listener) => listener());
  }

  public subscribe = (listener: () => void): (() => void) => {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  };

  public getSnapshot = (): AuthStoreState => {
    return this.cachedSnapshot;
  };

  public reset = (): void => {
    this.state = {
      isAuthenticated: true,
      role: 'superadmin',
      activeVenueId: 'venue_01',
      partnerAccounts: JSON.parse(JSON.stringify(INITIAL_PARTNER_ACCOUNTS)),
      customerAccounts: JSON.parse(JSON.stringify(INITIAL_CUSTOMER_ACCOUNTS)),
      staffProfile: {
        name: 'Trần Văn',
        title: 'Quản lý ca',
      },
    };
    this.save();
    this.notify();
  };

  public isAuthenticated = (): boolean => {
    return this.state.isAuthenticated;
  };

  public login = (email: string, role?: UserRole): boolean => {
    const trimmed = email.trim().toLowerCase();

    // Check partner accounts
    const partner = this.state.partnerAccounts.find(
      (p) => p.email.toLowerCase() === trimmed,
    );

    let determinedRole: UserRole = role || (trimmed.includes('partner') || Boolean(partner) ? 'partner' : 'superadmin');
    let venueId = 'venue_01';
    let staffName = 'Admin Hệ Thống';
    let staffTitle = 'Super Admin';

    if (partner) {
      determinedRole = 'partner';
      venueId = partner.venueId;
      staffName = partner.fullName || partner.venueName;
      staffTitle = `Chủ Sân ${partner.venueName}`;
    } else if (trimmed.includes('partner') || role === 'partner') {
      determinedRole = 'partner';
      venueId = 'venue_01';
      staffName = 'Chủ Sân Tao Đàn';
      staffTitle = 'Đối tác Quản lý';
    }

    this.state.isAuthenticated = true;
    this.state.role = determinedRole;
    this.state.activeVenueId = venueId;
    this.state.staffProfile = {
      name: staffName,
      title: staffTitle,
    };
    this.save();
    this.notify();
    return true;
  };

  public logout = (): void => {
    this.state.isAuthenticated = false;
    this.save();
    this.notify();
  };

  public getRole = (): UserRole => {
    return this.state.role;
  };

  public setRole = (role: UserRole): void => {
    this.state.role = role;
    this.save();
    this.notify();
  };

  public getActiveVenueId = (): string => {
    return this.state.activeVenueId;
  };

  public setActiveVenueId = (venueId: string): void => {
    this.state.activeVenueId = venueId;
    this.save();
    this.notify();
  };

  public getPartnerAccounts = (): PartnerAccount[] => {
    return this.state.partnerAccounts;
  };

  public addPartnerAccount = (
    account: Omit<PartnerAccount, 'id' | 'createdAt'> & { id?: string }
  ): PartnerAccount => {
    const newAccount: PartnerAccount = {
      id: account.id || `acc_${Date.now()}`,
      fullName: account.fullName,
      email: account.email,
      phone: account.phone,
      venueId: account.venueId,
      venueName: account.venueName,
      role: account.role || 'partner',
      isActive: account.isActive !== undefined ? account.isActive : true,
      createdAt: new Date().toISOString(),
    };

    this.state.partnerAccounts.push(newAccount);
    this.save();
    this.notify();
    return newAccount;
  };

  public toggleAccountStatus = (id: string): boolean => {
    const account = this.state.partnerAccounts.find((a) => a.id === id);
    if (!account) return false;

    account.isActive = !account.isActive;
    this.save();
    this.notify();
    return true;
  };

  public getCustomerAccounts = (): CustomerAccount[] => {
    return this.state.customerAccounts || [];
  };

  public fetchCustomerAccounts = async (): Promise<void> => {
    try {
      const res = await fetch('/api/users');
      if (res.ok) {
        const data = await res.json();
        if (Array.isArray(data) && data.length > 0) {
          const current = this.state.customerAccounts || [];
          const merged = [...current];
          for (const u of data) {
            const idx = merged.findIndex(
              (m) =>
                m.email.toLowerCase() === u.email.toLowerCase() ||
                (m.phone && u.phone && m.phone.replace(/\s+/g, '') === u.phone.replace(/\s+/g, '')) ||
                m.id === u.id
            );
            if (idx === -1) {
              merged.unshift(u);
            } else {
              merged[idx] = { ...merged[idx], ...u };
            }
          }
          this.state.customerAccounts = merged;
          this.save();
          this.notify();
        }
      }
    } catch {
      // Keep current state if network unreachable
    }
  };

  public addCustomerAccount = (
    account: Omit<CustomerAccount, 'id' | 'createdAt'> & { id?: string }
  ): CustomerAccount => {
    const newAccount: CustomerAccount = {
      id: account.id || `user_${Date.now()}`,
      fullName: account.fullName,
      email: account.email,
      phone: account.phone,
      preferredSport: account.preferredSport || 'Cầu lông',
      skillLevel: account.skillLevel || 'Cơ bản',
      district: account.district || 'Quận 1',
      isActive: account.isActive !== undefined ? account.isActive : true,
      matchesPlayed: account.matchesPlayed ?? 0,
      createdAt: new Date().toISOString(),
    };

    this.state.customerAccounts = [newAccount, ...(this.state.customerAccounts || [])];
    this.save();
    this.notify();
    return newAccount;
  };

  public updateCustomerAccount = (
    id: string,
    updates: Partial<CustomerAccount>
  ): boolean => {
    const index = (this.state.customerAccounts || []).findIndex((a) => a.id === id);
    if (index === -1) return false;

    this.state.customerAccounts[index] = {
      ...this.state.customerAccounts[index],
      ...updates,
    };
    this.save();
    this.notify();
    return true;
  };

  public deleteCustomerAccount = (id: string): boolean => {
    const beforeLen = (this.state.customerAccounts || []).length;
    this.state.customerAccounts = (this.state.customerAccounts || []).filter(
      (a) => a.id !== id
    );
    if (this.state.customerAccounts.length === beforeLen) return false;

    this.save();
    this.notify();
    return true;
  };

  public toggleCustomerStatus = (id: string): boolean => {
    const account = (this.state.customerAccounts || []).find((a) => a.id === id);
    if (!account) return false;

    account.isActive = !account.isActive;
    this.save();
    this.notify();
    return true;
  };
}

export const authStore = new AuthStoreEngine();

export function useAuthStore() {
  const data = useSyncExternalStore(
    authStore.subscribe,
    authStore.getSnapshot,
    authStore.getSnapshot
  );

  return {
    ...data,
    isAuthenticated: authStore.isAuthenticated,
    login: authStore.login,
    logout: authStore.logout,
    getRole: authStore.getRole,
    setRole: authStore.setRole,
    getActiveVenueId: authStore.getActiveVenueId,
    setActiveVenueId: authStore.setActiveVenueId,
    getPartnerAccounts: authStore.getPartnerAccounts,
    addPartnerAccount: authStore.addPartnerAccount,
    toggleAccountStatus: authStore.toggleAccountStatus,
    getCustomerAccounts: authStore.getCustomerAccounts,
    addCustomerAccount: authStore.addCustomerAccount,
    updateCustomerAccount: authStore.updateCustomerAccount,
    deleteCustomerAccount: authStore.deleteCustomerAccount,
    toggleCustomerStatus: authStore.toggleCustomerStatus,
    reset: authStore.reset,
  };
}
