import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DevMeUpWidget extends StatelessWidget {
  const DevMeUpWidget({super.key});

  // Function to open the URL
  void _launchURL(String url) async {
    if (await canLaunchUrl(Uri.https(url))) {
      await launchUrl(Uri.https(url), mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchURL('devmeup.fr'),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          'DevMeUp',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
