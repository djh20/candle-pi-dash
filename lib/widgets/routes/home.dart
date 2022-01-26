import 'package:flutter/material.dart';
import 'package:dash_delta/widgets/dash.dart';

class HomePage extends StatelessWidget {
  const HomePage({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final model = context.watch<AppModel>();
    //print("home");
    return const Scaffold(
      //backgroundColor: Colors.black,
      /*
      body: Center(
        child: Text(
          speed.toString(),
          style: TextStyle(fontSize: 170)
        )
      ),
      */

      body: Dash()
    );
  }
}