import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const catalog = JSON.parse(readFileSync(new URL('./catalog.json', import.meta.url), 'utf8'));
assert.equal(catalog.schemaVersion, 1);
assert.equal(catalog.endpoints.length, 16);
assert.equal(catalog.operations.length, 29);
assert.equal(catalog.operations.filter((x) => x.class === 'READ_ONLY').length, 9);
assert.equal(catalog.operations.filter((x) => x.class === 'WRITE').length, 17);
assert.equal(catalog.operations.filter((x) => x.class === 'MIXED').length, 2);
assert.equal(catalog.operations.filter((x) => x.class === 'UNKNOWN').length, 1);
assert.equal(catalog.operations.filter((x) => x.status === 'RUNTIME_READ_CONFIRMED').length, 5);
assert.equal(catalog.liveBusinessRequestsThisDiscovery, 0);
assert.equal(catalog.writeRequestsThisDiscovery, 0);
assert.equal(catalog.capabilities.find((x) => x.id === 'receivedInvoices').availability, 'YES');
assert.equal(catalog.capabilities.find((x) => x.id === 'viesVatStatus').availability, 'YES');
for (const endpoint of catalog.endpoints) {
  assert(!endpoint.endpoint.includes('localhost'));
  assert(!endpoint.endpoint.includes('127.0.0.1'));
}

const serialized = JSON.stringify(catalog);
assert(!/-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(serialized));
assert(!/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i.test(serialized));
assert(!/"(?:password|token|cookie|nif)"\s*:/i.test(serialized));
console.log('AT read discovery catalog: PASS');
