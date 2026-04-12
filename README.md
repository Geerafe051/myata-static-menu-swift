# Myata Static Menu Swift

Нативное macOS-приложение на SwiftUI для управления статическим меню заведения.

## Цель

Этот проект заменяет browser-based control panel и постепенно переносит всю логику в Swift:

- чтение данных из Google Sheets CSV
- локальная генерация `index.html`
- генерация `menu.json`
- генерация `yandex-menu.yml`
- позже: публикация в Yandex Object Storage
- позже: миграция изображений в собственный bucket

## Текущее состояние

Сейчас приложение уже умеет:

- хранить настройки источника данных
- скачивать `Settings`, `Categories`, `Items` из Google Sheets
- собирать локальные артефакты в `Application Support/MyataStaticMenuSwift/dist`
- показывать лог операций и путь к итоговым файлам

## Как открыть

1. Открой `Package.swift` в Xcode.
2. Выбери target `MyataStaticMenuSwift`.
3. Запусти приложение как обычный macOS app.

## Roadmap

1. Довести HTML-рендер до визуального паритета с web-версией
2. Добавить native S3 publish на Swift
3. Добавить native image migration
4. Упаковать конфиг и статус в более polished macOS UX
