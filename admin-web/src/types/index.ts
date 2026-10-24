export type UserRole = 'superadmin' | 'partner';

export type SlotStatus = 'available' | 'bookedApp' | 'reservedManual' | 'maintenance';

export interface Venue {
  id: string;
  name: string;
  address: string;
  district: string;
  hotline: string;
  sports: string[];
  openTime: string;
  closeTime: string;
  baseHourlyRate: number;
  imageUrl: string;
  isActive: boolean;
  totalCourts?: number;
  description?: string;
}

export type SportType = 'badminton' | 'pickleball' | 'football' | 'tennis' | string;

export interface Court {
  id: string;
  venueId: string;
  name: string;
  sport: 'badminton' | 'pickleball' | 'football' | string;
  courtNumber?: number;
  surfaceType: string;
  facilityType: 'indoor' | 'outdoor';
  regularPrice: number;
  peakPrice: number;
  isActive: boolean;
}

export interface CourtSlot {
  id: string; // e.g. "court_01_08_00"
  courtId: string;
  courtName: string;
  venueId: string;
  date: string;
  startTime: string;
  endTime: string;
  price: number;
  isPeak: boolean;
  status: SlotStatus;
  ticketId?: string;
  customerName?: string;
  customerPhone?: string;
  note?: string;
}

export interface BookingTicket {
  id: string; // e.g. "SH-8291"
  slotId: string;
  courtId: string;
  courtName: string;
  venueId: string;
  venueName: string;
  sport: string;
  date: string;
  timeSlot: string; // "08:00 - 09:00"
  customerName: string;
  customerPhone: string;
  price: number;
  paymentStatus: 'paid' | 'pending' | 'cancelled';
  paymentMethod?: 'momo' | 'zalopay' | 'vnpay' | 'cash' | 'vietqr';
  checkedIn: boolean;
  checkedInAt?: string;
  createdAt: string;
}

export type Booking = BookingTicket;

export interface AddOnItem {
  id: string;
  name: string;
  category: 'beverage' | 'rental' | 'equipment';
  price: number;
  unit: string;
}

export interface PartnerAccount {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  venueId: string;
  venueName: string;
  role: 'partner' | 'superadmin';
  isActive: boolean;
  createdAt: string;
}

export interface TransactionRecord {
  id: string;
  venueId: string;
  type: 'court_booking' | 'pos_service';
  description: string;
  amount: number;
  paymentMethod: string;
  customerName: string;
  createdAt: string;
  status: 'completed' | 'refunded';
}
