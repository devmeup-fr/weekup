import 'package:flutter/material.dart';
import 'package:my_alarms/models/alarm_model.dart';

class AlarmTile extends StatelessWidget {
  const AlarmTile({
    required this.alarm,
    required this.onPressed,
    super.key,
    this.onDismissed,
    this.isActive = false,
    required this.onToggleActive, // Function to handle the toggle action
  });

  final AlarmModel alarm;
  final void Function() onPressed;
  final void Function()? onDismissed;
  final bool isActive;
  final void Function(bool)
      onToggleActive; // New function to handle activation/deactivation

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: onDismissed != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 30),
        child: const Icon(
          Icons.delete,
          size: 30,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDismissed?.call(),
      child: GestureDetector(
        onTap: onPressed,
        child: Card(
          color: Colors.transparent,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              children: [
                // Icône ou indicateur pour l'alarme
                Icon(
                  Icons.alarm_rounded,
                  size: 30,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 16),
                // Informations principales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alarm.title,
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(
                                  0.3), // Change text color based on active state
                          fontSize: 48,
                        ),
                      ),
                      if (alarm.subtitle != null) const SizedBox(height: 4),
                      if (alarm.subtitle != null)
                        Text(
                          alarm.subtitle!,
                          style: TextStyle(
                            fontSize: 16,
                            color: isActive
                                ? Colors.grey.shade600
                                : Colors.grey.shade600
                                    .withOpacity(0.3), // Adjust subtitle color
                          ),
                        ),
                    ],
                  ),
                ),
                // Toggle switch to activate/deactivate the alarm
                Switch(
                  value: isActive,
                  onChanged: (value) {
                    onToggleActive(
                        value); // Notify parent to update alarm state
                  },
                  activeColor: Colors.green,
                ),
                const Icon(
                  Icons.keyboard_arrow_right_rounded,
                  size: 35,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
