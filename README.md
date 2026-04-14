# todo (Swift macOS)

`todo`, macOS icin SwiftUI + SwiftData ile gelistirilmis bir menu bar gorev yonetim uygulamasidir.

## Gereksinimler

- macOS 14 veya uzeri
- Xcode Command Line Tools (`xcode-select --install`)
- Swift 5.10+

## Kurulum ve Calistirma

Proje kok dizininde:

```bash
chmod +x build.sh
./build.sh
```

`build.sh` scripti su islemleri otomatik yapar:

1. Release modda `swift build` calistirir.
2. `~/Applications/todo.app` icinde `.app` bundle olusturur.
3. Uygulamayi ad-hoc olarak imzalar (`codesign --sign -`).
4. Acik eski instance varsa kapatir ve yeni uygulamayi baslatir.

## Manuel Build (Opsiyonel)

```bash
swift build
swift run
```

## Proje Yapisi

- `Package.swift`: Swift Package tanimi
- `Sources/todo`: Uygulama kaynak kodu
- `build.sh`: macOS `.app` paketleme ve baslatma scripti

## Not

Bu uygulama yapay zeka yardimiyla olusturulmustur. Ihtiyaciniza gore istediginiz gibi kullanabilir, degistirebilir ve gelistirebilirsiniz.
