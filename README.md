# Quran Reels Filters — مولّد فيديوهات قرآنية

تطبيق محلي لتوليد فيديوهات قصيرة (Reels / Shorts) لآيات من القرآن الكريم عبر نظام فلاتر جاهزة. يعتمد على FFmpeg و ImageMagick لمعالجة الصوت والفيديو والنصوص العربية.

## الفكرة
المستخدم يختار:
- القارئ
- السورة
- من آية → إلى آية
- مدة الفيديو
- فلتر جاهز

والتطبيق يولّد فيديو 9:16 يحتوي على:
- صوت التلاوة
- خلفية ثابتة/متدرجة
- نص الآيات بتصميم جميل

## المميزات (MVP)
- فلاتر جاهزة قابلة للتوسعة (3 فلاتر مبدئيًا)
- جلب الآيات من `api.alquran.cloud`
- جلب صوت التلاوة من `everyayah.com`
- توليد فيديو MP4 محليًا باستخدام FFmpeg
- دعم RTL عبر ImageMagick
- معاينة الفيديو الناتج + حفظ في مجلد الإخراج

## المتطلبات
- Flutter (>= 3.10.8)
- FFmpeg + ffprobe ضمن PATH
- ImageMagick (يفضّل مع دعم Pango)
- خط عربي مناسب مثبت محليًا (مثال: Amiri)

### فحص التثبيت
```bash
ffmpeg -version
ffprobe -version
magick -version   # أو convert -version
```

## التشغيل
```bash
cd /Users/ahmedabuzyad/development/flutter_media_filters
flutter pub get
flutter run -d macos   # أو windows / linux
```

## الاستخدام
1. اختر القارئ والسورة
2. حدّد نطاق الآيات
3. اختر مدة الفيديو
4. اختر فلتر جاهز
5. اضغط Generate Video

## الفلاتر (Config-based)
الفلاتر معرفة في:
- `lib/features/quran_generator/domain/filter_theme.dart`

يمكنك إضافة فلتر جديد بخصائص:
- نوع الخلفية (لون ثابت / صورة متدرجة / صورة / فيديو)
- الخط والحجم
- لون النص
- Stroke
- موضع النص (Center / Bottom)
- حركة بسيطة (Fade / Slide)

## البنية المعمارية
```
lib/features/quran_generator/
├── domain/                 # نماذج البيانات
├── data/                   # الخدمات (Quran API, Audio, FFmpeg, ImageMagick)
├── providers/              # إدارة الحالة (Riverpod)
└── presentation/           # الواجهة
```

## ملاحظات
- التطبيق مصمم كـ MVP مكتبي (Desktop) لتوافر أدوات CLI.
- لتشغيله على الموبايل، ستحتاج بدائل لـ ImageMagick/FFmpeg CLI.

## الترخيص
MIT
