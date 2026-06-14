# CI/CD — Теория

## Что такое CI/CD?

CI/CD — это набор практик автоматизации разработки, которые позволяют быстро и надёжно доставлять код от разработчика до конечного пользователя.

Расшифровка:
- **CI** — Continuous Integration (Непрерывная интеграция)
- **CD** — Continuous Delivery (Непрерывная доставка) или Continuous Deployment (Непрерывное развёртывание)

---

## CI — Continuous Integration

### Идея
Каждый раз, когда разработчик пушит код или создаёт Pull Request, автоматически запускается серия проверок. Это позволяет поймать баги и проблемы до того, как код попадёт в основную ветку.

### Что делает CI:
- Запускает статический анализ кода
- Запускает тесты (unit, widget, integration)
- Проверяет форматирование
- Проверяет, что проект вообще собирается

### Зачем это нужно:
- Ошибки ловятся сразу, а не через неделю
- Код в main-ветке всегда рабочий
- Нет человеческого фактора — всё автоматически
- Команда может работать параллельно без страха сломать друг другу код

---

## CD — Continuous Delivery / Deployment

### Continuous Delivery
После успешного прохождения CI — автоматически собирается артефакт (APK, IPA, билд сайта) и он готов к деплою. Но деплой запускается вручную (нажатием кнопки).

### Continuous Deployment
Полная автоматизация: после успешного CI код автоматически уезжает в прод без участия человека.

### Что делает CD для Flutter:
- Сборка APK / App Bundle для Android
- Сборка IPA для iOS
- Публикация в Google Play (внутреннее тестирование / прод)
- Публикация в App Store / TestFlight
- Раздача билдов тестерам через Firebase App Distribution

---

## Пайплайн (Pipeline)

Пайплайн — это последовательность шагов, которые выполняются автоматически.

Типичный пайплайн для Flutter:

```
Push / PR
    │
    ▼
[Checkout code]          ← скачать код из репозитория
    │
    ▼
[Setup Flutter]          ← установить нужную версию Flutter
    │
    ▼
[flutter pub get]        ← установить зависимости
    │
    ▼
[dart format --check]    ← проверить форматирование
    │
    ▼
[flutter analyze]        ← статический анализ
    │
    ▼
[flutter test]           ← запустить тесты
    │
    ▼
[flutter build apk]      ← собрать APK (только для CD)
    │
    ▼
[Deploy / Upload]        ← загрузить билд (только для CD)
```

Если любой шаг упал — пайплайн останавливается и разработчик получает уведомление.

---

## GitHub Actions

GitHub Actions — самый популярный инструмент CI/CD для проектов на GitHub.

### Как это работает:
1. В репозитории создаётся папка `.github/workflows/`
2. В ней создаются файлы `.yml` — описание пайплайна
3. GitHub автоматически запускает их по триггерам (push, pull_request и т.д.)

### Ключевые понятия:

**Workflow** — весь пайплайн целиком, описывается в одном `.yml` файле.

**Job** — группа шагов, которые выполняются на одной машине (runner).
Джобы могут запускаться параллельно или последовательно.

**Step** — один конкретный шаг внутри джобы. Это либо shell-команда, либо готовый Action.

**Action** — готовый переиспользуемый блок. Например:
- `actions/checkout@v4` — скачать код репозитория
- `subosito/flutter-action@v2` — установить Flutter

**Runner** — виртуальная машина, на которой выполняется джоб.
Доступные: `ubuntu-latest`, `macos-latest`, `windows-latest`.

### Триггеры (когда запускается workflow):
```yaml
on:
  push:               # при пуше в любую ветку
    branches: [main]  # или только в конкретную
  pull_request:       # при создании/обновлении PR
    branches: [main]
  workflow_dispatch:  # запуск вручную из интерфейса GitHub
  schedule:           # по расписанию (cron)
    - cron: '0 9 * * 1'  # каждый понедельник в 9:00
```

---

## Структура `.yml` файла

```yaml
name: CI                          # название workflow

on:                               # триггеры
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:                             # джобы
  test:                           # название джоба
    runs-on: ubuntu-latest        # на какой машине запускать

    steps:                        # шаги
      - name: Checkout            # название шага
        uses: actions/checkout@v4 # готовый Action

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.9'  # версия Flutter
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get       # shell-команда

      - name: Analyze
        run: flutter analyze

      - name: Test
        run: flutter test
```

---

## Ветки и стратегия CI/CD

### Типичная стратегия:

**main / master** — основная ветка, код здесь всегда рабочий.
CI запускается при каждом PR. CD запускается при мерже в main.

**develop** — ветка для разработки.
CI запускается при пуше, но CD не запускается.

**feature/*** — ветки для конкретных фич.
CI запускается при создании PR в develop/main.

### Защита main-ветки:
В настройках GitHub можно включить Branch Protection:
- Запретить прямой пуш в main
- Требовать прохождения CI перед мержем PR
- Требовать ревью от другого разработчика

---

## Секреты (Secrets)

Для деплоя нужны чувствительные данные: API ключи, пароли, сертификаты.
Хранить их в коде нельзя — они хранятся в Secrets репозитория.

```yaml
# Добавляются в GitHub: Settings → Secrets → Actions
# Используются в workflow так:
- name: Deploy
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
    STORE_PASSWORD: ${{ secrets.STORE_PASSWORD }}
  run: ./deploy.sh
```

---

## Артефакты (Artifacts)

Артефакты — это файлы, которые создаются в процессе пайплайна (APK, отчёты тестов) и которые можно скачать из интерфейса GitHub.

```yaml
- name: Upload APK
  uses: actions/upload-artifact@v4
  with:
    name: app-debug
    path: build/app/outputs/flutter-apk/app-debug.apk
    retention-days: 7  # хранить 7 дней
```

---

## Кэширование

Кэширование ускоряет пайплайн — не нужно каждый раз скачивать все зависимости заново.

```yaml
- name: Cache pub dependencies
  uses: actions/cache@v4
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
    restore-keys: |
      ${{ runner.os }}-pub-
```

---

## Матрица (Matrix)

Позволяет запустить одни и те же шаги с разными параметрами одновременно.
Например, протестировать приложение на нескольких версиях Flutter:

```yaml
jobs:
  test:
    strategy:
      matrix:
        flutter-version: ['3.24.0', '3.32.0', '3.38.9']
    runs-on: ubuntu-latest
    steps:
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ matrix.flutter-version }}
```

---

## Инструменты для CD Flutter

| Инструмент | Что делает |
|------------|-----------|
| **Fastlane** | Автоматизация сборки и публикации в сторы |
| **Firebase App Distribution** | Раздача тестовых билдов команде |
| **Google Play API** | Публикация в Google Play программно |
| **App Store Connect API** | Публикация в App Store программно |
| **Codemagic** | CI/CD специально для Flutter (есть free-tier) |

---

## Цена GitHub Actions

| Тип репозитория | Минуты в месяц | Стоимость сверх |
|-----------------|----------------|-----------------|
| Публичный | Неограниченно | Бесплатно |
| Приватный (Free план) | 2 000 мин | $0.008/мин (Linux) |
| Приватный (Pro план) | 3 000 мин | $0.008/мин (Linux) |

Для учебного проекта бесплатного лимита более чем достаточно.

---

## Итог

CI/CD — это не сложно, это просто автоматизация того, что разработчик и так делает руками:

```
Без CI/CD:               С CI/CD:
Пишешь код               Пишешь код
Запускаешь тесты         Пушишь
Анализируешь код         Всё остальное — автоматически
Собираешь APK
Загружаешь вручную
```

Один раз настроил — дальше работает само.
