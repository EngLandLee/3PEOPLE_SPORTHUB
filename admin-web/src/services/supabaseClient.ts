import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { BookingTicket } from '../types';

const envUrl = (typeof import.meta !== 'undefined' && (import.meta as any).env?.VITE_SUPABASE_URL) || '';
const envAnonKey = (typeof import.meta !== 'undefined' && (import.meta as any).env?.VITE_SUPABASE_ANON_KEY) || '';

/**
 * Returns true if Supabase URL and Anon Key are configured and not placeholders.
 */
export const isSupabaseConfigured = (): boolean => {
  return (
    typeof envUrl === 'string' &&
    typeof envAnonKey === 'string' &&
    envUrl.trim().length > 0 &&
    envAnonKey.trim().length > 0 &&
    !envUrl.includes('YOUR_PROJECT_REF') &&
    !envAnonKey.includes('YOUR_ANON_KEY')
  );
};

export const supabase: SupabaseClient | null = isSupabaseConfigured()
  ? createClient(envUrl, envAnonKey, {
      realtime: {
        params: {
          eventsPerSecond: 10,
        },
      },
    })
  : null;

/**
 * Map Postgres snake_case row to SportHub BookingTicket interface
 */
export function mapSupabaseRowToBooking(row: Record<string, unknown>): BookingTicket {
  const id = String(row.booking_id || row.id || '');
  const venueId = String(row.venue_id || 'venue_01');
  const courtNumber = Number(row.court_number || 1);
  const courtId = String(row.court_id || `court_0${courtNumber}`);
  const startTime = String(row.start_time || '18:00');
  const slotId = String(row.slot_id || `${courtId}_${startTime.replace(':', '_')}`);

  return {
    id,
    slotId,
    courtId,
    courtName: String(row.court_name || `Sân ${courtNumber}`),
    venueId,
    venueName: String(row.venue_name || 'CLB Cầu Lông & Pickleball Tao Đàn'),
    sport: String(row.sport || 'badminton'),
    date: String(row.date || new Date().toISOString().split('T')[0]),
    timeSlot: String(row.time_slot || `${startTime} - ${row.end_time || '19:00'}`),
    customerName: String(row.customer_name || 'Khách đặt qua App'),
    customerPhone: String(row.customer_phone || '0900 000 000'),
    price: Number(row.price || 0),
    paymentStatus: (row.payment_status as 'paid' | 'pending' | 'cancelled') || 'pending',
    paymentMethod: (row.payment_method as any) || 'vietqr',
    checkedIn: Boolean(row.checked_in),
    checkedInAt: row.checked_in_at ? String(row.checked_in_at) : undefined,
    createdAt: row.created_at ? String(row.created_at) : new Date().toISOString(),
  };
}

/**
 * Subscribes to live booking changes (INSERT, UPDATE) via Supabase Realtime WebSocket
 */
export function subscribeToLiveBookings(
  onInsert: (booking: BookingTicket) => void,
  onUpdate: (booking: BookingTicket) => void,
): (() => void) | null {
  if (!supabase) return null;

  try {
    const channel = supabase
      .channel('public:bookings')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'bookings' },
        (payload) => {
          const row = payload.new as Record<string, unknown>;
          const mapped = mapSupabaseRowToBooking(row);
          onInsert(mapped);
        }
      )
      .on(
        'postgres_changes',
        { event: 'UPDATE', schema: 'public', table: 'bookings' },
        (payload) => {
          const row = payload.new as Record<string, unknown>;
          const mapped = mapSupabaseRowToBooking(row);
          onUpdate(mapped);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  } catch (e) {
    console.warn('[SupabaseClient] Realtime subscription error:', e);
    return null;
  }
}

/**
 * Check-in ticket in Supabase PostgreSQL
 */
export async function checkInTicketInSupabase(ticketId: string): Promise<boolean> {
  if (!supabase) return false;
  const cleanId = ticketId.trim().toUpperCase();

  try {
    const { data, error } = await supabase.rpc('fn_checkin_booking', {
      p_ticket_id: cleanId,
    });
    if (!error && (data as { success?: boolean })?.success) {
      return true;
    }
  } catch {
    // Fall back to direct table update
  }

  try {
    const { error } = await supabase
      .from('bookings')
      .update({
        checked_in: true,
        checked_in_at: new Date().toISOString(),
      })
      .or(`id.ilike.${cleanId},booking_id.ilike.${cleanId}`);

    return !error;
  } catch (err) {
    console.error('[SupabaseClient] checkInTicketInSupabase error:', err);
    return false;
  }
}
