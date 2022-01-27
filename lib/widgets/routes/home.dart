import 'package:flutter/material.dart';
import 'package:dash_delta/widgets/dash.dart';

class HomePage extends StatelessWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Dash()
    );
  }
}