import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const catalog = JSON.parse(readFileSync(new URL('./catalog.json', import.meta.url), 'utf8'));
const allowedClasses = new Set(['READ_ONLY', 'WRITE', 'MIXED', 'UNKNOWN']);
const ids = new Set();
for (const operation of catalog.operations) {
  if (ids.has(operation.id)) throw new Error(`duplicate operation id: ${operation.id}`);
  ids.add(operation.id);
  if (!allowedClasses.has(operation.class)) throw new Error(`invalid class: ${operation.id}`);
}
for (const endpoint of catalog.endpoints) {
  for (const operation of endpoint.operations) {
    if (!ids.has(operation)) throw new Error(`unknown operation ${operation} at ${endpoint.id}`);
  }
}
const counts = Object.fromEntries([...allowedClasses].map((kind) => [
  kind,
  catalog.operations.filter((operation) => operation.class === kind).length,
]));
console.log(JSON.stringify({
  catalog: fileURLToPath(new URL('./catalog.json', import.meta.url)),
  endpoints: catalog.endpoints.length,
  operations: catalog.operations.length,
  counts,
  runtimeReadConfirmed: catalog.operations.filter((operation) =>
    operation.class === 'READ_ONLY' && operation.status === 'RUNTIME_READ_CONFIRMED').length,
  liveBusinessRequests: catalog.liveBusinessRequestsThisDiscovery,
  writeRequests: catalog.writeRequestsThisDiscovery,
}, null, 2));
