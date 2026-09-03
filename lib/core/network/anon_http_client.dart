import 'package:http/http.dart' as http;

/// An [http.Client] that prevents the Supabase SDK from forwarding the API key
/// as an `Authorization: Bearer ...` token.
///
/// Why this is needed: the app talks to Supabase entirely anonymously (no
/// signed-in user, no session JWT). The legacy `anon` JWT key could legally be
/// copied into `Authorization: Bearer` by the SDK. The new **publishable** key
/// (`sb_publishable_...`) is NOT a JWT, and PostgREST rejects any non-JWT key
/// placed in the `Authorization` header with `Invalid JWT` / 404. Per Supabase
/// the publishable key must only ever ride in the `apikey` header.
///
/// Because this app never authenticates a user, there is never a legitimate
/// user JWT to send in `Authorization`. Stripping that header here forces every
/// request to authenticate with the `apikey` header alone, which is exactly the
/// supported shape for new-format keys on anonymous data access.
class PublishableKeyHttpClient extends http.BaseClient {
  PublishableKeyHttpClient() : _inner = http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // The publishable key (customer-facing) is fine to keep on `apikey`, which
    // the SDK sets automatically. Only the mistakenly-injected `Authorization:
    // Bearer <key>` copy is invalid for non-JWT keys and must be removed.
    request.headers.remove('Authorization');
    request.headers.remove('authorization');
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}