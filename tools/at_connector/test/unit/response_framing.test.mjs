import assert from 'node:assert/strict';
import test from 'node:test';
import { gzipSync } from 'node:zlib';
import { analyzeHttpResponseFraming, sanitizedFramingMetadata,
  SOAP11_NAMESPACE } from '../../src/response_framing.mjs';
import { parseFactIntWsResponse } from '../../src/factintws_parser.mjs';

const body = (prefix = 'soap') => `<?xml version="1.0"?><${prefix}:Envelope xmlns:${prefix}="${SOAP11_NAMESPACE}"><${prefix}:Body><EcraInicialResponse><EstadoOperacao>200</EstadoOperacao><Desc>ok</Desc><NumTotalFaturasPorValidar>5</NumTotalFaturasPorValidar><NumTotalFaturasPorAssociarReceita>0</NumTotalFaturasPorAssociarReceita><ValorTotalBeneficioProvisorio>503.39</ValorTotalBeneficioProvisorio></EcraInicialResponse></${prefix}:Body></${prefix}:Envelope>`;

for (const prefix of ['soap', 'SOAP-ENV', 'env']) {
  test(`SOAP 1.1 prefix ${prefix} is recognized by namespace`, () => {
    const xml = body(prefix);
    const framing = analyzeHttpResponseFraming({ bytes: Buffer.from(xml),
      headers: { 'content-type': 'text/xml; charset=UTF-8' }, httpStatus: 200 });
    assert.equal(framing.soap11EnvelopeDetected, true);
    assert.equal(framing.rootPrefix, prefix);
    assert.equal(parseFactIntWsResponse(xml, 'EcraInicial').totals.pendingValidation, 5);
  });
}

test('UTF-8 BOM and XML declaration preserve SOAP root detection', () => {
  const framing = analyzeHttpResponseFraming({ bytes: Buffer.concat([
    Buffer.from([0xef, 0xbb, 0xbf]), Buffer.from(body('env')),
  ]), headers: { 'content-type': 'text/xml;charset=utf-8' }, httpStatus: 200 });
  assert.equal(framing.bomPresent, true);
  assert.equal(framing.xmlDeclarationPresent, true);
  assert.equal(framing.soap11EnvelopeDetected, true);
});

test('wrong SOAP namespace fails closed', () => {
  const xml = body('env').replace(SOAP11_NAMESPACE, 'urn:wrong');
  assert.throws(() => parseFactIntWsResponse(xml, 'EcraInicial'),
    (error) => error.code === 'PARSING_ERROR' && error.field === 'Envelope');
});

test('HTTP metadata survives parser failure and raw body is excluded from sanitized shape', () => {
  const bytes = Buffer.from('<wrapper xmlns="urn:not-soap"/>');
  const framing = analyzeHttpResponseFraming({ bytes, httpStatus: 502,
    headers: { 'content-type': 'application/xml; charset=ISO-8859-1',
      'content-length': String(bytes.length), connection: 'close' } });
  assert.equal(framing.httpStatus, 502);
  assert.equal(framing.charset, 'iso-8859-1');
  assert.equal(framing.rootLocalName, 'wrapper');
  assert.equal(framing.soap11EnvelopeDetected, false);
  assert.equal(Object.hasOwn(sanitizedFramingMetadata(framing), 'decodedText'), false);
});

test('gzip metadata is inspected before one in-memory decompression', () => {
  const compressed = gzipSync(Buffer.from(body('soap')));
  const framing = analyzeHttpResponseFraming({ bytes: compressed,
    headers: { 'content-encoding': 'gzip', 'transfer-encoding': 'chunked' }, httpStatus: 200 });
  assert.equal(framing.gzipSignature, true);
  assert.equal(framing.autoDecompressionStatus, 'NEEDS_DECOMPRESSION');
  assert.equal(framing.soap11EnvelopeDetected, true);
});

test('HTML, JSON and malformed XML framing are classified without content output', () => {
  const html = analyzeHttpResponseFraming({ bytes: Buffer.from('<!doctype html><html></html>') });
  const json = analyzeHttpResponseFraming({ bytes: Buffer.from('{"status":"synthetic"}') });
  const malformed = analyzeHttpResponseFraming({ bytes: Buffer.from('<not-closed') });
  assert.equal(html.htmlDetected, true);
  assert.equal(json.jsonDetected, true);
  assert.equal(malformed.xmlDetected, true);
  assert.equal(malformed.rootLocalName, null);
});
