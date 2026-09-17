# 🏦 Dijital Banka & Şirket Maaş Yönetim Simülasyonu

Tek bir banka sahibi (Süper Admin) tarafından yönetilen; şirketlerin çalışanlarına
otomatik maaş ödediği, prim/ceza/terfi/sözleşme kurallarının uygulandığı, tamamen
özelleştirilebilir bir Flutter uygulaması.

## 🚀 Çalıştırma

```bash
flutter pub get
flutter run          # tüm cihazlar
flutter run -d chrome  # web için
```

## 🔐 Demo Giriş Bilgileri

| Rol          | E-posta               | Şifre     |
|--------------|-----------------------|-----------|
| Süper Admin  | `admin@bank.com`      | `admin123`|
| Çalışan      | `ahmet@techcorp.com`  | `123456`  |

## ✨ Özellikler

### Süper Admin (Banka Sahibi)
- 👑 **Sınırsız yetki** — tüm sistem ayarlarını değiştirir
- 🏢 **Şirket yönetimi** — şirket oluşturma, kredi yükleme/düşme, silme
- 👥 **Kullanıcı yönetimi** — e-posta / şifre / unvan istemeden çalışan ekleme
- ✏️ **İsim düzenleme** — çalışan ve yönetici isimlerini doğrudan değiştirme
- 📄 **TXT ile toplu ekleme** — her satırdaki isim kullanıcı olur; maaş şirket sınırına göre dağıtılır, sözleşme 1–5 yıl, fesih cezası maaşın 2 veya 3 katıdır
- 🔎 **Kullanıcı arama** — ada, şirkete ve unvana göre arama kutuları
- 🎁 **Toplu prim** — şirketin tüm çalışanlarına aynı anda prim dağıtma
- 💰 **Maaş sistemi** — belirlenen günde otomatik/manuel ödeme
- 🎁 **Performans primi** — tek seferlik veya aylık prim
- ⚠️ **Ceza sistemi** — sabit tutar veya maaş yüzdesi üzerinden
- 📈 **Terfi sistemi** — unvan ve maaş artışı + terfi primi
- 🎲 **Rastgele kredi kesintisi** — ayarlanabilir min/max aralık
- 📝 **Sözleşme sistemi** — süreli sözleşme, fesih ücreti, şirket transferi
- 📊 **İşlem geçmişi** — tüm hareketler filtrelenebilir
- ⚙️ **Özelleştirilebilir ayarlar** — para birimi, banka adı, kesinti aralıkları

### Çalışan
- 💳 Bakiye görüntüleme
- 📜 Kendi işlem geçmişi
- 💸 Diğer kullanıcılara para transferi
- 📅 Sözleşme ve maaş bilgileri

## 🏗️ Mimari

```
lib/
├── main.dart                    # Giriş noktası
├── models/                      # Veri modelleri
│   ├── app_user.dart
│   ├── company.dart
│   ├── transaction.dart
│   └── bank_settings.dart
├── services/
│   └── storage_service.dart     # SharedPreferences kalıcılık
├── providers/
│   └── bank_provider.dart       # Tüm iş mantığı (Provider)
├── widgets/
│   └── common.dart              # Ortak bileşenler
└── screens/
    ├── login_screen.dart
    ├── super_admin_dashboard.dart
    ├── employee_dashboard.dart
    └── tabs/
        ├── overview_tab.dart
        ├── companies_tab.dart
        ├── users_tab.dart
        ├── transactions_tab.dart
        └── settings_tab.dart
```

**Durum yönetimi:** Provider  
**Kalıcı depolama:** SharedPreferences (JSON)  
**Tasarım:** Material 3, karanlık tema, responsive (mobil + tablet + web)

## 📝 Notlar

- Tüm veriler cihazda yerel olarak saklanır.
- İlk açılışta örnek bir şirket ve çalışan otomatik oluşturulur.
- Ayarlar sekmesinden "Tüm Verileri Sıfırla" ile demo verilerine dönebilirsiniz.
