# 4jave

VPN/прокси-клиент на Flutter с ядром Mihomo (Clash Meta). Windows + Android.

## Сборка без установки Flutter
1. Создайте репозиторий на GitHub и загрузите туда содержимое этой папки.
2. Вкладка Actions → build → Run workflow.
3. Через несколько минут в Artifacts будут `4jave-windows` (папка с 4jave.exe и core/mihomo.exe) и `4jave-android` (APK).

## Локальная сборка
    flutter create --platforms=windows,android --org com.fourjave --project-name fourjave .
    flutter pub get
    flutter run -d windows
Положите `mihomo.exe` (https://github.com/MetaCubeX/mihomo/releases) в `core/` рядом с `4jave.exe`.

## Что готово
- Подписки Clash/Mihomo по ссылке, обновление, удаление
- Запуск/остановка ядра, выбор сервера, пинг, скорость в реальном времени
- Режимы Правила / Глобально / Напрямую, системный прокси, TUN (от администратора)

## Что ещё не сделано
- Android: нужен VpnService и сборка ядра под Android (см. libclash в FlClash)
- Трей, автозапуск, горячие клавиши, helper-сервис для TUN без админа, логи, редактор конфига, автообновление
- Импорт vless/vmess/ss ссылок и base64-подписок
