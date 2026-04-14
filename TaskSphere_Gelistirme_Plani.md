# TaskSphere - Asamali Gelistirme Plani (macOS SwiftUI Menu Bosya adim adim uygulama gelistirme kontrol merkezidir.
- Her asama basinda bulunan checkbox, asama tamamlaninca `[x]` olarak isaretlenmelidir.
- Bir asama tamaar syon, gecisler, bos dApp)

## Calisma Promptu (Bu dosya icin kural)
- Bu dmlanmadan bir sonraki asamanin implementasyonuna gecilmez.
- Her asama tamamlandiginda:
  1. "Neler bitti?" notu eklenir.
  2. Sonraki asama icin mini plan (3-6 madde) guncellenir.
  3. Gerekli test/validasyon sonucu kisa not olarak yazilir.
- Bu dosya hem plan hem de ilerleme kaydi olarak kullanilir.

---

## Proje Vizyonu
TaskSphere, macOS icin sadece menu bar uzerinden calisan, modern ve hizli bir yapilacaklar uygulamasidir. Dock ikonu olmadan calisir, gorevleri SwiftData ile saklar, iCloud ile senkronize eder ve akilli ozellikler (clipboard, dogal dil ayrisma, pomodoro odak modu) sunar.

## Teknoloji ve Mimari Kararlari (Sabit)
- Dil: Swift (en guncel stabil surum)
- UI: SwiftUI (macOS Sonoma/Sequoia estetik hedefi)
- Veri Katmani: SwiftData
- Senkronizasyon: CloudKit (SwiftData ile)
- Uygulama Modu: `MenuBarExtra` only, Dock iconu yok

---

## Asama 1 - Proje Iskeleti ve Temel MenuBarExtra
- [x] **A1: Baslangic proje yapisini kur**

### Hedef
TaskSphere uygulamasinin sadece menu barda calisan temel iskeletini hazirlamak.

### Yapilacaklar
- Yeni macOS SwiftUI app olustur (TaskSphere).
- App yasam dongusunu `MenuBarExtra` merkezli kurgula.
- Dock ikonunu devre disi birakacak ayari ekle.
- Bos bir ana popover/pencere iskeleti olustur.
- Basit bir app state katmani olustur (`AppState`, `TaskStore` taslagi).

### Tamamlanma Kriterleri
- Uygulama acildiginda sadece menu barda gorunmeli.
- Dock'ta app ikonu gorunmemeli.
- Menu bar ikonuna tiklaninca bos bir popover acilmali.

### Test/Validasyon
- Manuel: App launch davranisi ve Dock gorunurlugu.
- Manuel: Menu bar tiklandiginda popover acilmasi.

### Asama Sonu Notlari
- Neler bitti: SwiftUI + MenuBarExtra tabanli `todo` uygulama iskeleti kuruldu, Dock iconu gizlendi (LSUIElement), temel `AppState`/store akisi olusturuldu.
- Sonraki Asama Mini Plani:
  - Gorev modeli ve SwiftData semasi
  - Ana liste UI ve checkbox tamamlama akisi
  - Pending sayisini hesaplayacak state baglantisi

---

## Asama 2 - Veri Modeli + Ana Liste + Dinamik Ikon
- [x] **A2: Gorev yonetimi ve menu bar dinamik sayacini ekle**

### Hedef
Gorevlerin eklenmesi/guncellenmesi ve menu bardaki daire icinde canli pending sayisinin gosterimi.

### Yapilacaklar
- SwiftData `TaskItem` modelini tanimla:
  - `id`, `title`, `createdAt`, `isCompleted`, `completedAt`, `dueDate?`, `sourceType?`
- `TaskStore` icinde CRUD operasyonlarini olustur.
- Ana popover icerisine:
  - Gorev giris alani
  - `List` veya `LazyVStack` ile gorev listesi
  - Her satirda hizli tamamlama checkbox'i
- Menu bar ikonunu ozel view yap:
  - Daire gorunumu
  - Iceride `pendingTasks.count`
  - Canli guncelleme

### Tamamlanma Kriterleri
- Gorev eklenebilmeli/silinebilmeli/tamamlanabilmeli.
- Menu bardaki sayi anlik olarak degismeli.

### Test/Validasyon
- 10+ gorev ile performans ve canli sayac testi.
- App restart sonrasi verinin korunmasi.

### Asama Sonu Notlari
- Neler bitti: SwiftData `TaskItem` modeli eklendi, ana listede gorev ekleme/tamamlama/silme calisir hale getirildi, menu bar daire ikonu bekleyen gorev sayisini canli gosteriyor.
- Sonraki Asama Mini Plani:
  - Tamamlananlar ayrik penceresi
  - Sol ust "Tamamlananlar" butonu
  - Ekranlar arasi veri tutarliligi

---

## Asama 3 - Tamamlananlar Secondary Window
- [x] **A3: Tamamlanan gorevler icin ayri pencere**

### Hedef
Ana listeden ayrik bir "Tamamlananlar" penceresi ile gecmis gorevleri yonetmek.

### Yapilacaklar
- Ana popover sol ustte "Tamamlananlar" butonunu ekle.
- Buton aksiyonunda secondary window ac.
- Bu pencerede sadece tamamlanmis gorevleri listele.
- Gerekirse geri alma (uncomplete) ve kalici silme aksiyonlari ekle.

### Tamamlanma Kriterleri
- Buton tiklandiginda ayri pencere acilmali.
- Tamamlanan gorevler burada tutarli bicimde gorunmeli.

### Test/Validasyon
- Ana liste ve tamamlananlar penceresi arasinda state senkronu.
- Coklu pencere acik senaryoda veri tutarliligi.

### Asama Sonu Notlari
- Neler bitti: "Tamamlananlar" butonu ile acilan ayri pencere eklendi; tamamlanmis gorevler listeleniyor, geri alma ve kalici silme aksiyonlari mevcut.
- Sonraki Asama Mini Plani:
  - Drag & drop overlay
  - Dis kaynaktan metin/link alma
  - Otomatik goreve donusturme

---

## Asama 4 - Drag & Drop ile Hizli Gorev Ekleme
- [x] **A4: Dis veriyi surukle-birak ile goreve cevir**

### Hedef
Tarayici linki, PDF metni vb. suruklenen icerikleri "Buraya Birak" overlay ile goreve donusturmek.

### Yapilacaklar
- Menu bar popover ve uygun ise ikon bolgesine drop hedefi ekle.
- Drag girisinde "Buraya Birak" overlay goster.
- Kabul edilen veri tipleri: plain text, URL.
- Parse ve normalize ederek yeni gorev kaydi ac.
- Kaynagi `sourceType` alaninda sakla.

### Tamamlanma Kriterleri
- Dis kaynaktan birakilan metin/link otomatik gorev olusturur.
- Overlay davranisi net ve stabil calisir.

### Test/Validasyon
- Safari/Chrome'dan link birakma testi.
- PDF veya text editorden metin birakma testi.

### Asama Sonu Notlari
- Neler bitti: Popover icine text/URL drag&drop destegi ve "Buraya Birak" overlay davranisi eklendi; birakilan icerik otomatik goreve donusturuluyor.
- Sonraki Asama Mini Plani:
  - Clipboard monitor servisi
  - Floating toast/banner UI
  - 5sn timeout + kaydet aksiyonu

---

## Asama 5 - Clipboard Monitor + Floating Toast
- [x] **A5: Panoyu izleyip hizli kaydet bildirimi sun**

### Hedef
Kopyalanan metni algilayip menu bar ikonunun altinda gecici bir toast/banner ile kaydetme imkani vermek.

### Yapilacaklar
- `NSPasteboard` degisim takibi icin monitor servisi kur.
- Kopyalanan metni ozetleyen toast/banner tasarla.
- "Kaydet" butonu ile metni goreve cevir.
- Bildirimi 5 saniye sonra otomatik kapat.
- Ardisik kopyalamalarda kuyruk veya son-icerik politikasini belirle.

### Tamamlanma Kriterleri
- Metin kopyalaninca bildirim gorunmeli.
- Kaydet ile gorev olusmali; kaydetmezse 5 sn sonra kaybolmali.

### Test/Validasyon
- Hizli ard arda kopyalama stres testi.
- Farkli metin uzunluklarinda ozetleme gorunumu.

### Asama Sonu Notlari
- Neler bitti: `NSPasteboard` tabanli pano izleme servisi eklendi; kopyalanan metin icin 5 saniyelik "Kaydet" toast'i ile hizli gorev olusturma aktif.
- Sonraki Asama Mini Plani:
  - Settings window olusturma
  - AppStorage/UserDefaults persistency
  - Tema ve daire stilleri

---

## Asama 6 - Settings Window ve Ozellestirme
- [x] **A6: Gelismis ayarlar ekranini tamamla**

### Hedef
Disli ikonundan acilan ayarlar penceresinde stil, davranis ve kalicilik seceneklerini sunmak.

### Yapilacaklar
- Sag ust disli ikon + Settings window akisi kur.
- Tum ayarlari `AppStorage`/`UserDefaults` ile kalici hale getir.
- Menu bar daire stili:
  - Hazir taslaklar: Modern Neon, Classic Mono, Pastel Soft
  - Ozel secim: arka plan rengi, yazi rengi, border kalinligi
- Ekstra ayarlar:
  - Launch at Login
  - Hotkeys (hizli gorev ekleme)
  - Auto-Archive (24 saat sonra tamamlananlari gizle)

### Tamamlanma Kriterleri
- Ayarlar degistiginde UI aninda guncellenmeli.
- App restart sonrasi ayarlar korunmali.

### Test/Validasyon
- Her preset ve custom secim icin gorunur dogrulama.
- Launch at Login ve Auto-Archive davranis testi.

### Asama Sonu Notlari
- Neler bitti: Sag ust disli ikonu ile acilan ayri Ayarlar penceresi eklendi; stil presetleri (Modern Neon, Classic Mono, Pastel Soft) ve custom HEX/border ayarlari kalici hale getirildi. Launch at Login, hotkey notu ve Auto-Archive (24 saat) ayarlari UserDefaults ile saklanip uygulama akisina baglandi.
- Sonraki Asama Mini Plani:
  - Dogal dil parser
  - Tarih/saatten reminder uretimi
  - AI yardimli gorev ayristirma fallback'leri

---

## Asama 7 - Pro Ozellik 1: Natural Language Parsing
- [x] **A7: Dogal dilden tarih/saat ayrisma + hatirlatici**

### Hedef
Kullanici metninden tarih/saat bilgisini ayiklayip uygun hatirlatici planlamak.

### Yapilacaklar
- Gorev giris akisina NLP parse katmani ekle.
- Ornek: "Yarin saat 14:00'te toplanti yap" -> `title` + `dueDate`.
- Belirsiz tarih/saatlerde fallback akisi (onay isteme veya sadece metin kaydi).
- macOS bildirim/hatirlatici mekanizmasi ile entegrasyon.

### Tamamlanma Kriterleri
- Acik tarih/saat iceren cumlelerden dueDate dogru cikmali.
- Hatirlatici zamaninda tetiklenmeli.

### Test/Validasyon
- Turkce farkli tarih/saat kaliplariyla test.
- Saat dilimi/locale degisimi testi.

### Asama Sonu Notlari
- Neler bitti: Gorev giris akisine Turkce dogal dil parser'i eklendi (`bugun/yarin + saat HH:mm` kaliplari); parse basariliysa `dueDate` atanip lokal macOS bildirimi planlaniyor. Belirsiz saat ifadelerinde fallback olarak gorev normal kaydedilip kullaniciya kisa uyari gosteriliyor.
- Sonraki Asama Mini Plani:
  - Focus mode gorev secimi
  - Menu bar ikonunu pomodoro sayacina cevirme
  - Timer state ve durdur/devam ettir

---

## Asama 8 - Pro Ozellik 2: Focus Mode + Pomodoro
- [x] **A8: Secili gorev icin pomodoro odak modunu aktif et**

### Hedef
Bir gorev focus moduna alindiginda menu bar dairesini geri sayim sayacina donusturmek.

### Yapilacaklar
- Gorev satirina "Focus" aksiyonu ekle.
- Focus aktifken menu bar dairede kalan sure goster.
- Pomodoro sureleri ayarlanabilir olsun (or. 25/5).
- Sure bitince bildirim ve durum gecisi.

### Tamamlanma Kriterleri
- Focus baslat/durdur/devam ettir calisir.
- Daire gorunumu gorev sayaci <-> timer arasinda dogru gecis yapar.

### Test/Validasyon
- Arka planda calisma ve uyku/uyanma durumlari.
- Birden fazla gorevde focus secim kisitlari.

### Asama Sonu Notlari
- Neler bitti: Gorev satirlarina Focus aksiyonu eklendi; secili gorev icin odak modunda pomodoro geri sayimi baslatiliyor. Menu bar daire ikonu odak aktifken kalan sureyi gosteriyor, ana ekranda duraklat/devam/bitir kontrolleri calisiyor ve odak/mola gecislerinde bildirim tetikleniyor. Pomodoro sureleri (or. 25/5) ayarlar ekranindan kalici olarak degistirilebiliyor.
- Sonraki Asama Mini Plani:
  - SwiftData + CloudKit schema uyumu
  - Senkron catismasi politikasi
  - Cihazlar arasi dogrulama

---

## Asama 9 - Pro Ozellik 3: iCloud Sync (SwiftData + CloudKit) (şu anda yapma, daha sonra yapabiliriz)
- [ ] **A9: Cihazlar arasi senkronizasyonu devreye al**

### Hedef
Task verilerini tum Apple cihazlari arasinda CloudKit ile senkronize etmek.

### Yapilacaklar
- SwiftData container'i CloudKit destekli konfige et.
- Model uyumlulugunu ve migration stratejisini netlestir.
- Offline/online gecislerinde veri butunlugu politikasi yaz.
- Catismalar icin "son guncelleme kazanir" vb. kural belirle.

### Tamamlanma Kriterleri
- En az iki cihaz/simulator arasinda gorev senkronu calisir.
- Tamamlanma durumu ve metadata kayipsiz tasinir.

### Test/Validasyon
- Cevrimdisi degisiklik -> yeniden baglanma senaryosu.
- Ayni gorevde esit-zamanli degisiklik catismasi.

### Asama Sonu Notlari
- Neler bitti: _(doldurulacak)_
- Sonraki Asama Mini Plani:
  - UI polish ve vibrancy
  - Performans optimizasyonu
  - Son kalite guvence

---

## Asama 10 - UI Polish, Performans, QA ve Release Hazirlik (şu anda yapma, daha sonra yapabiliriz)
- [ ] **A10: Uretim kalitesine getir ve paketle**

### Hedef
Uygulamayi estetik, performansli ve dagitima hazir hale getirmek.

### Yapilacaklar
- Sonoma/Sequoia uyumlu vibrancy ve modern gorunumu sonlandir.
- Animaurumlar ve hata durumlarini iyilestir.
- Baslangic suresi, liste performansi, memory kullanimini optimize et.
- Kritik akislara otomasyon testleri ekle.
- Release checklist ve versiyonlama notlarini hazirla.

### Tamamlanma Kriterleri
- Uygulama stabil ve akici calisir.
- Temel akislarda kritik bug kalmaz.
- Release checklist tamamlanir.

### Test/Validasyon
- Fonksiyonel regresyon testi.
- Kullanici senaryosu bazli uc uca dogrulama.

### Asama Sonu Notlari
- Neler bitti: _(doldurulacak)_
- Kapanis Mini Plani:
  - README ve kullanim rehberi
  - Bilinen limitler
  - Sonraki surum backlog'u

---

## Genel Backlog (Opsiyonel Sonraki Surumler)
- Siri/Shortcuts entegrasyonu
- Takvim entegrasyonu
- Gorev etiketleme ve filtreleme
- Haftalik analiz paneli
