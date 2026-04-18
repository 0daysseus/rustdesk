import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/external_url_policy.dart';

void main() {
  test('blocks official rustdesk urls', () {
    expect(
      isBlockedOfficialRustDeskUrl('https://rustdesk.com/download'),
      isTrue,
    );
    expect(
      isBlockedOfficialRustDeskUrl('https://admin.rustdesk.com/api/login'),
      isTrue,
    );
    expect(
      allowedExternalUri('https://rustdesk.com/privacy.html'),
      isNull,
    );
  });

  test('allows non-rustdesk urls', () {
    expect(
      isBlockedOfficialRustDeskUrl('https://example.com/download'),
      isFalse,
    );
    expect(
      allowedExternalUri('https://example.com/download')?.host,
      'example.com',
    );
  });
}
