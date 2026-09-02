# UI localization audit — Taxy 0.7.14

## Implemented surfaces

- App locale resolution and fallback (`pt-PT`, `en`, fallback `pt-PT`).
- Language settings and immediate runtime switching.
- Welcome/home entry copy, module availability labels and e-Fatura entry copy.
- Home dashboard, simulation management and result-summary copy.
- “How we calculate” method and validated/unsupported scope copy.
- Complete experimental e-Fatura flow: connection, overview, categories,
  invoices, loading, empty, error, refresh and disconnect states.
- Locale-aware EUR, dates and invoice pluralization.
- Localized e-Fatura category labels while retaining technical codes only in
  the domain and connector layers.

## Hardcoded-string inventory

An offline scan still identifies additional Portuguese strings in the IRS
wizard, detailed fiscal-result screens and opportunities. These are
legal/fiscal product content rather than generic UI chrome. They remain
Portuguese in this pass to avoid changing fiscal meaning through an unreviewed
bulk translation. The localization infrastructure now provides a single path
for their reviewed migration; no parallel translation mechanism was added.

Developer-only validation labels and fixture descriptions are intentionally
outside localization. Technical connector errors never cross into normal UI
copy.

## Accessibility and layout checks

- Small 320×640 viewport with 200% text scaling.
- Automated compact/dark/200% coverage for Home, Fiscal Profile, Income,
  Expenses, Saved estimates, Settings and e-Fatura surfaces.
- Standard and wide layouts; category items switch to two columns only when
  enough width is available.
- Light/dark theme colors come exclusively from `ColorScheme`.
- Screen-reader labels for the experimental status, categories and invoices.
- All icon-only actions retain tooltips; primary tap targets use Material
  controls.

## Regression boundary

This pass does not modify FactIntWS, crypto, NTP, mTLS, credential storage,
feature-flag semantics, IRS rules or the tax engine. Android now registers only
the screenshot-protection method used by the public-backend flow; the direct
FactIntWS bridge is not reachable from the production activity. No live request
is part of this audit.
