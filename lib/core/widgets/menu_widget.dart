import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';
import '../../screens/home_screen.dart';
import '../utils/localization_util.dart';
import 'no_animation_material_page_route.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> onLogoutPressed(BuildContext context) async {
    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    bool authenticated =
        context.watch<AuthCubit>().state.cubitStatus == AuthStatus.success;

    return Row(children: [
      if (authenticated)
        PopupMenuButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.logout),
                title: Text(context.translate('common.logout')),
                onTap: () {
                  Navigator.pop(context);
                  onLogoutPressed(context);
                  Navigator.pushAndRemoveUntil(context,
                      NoAnimationMaterialPageRoute(
                    builder: (BuildContext context) {
                      return const HomeScreen();
                    },
                  ), (Route<dynamic> route) => false);
                },
              ),
            ),
          ],
        )
    ]);
  }
}
