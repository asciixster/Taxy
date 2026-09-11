import assert from 'node:assert/strict';
import fs from 'node:fs';

const catalog = JSON.parse(fs.readFileSync(new URL('./operations.json', import.meta.url)));
assert.equal(catalog.schemaVersion, 1);
assert.equal(catalog.operations.length, 7);

const names = new Set();
for (const operation of catalog.operations) {
  assert.match(operation.name, /^[A-Za-z0-9]+Request$/);
  assert.ok(!names.has(operation.name), `duplicate operation: ${operation.name}`);
  names.add(operation.name);
  assert.ok(['READ_CANDIDATE', 'READ_CANDIDATE_SIDE_EFFECT_UNPROVEN', 'WRITE'].includes(operation.semantics));
  assert.ok(operation.liveGate);
}

const write = catalog.operations.filter((item) => item.semantics === 'WRITE');
assert.deepEqual(write.map((item) => item.name), ['submeterDeclaracaoMobileRequest']);
assert.ok(catalog.operations.filter((item) => item.liveGate.startsWith('BLOCKED')).length === 6);
assert.equal(catalog.operations.filter((item) => item.liveGate === 'ELIGIBLE').length, 0);

console.log(JSON.stringify({
  cataloguedOperations: catalog.operations.length,
  readCandidates: catalog.operations.length - write.length,
  confirmedReadOnly: 0,
  liveEligible: 0,
  writeOperations: write.length,
  writeRequests: 0
}));
