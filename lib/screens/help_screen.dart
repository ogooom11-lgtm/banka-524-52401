import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bank_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/common.dart';
import '../widgets/responsive.dart';

/// Klavye kısayolları (Windows / masaüstü).
class ShortcutInfo {
  final String keys;
  final String description;
  const ShortcutInfo(this.keys, this.description);
}

const List<ShortcutInfo> kShortcuts = [
  ShortcutInfo('Ctrl + K', 'Komut paletini aç (her yere hızlı erişim)'),
  ShortcutInfo('Ctrl + F', 'Kullanıcı listesinde aramaya odaklan'),
  ShortcutInfo('F1', 'Bu "Nasıl Çalışır?" sayfasını aç'),
  ShortcutInfo('F2', 'Maaş merkezine git'),
  ShortcutInfo('F5', 'Vadesi gelen maaşları hemen öde'),
  ShortcutInfo('Ctrl + Z', 'Son işlemi geri al'),
  ShortcutInfo('Ctrl + B', 'Yedekleme / veri yönetimi panelini aç'),
  ShortcutInfo('Ctrl + N', 'Yeni kullanıcı ekle'),
  ShortcutInfo('Ctrl + Shift + L', 'Tema (açık/koyu) değiştir'),
  ShortcutInfo('Esc', 'Açık olan pencereyi kapat'),
];

/// Uygulamanın nasıl çalıştığını anlatan detaylı rehber sayfası.
class HelpScreen extends StatefulWidget {
  final bool standalone;

  const HelpScreen({super.key, this.standalone = false});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final scheme = Theme.of(context).colorScheme;
    final preset = accentById(bank.accentId);

    final content = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(context, bank, preset),
              const SizedBox(height: 22),
              _searchRow(context),
              const SizedBox(height: 18),
              _quickStart(context, bank),
              const SizedBox(height: 22),
              _modules(context),
              const SizedBox(height: 22),
              _rules(context, bank),
              const SizedBox(height: 22),
              _customization(context),
              const SizedBox(height: 22),
              _shortcuts(context),
              const SizedBox(height: 22),
              _fileFormats(context),
              const SizedBox(height: 22),
              _faq(context),
              const SizedBox(height: 22),
              _footer(context, bank, scheme),
            ],
          ),
        ),
      ),
    );

    if (!widget.standalone) return content;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nasıl Çalışır?'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: content,
    );
  }

  Widget _searchRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SearchInput(
            controller: _search,
            hint: 'Rehberde ara: "prim", "ceza", "kredi", "yedek"...',
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        if (_query.isNotEmpty) ...[
          const SizedBox(width: 10),
          TextButton.icon(
            onPressed: () => setState(() {
              _search.clear();
              _query = '';
            }),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Temizle'),
          ),
        ],
      ],
    );
  }

  bool _match(String text) =>
      _query.isEmpty || text.toLowerCase().contains(_query);

  Widget _hero(BuildContext context, BankProvider bank, AccentPreset preset) {
    return FadeSlideIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              preset.gradient.first.withValues(alpha: 0.95),
              preset.gradient.last.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: preset.seed.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bank.logoEmoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bank.bankName} nasıl çalışır?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bu sayfa, uygulamanın tüm modüllerini ve işleyiş kurallarını adım adım anlatır.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _heroChip(Icons.verified_user_outlined,
                    'Sunucu gerekmez, veriler cihazda'),
                _heroChip(Icons.wifi_off_outlined, 'Tamamen çevrimdışı çalışır'),
                _heroChip(Icons.desktop_windows_outlined,
                    'Windows masaüstü için tasarlandı'),
                _heroChip(Icons.translate, 'Arayüz tamamen Türkçe'),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 26,
                runSpacing: 12,
                children: [
                  _heroStat('Şirket', '${bank.companies.length}'),
                  _heroStat('Kullanıcı', '${bank.users.length}'),
                  _heroStat('Aylık maaş yükü', bank.money(bank.totalMonthlySalaries, compact: true)),
                  _heroStat('İşlem kaydı', '${bank.transactions.length}'),
                  _heroStat('Aktif kredi', '${bank.activeLoanCount}'),
                  _heroStat('Sürüm', '2.0'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Demo hesaplar → Yönetici: admin@bank.com / admin123 • '
              'Çalışan: ahmet@techcorp.com / 123456',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _quickStart(BuildContext context, BankProvider bank) {
    final steps = <(String, String, IconData)>[
      (
        'Şirket oluşturun',
        'Şirketler sekmesinden "Yeni Şirket" ile şirket açın; maaş üst ve alt sınırını belirleyin. Başlangıç bakiyesi girerseniz banka bu tutarı şirkete kredi olarak yükler.',
        Icons.add_business_outlined
      ),
      (
        'Personel ekleyin',
        'Kullanıcılar sekmesinden tek tek ekleyebilir, TXT isim listesi veya CSV dosyası ile onlarca kişiyi saniyeler içinde yükleyebilirsiniz. Maaşlar şirket sınırına göre otomatik dağıtılır.',
        Icons.person_add_alt_1
      ),
      (
        'Kuralları ayarlayın',
        'Ayarlar sekmesinden maaş günü, vergi, prim varsayılanı, ceza sınırı, sözleşme süresi, transfer komisyonu ve kredi limitlerini kendinize göre düzenleyin.',
        Icons.tune
      ),
      (
        'Ödeme döngüsünü çalıştırın',
        'Maaş Merkezi\'nden vadesi gelen maaşları tek tıkla ödeyin. Otomatik maaş açıksa uygulama açılışında vadesi gelenler kendiliğinden ödenir.',
        Icons.payments_outlined
      ),
      (
        'İzleyin ve raporlayın',
        'Genel Bakış ve Raporlar sekmeleri; bakiye, nakit akışı, en yüksek maaşlar, sözleşme riskleri ve kredi durumunu grafiklerle gösterir.',
        Icons.insights_outlined
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: '5 adımda hızlı başlangıç',
          subtitle: 'Sıfırdan çalışan bir banka kurmak bu kadar basit.',
          icon: Icons.rocket_launch_outlined,
        ),
        StaggeredColumn(
          spacing: 12,
          children: [
            for (var i = 0; i < steps.length; i++)
              if (_match(steps[i].$1) ||
                  _match(steps[i].$2) ||
                  _query.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ]),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(steps[i].$3,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 7),
                                Text(
                                  steps[i].$1,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              steps[i].$2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.55),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _modules(BuildContext context) {
    final modules = <(String, String, IconData, String)>[
      (
        'Genel Bakış',
        'Banka özeti, toplam varlıklar, son hareketler ve tek tık hızlı işlemler.',
        Icons.dashboard_outlined,
        'Toplam şirket/kullanıcı bakiyesi, aylık maaş yükü, nakit akışı grafiği ve riskli sözleşmeler burada özetlenir.'
      ),
      (
        'Şirketler',
        'Şirket açma, bakiye yükleme/düşme, maaş sınırı ve ekip yönetimi.',
        Icons.business_outlined,
        'Her şirket kartında doluluk oranı, çalışan sayısı ve aylık maaş yükü görünür. Kartın üzerinden bakiye işlemi, toplu prim, maaş yeniden dağıtımı ve silme yapılabilir.'
      ),
      (
        'Kullanıcılar',
        'Personel ekleme/düzenleme, toplu işlemler ve detaylı kullanıcı profili.',
        Icons.people_outline,
        'Üç arama kutusu (ad, şirket, unvan), sıralanabilir liste, satır seçimiyle toplu prim/ceza/terfi/şirket değiştirme, TXT/CSV içe aktarma.'
      ),
      (
        'Maaş Merkezi',
        'Maaş ödemeleri, aylık primler, krediler ve taksit takibi.',
        Icons.payments_outlined,
        'Vadesi gelen maaşları toplu ödeyin, tanımlı aylık primleri dağıtın, kredi verin ve taksitleri tahsil edin.'
      ),
      (
        'İşlemler',
        'Tüm para hareketlerinin filtrelenebilir, dışa aktarılabilir geçmişi.',
        Icons.receipt_long_outlined,
        'Tür, tarih aralığı, tutar, şirket/kullanıcı ve serbest metin filtreleri; CSV dışa aktarma.'
      ),
      (
        'Raporlar',
        'Grafikler, en yüksek maaşlar, kategori dağılımı ve kredi performansı.',
        Icons.insights_outlined,
        '6 aylık gelir/gider serisi, işlem türü dağılımı, şirket karşılaştırması, sözleşme risk haritası.'
      ),
      (
        'Ayarlar',
        'Banka kimliği, para birimi, kurallar, görünüm, modüller ve veri yönetimi.',
        Icons.settings_outlined,
        'Tam özelleştirme burada: banka adı/sloganı, para birimi ve ondalık, maaş kuralları, vergi, ceza, transfer, kredi, tema/palet/yoğunluk, modül açma-kapama, yedekleme.'
      ),
      (
        'Nasıl Çalışır?',
        'Bu rehber sayfa: tüm özellikler, kurallar, kısayollar ve SSS.',
        Icons.help_outline,
        'Uygulamayı ilk kez kullananlar için adım adım anlatım ve sık sorulan sorular.'
      ),
    ];

    final filtered = modules
        .where((m) =>
            _query.isEmpty ||
            m.$1.toLowerCase().contains(_query) ||
            m.$2.toLowerCase().contains(_query) ||
            m.$4.toLowerCase().contains(_query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Modüller',
          subtitle: filtered.length == modules.length
              ? 'Uygulamadaki her sekme ne işe yarar?'
              : '${filtered.length} modül eşleşti',
          icon: Icons.widgets_outlined,
        ),
        WrapGrid(
          minItemWidth: 320,
          maxColumns: 3,
          children: [
            for (final m in filtered)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Icon(m.$3,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      m.$2,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      m.$4,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _rules(BuildContext context, BankProvider bank) {
    final s = bank.settings;
    final rules = <(String, String, IconData)>[
      (
        'Maaş ödemesi',
        'Her çalışanın bir "maaş günü" vardır. Bugün veya geçmişse maaş ödenebilir. '
            'Ödeme yapıldığında tutar şirket bakiyesinden düşülür, çalışan bakiyesine eklenir ve bir sonraki ayın aynı gününe otomatik ilerlenir. '
            'Şu anki ayar: her ayın ${s.salaryDay}. günü • otomatik ödeme ${s.autoPayroll ? 'açık' : 'kapalı'}.',
        Icons.event_available_outlined
      ),
      (
        'Vergi',
        s.taxEnabled
            ? 'Maaş brüt olarak şirketten çıkar; %${s.taxPercent.toStringAsFixed(0)} gelir vergisi kesilip banka kasasına aktarılır, çalışana net tutar geçer.'
            : 'Vergi kesintisi kapalı (Ayarlar > Maaş Kuralları). Açtığınızda maaştan belirlediğiniz oran kadar gelir vergisi kesilir.',
        Icons.percent
      ),
      (
        'Prim',
        'Tek kişiye prim, şirketteki herkese toplu prim veya her ay otomatik ödenecek "aylık prim" tanımlanabilir. '
            'Primler şirket bakiyesinden karşılanır; bakiye yetersizse işlem reddedilir.',
        Icons.card_giftcard
      ),
      (
        'Ceza',
        'Sabit tutar veya maaş yüzdesi olarak uygulanır (üst sınır %${s.penaltyMaxPercent.toStringAsFixed(0)}). '
            'Ceza tutarı çalışanın bakiyesinden düşülür ve şirket kasasına eklenir. '
            'Bakiye yetersizse ceza uygulanmaz.',
        Icons.gavel_outlined
      ),
      (
        'Terfi / zam',
        'Unvan ve maaş birlikte güncellenir; istenirse şirketten terfi primi ödenir. '
            'Yeni maaş şirketin maaş sınırını aşamaz. Toplu terfi ile bir ekibe aynı oranda zam yapılabilir.',
        Icons.trending_up
      ),
      (
        'Kredi / avans',
        'Çalışana maaşının en fazla ${s.loanMaxSalaryMultiplier.toStringAsFixed(0)} katı kadar (üst sınır ${bank.money(s.loanMaxAmount, compact: true)}) kredi verilir. '
            'Kredi taksitlere bölünür, faiz uygulanır (şu an %${s.loanInterestPercent.toStringAsFixed(1)}) ve taksitler çalışan bakiyesinden tahsil edilir.',
        Icons.request_quote_outlined
      ),
      (
        'Transfer',
        'Kullanıcılar birbirine para gönderebilir. Ayarlara göre minimum/maksimum tutar, komisyon (%${s.transferFeePercent.toStringAsFixed(1)}) ve '
            'şirketler arası transfer kısıtı uygulanır. Komisyon banka kasasına yazılır.',
        Icons.swap_horiz
      ),
      (
        'Sözleşme & fesih',
        'Sözleşmelerin başlangıç/bitiş tarihi ve erken fesih ücreti vardır. Şirket değiştirirken fesih ücreti çalışan bakiyesinden kesilir. '
            '${s.autoContractRenewal ? 'Süresi dolan sözleşmeler otomatik yenilenir.' : 'Süresi dolan sözleşmeler "riskli" olarak listelenir.'} '
            'Uyarı eşiği: ${s.contractAlertDays} gün.',
        Icons.description_outlined
      ),
      (
        'Rastgele kredi kesintisi',
        s.randomDeductionEnabled
            ? 'Simülasyon amaçlıdır: ${s.randomDeductionPercent ? 'maaşın yüzdesi olarak' : 'belirlenen tutar aralığında'} rastgele kesinti uygular. '
                'Aralık: ${s.randomDeductionMin.toStringAsFixed(0)} - ${s.randomDeductionMax.toStringAsFixed(0)}${s.randomDeductionPercent ? '%' : ''}. Kesinti çalışan bakiyesini aşamaz.'
            : 'Kapalı (Ayarlar > Prim & Ceza bölümünden açabilirsiniz).',
        Icons.casino_outlined
      ),
      (
        'Süper admin ayrıcalığı',
        'Banka sahibi her şeyi yapabilir: kullanıcı adı düzenleme, şifre değiştirme, bakiye belirleme, işlem geri alma, '
            'sistem günlüğünü görüntüleme ve tüm verileri yedekleme/geri yükleme.',
        Icons.workspace_premium_outlined
      ),
    ];

    final filtered = rules
        .where((r) =>
            _query.isEmpty ||
            r.$1.toLowerCase().contains(_query) ||
            r.$2.toLowerCase().contains(_query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'İşleyiş kuralları',
          subtitle: filtered.length == rules.length
              ? 'Para nasıl hareket eder, kurallar nasıl uygulanır?'
              : '${filtered.length} kural eşleşti',
          icon: Icons.rule_outlined,
        ),
        WrapGrid(
          minItemWidth: 380,
          maxColumns: 2,
          children: [
            for (final r in filtered)
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(r.$3,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      r.$2,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.6,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _customization(BuildContext context) {
    final items = <(String, List<String>)>[
      (
        'Kimlik',
        [
          'Banka adı, slogan, logo emojisi',
          'İletişim bilgileri (e-posta, telefon, web, adres)',
        ]
      ),
      (
        'Para',
        [
          'Para birimi sembolü ve konumu (başta/sonda)',
          'Ondalık basamak sayısı (0-4)',
        ]
      ),
      (
        'Maaş kuralları',
        [
          'Maaş günü, otomatik ödeme',
          'Dağıtım alt sınır oranı',
          'Vergi oranı ve açma/kapama',
        ]
      ),
      (
        'Görünüm',
        [
          'Açık / koyu / sistem teması',
          '8 vurgu rengi paleti',
          'Arayüz yoğunluğu (sıkı/normal/rahat)',
          'Animasyonları kapatma, gradyan arka plan',
        ]
      ),
      (
        'Modüller',
        [
          'Şirketler, kullanıcılar, maaş merkezi, işlemler',
          'Raporlar, krediler ve yardım sayfası aç/kapat',
        ]
      ),
      (
        'Veri',
        [
          'JSON yedek al / geri yükle / birleştir',
          'CSV dışa aktarma (kullanıcı, işlem, günlük)',
          'Geri alma (son 15 işlem) ve sistem günlüğü',
        ]
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Neleri özelleştirebilirsiniz?',
          subtitle: 'Neredeyse her şey. Ayarlar sekmesinden tek tıkla.',
          icon: Icons.tune,
        ),
        WrapGrid(
          minItemWidth: 280,
          maxColumns: 3,
          children: [
            for (final item in items)
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    for (final line in item.$2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                line,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _shortcuts(BuildContext context) {
    final filtered = kShortcuts
        .where((s) =>
            _query.isEmpty ||
            s.keys.toLowerCase().contains(_query) ||
            s.description.toLowerCase().contains(_query))
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Klavye kısayolları',
          subtitle: 'Windows\'ta hız için: fareye ihtiyaç duymadan yönetin.',
          icon: Icons.keyboard_outlined,
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              for (final s in filtered)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                          ),
                        ),
                        child: Text(
                          s.keys,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          s.description,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fileFormats(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Dosya formatları',
          subtitle: 'Toplu veri girişi ve yedekleme biçimleri.',
          icon: Icons.file_present_outlined,
        ),
        WrapGrid(
          minItemWidth: 300,
          maxColumns: 3,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TXT • İsim listesi',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Her satıra bir ad soyad yazın. Maaş, şirket sınırına göre otomatik dağıtılır; '
                    'sözleşme ve fesih ücreti ayarlardan uygulanır.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _codeBlock(context, 'Ayşe Yılmaz\nMehmet Demir\nZeynep Kaya'),
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CSV • Detaylı veri',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Başlık satırı otomatik algılanır. Boş maaşlar limit aralığında dağıtılır, '
                    'boş e-postalar üretilir. Excel için noktalı virgül (;) ayırıcı kullanılır.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _codeBlock(
                    context,
                    'Ad Soyad;E-posta;Unvan;Maaş;Şirket\n'
                    'Ayşe Yılmaz;ayse@firma.com;Analist;32000;TechCorp A.Ş.',
                  ),
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('JSON • Yedek',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Ayarlar > Veri Yönetimi bölümünden tek dosyada tüm şirket, kullanıcı, hareket, '
                    'kredi ve ayar verisi yedeklenir; başka bir bilgisayarda geri yüklenebilir.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  _codeBlock(context, 'arena-bank-yedek-20260101_1200.json'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeBlock(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _faq(BuildContext context) {
    final faqs = <(String, String)>[
      (
        'Veriler nerede saklanıyor?',
        'Tüm veriler uygulamanın çalıştığı bilgisayarda (yerel depolama) saklanır. Sunucu veya internet bağlantısı gerekmez. '
            'Bu nedenle düzenli olarak Ayarlar > Veri Yönetimi bölümünden JSON yedek almanız önerilir.'
      ),
      (
        'Çalışanlar da giriş yapabilir mi?',
        'Evet. Giriş ekranındaki "Çalışan" sekmesinden personel giriş yapıp kendi bakiyesini, maaş bordrosunu, '
            'sözleşmesini, kredilerini görür ve diğer kullanıcılara para transfer edebilir. '
            'Yönetici paneli ise yalnızca süper admin oturumunda açılır.'
      ),
      (
        'Maaşlar otomatik mi ödeniyor?',
        'Ayarlar > Maaş Kuralları > "Otomatik maaş ödemesi" açıksa uygulama açıldığında ve her dakika yapılan denetimde '
            'vadesi gelen maaşlar şirket bakiyesi yeterliyse kendiliğinden ödenir. Kapalıysa Maaş Merkezi\'nden toplu ödeyebilirsiniz.'
      ),
      (
        'Bir işlemi geri alabilir miyim?',
        'Kritik işlemlerden önce sistem otomatik olarak anlık görüntü alır (son 15 işlem). '
            'Ayarlar > Veri Yönetimi > "Geri Al" veya Ctrl + Z ile son işlemi geri alabilirsiniz.'
      ),
      (
        'Şirket maaş sınırı ne işe yarıyor?',
        'Bir çalışanın maaşı, bağlı olduğu şirketin üst sınırını aşamaz. Bu kural manuel ekleme, toplu içe aktarma, '
            'terfi ve şirket transferlerinde uygulanır; ayrıca dağıtım aralığının üst değeri olarak kullanılır.'
      ),
      (
        'Tema ve renkleri değiştirebilir miyim?',
        'Evet. Ayarlar > Görünüm bölümünde açık/koyu/sistem teması, 8 farklı vurgu paleti, '
            'arayüz yoğunluğu (sıkı/normal/rahat), animasyonlar ve gradyan arka plan ayarlanabilir.'
      ),
      (
        'Kaç kişiye kadar veri tutabilir?',
        'Yerel depolama kapasitesi çok yüksektir; yüzlerce kullanıcı ve on binlerce işlem kaydı sorunsuz çalışır. '
            'Listeler sanallaştırılmış (lazy) olarak çizilir, bu yüzden performans düşmez.'
      ),
      (
        'Windows kurulumu nasıl yapılır?',
        'Proje klasöründe "flutter create --platforms=windows ." komutuyla Windows çalıştırıcısı üretilir, '
            'ardından "flutter run -d windows" ile çalıştırılır veya "flutter build windows --release" ile .exe üretilir. '
            'Ayrıntılar README ve WINDOWS.md dosyalarında.'
      ),
      (
        'Para birimini değiştirirsem eski tutarlar bozulur mu?',
        'Hayır. Para birimi yalnızca gösterimi etkiler; tutarlar sayısal olarak saklanır. '
            'Sembolü, konumunu ve ondalık basamağı dilediğiniz zaman değiştirebilirsiniz.'
      ),
      (
        'Uygulamayı nasıl sıfırlarım?',
        'Ayarlar > Veri Yönetimi > "Demo Verisine Sıfırla" ile örnek veriler yüklenir, '
            '"Tüm Verileri Sil" ile yalnızca yönetici hesabı kalır.'
      ),
    ];

    final filtered = faqs
        .where((f) =>
            _query.isEmpty ||
            f.$1.toLowerCase().contains(_query) ||
            f.$2.toLowerCase().contains(_query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Sık sorulan sorular',
          subtitle: filtered.length == faqs.length
              ? 'Merak edilenler ve kısa yanıtları'
              : '${filtered.length} soru eşleşti',
          icon: Icons.quiz_outlined,
        ),
        WrapGrid(
          minItemWidth: 420,
          maxColumns: 2,
          children: [
            for (final f in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 0),
                child: ExpandableSection(
                  title: f.$1,
                  icon: Icons.help_outline,
                  child: Text(
                    f.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.6,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        ),
        if (filtered.isEmpty)
          const EmptyState(
            icon: Icons.search_off,
            title: 'Sonuç bulunamadı',
            message: 'Farklı bir kelimeyle aramayı deneyin.',
          ),
      ],
    );
  }

  Widget _footer(
      BuildContext context, BankProvider bank, ColorScheme scheme) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Text(bank.logoEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bank.bankName} • Dijital Banka ve Maaş Yönetim Simülasyonu',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  'Sürüm 2.0 • Flutter ile geliştirildi • Veriler yerel olarak saklanır • '
                  'Arayüz dili: Türkçe',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          PillBadge(
            label: scheme.brightness == Brightness.dark ? 'Koyu tema' : 'Açık tema',
            icon: Icons.palette_outlined,
          ),
        ],
      ),
    );
  }
}
