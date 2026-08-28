import { createSecureContext } from 'node:tls';
import { readFileSync } from 'node:fs';
import { AtSoapClient } from './client.mjs';
import { loadConfig } from './config.mjs';
import { redact, safeLog } from './redaction.mjs';

function output(line) { process.stdout.write(`${line}\n`); }

async function main() {
  const command = process.argv[2] || 'probe';
  const config = loadConfig(process.env);
  if (command === 'inspect') {
    createSecureContext({ pfx: readFileSync(config.pfxPath), passphrase: config.pfxPassword, minVersion: 'TLSv1.2' });
    output(JSON.stringify({ pfx: 'loaded', privateKey: 'kept-in-memory' }));
    return;
  }
  if (command !== 'probe') throw new Error(`Unknown command: ${command}`);
  const client = new AtSoapClient(config, { logger: output });
  const result = await client.probeConsultation();
  output(JSON.stringify(redact({
    outcome: result.response.isXml ? 'REAL_XML_RESPONSE_RECEIVED' : 'NON_XML_RESPONSE_RECEIVED',
    endpoint: result.endpoint,
    tls: result.transport.tls,
    httpStatus: result.transport.statusCode,
    fault: result.response.fault,
  }), null, 2));
}

main().catch((error) => {
  safeLog(output, 'at.command.failed', { name: error.name, message: error.message, cause: error.cause?.message });
  process.exitCode = 1;
});
