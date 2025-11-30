import 'dart:convert';

import 'package:shared/models/user.dart';

/// Simple JWT-like token service
/// In production, use a proper JWT library!
class TokenService {
  /// Creates token service with signing secret
  TokenService(this._secret);

  final String _secret;

  /// Generate a token for a user ID
  String generate(String userId) {
    final payload = {
      'userId': userId,
      'iat': DateTime.now().millisecondsSinceEpoch,
      'exp':
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
    };

    // Simple base64 encoding (NOT secure - just for demo)
    final payloadJson = jsonEncode(payload);
    final signature = _sign(payloadJson);

    return '${base64Encode(utf8.encode(payloadJson))}.$signature';
  }

  /// Verify and decode a token
  TokenPayload? verify(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 2) return null;

      final payloadJson = utf8.decode(base64Decode(parts[0]));
      final expectedSig = _sign(payloadJson);

      if (parts[1] != expectedSig) return null;

      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // Check expiration
      final exp = payload['exp'] as int;
      if (DateTime.now().millisecondsSinceEpoch > exp) return null;

      return (
        userId: payload['userId'] as String,
        issuedAt: DateTime.fromMillisecondsSinceEpoch(payload['iat'] as int),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp),
      );
    } on Object catch (_) {
      return null;
    }
  }

  String _sign(String data) =>
      // Super simple "signature" - NOT SECURE, just for demo
      base64Encode(utf8.encode('$data$_secret')).substring(0, 32);
}
