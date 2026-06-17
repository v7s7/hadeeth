# معاينة الشخصيات والإكسسوارات

هذه الصفحة توضّح أن الشخصيات مرسومة بالكود بدل PNG، بينما الإكسسوارات تُعرض كصور PNG حقيقية (خلفية شفافة) مع رمز/لون احتياطي.

## لماذا تغيّرنا لهذا الأسلوب؟

ملفات PNG الثنائية لا تظهر كـ diff نصي في بعض واجهات GitHub/Codex، لذلك بقيت الشخصيات مرسومة عبر `CharacterAvatar` باستخدام Flutter `CustomPainter`. الإكسسوارات لاحقًا تمت إضافتها كصور PNG مولّدة بالذكاء الاصطناعي، أُزيلت خلفياتها برمجيًا (Pillow/flood-fill) ووُضعت في `assets/images/accessories/`.

## الشخصيات بالكود

| الشخصية | المعرّف المستخدم في التطبيق | الشكل المرسوم |
|---|---|---|
| الغترة الزرقاء | `male_ghutra_blue` | ثوب أزرق فاتح + غترة بيضاء + رأس بلا ملامح |
| البشت الذهبي | `male_bisht_gold` | ثوب أبيض + بشت ذهبي + غترة بيضاء + رأس بلا ملامح |
| الشماغ الأحمر | `male_shmagh_red` | ثوب أبيض + شماغ أحمر/أبيض + رأس بلا ملامح |
| الحجاب الوردي | `female_hijab_pink` | عباءة داكنة + حجاب وردي + وجه بلا ملامح |
| النقاب | `female_niqab` | عباءة سوداء + نقاب بسيط |
| الزي المطرز | `female_hijab_teal` | عباءة تركواز مطرزة + حجاب مطابق |

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

1. افتح ملفات Dart في الـ diff لمنطق الشخصيات والإكسسوارات؛ لن تحتاج إلى مراجعة PNG binary للشخصيات.
2. راجع `lib/widgets/character_avatar.dart` لترى رسم الشخصيات بالكود.
3. راجع `lib/models/app_accessory.dart` لترى الإكسسوارات، مسارات صورها، وشروط فتحها.
4. شغّل التطبيق محليًا لمشاهدة الرسوم في اختيار الشخصية، الهوم، والبروفايل.
