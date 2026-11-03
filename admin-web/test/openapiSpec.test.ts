import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

describe('OpenAPI Specification Test', () => {
  const specPath = path.resolve(__dirname, '../public/api-docs/openapi.json');

  it('spec file exists and is valid JSON', () => {
    expect(fs.existsSync(specPath)).toBe(true);
    const content = fs.readFileSync(specPath, 'utf-8');
    const spec = JSON.parse(content);

    expect(spec.openapi).toMatch(/^3\.0\./);
    expect(spec.info.title).toContain('SportHub');
    expect(spec.paths).toBeDefined();
  });

  it('contains all required API paths', () => {
    const content = fs.readFileSync(specPath, 'utf-8');
    const spec = JSON.parse(content);
    const paths = Object.keys(spec.paths);

    expect(paths).toContain('/api/auth/login');
    expect(paths).toContain('/api/auth/register');
    expect(paths).toContain('/api/auth/verify-otp');
    expect(paths).toContain('/api/auth/resend-otp');
    expect(paths).toContain('/api/auth/forgot-password');
    expect(paths).toContain('/api/auth/reset-password');
    expect(paths).toContain('/api/auth/logout');
    expect(paths).toContain('/api/sync');
    expect(paths).toContain('/api/sync/reset');
    expect(paths).toContain('/api/courts');
    expect(paths).toContain('/api/courts/{courtId}');
    expect(paths).toContain('/api/venues');
    expect(paths).toContain('/api/venues/{id}');
    expect(paths).toContain('/api/bookings');
    expect(paths).toContain('/api/bookings/{id}');
    expect(paths).toContain('/api/checkin');
    expect(paths).toContain('/api/chatbot/config');
    expect(paths).toContain('/api/chatbot/faqs');
    expect(paths).toContain('/api/chatbot/faqs/{id}');
    expect(paths).toContain('/api/chatbot/conversations');
    expect(paths).toContain('/api/chatbot/message');
    expect(paths).toContain('/api/chatbot/action/execute');
    expect(paths).toContain('/api/chatbot/action/cancel');
    expect(paths).toContain('/api/chatbot/test-connection');
  });

  it('defines necessary components schemas', () => {
    const content = fs.readFileSync(specPath, 'utf-8');
    const spec = JSON.parse(content);
    const schemas = spec.components?.schemas || {};

    expect(schemas.SyncedCourt).toBeDefined();
    expect(schemas.SyncedVenue).toBeDefined();
    expect(schemas.SyncedBooking).toBeDefined();
    expect(schemas.ChatbotConfig).toBeDefined();
    expect(schemas.ChatbotFaq).toBeDefined();
  });

  it('validates server info, securitySchemes, and additional schemas', () => {
    const content = fs.readFileSync(specPath, 'utf-8');
    const spec = JSON.parse(content);

    expect(spec.openapi).toBe('3.0.3');
    expect(spec.info.version).toBe('1.0.0');
    expect(Array.isArray(spec.servers)).toBe(true);
    expect(spec.servers.length).toBeGreaterThanOrEqual(1);

    expect(spec.components?.securitySchemes?.AdminBearerAuth).toBeDefined();
    expect(spec.components?.securitySchemes?.AdminBearerAuth.type).toBe('http');
    expect(spec.components?.securitySchemes?.AdminBearerAuth.scheme).toBe('bearer');

    const schemas = spec.components?.schemas || {};
    expect(schemas.ChatbotConversation).toBeDefined();
    expect(schemas.ActionProposal).toBeDefined();
  });
});
