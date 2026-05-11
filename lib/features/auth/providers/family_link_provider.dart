import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learnlock/models/supervised_account.dart';
import 'package:learnlock/services/family_link_service.dart';

final familyLinkSupervisedProvider =
    FutureProvider<List<SupervisedAccount>>((ref) async {
  final familyLinkService = ref.watch(familyLinkServiceProvider);
  return familyLinkService.fetchSupervisedAccounts();
});
