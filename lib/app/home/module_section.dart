import 'package:flutter/material.dart';

import '../modules/taxy_module.dart';

final class ModuleSection extends StatelessWidget {
  const ModuleSection({super.key, required this.onOpenIrs});

  final VoidCallback onOpenIrs;

  @override
  Widget build(BuildContext context) {
    final active = TaxyModuleRegistry.byId('irs');
    final coming = TaxyModuleRegistry.modules.where(
      (module) => !module.isActive,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Simuladores', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(18),
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long_rounded),
            ),
            title: Text(
              active.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(active.description),
            trailing: const Chip(label: Text('Disponível')),
            onTap: onOpenIrs,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: coming.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) => Chip(
              avatar: const Icon(Icons.schedule_rounded, size: 16),
              label: Text('${coming.elementAt(index).title} · Em breve'),
            ),
          ),
        ),
      ],
    );
  }
}
