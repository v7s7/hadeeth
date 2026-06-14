import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

/// يرسل إشعارات FCM باستخدام HTTP v1 API (الأحدث، بدون Legacy key).
///
/// الاستخدام:
///   final svc = FcmV1Service.fromJson(serviceAccountMap);
///   await svc.sendToTopic(topic: 'all_users', title: '...', body: '...');
class FcmV1Service {
  FcmV1Service._({
    required String clientEmail,
    required String privateKey,
    required String projectId,
  })  : _clientEmail = clientEmail,
        _privateKey = privateKey,
        _projectId = projectId;

  factory FcmV1Service.fromJson(Map<String, dynamic> json) {
    return FcmV1Service._(
      clientEmail: json['client_email'] as String,
      privateKey: json['private_key'] as String,
      projectId: json['project_id'] as String,
    );
  }

  final String _clientEmail;
  final String _privateKey;
  final String _projectId;

  String? _cachedToken;
  DateTime? _tokenExpiry;

  // ── OAuth2 access token via JWT ────────────────────────────────────────────

  Future<String> _accessToken() async {
    // إعادة استخدام التوكن إن لم يقترب انتهاؤه (هامش 5 دقائق).
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now()
            .isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)))) {
      return _cachedToken!;
    }

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final jwt = JWT({
      'iss': _clientEmail,
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now,
      'exp': now + 3600,
    });

    final signed = jwt.sign(
      RSAPrivateKey(_privateKey),
      algorithm: JWTAlgorithm.RS256,
    );

    final res = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': signed,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('OAuth2 token error (${res.statusCode}): ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _cachedToken = data['access_token'] as String;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: data['expires_in'] as int));

    return _cachedToken!;
  }

  // ── FCM v1 send ────────────────────────────────────────────────────────────

  Future<void> sendToTopic({
    required String topic,
    required String title,
    required String body,
  }) async {
    final token = await _accessToken();

    final res = await http.post(
      Uri.parse(
          'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'message': {
          'topic': topic,
          'notification': {'title': title, 'body': body},
          'apns': {
            'payload': {
              'aps': {'sound': 'default', 'badge': 1}
            }
          },
          'android': {
            'notification': {'sound': 'default'}
          },
        }
      }),
    );

    if (res.statusCode != 200) {
      throw Exception('FCM v1 error (${res.statusCode}): ${res.body}');
    }
  }
}
