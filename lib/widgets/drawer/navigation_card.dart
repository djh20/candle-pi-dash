import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class NavigationCardContent extends StatelessWidget {
  const NavigationCardContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropertyChangeConsumer<AppModel, String>(
      properties: const ["gps_locked"],
      builder: (context, model, properties) {
        final bool gpsLocked = model?.vehicle.getMetricBool("gps_locked") ?? false;

        return gpsLocked ? 
        const NavigationCardMap() : 
        const SizedBox(
          height: Constants.cardContentHeight,
          child: Center(
            child: Text(
              "Location unavailable",
              style: TextStyle(fontSize: 18)
            )
          )
        );
      }
    );
  }
}

class NavigationCardMap extends StatefulWidget {
  const NavigationCardMap({ Key? key }) : super(key: key);

  @override
  State<NavigationCardMap> createState() => _NavigationCardMapState();
}

class _NavigationCardMapState extends State<NavigationCardMap> 
  with TickerProviderStateMixin {

  late AnimationController animController;
  
  @override
  void initState() {
    animController = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this
    );
    super.initState();
  }

  @override
  void dispose() {
    animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = PropertyChangeProvider.of<AppModel, String>(
      context, listen: false
    )?.value;

    final mapController = MapController();
    
    model?.newMap(mapController, animController);

    return SizedBox(
      height: Constants.cardContentHeight,
      child: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: model?.mapPosition,
              rotation: model?.mapRotation ?? 0.0,
              zoom: Constants.mapZoom.toDouble(),
              allowPanningOnScrollingParent: false,
              interactiveFlags: InteractiveFlag.none
            ),
            layers: [
              TileLayerOptions(
                tileProvider: const AssetTileProvider(),
                urlTemplate: "assets/generated/map/{z}-{x}-{y}.png"
              ),
            ],
          ),
          const Center(
            child: Icon(
              Icons.navigation,
              color: Colors.black,
              size: 30
            )
          )
        ]
      )
    );
  }
}