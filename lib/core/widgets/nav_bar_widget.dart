import 'package:flutter/material.dart';

import '/core/utils/localization_util.dart';
import '/core/widgets/local_flag_widget.dart';
import '/core/widgets/menu_widget.dart';

class NavBar extends AppBar {
  final Function? handleChangeView;
  final PreferredSizeWidget? bottomNavbar;
  final String? titleNavBar;
  final bool isNeedingBackValidation;
  final bool shouldPop;

  NavBar({
    super.key,
    required BuildContext context,
    this.handleChangeView,
    this.bottomNavbar,
    this.titleNavBar,
    this.isNeedingBackValidation = false,
    this.shouldPop = true,
  }) : super(
          title: Row(
            children: [
              Text(titleNavBar ?? context.translate('common.appTitle'),
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Colors.white,
                      )),
            ],
          ),
          leadingWidth: 32,
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    iconSize: 22,
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onPressed: () => _handleBackPress(context,
                        isNeedingBackValidation, shouldPop, handleChangeView),
                  ))
              : null,
          backgroundColor: Theme.of(context).colorScheme.primary,
          bottom: bottomNavbar,
          actions: [const MenuWidget(), const LocaleFlagWidget()],
        );

  static Future<void> _handleBackPress(
      BuildContext context,
      bool isNeedingBackValidation,
      bool shouldPop,
      Function? handleChangeView) async {
    if (isNeedingBackValidation) {
      final shouldLeave = await _showBackDialog(context);
      if (shouldLeave == true) {
        Navigator.pop(context);
      }
    } else if (handleChangeView != null) {
      handleChangeView();
    } else {
      Navigator.pop(context);
    }
  }

  static Future<bool?> _showBackDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.translate('common.backButtonDialog.title')),
          content: Text(
            context.translate('common.backButtonDialog.content'),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(context.translate('common.cancel')),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: Text(context.translate('common.validate')),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }
}
