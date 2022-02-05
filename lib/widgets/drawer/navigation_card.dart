import 'package:candle_dash/constants.dart';
import 'package:candle_dash/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import 'package:property_change_notifier/property_change_notifier.dart';

class NavigationCardContent extends StatefulWidget {
  const NavigationCardContent({ Key? key }) : super(key: key);

  @override
  State<NavigationCardContent> createState() => _NavigationCardContentState();
}

class _NavigationCardContentState extends State<NavigationCardContent> 
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
              zoom: 15.0,
              allowPanningOnScrollingParent: false,
              interactiveFlags: InteractiveFlag.none
            ),
            layers: [
              TileLayerOptions(
                tileProvider: const AssetTileProvider(),
                urlTemplate: "assets/map/{z}-{x}-{y}.png"
              ),
              
              /*TileLayerOptions(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c']
              )*/
            ]
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

    /*

    final images = [
      'assets/map/16-64188-41570.png',
      'assets/map/16-64189-41570.png',
      'assets/map/16-64188-41571.png',
      'assets/map/16-64189-41571.png',
    ];

    print('doing thing');
    model?.tController.value = Matrix4(
      1.5, 0.0, 0.0, 0.0,
      0.0, 1.5, 0.0, 0.0,
      0.0, 0.0, 1.5, 0.0,
      0.0, -10.0, 0.0, 1.0,
    );

    print(model?.tController.value);

    return Container(
      height: 283,
      color: Colors.red,
      child: InteractiveViewer(
        panEnabled: false,
        scaleEnabled: false,
        transformationController: model?.tController,
        child: GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          children: images.map((path) {
            return Image.asset(
              path,
              //fit: BoxFit.none,
              //width: 500,
            );
          }).toList()
        ),
      )
      //color: Colors.grey,
      //child: FittedBox(
        //fit: BoxFit.cover,
        
      //)
      /*
      child: OSMFlutter(
        controller: model?.mapController ?? MapController(),
        showZoomController: true,
      )*/
      /*
      child: FlutterMap(
        options: MapOptions(
          zoom: 16.0,
          center: LatLng(-43.469810, 172.610123),
          //allowPanningOnScrollingParent: false,
          //interactiveFlags: InteractiveFlag.none
        ),
        layers: [
          /*
          TileLayerOptions(
            tileProvider: const AssetTileProvider(),
            urlTemplate: "assets/map/{z}-{x}-{y}.png"
          ),
          */
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']
          )
        ]
      )
      */
    );
    */
  }
}