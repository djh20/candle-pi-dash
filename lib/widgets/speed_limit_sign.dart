import 'package:flutter/material.dart';

class SpeedLimitSign extends StatelessWidget {
  final bool visible;
  final int speedLimit;

  const SpeedLimitSign({ 
    Key? key,
    required this.speedLimit,
    this.visible = true
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      //opacity: visible ? 1.0 : 0.0,
      offset: Offset(visible ? 0 : 1, 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
      child: Card(
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(100),
            bottomLeft: Radius.circular(100)
          )
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 76,
                width: 76,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red
                ),
              ),
              Container(
                alignment: Alignment.center,
                height: 60,
                width: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      speedLimit.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 38,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                )
              ),
              
            ],
          ),
        ),
      )
    );
  }
}