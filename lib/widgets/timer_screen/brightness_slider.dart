import 'package:flutter/material.dart';
import '../../providers/brightness_provider.dart';

class BrightnessSlider extends StatelessWidget {
  final BrightnessProvider brightnessProvider;

  const BrightnessSlider({Key? key, required this.brightnessProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(left: 20, top: 4, right: 20, bottom: 40),
      color: colorScheme.surfaceContainer,
      child: Row(
        children: [
          Icon(
            Icons.brightness_6_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 8),
          Expanded(
            // year2023: false opts into the current Material 3 "expressive"
            // slider — a thick gapped track with the bar-style handle — instead
            // of the legacy thin-track + round-dot look.
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(year2023: false),
              child: Slider(
                value: brightnessProvider.brightness
                    .clamp(BrightnessProvider.minBrightness, 1.0),
                onChanged: (value) => brightnessProvider.setBrightness(value),
                min: BrightnessProvider.minBrightness,
                max: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
