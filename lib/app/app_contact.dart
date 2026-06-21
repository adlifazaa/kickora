import 'package:url_launcher/url_launcher.dart';

/// Global contact details for Kickora (About, legal, support).
class AppContact {
  AppContact._();

  static const String email = 'sugarkeysapps@gmail.com';

  static Uri mailtoUri({String? subject}) {
    return Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: subject == null ? null : {'subject': subject},
    );
  }

  static Future<bool> openEmail({String? subject}) async {
    final uri = mailtoUri(subject: subject);
    return launchUrl(uri);
  }
}
