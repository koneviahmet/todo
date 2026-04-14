# Todo Uygulamasi - Proje Analizi ve Gelisim Onerileri

## 1) Mevcut Proje Ozeti

Bu proje, macOS uzerinde menu bar merkezli calisan bir gorev yonetim uygulamasi. Uygulama SwiftUI + SwiftData mimarisi ile kurulmus, coklu pencere yapisi kullaniliyor ve ana akislar verimli calismayi hedefliyor:

- Hizli gorev ekleme ve tamamlama
- Kategori bazli duzen
- Alt gorev ve not yonetimi
- Dogal dil ile tarih/saat parse
- Hatirlatici planlama
- Focus mode / pomodoro
- Clipboard ve drag&drop ile hizli yakalama

## 2) Mevcut Ozellik Envanteri

### 2.1 Ana Gorev Yonetimi
- Gorev ekleme, tamamlanma durumu degistirme, silme
- Arama ile gorev bulma
- Menu bar ikonunda bekleyen gorev sayaci

### 2.2 Tamamlananlar Akisi
- Ayrik pencere uzerinden tamamlanan gorevleri listeleme
- Geri alma (uncomplete) ve toplu/kalici silme senaryolari

### 2.3 Kategori Sistemi
- Kategori ekleme, yeniden adlandirma, silme
- Kategori silerken fallback kategoriye tasima
- Kategoriyi menu sayacina dahil etme secenegi

### 2.4 Alt Gorev ve Not Deneyimi
- Gorev altina alt gorev ekleme ve tamamlama
- Alt gorevlerde arama ve secili tamamlilari temizleme
- Alt gorev icin rich text not duzenleme ve autosave

### 2.5 Uretkenlik Ozellikleri
- Dogal dil parser (or: "yarin saat 14:00")
- Due date bazli lokal bildirim planlama
- Focus mode ve pomodoro dongusu (calisma + mola)

### 2.6 Hizli Veri Yakalama
- Drag&drop ile text/URL birakip goreve donusturme
- Clipboard monitor ile "kaydet" hizli paneli
- URL metadata cekip baslik zenginlestirme

### 2.7 Ayarlar ve Kisisellestirme
- Ikon stilleri/presetler ve ozel renk ayarlari
- Launch at login
- Auto-archive ayari
- Pomodoro sure ayarlari

## 3) Teknik Mimari Degerlendirmesi

### 3.1 Guclu Yonler
- SwiftUI + SwiftData ile modern ve bakimi kolay temel
- MenuBarExtra odakli net urun kimligi
- Ozelliklerin kullanici degeri yuksek (hizli yakalama, focus, NLP)
- Pencere bazli ayrisimla gorev akislarinin ayristirilmasi

### 3.2 Iyilestirme Gerektiren Alanlar
- Is kurallari view katmanina daginik; service/store katmani artirilabilir
- Test kapsami sinirli; unit + entegrasyon + UI test stratejisi gerekli
- Dokumantasyon parcali; tek bir "urun + teknik rehber" eksik
- CloudKit senkron politikasi (catisma/merge) net dokumante degil

## 4) Kullanim Pratikleri (Urunu Daha Verimli Kullanmak Icin)

### 4.1 Gunluk Akis Onersi (10-15 dk setup)
1. Sabah ilk acilista gorevleri kategoriye gore gozden gecir.
2. Kritik 1-2 gorevi Focus moduna aday olarak sec.
3. Notlardan veya tarayicidan gelen isi drag&drop ile aninda ekle.
4. Gun icinde kopyalanan is parcaciklarini clipboard panelinden kaydet.
5. Aksam "Tamamlananlar" penceresinde hizli temizlik yap.

### 4.2 Gorev Yazim Standardi
- Basliklar kisa ve eylem odakli olsun (or: "Musteri teklifini guncelle")
- Tarih/saat gerektirenlerde dogal dil kullan (or: "yarin saat 10:30")
- Buyuk gorevleri alt gorevlere bol (3-7 adim ideal)

### 4.3 Focus/Pomodoro Pratigi
- Tek seansta tek gorev: context switching azaltir
- 25/5 ile basla, sonra 50/10 secenegini test et
- Her pomodoro sonunda alt gorev notunu 1 cumle ile guncelle

### 4.4 Kategori Hijyeni
- 5-7 aktif kategori sinirini gecme
- "Inbox" ve "Someday" gibi tampon kategoriler kullan
- Kullanimdan dusen kategorileri birlestir veya kaldir

## 5) Yeni Eklenebilecek Ozellikler (Onceliklendirilmis Backlog)

## P0 - Yuksek Etki / Kisa Orta Efor

### 5.1 Recurring Tasks (Tekrarlayan Gorevler)
**Neden:** Gunluk/haftalik rutinleri manuel tekrar acma ihtiyacini bitirir.  
**Kapsam:**
- Gunluk, haftalik, aylik tekrar kurali
- Tamamlaninca bir sonraki ornegi otomatik olusturma
- "Skip this instance" destegi

### 5.2 Smart Inbox + Parse Onayi
**Neden:** NLP ve clipboard akisinda yanlis parse riskini azaltir.  
**Kapsam:**
- "Algilanan tarih/saat" onay satiri
- Tek tikla duzelt (tarih/saat kaldir, sadece metin kaydet)
- Son 10 yakalanan icerik icin geri alma

### 5.3 Quick Capture Global Shortcut
**Neden:** Menu acmadan gorev ekleme hizini artirir.  
**Kapsam:**
- Global hotkey ile mini input paneli
- NLP parse + kategori secim kisayolu
- Son kullanilan kategoriye hizli kayit

## P1 - Yuksek Etki / Orta Efor

### 5.4 Advanced Filtering and Saved Views
**Neden:** Gorev sayisi arttikca tarama maliyeti buyur.  
**Kapsam:**
- "Bugun", "Bu hafta", "Geciken", "Kategori+Durum" filtreleri
- Kaydedilmis gorunumler (or: "Work Deep Focus")

### 5.5 Habit Layer (Opsiyonel Mod)
**Neden:** Uygulamanin gunluk kullanim frekansini arttirir.  
**Kapsam:**
- Basit aliskanlik kaydi (done/not done)
- Zincir (streak) gostergesi
- Gorevden bagimsiz hafif bir modul

### 5.6 Calendar Surface (Iceride gorunum)
**Neden:** Due date odakli planlama daha gorunur olur.  
**Kapsam:**
- Haftalik timeline paneli
- Drag ile due date degistirme
- Takvim sync olmadan baslangic (yalin gorunum)

## P2 - Stratejik / Orta Yuksek Efor

### 5.7 Team-Ready Export/Share
**Neden:** Bireysel kullanimdan ekip ile paylasima gecis.  
**Kapsam:**
- Markdown/CSV export
- Haftalik rapor ozeti
- Secili listeyi paylasilabilir metne cevirme

### 5.8 Insights Dashboard
**Neden:** Kullanim davranisindan iyilestirme cikarma.  
**Kapsam:**
- Haftalik tamamlanan gorev trendi
- Kategori bazli dagilim
- Focus oturum verim ozetleri

## 6) Teknik Gelistirme Onerileri

### 6.1 Architecture Refinement
- View icindeki is kurallarini `TaskService`/`TaskRepository` katmanina tasima
- Tekrarlayan save/validation bloklarini merkezilestirme
- Pencere acma/router akislarini daha net ayristirma

### 6.2 Test Stratejisi
- Unit test: parser, reminder schedule, recurring logic
- Integration test: SwiftData CRUD + kategori tasima + alt gorev iliskileri
- UI smoke test: ana ekleme/tamamlama/focus baslatma

### 6.3 Veri ve Senkronizasyon
- CloudKit catisma cozumu kurali yazili hale getirilmeli
- Migration stratejisi (yeni alan ekleme/silme) dokumante edilmeli
- Offline degisikliklerde merge davranisi netlestirilmeli

### 6.4 Performans ve Stabilite
- Buyuk listelerde query/sort maliyeti olcumu
- Clipboard monitor ve timer akislarinda enerji tuketimi gozlemi
- Multi-window state guncellemelerinde race-condition taramasi

## 7) UX/UI Iyilestirme Fikri

- Empty-state metinleri daha yonlendirici olabilir
- Yeni kullanici icin 60 saniyelik onboarding (3 adim)
- Kisa komut yardimi (NLP ornekleri) input alanina ipucu olarak eklenebilir
- Tamamlananlar ekraninda "restore all (today)" gibi hizli aksiyonlar eklenebilir

## 8) Guvenlik ve Gizlilik Notlari

- Clipboard izleme acikca ayarlarda bilgilendirilmeli (toggle + aciklama)
- URL metadata cekmede network davranisi dokumante edilmeli
- Lokal bildirim izin durumlari net fallback ile ele alinmali

## 9) 30-60-90 Gunluk Uygulanabilir Yol Haritasi

### Ilk 30 Gun
- Recurring tasks temel modeli
- Global quick capture paneli
- NLP parse onay satiri

### 31-60 Gun
- Gelismis filtreleme + kaydedilmis gorunumler
- Test altyapisinin temelini kurma
- Dokumantasyonun README + architecture bolumleriyle birlestirilmesi

### 61-90 Gun
- Habit layer MVP
- Dashboard MVP
- CloudKit davranis dokumani + temel entegrasyon testleri

## 10) Basari Metrikleri (Olcmeden Iyilestirme Zor)

- Gunluk aktif kullanim (DAU benzeri)
- Gorev ekleme -> tamamlama donusum orani
- Focus oturumu tamamlama orani
- Haftalik yakalanan gorevlerin kaynak dagilimi (manual/clipboard/dragdrop)
- Ortalama gorev yasam suresi (eklemeden tamamlanmaya)

## 11) Sonuc

Proje halihazirda guclu bir temel ve yuksek pratik deger sunuyor. En hizli deger uretecek adimlar:

1. Recurring tasks
2. Quick capture + parse onayi
3. Gelismis filtreleme
4. Test ve dokumantasyon sertlestirmesi

Bu 4 adim birlikte ele alindiginda, uygulama hem gunluk kullanimda daha hizli olur hem de uzun vadede daha kolay surdurulebilir hale gelir.
