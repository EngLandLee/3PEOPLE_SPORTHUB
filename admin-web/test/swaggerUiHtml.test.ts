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

  it('configures Swagger UI options with brand theme, deep linking, filter, and try it out', () => {
    const html = fs.readFileSync(htmlPath, 'utf-8');

    expect(html).toContain('deepLinking: true');
    expect(html).toContain('filter: true');
    expect(html).toContain('displayRequestDuration: true');
    expect(html).toContain('tryItOutEnabled: true');
    expect(html).toContain('href="/"');
  });
});
