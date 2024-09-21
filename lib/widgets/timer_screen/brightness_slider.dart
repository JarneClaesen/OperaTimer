import 'package:flutter/material.dart';
import '../../providers/brightness_provider.dart';

class BrightnessSlider extends StatelessWidget {
  final BrightnessProvider brightnessProvider;

  const BrightnessSlider({Key? key, required this.brightnessProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20, top: 4, right: 20, bottom: 40),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Row(
        children: [
          Icon(Icons.brightness_6_rounded),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 1.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.0),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 26.0),
              ),
              child: Slider(
                value: brightnessProvider.brightness,
                onChanged: (value) {
                  brightnessProvider.setBrightness(value);
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
