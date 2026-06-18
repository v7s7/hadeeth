import 'package:flutter/material.dart';

import '../models/app_characters.dart';

class CharacterAvatar extends StatelessWidget {
  final CharacterOption character;
  final double height;
  final double? width;
  final double opacity;

  const CharacterAvatar({
    super.key,
    required this.character,
    required this.height,
    this.width,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: width ?? height * 0.72,
        child: Image.asset(character.assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
