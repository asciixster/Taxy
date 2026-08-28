import assert from 'node:assert/strict';
import test from 'node:test';
import { parseSoapResponse } from '../../src/parser.mjs';

test('parses SOAP 1.1 faults independently of prefix', () => {
  const xml = '<?xml version="1.0"?><soap:Envelope><soap:Body><soap:Fault><faultcode>soap:Client</faultcode><faultstring>Invalid request</faultstring></soap:Fault></soap:Body></soap:Envelope>';
  const result = parseSoapResponse(xml, 500);
  assert.deepEqual(result.fault, { code: 'soap:Client', message: 'Invalid request', detail: null });
});

test('parses SOAP fault detail structurally', () => {
  const result = parseSoapResponse('<Envelope><Body><Fault><faultcode>Client</faultcode><faultstring>No</faultstring><detail>AT-001</detail></Fault></Body></Envelope>', 500);
  assert.deepEqual(result.fault, { code: 'Client', message: 'No', detail: 'AT-001' });
});

test('parses namespaced request identifiers', () => {
  const result = parseSoapResponse('<S:Envelope><S:Body><x:CorrelationId>safe-id</x:CorrelationId></S:Body></S:Envelope>', 200);
  assert.equal(result.requestId, 'safe-id');
});

test('labels non-XML responses without inventing a SOAP fault', () => {
  const result = parseSoapResponse('Bad gateway', 502);
  assert.equal(result.isXml, false);
  assert.equal(result.fault, null);
});
