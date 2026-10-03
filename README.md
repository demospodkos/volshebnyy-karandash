# Волшебный карандаш ✏️✨

Мультисенсорное творческое приложение для детей 3–7 лет.

**Рисование + музыка в реальном времени + AI-превращение каракулей.**

## Стек

- Flutter
- Real-time canvas + particles
- SoundService (цвет → нота)
- AiService (готово к TFLite)
- MagicOverlay (красивая анимация результата)
- GitHub Actions → автоматическая сборка APK

## Запуск

```bash
flutter pub get
flutter run
```

## Структура

```
lib/
  main.dart
  screens/
    home_screen.dart
    drawing_screen.dart
    story_level_screen.dart
  services/
    sound_service.dart
    ai_service.dart
  widgets/
    particle_system.dart
    magic_overlay.dart
assets/
  sounds/          ← положи сюда .wav сэмплы
```

## Звуки

Положи в `assets/sounds/`:
- xylo_c5.wav … xylo_a5.wav
- magic_sparkle.wav
- success.wav

## APK

После push в `main` автоматически запускается workflow **Build APK**.  
Скачать можно во вкладке Actions → Artifacts.

## Статус

- [x] Холст + цвета + частицы
- [x] Звуковой сервис
- [x] Сюжетный уровень «Помоги гусенице»
- [x] AI-вызов + красивый результат
- [x] Автосборка APK
- [ ] Реальные .wav сэмплы (добавь вручную)
- [ ] Настоящая TFLite-модель (структура готова)

---

Сделано с ❤️ для маленьких творцов.
