#!/usr/bin/env node
import { runFactIntWsFeasibility } from '../src/factintws.mjs';

const result = await runFactIntWsFeasibility();
process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
if (!result.ready) process.exitCode = 2;
