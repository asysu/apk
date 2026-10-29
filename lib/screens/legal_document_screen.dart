import 'package:flutter/material.dart';

Future<void> showLegalDocuments(BuildContext context) async {
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Məxfilik siyasəti və istifadə şərtləri',
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const LegalDocumentScreen(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: child,
      );
    },
  );
}

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Məxfilik və istifadə şərtləri'),
        actions: [
          IconButton(
            tooltip: 'Bağla',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Məxfilik siyasəti',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Son yenilənmə: 29 oktyabr 2026',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          ..._buildSections(context, _privacySections),
          const SizedBox(height: 12),
          Text(
            'İstifadə şərtləri',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ..._buildSections(context, _termsSections),
        ],
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    List<_DocumentSection> sections,
  ) {
    return [
      for (final section in sections) ...[
        Text(
          section.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          section.body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
        const SizedBox(height: 18),
      ],
    ];
  }
}

class _DocumentSection {
  const _DocumentSection(this.title, this.body);

  final String title;
  final String body;
}

const _privacySections = [
  _DocumentSection(
    '1. Hansı məlumatlar saxlanılır?',
    'Adınız, dərs irəliləyişiniz, tamamladığınız mövzular və seçdiyiniz '
        'görünüş rejimi tətbiqin işləməsi üçün cihazınızda saxlanılır. Tətbiq '
        'hesab, parol, dəqiq məkan və ya ödəniş məlumatı tələb etmir. Adınız '
        'AI müəllimə göndərilmir.',
  ),
  _DocumentSection(
    '2. Məlumatların cihazda saxlanması',
    'Yerli məlumatlar tətbiqin cihaz yaddaşında qalır və tətbiqin məlumatlarını '
        'sildikdə və ya tətbiqi sildikdə itə bilər. Cihazınızı başqaları ilə '
        'paylaşırsınızsa, adınızın və irəliləyişinizin həmin cihazı istifadə '
        'edənlərə görünə biləcəyini nəzərə alın.',
  ),
  _DocumentSection(
    '3. AI müəllim və internet xidmətləri',
    'AI müəllim funksiyasından istifadə etdikdə yazdığınız sual və mövzu, '
        'həmçinin cavab hazırlamaq üçün lazım olan dərs məzmunu tətbiqin '
        'konfiqurasiya edilmiş serverinə və AI provayderinə (məsələn, Google '
        'Gemini) ötürülə bilər. Bu funksiya qurulmayıbsa və ya bağlantı '
        'yoxdursa, tətbiqin yerli dərs və sual materiallarından istifadə edə '
        'bilərsiniz. AI sorğularına adınızı, əlaqə məlumatınızı və digər '
        'şəxsi məlumatları daxil etməyin.',
  ),
  _DocumentSection(
    '4. Üçüncü tərəflərin emalı',
    'AI sorğularının üçüncü tərəflər tərəfindən saxlanması və emalı həmin '
        'xidmətlərin qüvvədə olan şərt və məxfilik qaydalarına tabedir. '
        'Tətbiq bu xidmətlərin saxlanma müddətini və emal üsullarını idarə '
        'etmir. Həssas və ya məxfi məlumatı AI sorğularında paylaşmayın.',
  ),
  _DocumentSection(
    '5. Məlumatlara nəzarət və təhlükəsizlik',
    'Tətbiqə yalnız göstərilməsini istədiyiniz adı yazın. Məlumatlar cihazınızda '
        'saxlanıldığından cihazın '
        'kilidini qorumaq və tətbiq məlumatlarını idarə etmək sizin '
        'məsuliyyətinizdədir. Tətbiqə API açarı daxil etməyiniz tələb olunmur; '
        'belə açarları heç vaxt ad və ya sual sahələrinə yazmayın.',
  ),
  _DocumentSection(
    '6. Siyasətdə dəyişikliklər və əlaqə',
    'Məxfilik qaydaları dəyişərsə, bu səhifədə yenilənmiş mətn dərc edilə '
        'bilər. Bu sənəd ümumi məlumat üçündür və hüquqi məsləhət deyil. '
        'Məxfiliklə bağlı sual və ya narahatlığınız varsa, tətbiqi təqdim edən '
        'komanda ilə əlaqə saxlayın.',
  ),
];

const _termsSections = [
  _DocumentSection(
    '1. Tətbiqin məqsədi',
    '“İmtahan 90+” 9-cu sinif şagirdlərinin riyaziyyat və ingilis dili üzrə '
        'məşq etməsi üçün nəzərdə tutulmuş tədris vasitəsidir. Tətbiq rəsmi '
        'imtahan orqanını təmsil etmir və rəsmi materialın əvəzi deyil.',
  ),
  _DocumentSection(
    '2. İstifadə və razılıq',
    '“Başla” düyməsinə basmaqla bu şərtləri və Məxfilik siyasətini oxuduğunuzu '
        'və qəbul etdiyinizi təsdiqləyirsiniz. 18 yaşdan kiçiksinizsə, '
        'sənədləri valideyniniz və ya qanuni qəyyumunuzla birlikdə oxuyun və '
        'onun icazəsi ilə istifadə edin.',
  ),
  _DocumentSection(
    '3. Tədris məzmunu',
    'Dərslər və cavablar öyrənməyə kömək məqsədi daşıyır. Məzmun və AI '
        'cavabları bəzən natamam və ya səhv ola bilər; vacib məlumatı dərslik '
        'və rəsmi mənbələrlə yoxlayın. İmtahan nəticəsinə, bal artımına və ya '
        'müəyyən sualın imtahanda çıxacağına zəmanət verilmir.',
  ),
  _DocumentSection(
    '4. AI funksiyası',
    'AI müəllimdən alınan cavablar avtomatik yaradılır və peşəkar, rəsmi və '
        'ya fərdi məsləhət sayılmır. AI xidmətinin mövcudluğu internetə və '
        'xarici provayderlərə bağlıdır. AI-yə göndərilən məlumatlar barədə '
        'ətraflı məlumat üçün Məxfilik siyasətinə baxın.',
  ),
  _DocumentSection(
    '5. Təhlükəsiz və qanuni istifadə',
    'Tətbiqdən qanuna uyğun, tədris məqsədilə istifadə edin. İcazəsiz girişə, '
        'xidmətin işini pozmağa, zərərli kod yaymağa və başqalarının '
        'məlumatlarını əldə etməyə cəhd etməyin. Tətbiqin qorunmasını aşmaq '
        'və ya onu dəyişdirmək yalnız tətbiq olunan qanunların icazə verdiyi '
        'hədlərdə mümkündür.',
  ),
  _DocumentSection(
    '6. Xidmətin mövcudluğu',
    'Tətbiq və onlayn AI funksiyaları texniki xidmət, şəbəkə problemi və ya '
        'xarici xidmətin dayanması səbəbindən müvəqqəti əlçatmaz ola bilər. '
        'Tətbiq internet olmadan yerli materialları təqdim edə bilər, lakin '
        'bütün funksiyalar işləməyə bilər.',
  ),
  _DocumentSection(
    '7. Məsuliyyət və hüquqi məsələlər',
    'Tətbiqdən istifadə zamanı öz hesabınıza və ehtiyatla davranın; cihazınızı '
        'qoruyun və şəxsi məlumatları paylaşmayın. Bu şərtlər heç kimə '
        'avtomatik cərimə, zərərin ödənilməsi və ya həbs cəzası tətbiq etmir '
        'və belə nəticələr barədə etiraf və ya razılıq tələb etmir. Mümkün '
        'hüquqi mübahisələr yalnız tətbiq olunan qanunlara və səlahiyyətli '
        'orqanların qərarlarına uyğun həll olunur.',
  ),
  _DocumentSection(
    '8. Şərtlərin yenilənməsi',
    'Bu şərtlər tətbiqin xüsusiyyətləri və tətbiq olunan qaydalar dəyişdikdə '
        'yenilənə bilər. Yenilənmiş mətn tətbiqdə göstəriləcək. Bu sənəd ümumi '
        'məlumat xarakteri daşıyır; hüquqi məsləhət və ya hər hansı nəticəyə '
        'zəmanət deyil.',
  ),
];
