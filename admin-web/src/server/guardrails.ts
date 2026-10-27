export interface GuardrailCheckResult {
  allowed: boolean;
  reason?: string;
  violationType?: 'prompt_injection' | 'system_prompt_leak' | 'scope_violation';
}

const INJECTION_PATTERNS = [
  /\bignore\s+(all\s+)?(previous|prior|above)\s+instructions\b/i,
  /\bdisregard\s+(the\s+)?(system|previous)\b/i,
  /bỏ\s+qua\s+(mọi\s+)?(hướng\s+dẫn|chỉ\s+thị|quy\s+tắc|yêu\s+cầu\s+trên)/i,
  /quên\s+(hết\s+)?(hướng\s+dẫn|vai\s+trò|chỉ\s+thị)/i,
  /\bsystem\s+prompt\b/i,
  /reveal\s+(your\s+)?(system|prompt|instructions)\b/i,
  /in\s+ra\s+(prompt|chỉ\s+thị|hướng\s+dẫn)\s+hệ\s+thống/i,
  /\byou\s+are\s+now\b/i,
  /đặt\s+sân\s+(với\s+)?giá\s+0\s*(đ|k|vnd)?\b/i,
];

const PII_OR_KEY_PATTERNS = [
  /fpt_[a-zA-Z0-9_\-]{16,}/g,
  /sk-[a-zA-Z0-9_\-]{20,}/g,
  /AIza[0-9A-Za-z-_]{35}/g,
];

export function guardrailIn(text: string): GuardrailCheckResult {
  if (!text || !text.trim()) {
    return { allowed: true };
  }

  for (const pattern of INJECTION_PATTERNS) {
    if (pattern.test(text)) {
      return {
        allowed: false,
        reason: 'Phát hiện câu lệnh vi phạm quy tắc an toàn hoặc cố ý thao túng hệ thống.',
        violationType: 'prompt_injection',
      };
    }
  }

  return { allowed: true };
}

export function guardrailOut(reply: string): string {
  if (!reply) return '';
  let cleaned = reply.trim();

  for (const pattern of PII_OR_KEY_PATTERNS) {
    cleaned = cleaned.replace(pattern, '[REDACTED]');
  }

  return cleaned;
}
