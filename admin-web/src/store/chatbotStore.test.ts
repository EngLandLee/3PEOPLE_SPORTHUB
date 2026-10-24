import { describe, it, expect, vi, beforeEach, afterAll } from 'vitest';
import { chatbotStore } from './chatbotStore';

// Mock global fetch
const originalFetch = global.fetch;
const mockFetch = vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) });
global.fetch = mockFetch;

describe('chatbotStore', () => {
  afterAll(() => {
    global.fetch = originalFetch;
  });

  beforeEach(() => {
    vi.clearAllMocks();
    chatbotStore.reset();
    localStorage.clear();
  });

  it('should have initial config', () => {
    const config = chatbotStore.getConfig();
    expect(config).toBeDefined();
    expect(config.provider).toBe('ollama');
  });

  it('should get FAQs', () => {
    const faqs = chatbotStore.getFaqs();
    expect(Array.isArray(faqs)).toBe(true);
  });

  it('should update config and sync to API', async () => {
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true }) });
    
    const success = await chatbotStore.updateConfig({ temperature: 0.5 });
    
    expect(success).toBe(true);
    const config = chatbotStore.getConfig();
    expect(config.temperature).toBe(0.5);
    
    expect(mockFetch).toHaveBeenCalledWith('/api/chatbot/config', expect.objectContaining({
      method: 'POST',
      body: expect.stringContaining('"temperature":0.5')
    }));
  });

  it('should add an FAQ and sync to API', async () => {
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true, faq: { id: 'faq_123', question: 'Q', answer: 'A', category: 'General', isActive: true } }) });
    
    const newFaq = await chatbotStore.addFaq({
      question: 'Q',
      answer: 'A',
      category: 'General',
      isActive: true,
    });
    
    expect(newFaq).toBeDefined();
    expect(newFaq.id).toBe('faq_123'); // From mock
    expect(chatbotStore.getFaqs().some(f => f.id === newFaq.id)).toBe(true);
  });

  it('should delete an FAQ and sync to API', async () => {
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true, faq: { id: 'faq_delete', question: 'Q', answer: 'A', category: 'General', isActive: true } }) });
    
    const newFaq = await chatbotStore.addFaq({
      question: 'Q',
      answer: 'A',
      category: 'General',
      isActive: true,
    });
    
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true }) });
    
    const success = await chatbotStore.deleteFaq(newFaq.id);
    expect(success).toBe(true);
    expect(chatbotStore.getFaqs().some(f => f.id === newFaq.id)).toBe(false);
  });

  it('should update an FAQ and sync to API', async () => {
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true, faq: { id: 'faq_update', question: 'Q', answer: 'A', category: 'General', isActive: true } }) });
    
    const newFaq = await chatbotStore.addFaq({
      question: 'Q',
      answer: 'A',
      category: 'General',
      isActive: true,
    });
    
    mockFetch.mockResolvedValueOnce({ ok: true, json: async () => ({ success: true, faq: { ...newFaq, question: 'Q2' } }) });
    
    const updated = await chatbotStore.updateFaq(newFaq.id, { question: 'Q2' });
    expect(updated.question).toBe('Q2');
    expect(chatbotStore.getFaqs().find(f => f.id === newFaq.id)?.question).toBe('Q2');
  });

  it('should log a conversation', () => {
    const convo = {
      id: 'conv_1',
      messages: [{ sender: 'user' as const, text: 'Hi', timestamp: '2026-09-08' }],
      createdAt: '2026-09-08'
    };
    
    chatbotStore.logConversation(convo);
    const convos = chatbotStore.getConversations();
    expect(convos.some(c => c.id === 'conv_1')).toBe(true);
  });
});
