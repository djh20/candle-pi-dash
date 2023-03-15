import 'dart:math';

import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class LogsCardContent extends StatelessWidget {
  const LogsCardContent({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ['logs'],
      builder: (context, model, properties) {
        List<Widget> children = [];
        final List<String> logs = model?.logs.reversed.take(50).toList() ?? [];
        final int logCategory = model?.logCategory ?? 0;

        for (int i = 0; i < logs.length; i++) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(logs[i]),
            )
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 220,
              child: ListView(
                children: children
              )
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ElevatedButton(
                onPressed: () => model?.nextLogCategory(), 
                child: Text('CATEGORY: $logCategory'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  elevation: 0
                ),
              ),
            )
          ],
        );
      }
    );
  }
}