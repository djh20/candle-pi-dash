import 'package:flutter/material.dart';

class DrawerCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const DrawerCard({ 
    Key? key,
    required this.title,
    required this.icon,
    this.children = const []
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 40,
      margin: const EdgeInsets.only(
        right: 10,
        bottom: 4,
        top: 4,
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16),
                const SizedBox(width: 5),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900
                  )
                )
              ]
            ),
            const SizedBox(height: 5),
            ...children
          ],
        ),
      ),
    );
  }
}