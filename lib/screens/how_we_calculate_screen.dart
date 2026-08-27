import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../navigation/app_navigation.dart';
import '../tax_engine/tax_rules.dart';
import '../widgets/notice_card.dart';
import 'tax_validation_lab_screen.dart';

final class HowWeCalculateScreen extends StatelessWidget {
  const HowWeCalculateScreen({super.key, required this.rules});
  final TaxRuleSet rules;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Como calculamos')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      children: [
        Text(
          'Transparência primeiro',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'O cálculo é determinístico e não usa inteligência artificial. Valores monetários são tratados em cêntimos inteiros, com arredondamento explícito.',
        ),
        const SizedBox(height: 24),
        const _MethodStep(
          number: '1',
          title: 'Rendimento líquido da categoria',
          text: 'Ao rendimento bruto subtraímos a dedução específica aplicável ao trabalho dependente.',
        ),
        const _MethodStep(
          number: '2',
          title: 'Mínimo de existência',
          text: 'Quando aplicável, calculamos o abatimento previsto no artigo 70.º do Código do IRS.',
        ),
        _MethodStep(
          number: '3',
          title: 'Escalões progressivos',
          text:
              'Aplicamos as taxas gerais de ${rules.taxYear} ao rendimento coletável.',
        ),
        const _MethodStep(
          number: '4',
          title: 'Deduções e retenções',
          text: 'Aplicamos limites por categoria e o limite conjunto. Por fim, descontamos o IRS já retido.',
        ),
        const SizedBox(height: 24),
        NoticeCard(
          title: 'Âmbito validado',
          icon: Icons.verified_outlined,
          messages: [
            'Residente durante todo o ano no Continente.',
            'Rendimentos exclusivamente da Categoria A.',
            'Sujeito passivo não casado e não unido de facto.',
            'Famílias com dependentes apenas quando declaradas monoparentais standard.',
            'Educação standard, sem estudante deslocado ou majorações territoriais.',
            'Regras ${rules.rulesVersion}, verificadas em ${_date(rules.verifiedAt)}.',
          ],
        ),
        const SizedBox(height: 18),
        const NoticeCard(
          title: 'Não suportado / NEEDS_VERIFICATION',
          icon: Icons.block_outlined,
          messages: [
            'Casados, unidos de facto e tributação conjunta.',
            'Madeira, Açores e residência parcial.',
            'IRS Jovem, Categoria B e pensões.',
            'Rendimentos estrangeiros, de capitais, prediais e mais-valias.',
            'Deficiência, estudante deslocado, guarda partilhada e outras situações especiais.',
          ],
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => AppNavigation.push(
              context,
              TaxValidationLabScreen(rules: rules),
            ),
            icon: const Icon(Icons.science_outlined),
            label: const Text('Abrir Tax Validation Lab'),
          ),
        ],
      ],
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

final class _MethodStep extends StatelessWidget {
  const _MethodStep({
    required this.number,
    required this.title,
    required this.text,
  });
  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 18, child: Text(number)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
