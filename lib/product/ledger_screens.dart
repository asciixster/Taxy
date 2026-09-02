import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/money.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'product_models.dart';

final class IncomeScreen extends ConsumerStatefulWidget {
  const IncomeScreen({super.key});

  @override
  ConsumerState<IncomeScreen> createState() => _IncomeScreenState();
}

final class _IncomeScreenState extends ConsumerState<IncomeScreen> {
  EntryProvenance? _filter;

  @override
  Widget build(BuildContext context) => _LedgerScaffold(
    isIncome: true,
    state: ref.watch(productStateProvider),
    provenanceFilter: _filter,
    onProvenanceFilterChanged: (value) => setState(() => _filter = value),
  );
}

final class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _LedgerScaffold(isIncome: false, state: ref.watch(productStateProvider));
}

final class _LedgerScaffold extends ConsumerWidget {
  const _LedgerScaffold({
    required this.isIncome,
    required this.state,
    this.provenanceFilter,
    this.onProvenanceFilterChanged,
  });
  final bool isIncome;
  final AsyncValue<ProductState> state;
  final EntryProvenance? provenanceFilter;
  final ValueChanged<EntryProvenance?>? onProvenanceFilterChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(isIncome ? l10n.income : l10n.expenses)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.localDataUnavailable)),
        data: (value) => _body(context, ref, value),
      ),
      floatingActionButton: state.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _add(context, ref, state.requireValue),
              icon: const Icon(Icons.add),
              label: Text(isIncome ? l10n.addIncome : l10n.addExpense),
            )
          : null,
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, ProductState value) {
    final l10n = AppLocalizations.of(context);
    final year = value.profile.activeTaxYear;
    var entries = isIncome
        ? value.incomes.where((entry) => entry.year == year).toList()
        : value.expenses.where((entry) => entry.year == year).toList();
    if (isIncome && provenanceFilter != null) {
      entries = entries
          .where(
            (entry) => (entry as IncomeEntry).provenance == provenanceFilter,
          )
          .toList();
    }
    final total = isIncome ? value.incomeTotal : value.expenseTotal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.totalForYear(year),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  total.format(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  isIncome ? l10n.localIncomeNotice : l10n.localExpenseNotice,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isIncome) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.all),
                  selected: provenanceFilter == null,
                  onSelected: (_) => onProvenanceFilterChanged?.call(null),
                ),
                const SizedBox(width: 8),
                for (final source in EntryProvenance.values) ...[
                  ChoiceChip(
                    label: Text(_provenance(context, source)),
                    selected: provenanceFilter == source,
                    onSelected: (_) => onProvenanceFilterChanged?.call(source),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (entries.isEmpty)
          _EmptyLedger(
            message: isIncome
                ? l10n.noIncomeRegistered
                : l10n.noExpensesRegistered,
          )
        else
          for (final entry in entries) ...[
            Card(
              child: isIncome
                  ? _IncomeTile(
                      entry: entry as IncomeEntry,
                      onEdit: () => _editIncome(context, ref, value, entry),
                      onDelete: () => _deleteIncome(ref, value, entry.id),
                    )
                  : _ExpenseTile(
                      entry: entry as ExpenseEntry,
                      onEdit: () => _editExpense(context, ref, value, entry),
                      onDelete: () => _deleteExpense(ref, value, entry.id),
                    ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    ProductState state,
  ) async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    var categoryIndex = isIncome
        ? IncomeCategory.other.index
        : ExpenseCategory.other.index;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isIncome ? l10n.addIncome : l10n.addExpense),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: categoryIndex,
                decoration: InputDecoration(labelText: l10n.category),
                items: isIncome
                    ? [
                        for (final value in IncomeCategory.values)
                          DropdownMenuItem(
                            value: value.index,
                            child: Text(_incomeCategory(context, value)),
                          ),
                      ]
                    : [
                        for (final value in ExpenseCategory.values)
                          DropdownMenuItem(
                            value: value.index,
                            child: Text(_expenseCategory(context, value)),
                          ),
                      ],
                onChanged: (value) => setDialogState(
                  () => categoryIndex = value ?? categoryIndex,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.amountEuros),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (accepted != true) return;
    final cents = _parseCents(controller.text);
    controller.dispose();
    if (cents == null || cents < 0) return;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final year = state.profile.activeTaxYear;
    final updated = isIncome
        ? state.copyWith(
            incomes: [
              ...state.incomes,
              IncomeEntry(
                id: id,
                category: IncomeCategory.values[categoryIndex],
                amount: Money.fromCents(cents),
                year: year,
                provenance: EntryProvenance.manual,
                status: EntryStatus.confirmed,
              ),
            ],
          )
        : state.copyWith(
            expenses: [
              ...state.expenses,
              ExpenseEntry(
                id: id,
                category: ExpenseCategory.values[categoryIndex],
                amount: Money.fromCents(cents),
                year: year,
                provenance: EntryProvenance.manual,
                status: EntryStatus.confirmed,
              ),
            ],
          );
    await ref.read(productRepositoryProvider).save(updated);
    ref.invalidate(productStateProvider);
  }

  Future<int?> _editAmount(BuildContext context, Money current) async {
    final controller = TextEditingController(
      text: (current.cents / 100).toStringAsFixed(2),
    );
    final l10n = AppLocalizations.of(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.edit),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: l10n.amountEuros),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final cents = accepted == true ? _parseCents(controller.text) : null;
    controller.dispose();
    return cents;
  }

  Future<void> _editIncome(
    BuildContext context,
    WidgetRef ref,
    ProductState state,
    IncomeEntry target,
  ) async {
    final cents = await _editAmount(context, target.amount);
    if (cents == null) return;
    final replacement = IncomeEntry(
      id: target.id,
      category: target.category,
      amount: Money.fromCents(cents),
      year: target.year,
      provenance: target.provenance,
      status: target.status,
      period: target.period,
      supportingReference: target.supportingReference,
      deduplicationIdentity: target.deduplicationIdentity,
    );
    await ref
        .read(productRepositoryProvider)
        .save(
          state.copyWith(
            incomes: [
              for (final entry in state.incomes)
                if (entry.id == target.id) replacement else entry,
            ],
          ),
        );
    ref.invalidate(productStateProvider);
  }

  Future<void> _editExpense(
    BuildContext context,
    WidgetRef ref,
    ProductState state,
    ExpenseEntry target,
  ) async {
    final cents = await _editAmount(context, target.amount);
    if (cents == null) return;
    final replacement = ExpenseEntry(
      id: target.id,
      category: target.category,
      amount: Money.fromCents(cents),
      year: target.year,
      provenance: target.provenance,
      status: target.status,
      date: target.date,
      vat: target.vat,
      possibleMatchIdentity: target.possibleMatchIdentity,
    );
    await ref
        .read(productRepositoryProvider)
        .save(
          state.copyWith(
            expenses: [
              for (final entry in state.expenses)
                if (entry.id == target.id) replacement else entry,
            ],
          ),
        );
    ref.invalidate(productStateProvider);
  }

  Future<void> _deleteIncome(
    WidgetRef ref,
    ProductState state,
    String id,
  ) async {
    await ref
        .read(productRepositoryProvider)
        .save(
          state.copyWith(
            incomes: state.incomes.where((entry) => entry.id != id).toList(),
          ),
        );
    ref.invalidate(productStateProvider);
  }

  Future<void> _deleteExpense(
    WidgetRef ref,
    ProductState state,
    String id,
  ) async {
    await ref
        .read(productRepositoryProvider)
        .save(
          state.copyWith(
            expenses: state.expenses.where((entry) => entry.id != id).toList(),
          ),
        );
    ref.invalidate(productStateProvider);
  }
}

int? _parseCents(String source) {
  final normalized = source.trim().replaceAll(' ', '').replaceAll(',', '.');
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(normalized);
  if (match == null) return null;
  final whole = int.parse(match.group(1)!);
  final decimals = (match.group(2) ?? '').padRight(2, '0');
  return whole * 100 + int.parse(decimals.isEmpty ? '0' : decimals);
}

final class _IncomeTile extends StatelessWidget {
  const _IncomeTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final IncomeEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.payments_outlined)),
    title: Text(entry.amount.format()),
    subtitle: Text(
      '${_incomeCategory(context, entry.category)} · ${_provenance(context, entry.provenance)} · ${_status(context, entry.status)}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).edit,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).remove,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

final class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final ExpenseEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
    title: Text(entry.amount.format()),
    subtitle: Text(
      '${_expenseCategory(context, entry.category)} · ${_provenance(context, entry.provenance)} · ${_status(context, entry.status)}',
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: AppLocalizations.of(context).edit,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).remove,
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );
}

String _provenance(BuildContext context, EntryProvenance value) {
  final l10n = AppLocalizations.of(context);
  return switch (value) {
    EntryProvenance.manual => l10n.sourceManual,
    EntryProvenance.imported => l10n.sourceImported,
    EntryProvenance.externalSource => l10n.sourceExternal,
    EntryProvenance.calculated => l10n.sourceCalculated,
  };
}

String _incomeCategory(BuildContext context, IncomeCategory value) {
  final l10n = AppLocalizations.of(context);
  return switch (value) {
    IncomeCategory.employment => l10n.categoryEmployment,
    IncomeCategory.selfEmployment => l10n.categorySelfEmployment,
    IncomeCategory.pension => l10n.categoryPension,
    IncomeCategory.other => l10n.categoryOther,
  };
}

String _expenseCategory(BuildContext context, ExpenseCategory value) {
  final l10n = AppLocalizations.of(context);
  return switch (value) {
    ExpenseCategory.general => l10n.categoryGeneral,
    ExpenseCategory.health => l10n.categoryHealth,
    ExpenseCategory.education => l10n.categoryEducation,
    ExpenseCategory.housing => l10n.categoryHousing,
    ExpenseCategory.professional => l10n.categoryProfessional,
    ExpenseCategory.other => l10n.categoryOther,
  };
}

String _status(BuildContext context, EntryStatus value) {
  final l10n = AppLocalizations.of(context);
  return switch (value) {
    EntryStatus.confirmed => l10n.statusConfirmed,
    EntryStatus.estimated => l10n.statusEstimated,
    EntryStatus.possibleDuplicate => l10n.statusPossibleDuplicate,
  };
}

final class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Icon(
          Icons.inbox_outlined,
          size: 44,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
