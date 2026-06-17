import 'package:flutter/foundation.dart';

import 'local_storage_service.dart';

/// خيارات حجم الخط المتاحة في التطبيق.
enum FontScaleOption {
  normal(1.0, 'عادي'),
  large(1.3, 'كبير'),
  largest(1.6, 'أكبر');

  const FontScaleOption(this.scale, this.labelAr);

  final double scale;
  final String labelAr;

  static FontScaleOption fromScale(double s) {
    if (s >= 1.55) return FontScaleOption.largest;
    if (s >= 1.25) return FontScaleOption.large;
    return FontScaleOption.normal;
  }
}

/// يُدير حجم الخط في التطبيق ويُخطر الشاشات عند التغيير.
///
/// يطبّقه جذر التطبيق على [MediaQuery.textScaler] ليؤثر على كل النصوص.
class FontSizeService extends ChangeNotifier {
  double _scale;

  FontSizeService()
      : _scale = LocalStorageService.cachedFontScale ?? 1.0;

  /// المقياس الحالي (1.0 / 1.3 / 1.6).
  double get scale => _scale;

  /// الخيار الحالي كـ [FontScaleOption].
  FontScaleOption get option => FontScaleOption.fromScale(_scale);

  /// يحمّل القيمة من القرص عند أول تشغيل (بعد preload في splash).
  Future<void> load() async {
    _scale = await LocalStorageService().getFontScale();
    notifyListeners();
  }

  /// يُغيّر مقياس الخط ويُخزّنه.
  Future<void> setOption(FontScaleOption option) async {
    if (_scale == option.scale) return;
    _scale = option.scale;
    notifyListeners();
    await LocalStorageService().setFontScale(option.scale);
  }
}
