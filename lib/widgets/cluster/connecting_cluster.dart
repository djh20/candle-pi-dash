import 'package:flutter/material.dart';

class ConnectingCluster extends StatelessWidget {
  const ConnectingCluster({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.cable, size: 38),
            Transform.scale(
              scale: 1.3,
              child: const CircularProgressIndicator(strokeWidth: 2)
            )
          ],
        ),
        const SizedBox(width: 16),
        const Text(
          "Connecting...", 
          style: TextStyle(fontSize: 32)
        ),
      ],
    );
  }
}