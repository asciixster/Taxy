# Future TaxObligation contract

Documentation only; 0.7.11 does not generate obligations.

`TaxObligation` needs: stable identifier, localized title, due date, status
(`upcoming`, `due`, `completed`, `unknown`), category, evidence source, supported
action and confidence. An obligation is shown only when its applicability and date
are backed by known profile data and a versioned source. Missing facts produce
`unknown`, never a guessed deadline.

