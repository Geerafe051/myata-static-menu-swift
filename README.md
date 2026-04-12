# Myata Static Menu Swift

Нативное macOS-приложение на SwiftUI для управления статическим меню заведения.

## Цель

Этот проект заменяет browser-based control panel и постепенно переносит всю логику в Swift:

- чтение данных из Google Sheets CSV
- локальная генерация `index.html`
- генерация `menu.json`
- генерация `yandex-menu.yml`
- публикация в Yandex Object Storage
- миграция изображений в собственный bucket

## Текущее состояние

Сейчас приложение уже умеет:

- хранить настройки источника данных
- хранить S3-конфигурацию локально
- скачивать `Settings`, `Categories`, `Items` из Google Sheets
- собирать локальные артефакты в `Application Support/MyataStaticMenuSwift/dist`
- публиковать собранные файлы в Yandex Object Storage
- переносить изображения блюд в `img/...` внутри bucket
- сохранять `image-migration.json`
- показывать лог операций и путь к итоговым файлам

## Что уже работает в UI

- `Refresh Menu` — build + publish
- `Build` — только локальная сборка
- `Publish` — загрузка файлов из `dist`
- `Migrate Images` — перенос всех `image_url` из таблицы в bucket

## Как открыть

1. Открой `Package.swift` в Xcode.
2. Выбери target `MyataStaticMenuSwift`.
3. Запусти приложение как обычный macOS app.

## Важное замечание

Сейчас `Access Key ID` и `Secret Access Key` хранятся локально в `Application Support` вместе с конфигом приложения. Следующим шагом их лучше перенести в macOS Keychain.

## Roadmap

1. Довести HTML-рендер до визуального паритета с web-версией
2. Перенести секреты из локального конфига в Keychain
3. Добавить предпросмотр собранного меню прямо в приложении
4. Упаковать конфиг и статус в более polished macOS UX
