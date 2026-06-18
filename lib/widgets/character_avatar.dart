import 'package:flutter/material.dart';

import '../models/app_accessory.dart';
import '../models/app_characters.dart';

class CharacterAvatar extends StatelessWidget {
  final CharacterOption character;
  final double height;
  final double? width;
  final double opacity;
  final AppAccessory? accessory;

  const CharacterAvatar({
    super.key,
    required this.character,
    required this.height,
    this.width,
    this.opacity = 1,
    this.accessory,
  });

  @override
  Widget build(BuildContext context) {
    final boxWidth = width ?? height * 0.72;
    final placement =
        accessory == null ? null : _placements[accessory!.category];

    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: boxWidth,
        child: placement == null
            ? Image.asset(character.assetPath, fit: BoxFit.contain)
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  if (placement.behindCharacter)
                    _accessoryLayer(placement, boxWidth, height),
                  Positioned.fill(
                    child:
                        Image.asset(character.assetPath, fit: BoxFit.contain),
                  ),
                  if (!placement.behindCharacter)
                    _accessoryLayer(placement, boxWidth, height),
                ],
              ),
      ),
    );
  }

  /// Maps the placement's fractional anchor (relative to the 512x512
  /// character artwork) to an exact pixel position inside the avatar box.
  /// The character is square and rendered with [BoxFit.contain], so its
  /// visible side equals the smaller of the box's two dimensions.
  Widget _accessoryLayer(
    _AccessoryPlacement placement,
    double boxWidth,
    double boxHeight,
  ) {
    final squareSide = boxWidth < boxHeight ? boxWidth : boxHeight;
    final horizontalInset = (boxWidth - squareSide) / 2;
    final verticalInset = (boxHeight - squareSide) / 2;
    final size = squareSide * placement.scale;
    final centerX = horizontalInset + placement.dx * squareSide;
    final centerY = verticalInset + placement.dy * squareSide;

    return Positioned(
      left: centerX - size / 2,
      top: centerY - size / 2,
      width: size,
      height: size,
      child: Image.asset(accessory!.imagePath, fit: BoxFit.contain),
    );
  }

  static const Map<AccessoryCategory, _AccessoryPlacement> _placements = {
    AccessoryCategory.frame: _AccessoryPlacement(
      dx: 0.5,
      dy: 0.5,
      scale: 1.05,
      behindCharacter: true,
    ),
    AccessoryCategory.misbah: _AccessoryPlacement(
      dx: 0.70,
      dy: 0.62,
      scale: 0.24,
      behindCharacter: false,
    ),
    AccessoryCategory.umbrella: _AccessoryPlacement(
      dx: 0.76,
      dy: 0.32,
      scale: 0.58,
      behindCharacter: false,
    ),
    AccessoryCategory.lantern: _AccessoryPlacement(
      dx: 0.28,
      dy: 0.66,
      scale: 0.30,
      behindCharacter: false,
    ),
    AccessoryCategory.badge: _AccessoryPlacement(
      dx: 0.5,
      dy: 0.40,
      scale: 0.16,
      behindCharacter: false,
    ),
    AccessoryCategory.notebook: _AccessoryPlacement(
      dx: 0.34,
      dy: 0.58,
      scale: 0.30,
      behindCharacter: false,
    ),
  };
}

class _AccessoryPlacement {
  final double dx;
  final double dy;
  final double scale;
  final bool behindCharacter;

  const _AccessoryPlacement({
    required this.dx,
    required this.dy,
    required this.scale,
    required this.behindCharacter,
  });
}
