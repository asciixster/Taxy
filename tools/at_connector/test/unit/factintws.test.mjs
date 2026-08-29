import assert from 'node:assert/strict';
import { generateKeyPairSync } from 'node:crypto';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import {
  assessFactIntWsReadiness, buildFactIntWsEnvelope, buildFactIntWsSecurityMaterial,
  FACTINTWS_ACTOR, FACTINTWS_AUTH_NAMESPACE, FACTINTWS_ENDPOINT_443,
  FACTINTWS_ENDPOINT_8443, FACTINTWS_NAMESPACE, FACTINTWS_OPERATION,
  FACTINTWS_PLANNED_CLIENT_IDENTITY, FACTINTWS_WSSE_NAMESPACE,
  factIntWsDigestBytes, factIntWsHttpContract, factIntWsOperations,
  factIntWsProtocolEvidence, FactIntWsEvidenceStatus, runFactIntWsFeasibility,
  sanitizedFactIntWsResearchEnvelope, serializeFactIntWsOperation,
} from '../../src/factintws.mjs';
import { parseFactIntInvoice, parseFactIntMoneyCents, parseFactIntWsResponse, toAtInvoiceDomain } from '../../src/factintws_parser.mjs';
import { redact } from '../../src/redaction.mjs';

const channel = Object.freeze({ system: 'A', version: 'Android SDK: synthetic' });
const syntheticNif = '000000000';
const fixture = (name) => readFileSync(new URL(`../fixtures/factintws_synthetic/${name}`, import.meta.url), 'utf8').trim();

test('official-app protocol constants are evidence, never runtime claims', () => {
  assert.equal(FACTINTWS_ENDPOINT_443, 'https://servicos.portaldasfinancas.gov.pt:443/mobile/a4/factintws/ws');
  assert.equal(FACTINTWS_ENDPOINT_8443, 'https://servicos.portaldasfinancas.gov.pt:8443/mobile/a4/factintws/ws');
  assert.equal(FACTINTWS_NAMESPACE, 'http://factemi.at.min_financas.pt/factintws');
  assert.equal(FACTINTWS_WSSE_NAMESPACE, 'http://schemas.xmlsoap.org/ws/2002/12/secext');
  assert.equal(FACTINTWS_AUTH_NAMESPACE, 'http://at.pt/wsp/auth');
  assert.equal(FACTINTWS_ACTOR, 'http://at.pt/actor/SPA');
  assert.equal(FACTINTWS_OPERATION, 'EcraInicial');
  assert.match(factIntWsProtocolEvidence.certificatePinning.value, /enforced/);
  for (const value of Object.values(factIntWsProtocolEvidence)) assert.notEqual(value.status, FactIntWsEvidenceStatus.RUNTIME);
});

test('digest vector proves exact SHA-1 input order and UTF-8 encoding', () => {
  const digest = factIntWsDigestBytes({ aesKey: Buffer.from('000102030405060708090a0b0c0d0e0f', 'hex'),
    created: '2026-08-29T12:34:56.789Z', password: 'synthetic-password' });
  assert.equal(digest.toString('hex'), '16f6c5f922bdc646515132f831ddb75a4589fe0b');
});

test('security material encrypts password, digest and nonce without exposing plaintext', () => {
  const { publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const material = buildFactIntWsSecurityMaterial({ aesKey: Buffer.alloc(16, 7), created: '2026-08-29T12:34:56.789Z',
    password: 'synthetic-password', rsaPublicKey: publicKey });
  assert.match(material.encryptedPassword, /^[A-Za-z0-9+/]+=*$/);
  assert.match(material.encryptedDigest, /^[A-Za-z0-9+/]+=*$/);
  assert.match(material.encryptedNonce, /^[A-Za-z0-9+/]+=*$/);
  assert.equal(JSON.stringify(material).includes('synthetic-password'), false);
});

test('four read-only request schemas serialize in official field order', () => {
  const cases = [
    ['EcraInicial', { nif: syntheticNif, year: '2026', channel }, ['Nif', 'Ano', 'CanalOrigem']],
    ['DadosContribuinte', { nif: syntheticNif, channel }, ['Nif', 'CanalOrigem']],
    ['FaturasPorClassificar', { nif: syntheticNif, year: '2026', channel }, ['Nif', 'Ano', 'CanalOrigem']],
    ['FaturasPorSetor', { nif: syntheticNif, sector: '01', year: '2026', index: '0', channel }, ['NifAdquirente', 'CodSetor', 'Ano', 'Indice', 'CanalOrigem']],
  ];
  const snapshots = ['ecra_inicial_request.xml', 'dados_contribuinte_request.xml', 'faturas_por_classificar_request.xml', 'faturas_por_setor_request.xml'];
  for (const [index, [operation, input, fields]] of cases.entries()) {
    const xml = serializeFactIntWsOperation(operation, input);
    assert.equal(xml, fixture(snapshots[index]));
    assert(xml.includes(`<app:${operation}Request`));
    let cursor = -1;
    for (const field of fields) { const next = xml.indexOf(`<app:${field}`, cursor + 1); assert(next > cursor); cursor = next; }
  }
});

test('SOAP envelope and HTTP contract match official-app serialization', () => {
  const credentials = { encryptedDigest: 'digest', encryptedPassword: 'password', encryptedNonce: 'nonce', created: '2026-08-29T12:34:56.789Z' };
  const xml = buildFactIntWsEnvelope({ username: syntheticNif, credentials, input: { nif: syntheticNif, year: '2026', channel } });
  assert(xml.includes('S:Actor="http://at.pt/actor/SPA"'));
  assert(xml.includes('at:Version="2"'));
  assert(xml.indexOf('<wss:Username>') < xml.indexOf('<wss:Password'));
  assert(xml.indexOf('<wss:Password') < xml.indexOf('<wss:Nonce>'));
  assert(xml.indexOf('<wss:Nonce>') < xml.indexOf('<wss:Created>'));
  const http = factIntWsHttpContract();
  assert.equal(http.headers.SOAPAction, `${FACTINTWS_NAMESPACE}/EcraInicial`);
  assert.equal(http.headers['Content-Type'], 'text/xml;charset=utf-8');
  assert.equal(http.timeoutMs, 120000);
});

test('protocol is offline-ready while feasibility command remains zero-network', async () => {
  assert.equal(assessFactIntWsReadiness().ready, true);
  const result = await runFactIntWsFeasibility({ transport: () => { throw new Error('must not run'); } });
  assert.equal(result.ready, true);
  assert.equal(result.networkRequests, 0);
  assert.equal(result.classification, 'READY_FOR_SEPARATELY_APPROVED_SINGLE_LIVE_TEST');
});

test('money parser returns integer cents without floating point', () => {
  assert.deepEqual(['0.00', '0.01', '1.00', '23.45', '1000.99'].map(parseFactIntMoneyCents), [0, 1, 100, 2345, 100099]);
  assert.throws(() => parseFactIntMoneyCents('1.234'));
});

test('typed invoice parser maps wire response separately from domain', () => {
  const xml = '<Fatura><IdDocumento>SYNTHETIC-ID</IdDocumento><NifEmitente>000000000</NifEmitente><DataDocumento>2026-01-02</DataDocumento><ValorTotal>23.45</ValorTotal><ValorIva>4.39</ValorIva><CodSetor>01</CodSetor></Fatura>';
  const invoice = parseFactIntInvoice(xml);
  assert.equal(invoice.wireType, 'FactIntInvoiceResponse');
  assert.equal(invoice.totalCents, 2345);
  assert.equal(invoice.vatCents, 439);
  assert.deepEqual(toAtInvoiceDomain(invoice), { source: 'FACTINTWS', date: '2026-01-02', totalCents: 2345, vatCents: 439, sectorCode: '01', sourceReferencePresent: true });
});

test('response parser handles success, empty, multiple, optional and unknown elements', () => {
  const xml = fixture('faturas_por_setor_success.xml');
  const result = parseFactIntWsResponse(xml, 'FaturasPorSetor');
  assert.equal(result.result.estadoOperacao, '200');
  assert.equal(result.invoices.length, 2);
  assert.equal(result.invoices[1].vatCents, null);
  assert(xml.includes('<SyntheticUnknownElement>'));
  const empty = parseFactIntWsResponse(fixture('faturas_por_classificar_empty.xml'), 'FaturasPorClassificar');
  assert.equal(empty.invoices.length, 0);
});

test('response parser fails closed on malformed invoice and parses SOAP fault', () => {
  const malformed = fixture('malformed_invoice.xml');
  assert.throws(() => parseFactIntWsResponse(malformed, 'FaturasPorSetor'), /DataDocumento/);
  const fault = parseFactIntWsResponse(fixture('soap_fault.xml'), 'EcraInicial');
  assert.equal(fault.fault.code, 'Client.Synthetic');
});

test('EcraInicial and DadosContribuinte synthetic response shapes parse without exposing data', () => {
  const initial = parseFactIntWsResponse(fixture('ecra_inicial_response.xml'), 'EcraInicial');
  assert.deepEqual(initial.totals, { pendingValidation: '2', pendingRevenueAssociation: '1', provisionalBenefitCents: 1234 });
  const taxpayer = parseFactIntWsResponse(fixture('dados_contribuinte_response.xml'), 'DadosContribuinte');
  assert.equal(taxpayer.taxpayerDataPresent, true);
});

test('research artefacts contain no official-app identity material or live path', () => {
  assert.equal(FACTINTWS_PLANNED_CLIENT_IDENTITY, 'TesteWebservices.pfx');
  const source = readFileSync(new URL('../../src/factintws.mjs', import.meta.url), 'utf8');
  assert.equal(/prod_client|qua_client|\.pkcs8/i.test(source), false);
  assert.equal(/networkRequests:\s*1/.test(source), false);
  const safe = redact({ username: syntheticNif, passwordDigest: 'digest-value', nonce: 'nonce-value', created: 'timestamp-value' });
  assert.equal(safe.passwordDigest, '[REDACTED]');
  assert.equal(safe.nonce, '[REDACTED]');
});

test('all eight requested operations are catalogued and write operations remain unavailable', () => {
  assert.equal(Object.keys(factIntWsOperations).length, 8);
  assert.equal(Object.values(factIntWsOperations).filter((entry) => entry.readOnly).length, 4);
  assert.throws(() => serializeFactIntWsOperation('ClassificarFatura', {}), /Unsupported read-only/);
  assert(!/\b[1-9]\d{8}\b/.test(sanitizedFactIntWsResearchEnvelope()));
});
