# Static Menu Publisher

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
- хранить несекретную S3-конфигурацию локально
- сохранять `Access Key ID` и `Secret Access Key` в macOS Keychain
- скачивать `Settings`, `Categories`, `Items` из Google Sheets
- собирать локальные артефакты в `Application Support/MyataStaticMenuSwift/dist`
- публиковать собранные файлы в Yandex Object Storage
- переносить изображения блюд в `img/...` внутри bucket
- сохранять `image-migration.json`
- показывать лог операций и путь к итоговым файлам

## Что уже работает в UI

- `Refresh Menu` — build + publish
- `Build` — только локальная сборка
- `Publish` — загрузка файлов из `dist`, а если их ещё нет, приложение сначала выполнит `Build`
- `Migrate Images` — перенос всех `image_url` из таблицы в bucket

## Как открыть

1. Открой `MyataStaticMenuSwift.xcodeproj` в Xcode.
2. Выбери схему `MyataStaticMenuSwift`.
3. Запусти приложение как обычный macOS app.

Для быстрой проверки из терминала по-прежнему можно использовать:

```bash
swift build
xcodebuild -project MyataStaticMenuSwift.xcodeproj -scheme MyataStaticMenuSwift -configuration Debug -derivedDataPath .xcode-derived build
```

## Release `.app`

Чтобы получить готовый bundle, который можно переложить в `Applications`, используй:

```bash
./scripts/build-release-app.sh
```

Схема версионирования:

- `MARKETING_VERSION` (`major.minor`) меняется вручную в проекте, когда это нужно.
- `CURRENT_PROJECT_VERSION` (`build`) увеличивается автоматически при каждом успешном запуске `build-release-app.sh`.
- локальный счётчик сборки хранится в `Config/build-number.txt` и не коммитится в git.

После сборки готовое приложение появится здесь:

```bash
release/Static Menu Publisher.app
```

## Важное замечание

Файл конфигурации хранит только несекретные настройки. S3-ключи сохраняются в macOS Keychain.

## Roadmap

1. Довести HTML-рендер до визуального паритета с web-версией
2. Добавить предпросмотр собранного меню прямо в приложении
3. Подготовить экспортируемый `.app` и более polished macOS UX
4. При необходимости добавить тесты на парсинг CSV, YML и S3-публикацию
