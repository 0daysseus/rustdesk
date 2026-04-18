import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

bool isBlockedOfficialRustDeskUrl(String url) {
  final uri = Uri.tryParse(url);
  final host = uri?.host.toLowerCase();
  if (host != null && host.isNotEmpty) {
    return host == 'rustdesk.com' || host.endsWith('.rustdesk.com');
  }
  return url.toLowerCase().contains('rustdesk.com');
}

Uri? allowedExternalUri(String url) {
  if (isBlockedOfficialRustDeskUrl(url)) {
    return null;
  }
  return Uri.tryParse(url);
}

Future<bool> launchExternalUrl(
  String url, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  final uri = allowedExternalUri(url);
  if (uri == null) {
    return false;
  }
  return launchUrl(uri, mode: mode);
}

Future<bool> launchExternalUrlString(
  String url, {
  LaunchMode mode = LaunchMode.platformDefault,
}) async {
  if (isBlockedOfficialRustDeskUrl(url)) {
    return false;
  }
  return launchUrlString(url, mode: mode);
}
