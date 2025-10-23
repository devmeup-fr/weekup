import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DevMeUpWidget extends StatelessWidget {
  const DevMeUpWidget({super.key});

  // Open the URL in the external browser
  Future<void> _launchURL(Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      debugPrint('Could not launch $uri');
    }
  }

  // Show a bottom sheet with a link to the site
  void _showDevMeUpBottomSheet(BuildContext context) {
    // List of links to display
    final links = <({IconData icon, String label, Uri uri})>[
      (
        icon: Icons.link,
        label: 'devmeup.fr',
        uri: Uri.parse('https://devmeup.fr')
      ),
      (
        icon: Icons.code,
        label: 'source',
        uri: Uri.parse('https://github.com/devmeup-fr/my_alarms')
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DevMeUp',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 0),
              const SizedBox(height: 16),

              // Replace the big button by a list of links
              ...links.map(
                (item) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _launchURL(item.uri);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDevMeUpBottomSheet(context),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          _showDevMeUpBottomSheet(context);
        }
      },
      child: const Padding(
        padding: EdgeInsets.all(10),
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
