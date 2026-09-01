import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import 'product_models.dart';

final class FiscalProfileScreen extends ConsumerWidget {
  const FiscalProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(productStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fiscalProfile)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _LoadError(onRetry: () => ref.invalidate(productStateProvider)),
        data: (value) => _ProfileForm(state: value),
      ),
    );
  }
}

final class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.state});
  final ProductState state;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

final class _ProfileFormState extends ConsumerState<_ProfileForm> {
  late int _year;
  TaxRegion? _region;
  CivilStatus? _civilStatus;
  int? _dependants;
  bool? _employment;
  bool? _selfEmployment;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.state.profile;
    _year = profile.activeTaxYear;
    _region = profile.region;
    _civilStatus = profile.civilStatus;
    _dependants = profile.dependentCount;
    _employment = profile.hasEmployment;
    _selfEmployment = profile.hasSelfEmployment;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final complete = FiscalProfile(
      activeTaxYear: _year,
      region: _region,
      civilStatus: _civilStatus,
      dependentCount: _dependants,
      hasEmployment: _employment,
      hasSelfEmployment: _selfEmployment,
    ).isComplete;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Card(
          child: ListTile(
            leading: Icon(complete ? Icons.check_circle : Icons.info_outline),
            title: Text(
              complete ? l10n.profileComplete : l10n.profileIncomplete,
            ),
            subtitle: Text(l10n.profilePurpose),
          ),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: _year,
          decoration: InputDecoration(labelText: l10n.activeTaxYear),
          items: const [2025, 2026]
              .map(
                (year) => DropdownMenuItem(value: year, child: Text('$year')),
              )
              .toList(),
          onChanged: (value) => setState(() => _year = value ?? _year),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<TaxRegion?>(
          initialValue: _region,
          decoration: InputDecoration(labelText: l10n.taxResidence),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.unknownValue)),
            DropdownMenuItem(
              value: TaxRegion.continent,
              child: Text(l10n.mainlandPortugal),
            ),
            DropdownMenuItem(
              value: TaxRegion.madeira,
              child: Text(l10n.madeira),
            ),
            DropdownMenuItem(value: TaxRegion.azores, child: Text(l10n.azores)),
          ],
          onChanged: (value) => setState(() => _region = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CivilStatus?>(
          initialValue: _civilStatus,
          decoration: InputDecoration(labelText: l10n.civilStatusLabel),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.unknownValue)),
            DropdownMenuItem(
              value: CivilStatus.single,
              child: Text(l10n.single),
            ),
            DropdownMenuItem(
              value: CivilStatus.married,
              child: Text(l10n.married),
            ),
            DropdownMenuItem(
              value: CivilStatus.deFacto,
              child: Text(l10n.deFactoUnion),
            ),
          ],
          onChanged: (value) => setState(() => _civilStatus = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          initialValue: _dependants,
          decoration: InputDecoration(labelText: l10n.dependants),
          items: [
            DropdownMenuItem(value: null, child: Text(l10n.unknownValue)),
            for (var value = 0; value <= 6; value++)
              DropdownMenuItem(value: value, child: Text('$value')),
          ],
          onChanged: (value) => setState(() => _dependants = value),
        ),
        const SizedBox(height: 12),
        _NullableBoolField(
          label: l10n.employmentIncome,
          value: _employment,
          onChanged: (value) => setState(() => _employment = value),
        ),
        const SizedBox(height: 12),
        _NullableBoolField(
          label: l10n.selfEmploymentIncome,
          value: _selfEmployment,
          onChanged: (value) => setState(() => _selfEmployment = value),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: Text(l10n.save),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final profile = FiscalProfile(
      activeTaxYear: _year,
      region: _region,
      civilStatus: _civilStatus,
      dependentCount: _dependants,
      hasEmployment: _employment,
      hasSelfEmployment: _selfEmployment,
    );
    await ref
        .read(productRepositoryProvider)
        .save(widget.state.copyWith(profile: profile));
    ref.invalidate(productStateProvider);
    if (mounted) Navigator.pop(context);
  }
}

final class _NullableBoolField extends StatelessWidget {
  const _NullableBoolField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<bool?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.unknownValue)),
        DropdownMenuItem(value: true, child: Text(l10n.yes)),
        DropdownMenuItem(value: false, child: Text(l10n.no)),
      ],
      onChanged: onChanged,
    );
  }
}

final class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context).localDataUnavailable,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    ),
  );
}
