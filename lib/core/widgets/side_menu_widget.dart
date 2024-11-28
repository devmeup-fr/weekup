import 'package:flutter/material.dart';

import '../models/menu_model.dart';
import '../utils/localization_util.dart';

class SideMenuWidget extends StatefulWidget {
  final Function(int) onMenuItemSelected;
  final List<MenuModel> menuData;
  final int selectedIndex;

  const SideMenuWidget(
      {super.key,
      required this.onMenuItemSelected,
      required this.menuData,
      required this.selectedIndex});

  @override
  State<SideMenuWidget> createState() => _SideMenuWidgetState();
}

class _SideMenuWidgetState extends State<SideMenuWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      color: const Color(0xFF171821),
      child: ListView.builder(
        itemCount: widget.menuData.length,
        itemBuilder: (context, index) => buildMenuEntry(widget.menuData, index),
      ),
    );
  }

  Widget buildMenuEntry(List<MenuModel> menuData, int index) {
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(
          Radius.circular(6.0),
        ),
        color: isSelected ? Theme.of(context).focusColor : Colors.transparent,
      ),
      child: InkWell(
        onTap: () => widget.onMenuItemSelected(index),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              child: Icon(
                menuData[index].icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
              ),
            ),
            Text(
              context.translate(menuData[index].label),
              style: TextStyle(
                fontSize: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
