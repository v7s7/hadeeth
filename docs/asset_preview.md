# معاينة الشخصيات والإكسسوارات

هذه الصفحة توضّح أن الشخصيات والإكسسوارات الآن كلها صور PNG حقيقية (خلفية شفافة)، مع رمز/لون احتياطي يبقى للنصوص وقراءة الشاشة فقط.

## لماذا تغيّرنا لهذا الأسلوب؟

في البداية بقيت الشخصيات مرسومة عبر `CharacterAvatar` باستخدام Flutter `CustomPainter` لأن ملفات PNG الثنائية لا تظهر كـ diff نصي في بعض واجهات GitHub/Codex. لكن الرسم بالكود كان محدودًا وظهرت فيه أخطاء بصرية، بينما كانت صور PNG مرسومة بجودة أعلى لكل الشخصيات موجودة أصلًا (`assets/images/character/`) وغير مستخدمة. استبدلنا الرسم بالكود بهذه الصور مباشرة. الإكسسوارات تتبع نفس الأسلوب: صور PNG مولّدة بالذكاء الاصطناعي، أُزيلت خلفياتها برمجيًا (Pillow/flood-fill) ووُضعت في `assets/images/accessories/`.

## الشخصيات (صور PNG)

| الشخصية | المعرّف المستخدم في التطبيق | صورة PNG |
|---|---|---|
| الغترة الزرقاء | `male_ghutra_blue` | `male_ghutra_blue.png` |
| البشت الذهبي | `male_bisht_gold` | `male_bisht_gold.png` |
| الشماغ الأحمر | `male_shmagh_red` | `male_shmagh_red.png` |
| الحجاب الوردي | `female_hijab_pink` | `female_hijab_pink.png` |
| النقاب | `female_niqab` | `female_niqab.png` |
| الزي المطرز | `female_hijab_teal` | `female_hijab_teal.png` |

كل صورة بحجم 512×512 بخلفية شفافة حقيقية (RGBA)، مخزّنة في `assets/images/character/` ومرتبطة عبر حقل `assetPath` في `lib/models/app_characters.dart`. الودجت `CharacterAvatar` يعرضها مباشرة عبر `Image.asset` بدل الرسم بـ `CustomPainter`.

## الإكسسوارات (صور PNG + رمز احتياطي)

| الإضافة | المعرّف | صورة PNG | شرط الفتح |
|---|---|---|---|
| مسباح كهرمان | `misbah_amber` | `misbah_amber.png` | افتراضي |
| مسباح خشبي | `misbah_wood` | `misbah_wood.png` | 100 XP |
| مسباح أسود | `misbah_black` | `misbah_black.png` | سلسلة 7 أيام |
| مظلة زرقاء | `umbrella_blue` | `umbrella_blue.png` | 150 XP |
| مظلة ذهبية | `umbrella_gold` | `umbrella_gold.png` | 200 XP |
| مظلة حمراء | `umbrella_red` | `umbrella_red.png` | سلسلة 10 أيام |
| إطار ذهبي | `frame_gold` | `frame_gold.png` | سلسلة 14 يومًا |
| شارة طالب علم | `badge_knowledge` | `badge_knowledge.png` | 250 XP |
| فانوس ذهبي | `lantern_gold` | `lantern_gold.png` | 350 XP |
| دفتر الحديث | `notebook_teal` | `notebook_teal.png` | سلسلة 21 يومًا |

كل صورة مخزّنة في `assets/images/accessories/` ومرتبطة عبر حقل `imagePath` في `lib/models/app_accessory.dart`. حقل `emoji` بقي كاحتياط نصي (Semantics/قراءة الشاشة) لكن العرض الفعلي في الواجهة يستخدم الصورة.

## كيف تراجعها؟

1. راجع `lib/models/app_characters.dart` لترى مسارات صور الشخصيات (`assetPath`).
2. راجع `lib/widgets/character_avatar.dart` لترى أنه يعرض الصورة مباشرة عبر `Image.asset`.
3. راجع `lib/models/app_accessory.dart` لترى الإكسسوارات، مسارات صورها، وشروط فتحها.
4. شغّل التطبيق محليًا لمشاهدة الصور في اختيار الشخصية، الهوم، والبروفايل.
