# Taxfix → Taxy: public product gap

Date: 2026-09-04. This audit uses only public Taxfix pages, public support
material and public store descriptions. No application binary, private asset,
copy or proprietary implementation was inspected or reproduced.

| Element | TAXFIX_HAS | TAXY_HAS | TAXY_GAP | TAXY_OPPORTUNITY |
|---|---|---|---|---|
| Onboarding | A short route into a guided return | A clear product welcome and year selection | The legacy simulator still exposes fiscal structure early | Start with the year and one human question |
| Tax interview | Personalised question-and-answer flow; public material says roughly 70 questions | A deterministic wizard and fiscal profile | The wizard is form-like and contains tax vocabulary | One decision per screen, branching rules outside widgets |
| Progress | Categories and completion checks | Profile checklist | A fixed question percentage would be misleading | Show completed areas and current section |
| Branching | Only information relevant to the case is requested | Some conditional legacy steps | Conditions are coupled to presentation | A testable rule engine and deterministic cleanup |
| Estimate feedback | Free estimated result before submission | Existing IRS engine and result | Estimate is detached from profile discovery | Provisional estimate once sufficient supported data exists |
| Explanations | Help text and calculation detail | Calculation audit screen | Explanation is not available at the moment of doubt | “Why we ask this” and a four-part result summary |
| Documents | Photo/upload and task-oriented document guidance | No product document flow | No safe confirmation boundary | Foundation only: select/capture, type, metadata, confirmation |
| Review | Review/approve before submission | Existing result and editable simulation | No section-oriented answer review | Review facts by section and edit with branch cleanup |
| Next actions | Personalised tasks and submission path | Several equal-weight home actions | Priority is unclear | One safe next action, never an invented obligation |
| Error recovery | Missing-document guidance and support content | Shared local/network errors | Interview recovery is not first-class | Atomic local persistence after every answer |
| Monetisation | Estimate is available before a paid filing boundary | No filing/payment product | Not applicable to the 0.8 MVP | Keep calculation and explanation independent of submission |
| Annual experience | Previous-year carry-over and return status | Local snapshots and year-aware rules | Guided state is not year-isolated | One interview file per fiscal year and an annual companion |

## Public evidence

- Taxfix, [“How it works”](https://taxfix.de/en/how-it-works/): question-and-answer process, paperless document upload,
  early estimate and final review.
- Taxfix Support, [“Your tax return with the Taxfix app”](https://support.taxfix.de/hc/en-us/articles/28595920662301-Your-tax-return-with-the-Taxfix-app-How-it-works): category completion,
  contextual help, estimated result and calculation detail.
- Taxfix Support, [“What does the app do?”](https://support.taxfix.de/hc/en-us/articles/28259701093405-What-does-the-app-do): step-by-step questions instead of
  forms and contextual document guidance.
- [Public App Store description](https://apps.apple.com/de/app/taxfix-online-steuererkl%C3%A4rung/id1163776422): interview mode based on simple questions.

The 0.8.0 implementation adopts only general interaction principles. Its
wording, visual system, Portuguese fiscal model and code are original to Taxy.

## Reassessment after 0.8.0

A user with a supported, simple employment case can select a year, answer in
ordinary language, skip irrelevant employment detail, reach a clearly labelled
estimate, inspect why it changed and resume later without knowing the names of
Portuguese tax categories or forms. Unsupported income is recorded but never
silently approximated. Broader calculation coverage remains a tax-engine gap,
not a reason to make the interview misleading.
