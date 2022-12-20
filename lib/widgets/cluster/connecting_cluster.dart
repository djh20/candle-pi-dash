import 'package:flutter/material.dart';

class ConnectingCluster extends StatelessWidget {
  const ConnectingCluster({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.cable, size: 32),
        SizedBox(width: 8),
        Text(
          "Connecting to vehicle...", 
          style: TextStyle(fontSize: 24)
        ),
      ],
    );
  }
}