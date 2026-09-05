import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tax_interview_models.dart';
import 'tax_interview_repository.dart';

final taxInterviewRepositoryProvider = Provider<TaxInterviewRepository>(
  (_) => LocalTaxInterviewRepository(),
);

final taxInterviewForYearProvider = FutureProvider.family<TaxInterview?, int>(
  (ref, year) => ref.watch(taxInterviewRepositoryProvider).load(year),
);
