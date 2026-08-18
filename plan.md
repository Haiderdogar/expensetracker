Checkpoint: Analytics & Budgets (2026-08-18)

Status
- analytics-budgets: in_progress
- update-loading-ui: pending
- preserve-native-splash: pending
- investigate-delay: done
- remove-auth-delay: done

What was changed in this iteration
- Analytics
  - Analytics screen and widgets for category breakdown and monthly spending trend were already present and reuse fl_chart.
  - No dependency changes required (fl_chart is present).

- Budgets
  - Provider: currentMonthBudgetProgress now handles missing categories gracefully (falls back to "Unknown") instead of throwing an exception.
  - UI: Budgets screen now supports pull-to-refresh, an AppBar refresh action, a summary card showing total budgets and total spent, and retry UI when provider errors occur.
  - Budget tiles (BudgetProgressTile): added inline edit and delete actions (Popup menu), improved alerts for "Near budget limit" and "Over budget", and robust error handling with SnackBars.

Next steps
- Analytics: add additional charts (income vs expense time series, monthly cashflow area) using existing providers or add new providers if needed. Consider interactive filters (date range, categories).
- Budgets: polish the Add/Edit UX (prefilled edit sheet, category rename handling), add notifications for approaching budgets, and optionally show a small per-category chart.
- Transaction currency: ensure currency symbol propagates everywhere; small remaining TODO noted in previous checkpoint (amount prefix updates are implemented in AddTransactionScreen).
- Regenerate Riverpod generated files with build_runner and run `flutter analyze` and a quick device/emulator run to validate UX.

Notes
- A new todo 'analytics-budgets' was created and set in_progress in the session DB.
- Provider-generated files were not re-generated in this round; run `flutter pub run build_runner build --delete-conflicting-outputs` when ready to canonicalize generated code.

If you'd like, I can now:
- Implement the additional analytics charts (income vs expense time-series and monthly cashflow area) right away.
- Polish budget edit sheet to prefill values and use upsert for updates.
- Run `flutter analyze` and attempt a local build.

Tell me which of these to do next.