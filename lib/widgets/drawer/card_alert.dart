import 'package:candle_dash/constants.dart';
import 'package:flutter/material.dart';

class CardAlert extends StatelessWidget {
  final String text;

  const CardAlert({
    Key? key,
    required this.text
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Constants.cardContentHeight,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 18)
        )
      )
    );
  }
}