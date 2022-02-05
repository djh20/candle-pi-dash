
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/themes.dart';
import 'package:candle_dash/widgets/drawer/card.dart';
import 'package:candle_dash/widgets/drawer/insights_card.dart';
import 'package:candle_dash/widgets/drawer/metrics_card.dart';
import 'package:candle_dash/widgets/drawer/navigation_card.dart';
import 'package:candle_dash/widgets/drawer/performance_card.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonStyle = 
      ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        elevation: 0
      );

    final model = PropertyChangeProvider.of<AppModel, String>(
      context, 
      listen: false
    )?.value;

    return OverflowBox(
      minWidth: 0,
      maxWidth: 295,
      alignment: Alignment.centerRight,
      child: PageView(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        controller: model?.hPageController,
        onPageChanged: model?.hPageChanged,
        scrollBehavior: NoGlowBehavior(),
        children: [
          const SizedBox(), // Empty page
          PageView(
            clipBehavior: Clip.none,
            scrollDirection: Axis.vertical,
            controller: model?.vPageController,
            onPageChanged: model?.vPageChanged,
            //scrollBehavior: NoGlowBehavior(),
            children: [
              const DrawerCard(
                title: 'Map',
                icon: Icons.map,
                children: [
                  NavigationCardContent()
                ],
              ),
              const DrawerCard(
                title: 'Insights', // Insights,
                icon: Icons.search,
                children: [
                  InsightsCardContent()
                ],
              ),
              /*const DrawerCard(
                title: 'Battery',
                icon: Icons.battery_full,
                children: [
                  //PerformanceCardContent()
                ],
              ),*/
              const DrawerCard(
                title: 'Performance',
                icon: Icons.speed,
                children: [
                  PerformanceCardContent()
                ],
              ),
              DrawerCard(
                title: 'Settings',
                icon: Icons.settings,
                children: [
                  ElevatedButton(
                    child: const Text("LIGHT THEME"),
                    style: buttonStyle,
                    onPressed: () {
                      model?.setAutoTheme(false);
                      model?.setTheme(Themes.light);
                    },
                  ),
                  ElevatedButton(
                    child: const Text("DARK THEME"),
                    style: buttonStyle,
                    onPressed: () {
                      model?.setAutoTheme(false);
                      model?.setTheme(Themes.dark);
                    },
                  ),
                  ElevatedButton(
                    child: const Text("AUTO THEME"),
                    style: buttonStyle,
                    onPressed: () => model?.setAutoTheme(true),
                  ),
                  ElevatedButton(
                    child: const Text("CONNECT TO DEV SERVER"),
                    style: buttonStyle,
                    onPressed: () {
                      model?.vehicle.ip = Constants.devIp;
                      model?.vehicle.reconnect();
                    },
                  ),
                  /*
                  ElevatedButton(
                    child: const Text("SNACKBAR"),
                    style: buttonStyle,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                color: Colors.white,
                              ),
                              SizedBox(width: 10),
                              Text("Battery charge below 10%")
                            ],
                          ),
                          width: 400,
                          behavior: SnackBarBehavior.floating,
                          dismissDirection: DismissDirection.startToEnd,
                        )
                      );
                    },
                  )
                  */
                ],
              ),
              const DrawerCard(
                title: 'Metrics',
                icon: Icons.data_usage,
                children: [
                  MetricsCardContent()
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class NoGlowBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}