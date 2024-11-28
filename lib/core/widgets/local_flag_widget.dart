import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../blocs/locale_cubit.dart';
import '../utils/localization_util.dart';

class LocaleFlagWidget extends StatelessWidget {
  const LocaleFlagWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select<LocaleCubit, Locale>((bloc) => bloc.state);

    return Padding(
        padding: const EdgeInsets.all(8),
        child: DropdownButton<Locale>(
          value: locale,
          onChanged: (Locale? value) {
            if (value == null) return;
            FlutterI18n.refresh(context, value);
            context.read<LocaleCubit>().changeLocale(value);
          },
          icon: Container(),
          iconSize: 0.0,
          alignment: AlignmentDirectional.center,
          underline: Container(),
          focusColor: Colors.transparent,
          items: LocalizationApp.supportedLocales
              .map<DropdownMenuItem<Locale>>((Locale item) {
            var countryCode = item.countryCode;
            if (item.countryCode == 'EN') {
              countryCode = 'GB';
            }
            return DropdownMenuItem<Locale>(
              value: item,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Flag.fromString(
                      countryCode!,
                      width: 30,
                      height: 30,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ));
  }
}
