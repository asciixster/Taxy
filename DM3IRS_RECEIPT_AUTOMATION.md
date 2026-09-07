# DM3IRS receipt automation

## Proposed experience

1. Declaration status indicates that a receipt may exist.
2. Taxy notifies generically, without amount or fiscal detail on the lock screen.
3. User opens the authenticated app and chooses “View receipt”.
4. `obterReceiptMobileRequest` fetches metadata on demand.
5. Taxy displays status/dates and only the minimum useful financial result.
6. A declaration PDF is fetched separately only after another explicit user action.

## Storage policy

- normalized availability/status: `SHORT_CACHE`;
- receipt identifiers, taxpayer name/identifier and liquidation reference: `SESSION_ONLY`/`NO_STORE`;
- amount: `NO_STORE` unless the user explicitly creates a local tax-history snapshot;
- PDF: ephemeral memory/private temporary storage, delete on viewer close; user-initiated export is outside Taxy storage.

No automatic receipt/PDF download, background persistence or analytics containing status, amount, year or document type.
