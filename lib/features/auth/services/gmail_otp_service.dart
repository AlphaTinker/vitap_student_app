import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GmailOtpException implements Exception {
  final String message;

  const GmailOtpException(this.message);

  @override
  String toString() => message;
}

class GmailOtpService {
  GmailOtpService({
    required FlutterSecureStorage storage,
    required http.Client client,
    GoogleSignIn? googleSignIn,
  }) : _storage = storage,
       _client = client,
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn(
             scopes: const [
               'email',
               'https://www.googleapis.com/auth/gmail.readonly',
             ],
           );

  static const String otpSender = 'info1@vitap.ac.in';
  static const String _linkedEmailKey = 'gmail_otp_linked_email';

  final FlutterSecureStorage _storage;
  final http.Client _client;
  final GoogleSignIn _googleSignIn;

  Future<String?> restoreLinkedEmail() async {
    final linkedEmail = await _storage.read(key: _linkedEmailKey);
    if (linkedEmail == null) return null;

    final account =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently(suppressErrors: true);
    if (account == null || account.email != linkedEmail) {
      await _storage.delete(key: _linkedEmailKey);
      return null;
    }

    return account.email;
  }

  Future<String> link() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const GmailOtpException('Google sign-in was cancelled.');
    }

    await _storage.write(key: _linkedEmailKey, value: account.email);
    return account.email;
  }

  Future<void> unlink() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    } finally {
      await _storage.delete(key: _linkedEmailKey);
    }
  }

  Future<String?> findLatestOtp({required DateTime since}) async {
    final account =
        _googleSignIn.currentUser ??
        await _googleSignIn.signInSilently(suppressErrors: true);
    if (account == null) return null;

    final headers = await account.authHeaders;
    final messages = await _listRecentMessageIds(headers);
    if (messages.isEmpty) return null;

    final earliestAllowed = since
        .subtract(const Duration(minutes: 2))
        .millisecondsSinceEpoch;

    for (final messageId in messages) {
      final message = await _getMessage(headers, messageId);
      final internalDate =
          int.tryParse('${message['internalDate'] ?? ''}') ?? 0;
      if (internalDate < earliestAllowed) continue;

      final text = _extractMessageText(message);
      final otp = _extractOtp(text);
      if (otp != null) return otp;
    }

    return null;
  }

  Future<List<String>> _listRecentMessageIds(
    Map<String, String> headers,
  ) async {
    final uri =
        Uri.https('gmail.googleapis.com', '/gmail/v1/users/me/messages', {
          'q': 'from:$otpSender newer_than:30m',
          'maxResults': '10',
          'fields': 'messages/id',
        });

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const GmailOtpException(
        'Gmail permission expired. Link Gmail again.',
      );
    }
    if (response.statusCode != 200) {
      throw GmailOtpException(
        'Could not read Gmail messages (${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rawMessages = body['messages'];
    if (rawMessages is! List) return const [];

    return rawMessages
        .whereType<Map<String, dynamic>>()
        .map((message) => message['id'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _getMessage(
    Map<String, String> headers,
    String id,
  ) async {
    final uri = Uri.https(
      'gmail.googleapis.com',
      '/gmail/v1/users/me/messages/$id',
      {'format': 'full', 'fields': 'internalDate,snippet,payload'},
    );

    final response = await _client.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw GmailOtpException(
        'Could not read a Gmail message (${response.statusCode}).',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _extractMessageText(Map<String, dynamic> message) {
    final parts = <String>[];
    final snippet = message['snippet'];
    if (snippet is String) parts.add(snippet);

    final payload = message['payload'];
    if (payload is Map<String, dynamic>) {
      _collectPayloadText(payload, parts);
    }

    return parts.join('\n');
  }

  void _collectPayloadText(Map<String, dynamic> payload, List<String> parts) {
    final headers = payload['headers'];
    if (headers is List) {
      for (final header in headers.whereType<Map<String, dynamic>>()) {
        final name = header['name'];
        final value = header['value'];
        if (name is String &&
            value is String &&
            name.toLowerCase() == 'subject') {
          parts.add(value);
        }
      }
    }

    final body = payload['body'];
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is String && data.isNotEmpty) {
        final decoded = _decodeBase64Url(data);
        if (decoded != null) parts.add(decoded);
      }
    }

    final childParts = payload['parts'];
    if (childParts is List) {
      for (final child in childParts.whereType<Map<String, dynamic>>()) {
        _collectPayloadText(child, parts);
      }
    }
  }

  String? _decodeBase64Url(String data) {
    try {
      final normalized = base64Url.normalize(data);
      return utf8.decode(base64Url.decode(normalized), allowMalformed: true);
    } catch (_) {
      return null;
    }
  }

  String? _extractOtp(String text) {
    final contextualMatch = RegExp(
      r'(?:otp|one[\s-]?time|verification|code)\D{0,30}(\d{6})',
      caseSensitive: false,
    ).firstMatch(text);
    if (contextualMatch != null) return contextualMatch.group(1);

    return RegExp(r'\b\d{6}\b').firstMatch(text)?.group(0);
  }
}
