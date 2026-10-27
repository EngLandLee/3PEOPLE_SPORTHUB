import 'package:url_launcher/url_launcher.dart';

/// Opens the user's installed dialer or maps app for a venue contact action.
class ExternalLinkService {
  ExternalLinkService._();

  static Future<bool> callPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (normalized.isEmpty) return false;
    return launchUrl(
      Uri(scheme: 'tel', path: normalized),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> openMap(String address) async {
    final query = address.trim();
    if (query.isEmpty) return false;
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
