# UI localization audit — Taxy 0.7.7

## Implemented surfaces

- App locale resolution and fallback (`pt-PT`, `en`, fallback `pt-PT`).
- Language settings and immediate runtime switching.
- Welcome/home entry copy, module availability labels and e-Fatura entry copy.
- Complete experimental e-Fatura flow: connection, overview, categories,
  invoices, loading, empty, error, refresh and disconnect states.
- Locale-aware EUR, dates and invoice pluralization.
- Localized e-Fatura category labels while retaining technical codes only in
  the domain and connector layers.

## Hardcoded-string inventory

An offline scan identified additional Portuguese strings in the IRS wizard,
calculation explanations, validation lab and fiscal-result screens. These are
legal/fiscal product content rather than generic UI chrome. They remain
Portuguese in this pass to avoid changing fiscal meaning through an unreviewed
bulk translation. The localization infrastructure now provides a single path
for their reviewed migration; no parallel translation mechanism was added.

Developer-only validation labels and fixture descriptions are intentionally
outside localization. Technical connector errors never cross into normal UI
copy.

## Accessibility and layout checks

- Small 320×640 viewport with 200% text scaling.
- Standard and wide layouts; category items switch to two columns only when
  enough width is available.
- Light/dark theme colors come exclusively from `ColorScheme`.
- Screen-reader labels for the experimental status, categories and invoices.
- All icon-only actions retain tooltips; primary tap targets use Material
  controls.

## Regression boundary

This pass does not modify FactIntWS, crypto, NTP, mTLS, MethodChannel,
credential storage, Android bridge, feature-flag semantics, IRS rules or the
tax engine. No live request is part of this audit.
