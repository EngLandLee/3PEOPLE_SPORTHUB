import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AdminLayout } from './AdminLayout';
import { authStore } from '../../store/authStore';
import { notificationStore } from '../../store/notificationStore';

describe('AdminLayout', () => {
  beforeEach(() => {
    authStore.reset();
    notificationStore.reset();
    document.documentElement.classList.remove('dark');
    localStorage.clear();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders Super Admin navigation items when role is superadmin', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng quan Sàn')).toBeInTheDocument();
    expect(screen.getByText('Quản lý Cụm Sân')).toBeInTheDocument();
    expect(screen.getByText('Tài khoản Chủ Sân')).toBeInTheDocument();
  });

  it('renders Swagger API documentation link with external target in sidebar', () => {
    authStore.setRole('superadmin');
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const swaggerLink = screen.getByRole('link', { name: /Tài liệu API \(Swagger\)/i });
    expect(swaggerLink).toBeInTheDocument();
    expect(swaggerLink).toHaveAttribute('href', '/api-docs/index.html');
    expect(swaggerLink).toHaveAttribute('target', '_blank');
    expect(swaggerLink).toHaveAttribute('rel', 'noopener noreferrer');
  });

  it('renders Venue Partner navigation items when role is partner', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner']}>
        <AdminLayout />
      </MemoryRouter>
    );

    expect(screen.getByText('Tổng quan Cụm Sân')).toBeInTheDocument();
    expect(screen.getByText('Quản lý Sân')).toBeInTheDocument();
    expect(screen.getByText('Lịch Sân Master')).toBeInTheDocument();
    expect(screen.getByText('Quầy Lễ Tân & Soát Vé')).toBeInTheDocument();
    expect(screen.getByText('Báo cáo Doanh thu')).toBeInTheDocument();

    const swaggerLink = screen.getByRole('link', { name: /Tài liệu API \(Swagger\)/i });
    expect(swaggerLink).toBeInTheDocument();
    expect(swaggerLink).toHaveAttribute('href', '/api-docs/index.html');
  });

  it('allows switching roles from the topbar switcher', () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const roleButton = screen.getByTestId('role-switcher-button');
    fireEvent.click(roleButton);

    // Switch to partner
    const partnerOption = screen.getByTestId('role-option-partner');
    fireEvent.click(partnerOption);

    expect(authStore.getRole()).toBe('partner');
  });

  it('displays partner venue selector / badge when role is partner', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const venueSelector = screen.getByTestId('venue-badge-or-selector');
    expect(venueSelector).toBeInTheDocument();
    expect(venueSelector).toHaveTextContent(/Tao Đàn/i);
  });

  it('toggles dark and light mode when clicking theme toggle button', () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const themeToggle = screen.getByTestId('theme-toggle-button');
    expect(themeToggle).toBeInTheDocument();

    // Click to toggle dark mode
    fireEvent.click(themeToggle);
    expect(document.documentElement.classList.contains('dark')).toBe(true);
    expect(localStorage.getItem('sporthub_theme')).toBe('dark');

    // Click again to toggle light mode
    fireEvent.click(themeToggle);
    expect(document.documentElement.classList.contains('dark')).toBe(false);
    expect(localStorage.getItem('sporthub_theme')).toBe('light');
  });

  it('displays staff avatar and title in topbar', () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    expect(screen.getByText('Trần Văn')).toBeInTheDocument();
    expect(screen.getByText('Quản lý ca')).toBeInTheDocument();
  });

  it('allows switching from partner back to superadmin', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const roleButton = screen.getByTestId('role-switcher-button');
    fireEvent.click(roleButton);

    const superAdminOption = screen.getByTestId('role-option-superadmin');
    fireEvent.click(superAdminOption);

    expect(authStore.getRole()).toBe('superadmin');
  });

  it('allows switching venue in partner mode', () => {
    authStore.setRole('partner');
    render(
      <MemoryRouter initialEntries={['/partner']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const venueSelector = screen.getByTestId('venue-badge-or-selector');
    fireEvent.click(venueSelector);

    // Look for another venue like "Sân Bóng Đá Mini Nam Sài Gòn"
    const namSaiGonOption = screen.getByText(/Nam Sài Gòn/i);
    fireEvent.click(namSaiGonOption);

    expect(authStore.getActiveVenueId()).toBe('venue_q7_03');
  });

  it('allows logging out from topbar and sidebar logout buttons', () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const topbarLogout = screen.getByTestId('btn-logout-topbar');
    expect(topbarLogout).toBeInTheDocument();
    fireEvent.click(topbarLogout);
    expect(authStore.isAuthenticated()).toBe(false);

    // Re-login and test sidebar logout
    authStore.login('admin@sporthub.vn', 'superadmin');
    expect(authStore.isAuthenticated()).toBe(true);

    const sidebarLogout = screen.getByTestId('btn-logout-sidebar');
    expect(sidebarLogout).toBeInTheDocument();
    fireEvent.click(sidebarLogout);
    expect(authStore.isAuthenticated()).toBe(false);
  });

  it('opens notification dropdown when clicking bell button and marks all as read', () => {
    render(
      <MemoryRouter initialEntries={['/admin']}>
        <AdminLayout />
      </MemoryRouter>
    );

    const bellButton = screen.getByTestId('btn-notification-bell');
    expect(bellButton).toBeInTheDocument();
    fireEvent.click(bellButton);

    expect(screen.getByRole('region', { name: /trung tâm thông báo/i })).toBeInTheDocument();
    expect(screen.getByText('Đặt sân mới qua App')).toBeInTheDocument();

    const markAllButton = screen.getByTestId('btn-mark-all-read');
    fireEvent.click(markAllButton);

    expect(screen.queryByTestId('btn-mark-all-read')).not.toBeInTheDocument();
  });
});
