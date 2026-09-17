# 🏦 Dijital Banka & Şirket Maaş Yönetimi (v2)

Tek bir banka sahibi (**Süper Admin**) tarafından yönetilen; şirketlerin çalışanlarına
otomatik maaş ödediği, prim/ceza/terfi/sözleşme/kredi kurallarının uygulandığı,
**tamamen çevrimdışı** çalışan ve **her yönüyle özelleştirilebilen** Flutter uygulaması.

> Sürüm 2.0 — arayüz tamamen yenilendi: masaüstü (Windows) odaklı yerleşim, animasyonlar,
> komut paleti, sistem günlüğü, bildirim merkezi, kredi modülü, raporlar ve
> uygulama içi **"Nasıl Çalışır?"** rehberi eklendi.

---

## 🚀 Çalıştırma

```bash
flutter pub get

# Windows (masaüstü) — önerilen
flutter create --platforms=windows .
flutter run -d windows

# Diğer hedefler
flutter run -d chrome     # web
flutter run               # bağlı cihaz/emülatör
```

> Depoda platform klasörleri yer almaz. `flutter create --platforms=windows .`
> komutu yalnızca `windows/` klasörünü üretir, `lib/` içeriğine dokunmaz.

### Klavye Kısayolları (masaüstü)

| Kısayol | İşlev |
|---|---|
| `Ctrl + K` | Komut paleti (işlem, kullanıcı, şirket, sayfa arama) |
| `Ctrl + F` | Kullanıcı aramasına odaklan |
| `F1` | Nasıl Çalışır? sayfası |
| `F2` | Maaş Merkezi |
| `F5` | Vadesi gelen maaşları öde |
| `Ctrl + Z` | Son işlemi geri al |
| `Ctrl + B` | Yedekleme / veri yönetimi |
| `Ctrl + N` | Yeni kullanıcı |
| `Ctrl + Shift + L` | Tema değiştir |
| `Esc` | Açık diyaloğu kapat |

---

## 🔐 Demo Giriş Bilgileri

| Rol | E-posta | Şifre |
|---|---|---|
| Süper Admin (banka sahibi) | `admin@bank.com` | `admin123` |
| Şirket Yöneticisi | `yonetici@techcorp.com` | `123456` |
| Çalışan | `ahmet@techcorp.com` | `123456` |

Giriş ekranındaki **Yönetici / Personel** anahtarı ve demo kartları ile hızlıca
deneyebilirsiniz. Süper admin girişi yalnızca yönetici paneline erişir.

---

## ✨ Özellikler

### 👑 Süper Admin (Banka Sahibi)

**Genel Bakış**
- Karşılama, canlı sistem durumu, 6 aylık nakit akışı grafiği, işlem türü dağılımı
- 30 günlük giriş/çıkış kartları ve trend göstergeleri
- Hızlı işlemler: maaş öde, prim dağıt, rastgele kesinti, yeni kullanıcı/şirket, içe aktar
- Son hareketler ve riskli sözleşme uyarıları

**Şirketler**
- Şirket oluşturma/düzenleme (isim, sektör, vergi no, adres, iletişim, renk, maaş sınırları)
- Bakiye yükleme/çekme, şirkete özel prim dağıtımı, şirketten çalışana ödeme
- Maaş dağıtımını yeniden dengeleme, limit kullanım göstergesi
- Tehlikeli bölge: şirketi ve bağlı kayıtları silme

**Kullanıcılar**
- Ada/şirkete/unvana göre arama, rol–şirket–durum filtreleri, 6 sıralama seçeneği
- Tam düzenleme: kimlik, iletişim, IBAN, departman, notlar, maaş, prim, sözleşme, avatar rengi
- Maaş öde, prim, ceza (% veya sabit, ayarlanan üst sınırla), terfi/zam, sözleşme yenileme,
  şirket değiştirme (fesih ücretli), kredi verme, şifre değiştirme, işten çıkarma
- Çoklu seçim ve **toplu işlemler**: aktif/pasif, taşı, prim, ceza, terfi, silme
- **TXT/CSV ile toplu ekleme** ve kullanıcı kartı (özet / işlemler / krediler)
- İsim düzenleme: satır içi veya karttan tek tıkla

**Maaş Merkezi**
- Vadesi gelen maaşları ödeme, aylık primleri dağıtma, rastgele kesinti uygulama
- Maaş listesi, aylık prim tanımlama, kredi taksitlerini tahsil etme
- Şirket bakiyesi yetmezse ödeme atlanır ve kullanıcı bilgilendirilir

**İşlemler**
- Tür, akış (gelen/giden), şirket, kullanıcı, tarih aralığı, tutar aralığı ve metin filtreleri
- Hızlı tarih aralıkları (bugün, bu hafta, bu ay, son 30 gün, bu yıl)
- Özet kartları, işlem detayı, CSV dışa aktarma, sayfalama

**Raporlar**
- 30 / 90 / 180 / 365 günlük dönem seçimi
- Nakit akışı, giriş-çıkış, işlem türü dağılımı, şirket karşılaştırma tablosu
- En yüksek maaşlı çalışanlar, kredi portföyü, sözleşme risk haritası, dönem dışa aktarma

**Nasıl Çalışır?**
- 5 adımlık hızlı başlangıç, modül tanıtımları, maaş/prim/ceza/terfi/kredi/transfer/sözleşme
  kurallarının işleyişi, özelleştirme kontrol listesi, dosya formatı örnekleri, SSS

**Ayarlar**
- Banka kimliği: ad, slogan, logo emojisi, e-posta, telefon, web sitesi, adres
- Para birimi: sembol, ondalık basamak, sembolün konumu
- Maaş: maaş günü (1–28), otomatik ödeme, gelir vergisi (%), dağıtım alt sınır oranı
- Prim & ceza: varsayılan prim, ceza üst sınırı, rastgele kesinti aralığı (tutar veya %)
- Sözleşme: varsayılan süre, uyarı eşiği, fesih katsayısı, otomatik yenileme
- Transfer: aktiflik, şirketler arası izin, komisyon, min/maks tutar, açıklama zorunluluğu
- Kredi: limit, maaş kat sayısı, taksit sayısı, faiz
- Görünüm: sistem/açık/koyu tema, 8 vurgu rengi, 3 yoğunluk (sıkı/normal/geniş),
  animasyon anahtarı, gradyan arka plan
- Modüller: kullanılmayan bölümleri gizleme
- Veri: bildirimler, yedekleme hatırlatıcısı, günlük kayıt limiti, JSON yedek al/geri yükle,
  CSV dışa aktarma, şablon indirme, tüm verileri sıfırlama
- Tüm ayarlar **anında kaydedilir**

### 🧑💼 Personel Portalı

- Kişisel bakiye kartı (animasyonlu sayaç), aylık maaş/prim/net ücret ve kalan kredi kartları
- Son 6 ay gelir-gider grafiği, sözleşme durumu halkası
- Para transferi: alıcı arama, komisyon ve limit bilgisi, hızlı tutar çipleri, onaylı gönderim
- İşlemlerim: arama, gelen/giden filtresi, toplamlar, sayfalama
- Kredilerim: kalan borç, taksit ödeme, tamamlanan krediyi kaldırma
- Profil: iletişim ve sözleşme bilgileri, net ücret hesaplaması, isim düzenleme
- Görünüm tercihleri ve uygulama içi bildirimler
- Kendi içeriğiyle **Nasıl Çalışır?** rehberi

### 🧩 Genel

- 💾 **Çevrimdışı**: tüm veriler `SharedPreferences` içinde JSON olarak saklanır
- ↩️ **Geri al**: son 15 işlem adım adım geri alınabilir
- 📜 **Sistem günlüğü**: seviye, aktör, tarih ve detay ile denetim kaydı
- 🔔 **Bildirim merkezi**: maaş, prim, ceza, sözleşme ve risk bildirimleri
- 🎞️ **Animasyonlar**: sekme geçişleri, kademeli giriş, hover yükselmesi, sayaç efektleri
- 🖱️ **Masaüstü dostu**: fare tekerleği/drag ile kaydırma, hover ve tıklama durumları,
  geniş ekranda kenar çubuğu, dar ekranda otomatik sarmalama, tam klavye desteği
- 🇹🇷 **Tamamı Türkçe**: tüm etiketler, mesajlar ve `tr_TR` tarih/para biçimlendirmesi

---

## 📥 Veri Alışverişi

- **TXT**: her satıra bir ad soyad → kullanıcı oluşturulur (satır atlama, yinelenen ve boş
  satırlar bildirilir)
- **CSV**: `ad,email,unvan,maas,prim,telefon,iban` (ayırıcı `;`, `,` veya sekme otomatik algılanır)
- **JSON**: tam yedek (kullanıcılar, şirketler, işlemler, krediler, ayarlar, günlük, bildirimler)
- **Şablon**: ayarlardan CSV şablonunu indirip doldurabilirsiniz

---

## 🏗️ Mimari

```
lib/
├── main.dart                          # Uygulama kabuğu, tema, AuthGate, açılış ekranı
├── models/
│   ├── app_user.dart                  # Kullanıcı + sözleşme/sözleşme günleri
│   ├── company.dart                   # Şirket + limitler
│   ├── transaction.dart               # Txn (15 tür), TxnType, etki hesaplama
│   ├── bank_settings.dart             # Tüm özelleştirme alanları
│   ├── loan.dart                      # Kredi kaydı
│   ├── audit_log.dart                 # Sistem günlüğü kaydı
│   └── app_notification.dart          # Uygulama içi bildirim
├── services/
│   ├── storage_service.dart           # SharedPreferences kalıcılığı
│   └── export_service.dart            # CSV/TXT/JSON kodlama + dosya seçici
├── providers/
│   └── bank_provider.dart             # Tüm iş mantığı, geri al, günlük, zamanlayıcı
├── theme/
│   └── app_theme.dart                 # Vurgu renkleri, yoğunluk, Material 3 teması
├── utils/
│   └── formatters.dart                # tr_TR para/tarih/sayı biçimleri
├── widgets/
│   ├── common.dart                    # AppCard, StatCard, TxnListTile, bildirim/diyalog…
│   ├── animated_widgets.dart           # FadeSlideIn, HoverLift, PulseDot, gradyan zemin…
│   ├── charts.dart                    # Gruplu sütun, halka, sparkline, ilerleme halkası
│   ├── responsive.dart                # Kırılım noktaları, WrapGrid, AdaptiveRow
│   └── app_dialogs.dart               # Ortak diyalog iskeleti ve form alanları
└── screens/
    ├── login_screen.dart              # Yönetici/personel girişi
    ├── super_admin_dashboard.dart     # Kenar çubuğu + komut paleti + kısayollar
    ├── employee_dashboard.dart         # Personel portalı
    ├── help_screen.dart               # "Nasıl Çalışır?" sayfası
    ├── dialogs/                       # Kullanıcı, şirket, içe/dışa aktarma diyalogları
    └── tabs/                          # overview, companies, users, payroll,
                                       # transactions, reports, help, settings
```

**Durum yönetimi:** Provider · **Depolama:** SharedPreferences (JSON, çevrimdışı) ·
**Tasarım:** Material 3, açık/koyu tema, 8 vurgu rengi, Windows masaüstü odaklı yerleşim

---

## 📝 Notlar

- Tüm veriler yalnızca bu bilgisayarda saklanır; düzenli olarak **Yedek al**'ın.
- İlk açılışta örnek veri (3 şirket, 17 kullanıcı, 6 aylık hareket, 2 kredi) otomatik yüklenir.
- Ayarlar → Veri Yönetimi → **Tüm Verileri Sıfırla** ile demo verisine dönebilirsiniz.
- Uygulama içi **Nasıl Çalışır?** sayfası tüm kuralları örneklerle anlatır.
