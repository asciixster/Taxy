import assert from 'node:assert/strict';
import { constants, generateKeyPairSync, privateDecrypt } from 'node:crypto';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import {
  assessFactIntWsReadiness, assertFactIntWsLiveReadiness, buildFactIntWsEnvelope, buildFactIntWsSecurityMaterial,
  buildFactIntWsLiveReadinessMatrix, buildOfficialAppChannel,
  FACTINTWS_ACTOR, FACTINTWS_AUTH_NAMESPACE, FACTINTWS_ENDPOINT_443,
  FACTINTWS_ENDPOINT_8443, FACTINTWS_NAMESPACE, FACTINTWS_OPERATION,
  FACTINTWS_PLANNED_CLIENT_IDENTITY, FACTINTWS_WSSE_NAMESPACE,
  factIntWsDigestBytes, factIntWsHttpContract, factIntWsOperations, factIntWsTlsOptions,
  factIntWsProtocolEvidence, factIntWsRuntimeEvidence,
  FactIntWsChannelValueStatus, FactIntWsEvidenceStatus,
  resolveFactIntWsChannelFromEnvironment, runFactIntWsFeasibility,
  sanitizedFactIntWsResearchEnvelope, serializeFactIntWsOperation,
} from '../../src/factintws.mjs';
import { FactIntWsClient, FactIntWsRepository,
  runFactIntWsBootstrapSequence } from '../../src/factintws_client.mjs';
import { FactIntWsCreatedSource, resolveFactIntWsCreated, validateFactIntWsCreated } from '../../src/factintws_time.mjs';
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
  assert.equal(factIntWsRuntimeEvidence.endpoint8443.status, FactIntWsEvidenceStatus.RUNTIME);
  assert.equal(factIntWsRuntimeEvidence.endpoint8443.value, FACTINTWS_ENDPOINT_8443);
  assert.equal(factIntWsRuntimeEvidence.operation.value, 'EcraInicial');
});

test('digest vector proves exact SHA-1 input order and UTF-8 encoding', () => {
  const digest = factIntWsDigestBytes({ aesKey: Buffer.from('000102030405060708090a0b0c0d0e0f', 'hex'),
    created: '2026-08-29T12:34:56.789Z', password: 'synthetic-password' });
  assert.equal(digest.toString('hex'), '16f6c5f922bdc646515132f831ddb75a4589fe0b');
});

test('security material encrypts password, digest and nonce without exposing plaintext', () => {
  const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const aesKey = Buffer.from('000102030405060708090a0b0c0d0e0f', 'hex');
  const material = buildFactIntWsSecurityMaterial({ aesKey, created: '2026-08-29T12:34:56.789Z',
    password: 'synthetic-password', rsaPublicKey: publicKey });
  assert.equal(material.encryptedPassword, '5+VGcbAcFdzx/kpX/SVhJ/5t1gRuHOUuQYX7311plKo=');
  assert.equal(material.encryptedDigest, 'AjdFwLJlXEKpjMHctroOhu/BUA3ZGCEREDzLpg5mAdM=');
  assert.match(material.encryptedNonce, /^[A-Za-z0-9+/]+=*$/);
  assert.deepEqual(privateDecrypt({ key: privateKey, padding: constants.RSA_PKCS1_PADDING },
    Buffer.from(material.encryptedNonce, 'base64')), aesKey);
  assert.equal(JSON.stringify(material).includes('synthetic-password'), false);
});

test('Created requires exact UTC milliseconds and NTP source fails closed', async () => {
  assert.equal(validateFactIntWsCreated('2026-08-29T12:34:56.789Z'), '2026-08-29T12:34:56.789Z');
  assert.throws(() => validateFactIntWsCreated('2026-08-29T12:34:56Z'));
  const fromNtp = await resolveFactIntWsCreated({ ntpTimeProvider: async () => new Date('2026-08-29T12:34:56.789Z') });
  assert.deepEqual(fromNtp, { created: '2026-08-29T12:34:56.789Z', source: FactIntWsCreatedSource.NTP });
  await assert.rejects(resolveFactIntWsCreated(), /NTP/);
  await assert.rejects(resolveFactIntWsCreated({ ntpTimeProvider: async () => { throw new Error('offline'); } }), /NTP/);
});

test('live harness resolves verified time and channel gates before any AT request', () => {
  const harness = readFileSync(new URL('../../bin/factintws-live-once.mjs', import.meta.url), 'utf8');
  assert.equal(harness.includes('new Date().toISOString()'), false);
  assert(harness.includes('allowSystemClockFallback: false'));
  assert(harness.indexOf('resolveFactIntWsCreated') < harness.indexOf('networkRequests = 1'));
  assert(harness.indexOf('buildFactIntWsLiveReadinessMatrix') < harness.indexOf('networkRequests = 1'));
});

test('four read-only request schemas serialize in official field order', () => {
  const cases = [
    ['EcraInicial', { nif: syntheticNif, year: '2026', channel }, ['Nif', 'Ano', 'CanalOrigem']],
    ['DadosContribuinte', { nif: syntheticNif, channel }, ['Nif', 'CanalOrigem']],
    ['FaturasPorClassificar', { nif: syntheticNif, year: '2026', channel }, ['Nif', 'Ano', 'CanalOrigem']],
    ['FaturasPorSetor', { nif: syntheticNif, sector: 'C05', year: '2026', index: '0', channel }, ['NifAdquirente', 'CodSetor', 'Ano', 'Indice', 'CanalOrigem']],
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
  assert.equal(http.headers.SOAPAction, 'http://factemi.at.min_financas.pt/factintws/EcraInicial');
  assert.equal(http.headers['Content-Type'], 'text/xml;charset=utf-8');
  assert.equal(http.timeoutMs, 120000);
});

test('FactIntWS restores original TLS negotiation and selects only endpoint 8443', () => {
  assert.deepEqual(factIntWsTlsOptions(), { minVersion: 'TLSv1.2' });
  assert.equal('maxVersion' in factIntWsTlsOptions(), false);
  assert.equal('ciphers' in factIntWsTlsOptions(), false);
  const harness = readFileSync(new URL('../../bin/factintws-live-once.mjs', import.meta.url), 'utf8');
  assert(harness.includes('...factIntWsTlsOptions()'));
  assert(harness.includes('factIntWsHttpContract(FACTINTWS_OPERATION, FACTINTWS_ENDPOINT_8443)'));
  assert.equal(harness.includes('FACTINTWS_ENDPOINT_443'), false);
});

test('CanalOrigem uses explicit runtime-device metadata and remains fail-closed when absent', async () => {
  assert.equal(factIntWsProtocolEvidence.channelStructure.status, FactIntWsEvidenceStatus.OFFICIAL_APP);
  assert.deepEqual(buildOfficialAppChannel({ sdkInt: 35, release: '15' }),
    { system: 'A', version: 'Android SDK: 35 (15)' });
  assert.deepEqual(resolveFactIntWsChannelFromEnvironment({
    FACTINTWS_ANDROID_SDK_INT: '35', FACTINTWS_ANDROID_RELEASE: '15',
  }), { channel: { system: 'A', version: 'Android SDK: 35 (15)' },
    status: FactIntWsChannelValueStatus.RUNTIME_DEVICE_METADATA,
    source: 'EXPLICIT_ANDROID_RUNTIME_METADATA' });
  assert.throws(() => buildOfficialAppChannel({ sdkInt: null, release: null }));
  assert.equal(factIntWsProtocolEvidence.channelValues.status, FactIntWsEvidenceStatus.UNKNOWN);
  assert.equal(assessFactIntWsReadiness().ready, false);
  assert.throws(() => assertFactIntWsLiveReadiness(), /channelValues/);
  const matrix = buildFactIntWsLiveReadinessMatrix({ ntpReady: true, pfxReady: true,
    tlsDiagnosticReady: true, channelReady: true });
  assert.equal(matrix.DIGEST_READY, true);
  assert.equal(matrix.NONCE_READY, true);
  assert.equal(matrix.CREATED_READY, true);
  assert.equal(matrix.SOAPACTION_READY, true);
  assert.equal(matrix.ECRAINICIAL_SCHEMA_READY, true);
  assert.equal(matrix.NTP_READY, true);
  assert.equal(matrix.CANALORIGEM_READY, true);
  assert.equal(matrix.PFX_READY, true);
  assert.equal(matrix.TLS_DIAGNOSTIC_READY, true);
  assert.equal(matrix.READY, true);
  const result = await runFactIntWsFeasibility({ transport: () => { throw new Error('must not run'); } });
  assert.equal(result.ready, false);
  assert.equal(result.networkRequests, 0);
  assert.equal(result.classification, 'FACTINTWS_CHANNEL_VALUES_UNKNOWN');
});

test('money parser returns integer cents without floating point', () => {
  assert.deepEqual(['0.00', '0.01', '1.00', '23.45', '1000.99'].map(parseFactIntMoneyCents), [0, 1, 100, 2345, 100099]);
  assert.throws(() => parseFactIntMoneyCents('1.234'));
});

test('typed invoice parser maps wire response separately from domain', () => {
  const xml = '<Fatura><IdDocumento>SYNTHETIC-ID</IdDocumento><NifEmitente>000000000</NifEmitente><TipoDocumento>FT</TipoDocumento><DataDocumento>2026-01-02</DataDocumento><ValorTotal>23.45</ValorTotal><ValorIva>4.39</ValorIva><ValorIncentivoConsumo>0.50</ValorIncentivoConsumo><ValorProvisorioBeneficioDespesasGerais>0.35</ValorProvisorioBeneficioDespesasGerais><ValorProvisorioBeneficioSetor>0.25</ValorProvisorioBeneficioSetor><CodSetor>01</CodSetor><CanalOrigem>SYNTHETIC</CanalOrigem><Receita>N</Receita><AdquirentePodeManipularFaturas>S</AdquirentePodeManipularFaturas></Fatura>';
  const invoice = parseFactIntInvoice(xml);
  assert.equal(invoice.wireType, 'FactIntInvoiceResponse');
  assert.equal(invoice.totalCents, 2345);
  assert.equal(invoice.vatCents, 439);
  assert.deepEqual(invoice.documentType, { kind: 'unknown', rawCode: 'FT' });
  assert.equal(invoice.consumerIncentiveCents, 50);
  assert.equal(invoice.generalExpenseBenefitCents, 35);
  assert.equal(invoice.sectorBenefitCents, 25);
  assert.deepEqual(invoice.originChannel, { kind: 'unknown', rawCode: 'SYNTHETIC' });
  assert.deepEqual(invoice.recipe, { kind: 'known', code: 'N', value: false });
  assert.deepEqual(invoice.buyerCanManipulateInvoices, { kind: 'known', code: 'S', value: true });
  const domain = toAtInvoiceDomain(invoice);
  assert.equal(domain.source, 'FACTINTWS');
  assert.equal(domain.date, '2026-01-02');
  assert.equal(domain.totalCents, 2345);
  assert.equal(domain.vatCents, 439);
  assert.equal(domain.sectorCode, '01');
});

test('response parser handles success, empty, multiple, optional and unknown elements', () => {
  const xml = fixture('faturas_por_setor_success.xml');
  const result = parseFactIntWsResponse(xml, 'FaturasPorSetor');
  assert.equal(result.result.estadoOperacao, '200');
  assert.equal(result.invoices.length, 2);
  assert.equal(result.invoices[1].vatCents, null);
  assert.deepEqual(result.summary, { totalExpensesCents: 2445, provisionalBenefitCents: 200 });
  assert(xml.includes('<SyntheticUnknownElement>'));
  const empty = parseFactIntWsResponse(fixture('faturas_por_classificar_empty.xml'), 'FaturasPorClassificar');
  assert.equal(empty.invoices.length, 0);
});

test('response parser fails closed on malformed invoice and parses SOAP fault', () => {
  const malformed = fixture('malformed_invoice.xml');
  assert.throws(() => parseFactIntWsResponse(malformed, 'FaturasPorSetor'), /DataDocumento/);
  const fault = parseFactIntWsResponse(fixture('soap_fault.xml'), 'EcraInicial');
  assert.equal(fault.fault.code, 'Client.Synthetic');
  const auth = parseFactIntWsResponse(fixture('authentication_failed.xml'), 'EcraInicial');
  assert.equal(auth.fault.code, 'AuthenticationFailed');
  assert.equal(auth.fault.reason, 'Synthetic authentication failure');
});

test('EcraInicial and DadosContribuinte synthetic response shapes parse without exposing data', () => {
  const initial = parseFactIntWsResponse(fixture('ecra_inicial_response.xml'), 'EcraInicial');
  assert.deepEqual(initial.totals, { pendingValidation: 5, pendingRevenueAssociation: 1, provisionalBenefitCents: 50339 });
  assert.deepEqual(initial.buyerCanManipulateInvoices, { kind: 'known', code: 'S', value: true });
  assert.deepEqual(initial.canShowPreviousYear, { kind: 'known', code: 'S', value: true });
  assert.deepEqual(initial.sectors, [{ sectorCode: '01', provisionalBenefitCents: 1234,
    totalExpensesCents: 10000, totalVatExpensesCents: 2300 }]);
  const taxpayer = parseFactIntWsResponse(fixture('dados_contribuinte_response.xml'), 'DadosContribuinte');
  assert.equal(taxpayer.taxpayerDataPresent, true);
  assert.equal(taxpayer.taxpayer.sensitive, true);
});

test('EcraInicial required aggregates fail closed instead of becoming zero', () => {
  const missingPending = fixture('ecra_inicial_response.xml')
    .replace(/<app:NumTotalFaturasPorValidar>.*?<\/app:NumTotalFaturasPorValidar>/, '');
  assert.throws(
    () => parseFactIntWsResponse(missingPending, 'EcraInicial'),
    (error) => error.code === 'PARSING_ERROR' && error.field === 'NumTotalFaturasPorValidar',
  );
});

test('bootstrap sequence executes only EcraInicial, DadosContribuinte, EcraInicial in order', async () => {
  const operations = [];
  const transport = async ({ contract }) => {
    const operation = contract.headers.SOAPAction.split('/').at(-1);
    operations.push(operation);
    return { httpStatus: 200, tls: { authorized: true },
      body: fixture(operation === 'DadosContribuinte'
        ? 'dados_contribuinte_response.xml' : 'ecra_inicial_response.xml') };
  };
  const repository = new FactIntWsRepository(new FactIntWsClient({ transport }));
  const contexts = [];
  const result = await runFactIntWsBootstrapSequence({ repository,
    contextFor: async (operation, phase) => {
      contexts.push({ operation, phase });
      return { username: syntheticNif,
        credentials: { encryptedDigest: 'digest', encryptedPassword: 'password',
          encryptedNonce: 'nonce', created: '2026-08-30T12:00:00.000Z' },
        input: { nif: syntheticNif,
          ...(operation === 'EcraInicial' ? { year: '2026' } : {}), channel } };
    } });
  assert.deepEqual(operations, ['EcraInicial', 'DadosContribuinte', 'EcraInicial']);
  assert.equal(contexts.length, 3);
  assert.equal(contexts[0].phase.authentication, true);
  assert.equal(contexts[2].phase.final, true);
  assert.equal(result.complete, true);
  assert.equal(result.finalOverview.parsed.totals.pendingValidation, 5);
});

test('bootstrap sequence stops without retry when an intermediate call fails', async () => {
  let requests = 0;
  const transport = async ({ contract }) => {
    requests += 1;
    const operation = contract.headers.SOAPAction.split('/').at(-1);
    return { httpStatus: operation === 'DadosContribuinte' ? 500 : 200,
      tls: { authorized: true }, body: fixture(operation === 'DadosContribuinte'
        ? 'dados_contribuinte_response.xml' : 'ecra_inicial_response.xml') };
  };
  const repository = new FactIntWsRepository(new FactIntWsClient({ transport }));
  const result = await runFactIntWsBootstrapSequence({ repository,
    contextFor: async (operation) => ({ username: syntheticNif,
      credentials: { encryptedDigest: 'digest', encryptedPassword: 'password',
        encryptedNonce: 'nonce', created: '2026-08-30T12:00:00.000Z' },
      input: { nif: syntheticNif,
        ...(operation === 'EcraInicial' ? { year: '2026' } : {}), channel } }) });
  assert.equal(requests, 2);
  assert.equal(result.complete, false);
  assert.equal(result.finalOverview, null);
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
