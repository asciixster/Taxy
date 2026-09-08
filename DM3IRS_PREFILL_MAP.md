# DM3IRS prefill map

This is a design map, not a production capability. All fields remain unavailable to Taxy until authorization and product/legal gates pass.

Runtime note (2026-09-08): the single `infoUtilizadorAutenticadoMobileRequest` probe reached authenticated TLS but returned an HTTP 500 SOAP Fault categorized as `REQUEST_ERROR`. Therefore the runtime-confirmed prefill, removable-question and confirm-only counts are all `0`; these are no-payload observations, not evidence that the fields are absent from a valid response.

| DM3IRS field/group | Taxy destination | Interview effect | Confirmation |
|---|---|---|---|
| fiscal residence | FiscalProfile residence | prefill + confirm | YES |
| marital status / spouse | FiscalProfile family | reduce 2 questions | YES |
| dependants | FiscalProfile dependants | reduce 2 questions | YES |
| activity code | self-employment classification | reduce activity-code question | YES |
| independent-work income | income component | reduce gross-income entry | YES |
| employment income | employment income component | reduce gross-income entry | YES |
| pensions | pension-presence fact | remove presence question | YES |
| Category A withholding | withholding component | reduce withholding entry | YES |
| Category B withholding | withholding component | reduce withholding entry | YES |
| mandatory SS contributions | contribution component | reduce contribution entry | YES |
| payments on account | payment component | reduce payment entry | YES |
| activity expenses | expense-justification input | prefill + review | YES |
| e-Fatura expense sectors | expense evidence | prefill supported sectors | YES |
| IRS Jovem eligibility/options | profile/review | reduce eligibility questions | YES |

Static discovery creates 14 useful prefill mappings. Ten current interview prompts could be removed or reduced if these reads become legitimately available; none should be silently overridden. Source would be `OFFICIAL_AT`, conflicts remain user-resolved, and tax-year isolation is mandatory.
