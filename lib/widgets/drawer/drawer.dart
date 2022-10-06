
import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:candle_dash/widgets/drawer/card.dart';
import 'package:candle_dash/widgets/drawer/insights_card.dart';
import 'package:candle_dash/widgets/drawer/metrics_card.dart';
import 'package:candle_dash/widgets/drawer/navigation_card.dart';
import 'package:candle_dash/widgets/drawer/performance_card.dart';
import 'package:candle_dash/widgets/drawer/settings_card.dart';
import 'package:flutter/material.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class SideDrawer extends StatelessWidget {
  const SideDrawer({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = PropertyChangeProvider.of<AppModel, String>(
      context, 
      listen: false
    )?.value;

    return OverflowBox(
      minWidth: 0,
      maxWidth: Constants.drawerWidth,
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
            children: const [
              DrawerCard(
                title: 'Map',
                icon: Icons.map,
                children: [
                  NavigationCardContent()
                ],
              ),
              DrawerCard(
                title: 'Insights', // Insights,
                icon: Icons.search,
                children: [
                  InsightsCardContent()
                ],
              ),
              DrawerCard(
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
                  SettingsCardContent()
                ],
              ),
              DrawerCard(
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