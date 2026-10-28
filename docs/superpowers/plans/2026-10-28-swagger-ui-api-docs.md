# Swagger UI API Documentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xây dựng trang tài liệu tương tác API chuẩn OpenAPI 3.0.3 bằng Swagger UI cho toàn bộ hệ thống API backend SportHub (Vite Middleware Gateway) và tích hợp liên kết truy cập trên Web Admin Sidebar.

**Architecture:** Tạo tài liệu kỹ thuật `openapi.json` chứa đầy đủ 22 endpoints và schemas, trang `public/api-docs/index.html` tải Swagger UI 5.x qua CDN, cấu hình route `/api-docs` trong Vite middleware `apiSyncPlugin.ts`, và thêm nút liên kết "Tài liệu API (Swagger)" trên Sidebar của Web Admin.

**Tech Stack:** OpenAPI 3.0.3, Swagger UI 5.x (CDN standalone), Vite 6, TypeScript, React 19, Lucide React, Vitest.

## Global Constraints
- Tuân thủ tuyệt đối chuẩn OpenAPI Specification 3.0.3.
- Không cài đặt thêm các gói npm xung đột với React 19 (`swagger-ui-react` gây xung đột peer-dependencies); sử dụng `swagger-ui-dist` bundle qua CDN hoặc standalone static files.
- Đảm bảo 100% tests hiện tại của `admin-web` (106 tests) tiếp tục pass.
- Hỗ trợ đầy đủ tương tác "Try it out" từ trình duyệt tới các endpoint backend trên `http://localhost:5173`.

---

### Task 1: Tạo Đặc Tả Kỹ Thuật OpenAPI 3.0.3 (`openapi.json`)

**Files:**
- Create: `admin-web/public/api-docs/openapi.json`
- Test: `admin-web/test/openapiSpec.test.ts`

**Interfaces:**
- Produces: `admin-web/public/api-docs/openapi.json` - OpenAPI 3.0.3 compliant specification with components schemas for `SyncedCourt`, `SyncedVenue`, `SyncedBooking`, `ChatbotConfig`, `ChatbotFaq`, and all REST endpoints.

- [ ] **Step 1: Write test validating OpenAPI specification format and coverage**

```typescript
// admin-web/test/openapiSpec.test.ts
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
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm --prefix admin-web test -- --run admin-web/test/openapiSpec.test.ts`
Expected: FAIL with "spec file exists" or "ENOENT"

- [ ] **Step 3: Create `admin-web/public/api-docs/openapi.json`**

Generate full OpenAPI 3.0.3 specification covering all routes, parameters, requestBodies, and schemas.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm --prefix admin-web test -- --run admin-web/test/openapiSpec.test.ts`
Expected: PASS (all 3 tests pass)

- [ ] **Step 5: Commit**

```bash
git add admin-web/public/api-docs/openapi.json admin-web/test/openapiSpec.test.ts
git commit -m "feat(api-docs): add openapi 3.0.3 specification for sporthub"
```

---

### Task 2: Tạo Giao Diện Swagger UI (`public/api-docs/index.html`)

**Files:**
- Create: `admin-web/public/api-docs/index.html`
- Test: `admin-web/test/swaggerUiHtml.test.ts`

**Interfaces:**
- Consumes: `./openapi.json`
- Produces: Standalone Swagger UI web interface configured with SportHub branding.

- [ ] **Step 1: Write test for Swagger UI HTML page**

```typescript
// admin-web/test/swaggerUiHtml.test.ts
import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';

describe('Swagger UI HTML Page', () => {
  const htmlPath = path.resolve(__dirname, '../public/api-docs/index.html');

  it('index.html exists and links to swagger-ui CDN & openapi.json', () => {
    expect(fs.existsSync(htmlPath)).toBe(true);
    const html = fs.readFileSync(htmlPath, 'utf-8');

    expect(html).toContain('swagger-ui-bundle.js');
    expect(html).toContain('swagger-ui.css');
    expect(html).toContain('openapi.json');
    expect(html).toContain('SportHub');
    expect(html).toContain('SwaggerUIBundle');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npm --prefix admin-web test -- --run admin-web/test/swaggerUiHtml.test.ts`
Expected: FAIL with ENOENT

- [ ] **Step 3: Implement `admin-web/public/api-docs/index.html`**

Create HTML file with:
- Swagger UI CSS & JS via CDN (unpkg / cdnjs).
- Modern dark/navy themed top header with SportHub logo & title.
- SwaggerUIBundle initialization pointing to `./openapi.json`, with deepLinking, filter, and displayRequestDuration enabled.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm --prefix admin-web test -- --run admin-web/test/swaggerUiHtml.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add admin-web/public/api-docs/index.html admin-web/test/swaggerUiHtml.test.ts
git commit -m "feat(api-docs): create branded swagger ui html interface"
```

---

### Task 3: Cấu Hình Route `/api-docs` Trong Vite Middleware `apiSyncPlugin.ts`

**Files:**
- Modify: `admin-web/src/server/apiSyncPlugin.ts`
- Test: `admin-web/src/server/apiSyncPlugin.test.ts`

**Interfaces:**
- Consumes: HTTP request to `/api-docs` or `/api-docs/`
- Produces: Redirect to `/api-docs/index.html` or direct HTML streaming so users accessing `http://localhost:5173/api-docs` immediately see Swagger UI.

- [ ] **Step 1: Add unit test in `apiSyncPlugin.test.ts` for `/api-docs` route**

In `admin-web/src/server/apiSyncPlugin.test.ts`, add test case asserting that requests to `/api-docs` or `/api-docs/` are appropriately handled (redirected or served).

- [ ] **Step 2: Run test to verify it fails or needs implementation**

Run: `npm --prefix admin-web test -- --run src/server/apiSyncPlugin.test.ts`

- [ ] **Step 3: Update `admin-web/src/server/apiSyncPlugin.ts`**

Add route handling for `/api-docs` and `/api-docs/`:
```typescript
if (url === '/api-docs' || url === '/api-docs/') {
  res.statusCode = 302;
  res.setHeader('Location', '/api-docs/index.html');
  res.end();
  return;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm --prefix admin-web test -- --run src/server/apiSyncPlugin.test.ts`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add admin-web/src/server/apiSyncPlugin.ts admin-web/src/server/apiSyncPlugin.test.ts
git commit -m "feat(api-docs): add /api-docs redirect route in apiSyncPlugin"
```

---

### Task 4: Tích Hợp Điều Hướng "Tài Liệu API (Swagger)" Trên Sidebar Web Admin

**Files:**
- Modify: `admin-web/src/components/layout/Sidebar.tsx`
- Test: `admin-web/src/components/layout/AdminLayout.test.tsx`

**Interfaces:**
- Consumes: `NavItem` definition in `Sidebar.tsx`
- Produces: Navigation item with icon `FileCode2` linking to `/api-docs/index.html` with target `_blank`.

- [ ] **Step 1: Add test in `AdminLayout.test.tsx` for API docs link**

Add assertion that the sidebar renders `Tài liệu API (Swagger)` link with `href="/api-docs/index.html"`.

- [ ] **Step 2: Run test to verify it fails**

Run: `npm --prefix admin-web test -- --run src/components/layout/AdminLayout.test.tsx`
Expected: FAIL

- [ ] **Step 3: Update `Sidebar.tsx`**

1. Import `FileCode2` from `lucide-react`.
2. Add `isExternal?: boolean` to `NavItem`.
3. Add item `{ name: 'Tài liệu API (Swagger)', path: '/api-docs/index.html', icon: FileCode2, isExternal: true }` to both `superAdminNavItems` and `partnerNavItems`.
4. In render loop, if `item.isExternal` is true, render an `<a>` tag with `href={item.path}`, `target="_blank"`, `rel="noopener noreferrer"`.

- [ ] **Step 4: Run test to verify it passes**

Run: `npm --prefix admin-web test -- --run src/components/layout/AdminLayout.test.tsx`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add admin-web/src/components/layout/Sidebar.tsx admin-web/src/components/layout/AdminLayout.test.tsx
git commit -m "feat(navigation): add swagger api docs link to admin sidebar"
```

---

### Task 5: Kiểm Thử Toàn Diện & Nghiệm Thu (E2E & Full Vitest Suite)

**Files:**
- Verify: Full test suite in `admin-web`
- Verify: Live endpoints on `http://localhost:5173/api-docs` and `http://localhost:5173/api-docs/openapi.json`

- [ ] **Step 1: Run full test suite in `admin-web`**

Run: `npm --prefix admin-web test -- --run`
Expected: PASS (all tests pass)

- [ ] **Step 2: Verify live HTTP requests using curl**

Run:
```bash
curl -I http://localhost:5173/api-docs
curl -s http://localhost:5173/api-docs/openapi.json | head -n 30
curl -s http://localhost:5173/api-docs/index.html | head -n 30
```
Expected:
- `/api-docs` redirects (302) or serves Swagger UI
- `openapi.json` returns valid JSON with `openapi: "3.0.3"`
- `index.html` returns valid HTML containing `SwaggerUIBundle`

- [ ] **Step 3: Commit and summarize deliverable**

```bash
git commit -m "docs: finalize swagger ui api documentation deliverables" --allow-empty
```
