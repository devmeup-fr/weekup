import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/localization_util.dart';

class PolicyWidget extends StatelessWidget {
  const PolicyWidget({super.key});

  void _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            _launchURL('https://pyres.com/politique-de-confidentialite/');
          },
          child: Text(
            context.translate('auth.confidentialPolicy'),
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        )
      ],
    );
  }
}
