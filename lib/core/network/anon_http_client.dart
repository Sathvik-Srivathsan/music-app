import 'package:http/http.dart' as http;

/// An [http.Client] that stops the Supabase SDK from forwarding the API key as
/// an `Authorization: Bearer ...` token, while preserving genuine session JWTs.
///
/// Why this is needed: this app talks to Supabase anonymously (no signed-in
/// user). The legacy `anon` JWT key could legally be copied into
/// `Authorization: Bearer` by the SDK. The new **publishable** key
/// (`sb_publishable_...`) is NOT a JWT, and PostgREST rejects any non-JWT key
/// placed in the `Authorization` header with `Invalid JWT` / 404. Per Supabase
/// the publishable key must only ever ride in the `apikey` header.
///
/// The Supabase SDK's shared `AuthHttpClient` installs the key as a Bearer
/// token (`Bearer <key>`) whenever there is no signed-in session
/// (see `supabase`'s `auth_http_client.dart`: `authBearer = accessToken ??
/// _supabaseKey`). That is invalid for non-JWT publishable keys, so it must be
/// removed. When a real user signs in (GitHub OAuth), the SDK puts the user's
/// session JWT in `Authorization` instead — that value IS a JWT and MUST be
/// kept so authenticated requests (and future RLS) work.
///
/// Rule: drop `Authorization` only when it carries the publishable (non-JWT)
/// key; otherwise leave it untouched (real session JWT). The `apikey` header is
/// always left in place.
class PublishableKeyHttpClient extends http.BaseClient {
  PublishableKeyHttpClient() : _inner = http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Decide whether the current Authorization header is the invalid
    // "publishable key masquerading as a JWT" copy that must be removed.
    // A genuine session JWT is always a base64url JWT (`eyJ...`); the
    // publishable key (`sb_publishable_...`) is not. Keeping real JWTs is what
    // lets authenticated (GitHub-signed-in) requests carry their session token.
    final bearer = _bearerToken(request.headers['Authorization']) ??
        _bearerToken(request.headers['authorization']);

    if (bearer != null && !_looksLikeJwt(bearer)) {
      request.headers.remove('Authorization');
      request.headers.remove('authorization');
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();

  /// Extracts the token from a `Bearer <token>` header value, or null if the
  /// header is absent / not a Bearer header.
  String? _bearerToken(String? header) {
    if (header == null) return null;
    const prefix = 'Bearer ';
    if (!header.startsWith(prefix)) return null;
    final token = header.substring(prefix.length).trim();
    return token.isEmpty ? null : token;
  }

  /// A Supabase session token is a standard base64url JSON Web Token, which
  /// always starts with `eyJ`. The publishable key is not, so it never matches.
  bool _looksLikeJwt(String token) => token.startsWith('eyJ');
}
