# Real-device document capture smoke

Use a synthetic document only. Do not use a real fiscal document.

1. Install the CI-built Taxy 0.8.4 debug APK and cold-launch it.
2. Open **Document evidence** and verify there is no broad storage or permanent camera permission request.
3. Choose a synthetic JPG/PDF and confirm extraction opens the review screen.
4. Capture a second synthetic page with the camera and confirm the preview orientation is correct.
5. Verify gross income, withholding, Social Security and year are clearly editable and announced by TalkBack.
6. Deselect one field, correct another value and tap **Confirm values**.
7. Verify only selected values appear as evidence and Guided Review/NextAction update without silent overwrite.
8. Verify the original preview is unavailable after confirmation (raw deleted).
9. Start another capture, cancel/delete it and verify a clean return without retained candidate.
10. Force-stop and relaunch; confirm the prior evidence remains but no raw preview or unconfirmed value is auto-applied.
11. Repeat the review screen in dark mode at 200% text and check for overflow/unlabelled controls.
12. Record PASS/FAIL only; do not capture or attach document contents to logs or the PR.

Merge gate: all steps PASS, then `MERGE_RECOMMENDED_AFTER_DEVICE_SMOKE`.
