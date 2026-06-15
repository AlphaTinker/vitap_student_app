import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:vit_ap_student_app/features/auth/services/gmail_otp_service.dart';
import 'package:vit_ap_student_app/init_dependencies.dart';

final gmailOtpServiceProvider = Provider<GmailOtpService>((ref) {
  return GmailOtpService(
    storage: serviceLocator<FlutterSecureStorage>(),
    client: serviceLocator<http.Client>(),
  );
});

final gmailOtpLinkControllerProvider =
    AsyncNotifierProvider<GmailOtpLinkController, GmailOtpLinkState>(
      GmailOtpLinkController.new,
    );

class GmailOtpLinkState {
  const GmailOtpLinkState({this.email});

  final String? email;

  bool get isLinked => email != null;
}

class GmailOtpLinkController extends AsyncNotifier<GmailOtpLinkState> {
  late GmailOtpService _gmailOtpService;

  @override
  Future<GmailOtpLinkState> build() async {
    _gmailOtpService = ref.watch(gmailOtpServiceProvider);
    final email = await _gmailOtpService.restoreLinkedEmail();
    return GmailOtpLinkState(email: email);
  }

  Future<void> link() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final email = await _gmailOtpService.link();
      return GmailOtpLinkState(email: email);
    });
  }

  Future<void> unlink() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _gmailOtpService.unlink();
      return const GmailOtpLinkState();
    });
  }
}
