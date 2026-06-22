# MenuMind App Icons

## Структура
```
android/app/src/main/res/
  mipmap-mdpi/        ic_launcher.png (48x48)
                      ic_launcher_round.png (48x48)
  mipmap-hdpi/        ic_launcher.png (72x72)
                      ic_launcher_round.png (72x72)
  mipmap-xhdpi/       ic_launcher.png (96x96)
                      ic_launcher_round.png (96x96)
  mipmap-xxhdpi/      ic_launcher.png (144x144)
                      ic_launcher_round.png (144x144)
  mipmap-xxxhdpi/     ic_launcher.png (192x192)
                      ic_launcher_round.png (192x192)

store/
  play_store_icon_512.png   → Google Play Store listing

source/
  icon_1024.png             → исходник высокого разрешения
  icon_1024.svg             → векторный исходник
```

## Установка
Распакуй архив в корень `mobile/` проекта:
```powershell
Expand-Archive -Path menumind-icons.zip -DestinationPath . -Force
```

Файлы автоматически лягут в правильные папки `android/app/src/main/res/mipmap-*`.

## Google Play
Загрузи `store/play_store_icon_512.png` в консоль Google Play →
Store listing → App icon.
