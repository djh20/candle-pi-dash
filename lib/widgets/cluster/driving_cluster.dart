import 'package:candle_dash/widgets/cluster/info_footer.dart';
import 'package:flutter/material.dart';
import 'package:candle_dash/widgets/cluster/power_bar.dart';
import 'package:candle_dash/widgets/cluster/speedometer.dart';

class DrivingCluster extends StatelessWidget {
  const DrivingCluster({  Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        children: const [
          PowerBar(),
          Speedometer(),
          InfoFooter(),
          SizedBox(height: 25)
        ]
      ),
    );
  }
}