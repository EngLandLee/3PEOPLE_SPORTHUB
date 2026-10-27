export interface FormFieldSpec {
  key: string;
  label: string;
  type: 'text' | 'textarea' | 'number';
  required?: boolean;
  maxLength?: number;
  currentValue: string;
}

export interface ActionTarget {
  venueId: string;
  venueName: string;
  courtId: string;
  courtName: string;
  date: string;
  timeSlot: string;
  price: number;
}

export interface ActionProposal {
  id: string;
  tool: string;
  status: 'pending' | 'approved' | 'rejected' | 'cancelled' | 'executed';
  target: ActionTarget;
  form: FormFieldSpec[];
  createdAt: number;
  expiresAt: number;
}

export const activeProposals = new Map<string, ActionProposal>();

export function createMockProposal(params: {
  id?: string;
  venueId?: string;
  venueName: string;
  courtId: string;
  courtName: string;
  date: string;
  timeSlot: string;
  price: number;
}): ActionProposal {
  const id = params.id || `prop_${Date.now()}_${Math.random().toString(36).substr(2, 5)}`;
  const now = Date.now();
  return {
    id,
    tool: 'create_court_booking',
    status: 'pending',
    target: {
      venueId: params.venueId || 'venue_default',
      venueName: params.venueName,
      courtId: params.courtId,
      courtName: params.courtName,
      date: params.date,
      timeSlot: params.timeSlot,
      price: params.price,
    },
    form: [
      {
        key: 'timeSlot',
        label: 'Khung giờ chơi',
        type: 'text',
        required: true,
        currentValue: params.timeSlot,
      },
      {
        key: 'note',
        label: 'Ghi chú cho chủ sân',
        type: 'textarea',
        maxLength: 200,
        currentValue: '',
      },
    ],
    createdAt: now,
    expiresAt: now + 15 * 60 * 1000, // 15 phút
  };
}

export async function handleActionExecute(payload: {
  proposalId: string;
  approved: boolean;
  edits?: Record<string, any>;
}): Promise<{
  success: boolean;
  message: string;
  ticket?: any;
  error?: string;
}> {
  const proposal = activeProposals.get(payload.proposalId);
  if (!proposal) {
    return { success: false, error: 'proposal_not_found', message: 'Không tìm thấy đề xuất đặt sân này.' };
  }

  if (Date.now() > proposal.expiresAt) {
    proposal.status = 'rejected';
    return { success: false, error: 'proposal_expired', message: 'Đề xuất đặt sân đã hết hạn (quá 15 phút).' };
  }

  if (proposal.status !== 'pending') {
    return { success: false, error: 'proposal_invalid_state', message: 'Đề xuất này đã được xử lý trước đó.' };
  }

  if (!payload.approved) {
    proposal.status = 'rejected';
    return { success: true, message: 'Đã từ chối đề xuất đặt sân.' };
  }

  // Lọc an toàn qua Form Allowlist: chỉ chấp nhận các key có trong proposal.form
  const allowedKeys = new Set(proposal.form.map((f) => f.key));
  const sanitizedEdits: Record<string, string> = {};

  if (payload.edits && typeof payload.edits === 'object') {
    for (const [key, value] of Object.entries(payload.edits)) {
      if (allowedKeys.has(key) && typeof value === 'string') {
        const fieldSpec = proposal.form.find((f) => f.key === key);
        const maxLen = fieldSpec?.maxLength || 200;
        sanitizedEdits[key] = value.trim().slice(0, maxLen);
      }
    }
  }

  // Giá luôn lấy từ target gốc (Bất biến)
  const finalPrice = proposal.target.price;
  const finalTimeSlot = sanitizedEdits.timeSlot || proposal.target.timeSlot;
  const finalNote = sanitizedEdits.note || '';

  proposal.status = 'executed';

  const ticket = {
    id: `ticket_${Date.now()}`,
    courtId: proposal.target.courtId,
    courtName: proposal.target.courtName,
    venueName: proposal.target.venueName,
    date: proposal.target.date,
    timeSlot: finalTimeSlot,
    totalPrice: finalPrice,
    status: 'pending',
    note: finalNote,
  };

  return {
    success: true,
    message: 'Đặt sân thành công! Vé đã được lưu vào hệ thống.',
    ticket,
  };
}

export async function handleActionCancel(proposalId: string): Promise<{ success: boolean; message: string }> {
  const proposal = activeProposals.get(proposalId);
  if (proposal && proposal.status === 'pending') {
    proposal.status = 'cancelled';
  }
  return { success: true, message: 'Đã hủy đề xuất đặt sân.' };
}
