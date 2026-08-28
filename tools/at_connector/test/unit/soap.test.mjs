import assert from 'node:assert/strict';
import test from 'node:test';
import { connectivityProbeEnvelope, escapeXml, securityHeader, soapEnvelope } from '../../src/soap.mjs';

test('escapes every XML-sensitive character', () => {
  assert.equal(escapeXml(`<&>"'`), '&lt;&amp;&gt;&quot;&apos;');
});

test('serializes an explicit WS-Security header', () => {
  const header = securityHeader('user<&', { password: 'p', nonce: 'n', created: 'c' });
  assert.match(header, /<wss:Username>user&lt;&amp;<\/wss:Username>/);
  assert.match(header, /schemas.xmlsoap.org\/ws\/2002\/12\/secext/);
});

test('connectivity probe is a valid SOAP 1.1 envelope with an empty body', () => {
  const xml = connectivityProbeEnvelope();
  assert.match(xml, /^<\?xml version="1.0" encoding="UTF-8"\?>/);
  assert.match(xml, /http:\/\/schemas.xmlsoap.org\/soap\/envelope\//);
  assert.match(xml, /<S:Body><\/S:Body>/);
});

test('soap serializer places supplied body only inside Body', () => {
  assert.match(soapEnvelope({ body: '<InvoicesRequest/>' }), /<S:Body><InvoicesRequest\/><\/S:Body>/);
});
