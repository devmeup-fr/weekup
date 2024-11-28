import 'package:flutter/material.dart';

import '../utils/localization_util.dart';

class NoDataWidget extends StatelessWidget {
  final String? titleNoData;
  final bool withDescription;
  final String? descriptionNoData;

  const NoDataWidget(
      {super.key,
      this.titleNoData,
      this.withDescription = false,
      this.descriptionNoData});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.info_outline,
          size: 80.0,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 16),
        Text(
          context.translate(titleNoData ?? 'common.noDataTitle'),
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        if (withDescription) const SizedBox(height: 8),
        if (withDescription)
          Text(
            context.translate(descriptionNoData ?? 'common.noData'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }
}
