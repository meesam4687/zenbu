import 'package:flutter/material.dart';

enum SubtitlePreset { defaultOutline, classicBorder, custom }

class SubtitleConfig {
  final SubtitlePreset preset;
  final double fontSize;
  final String fontFamily;
  final int textColorValue;
  final double borderWidth;
  final int borderColorValue;
  final double backgroundOpacity;
  final int backgroundColorValue;
  final bool hasShadow;
  final int fontWeightIndex;

  const SubtitleConfig({
    this.preset = SubtitlePreset.defaultOutline,
    this.fontSize = 20.0,
    this.fontFamily = 'Liberation Sans',
    this.textColorValue = 0xFFFFFFFF,
    this.borderWidth = 3.4,
    this.borderColorValue = 0xFF000000,
    this.backgroundOpacity = 0.0,
    this.backgroundColorValue = 0xFF000000,
    this.hasShadow = true,
    this.fontWeightIndex = 0,
  });

  Color get textColor => Color(textColorValue);
  Color get borderColor => Color(borderColorValue);
  Color get backgroundColor => Color(backgroundColorValue);

  FontWeight get fontWeight {
    switch (fontWeightIndex) {
      case 0:
        return FontWeight.normal;
      case 1:
        return FontWeight.w600;
      case 2:
      default:
        return FontWeight.bold;
    }
  }

  double get effectiveFontSize =>
      preset == SubtitlePreset.custom ? fontSize : 20.0;

  String? get effectiveFontFamily {
    if (preset == SubtitlePreset.defaultOutline) return 'Liberation Sans';
    if (preset == SubtitlePreset.classicBorder) return null;
    return fontFamily.isEmpty || fontFamily == 'Default' ? null : fontFamily;
  }

  List<String> get effectiveFontFamilyFallback {
    if (preset == SubtitlePreset.defaultOutline ||
        fontFamily == 'Liberation Sans') {
      return const ['Arial', 'Roboto', 'sans-serif'];
    }
    return const ['sans-serif'];
  }

  FontWeight get effectiveFontWeight {
    if (preset == SubtitlePreset.defaultOutline) return FontWeight.normal;
    if (preset == SubtitlePreset.classicBorder) return FontWeight.normal;
    return fontWeight;
  }

  Color get effectiveTextColor {
    if (preset != SubtitlePreset.custom) return Colors.white;
    return textColor;
  }

  double get effectiveBorderWidth {
    if (preset == SubtitlePreset.defaultOutline) return 3.4;
    if (preset == SubtitlePreset.classicBorder) return 2.0;
    return borderWidth;
  }

  Color get effectiveBorderColor {
    if (preset != SubtitlePreset.custom) return Colors.black;
    return borderColor;
  }

  bool get effectiveHasShadow {
    if (preset == SubtitlePreset.defaultOutline) return true;
    if (preset == SubtitlePreset.classicBorder) return false;
    return hasShadow;
  }

  double get effectiveBackgroundOpacity {
    if (preset != SubtitlePreset.custom) return 0.0;
    return backgroundOpacity;
  }

  Color get effectiveBackgroundColor {
    if (preset != SubtitlePreset.custom) return Colors.black;
    return backgroundColor;
  }

  SubtitleConfig copyWith({
    SubtitlePreset? preset,
    double? fontSize,
    String? fontFamily,
    int? textColorValue,
    double? borderWidth,
    int? borderColorValue,
    double? backgroundOpacity,
    int? backgroundColorValue,
    bool? hasShadow,
    int? fontWeightIndex,
  }) {
    return SubtitleConfig(
      preset: preset ?? this.preset,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      textColorValue: textColorValue ?? this.textColorValue,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColorValue: borderColorValue ?? this.borderColorValue,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      hasShadow: hasShadow ?? this.hasShadow,
      fontWeightIndex: fontWeightIndex ?? this.fontWeightIndex,
    );
  }

  Map<String, dynamic> toJson() => {
    'preset': preset.index,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'textColorValue': textColorValue,
    'borderWidth': borderWidth,
    'borderColorValue': borderColorValue,
    'backgroundOpacity': backgroundOpacity,
    'backgroundColorValue': backgroundColorValue,
    'hasShadow': hasShadow,
    'fontWeightIndex': fontWeightIndex,
  };

  factory SubtitleConfig.fromJson(Map<String, dynamic> json) {
    final presetIdx = json['preset'] as int? ?? 0;
    final preset = (presetIdx >= 0 && presetIdx < SubtitlePreset.values.length)
        ? SubtitlePreset.values[presetIdx]
        : SubtitlePreset.defaultOutline;

    return SubtitleConfig(
      preset: preset,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 20.0,
      fontFamily: json['fontFamily'] as String? ?? 'Liberation Sans',
      textColorValue: json['textColorValue'] as int? ?? 0xFFFFFFFF,
      borderWidth: (json['borderWidth'] as num?)?.toDouble() ?? 3.4,
      borderColorValue: json['borderColorValue'] as int? ?? 0xFF000000,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.0,
      backgroundColorValue: json['backgroundColorValue'] as int? ?? 0xFF000000,
      hasShadow: json['hasShadow'] as bool? ?? true,
      fontWeightIndex: json['fontWeightIndex'] as int? ?? 0,
    );
  }
}

class CustomSubtitleView extends StatelessWidget {
  final String text;
  final SubtitleConfig config;

  const CustomSubtitleView({
    super.key,
    required this.text,
    this.config = const SubtitleConfig(),
  });

  @override
  Widget build(BuildContext context) {
    final textStyleBase = TextStyle(
      fontFamily: config.effectiveFontFamily,
      fontFamilyFallback: config.effectiveFontFamilyFallback,
      fontWeight: config.effectiveFontWeight,
      fontSize: config.effectiveFontSize,
      letterSpacing: 0.2,
      height: 1.2,
    );

    final bgOpacity = config.effectiveBackgroundOpacity;
    final borderWidth = config.effectiveBorderWidth;
    final borderColor = config.effectiveBorderColor;
    final hasShadow = config.effectiveHasShadow;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: bgOpacity > 0
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : EdgeInsets.zero,
        decoration: bgOpacity > 0
            ? BoxDecoration(
                color: config.effectiveBackgroundColor.withValues(
                  alpha: bgOpacity,
                ),
                borderRadius: BorderRadius.circular(4.0),
              )
            : null,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            if (hasShadow)
              Transform.translate(
                offset: const Offset(1.0, 1.0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyleBase.copyWith(
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = borderWidth > 0 ? borderWidth + 0.4 : 3.4
                      ..strokeJoin = StrokeJoin.round
                      ..strokeCap = StrokeCap.round
                      ..color = Colors.black,
                  ),
                ),
              ),

            if (borderWidth > 0)
              Text(
                text,
                textAlign: TextAlign.center,
                style: textStyleBase.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = borderWidth
                    ..strokeJoin = StrokeJoin.round
                    ..strokeCap = StrokeCap.round
                    ..color = borderColor,
                ),
              ),

            Text(
              text,
              textAlign: TextAlign.center,
              style: textStyleBase.copyWith(color: config.effectiveTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
