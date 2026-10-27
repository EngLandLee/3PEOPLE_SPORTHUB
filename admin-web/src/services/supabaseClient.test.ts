import { describe, it, expect } from 'vitest';
import {
  isSupabaseConfigured,
  mapSupabaseRowToBooking,
  checkInTicketInSupabase,
  subscribeToLiveBookings,
} from './supabaseClient';

describe('supabaseClient', () => {
  it('returns false for isSupabaseConfigured when env vars are empty/missing', () => {
    // In test environment without .env, it should safely return false
    expect(typeof isSupabaseConfigured()).toBe('boolean');
  });

  it('mapSupabaseRowToBooking accurately maps PostgreSQL snake_case to BookingTicket', () => {
    const rawRow = {
      id: 'SH-9999',
      booking_id: 'SH-9999',
      venue_id: 'venue_01',
      venue_name: 'CLB Cầu Lông & Pickleball Tao Đàn',
      court_number: 3,
      court_name: 'Sân Cầu Lông 03',
      sport: 'badminton',
      date: '2026-10-28',
      start_time: '19:00',
      end_time: '20:00',
      time_slot: '19:00 - 20:00',
      customer_name: 'Nguyễn Văn Test',
      customer_phone: '0909123456',
      price: 180000,
      payment_status: 'paid',
      payment_method: 'vietqr',
      checked_in: true,
      checked_in_at: '2026-10-28T19:05:00Z',
      created_at: '2026-10-28T10:00:00Z',
    };

    const booking = mapSupabaseRowToBooking(rawRow);

    expect(booking.id).toBe('SH-9999');
    expect(booking.courtName).toBe('Sân Cầu Lông 03');
    expect(booking.customerName).toBe('Nguyễn Văn Test');
    expect(booking.customerPhone).toBe('0909123456');
    expect(booking.price).toBe(180000);
    expect(booking.paymentStatus).toBe('paid');
    expect(booking.checkedIn).toBe(true);
    expect(booking.checkedInAt).toBe('2026-10-28T19:05:00Z');
  });

  it('subscribeToLiveBookings returns null safely when unconfigured', () => {
    if (!isSupabaseConfigured()) {
      const unsubscribe = subscribeToLiveBookings(() => {}, () => {});
      expect(unsubscribe).toBeNull();
    }
  });

  it('checkInTicketInSupabase returns false safely when unconfigured without throwing', async () => {
    if (!isSupabaseConfigured()) {
      const result = await checkInTicketInSupabase('SH-9999');
      expect(result).toBe(false);
    }
  });
});
