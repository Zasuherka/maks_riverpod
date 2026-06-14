# Задания для закрепления Riverpod

---

## Задача 1 — «Избранное»

**Прокачивает:** `keepAlive` Notifier + `family` провайдер + сброс стейта при logout

Добавить функционал избранных товаров:
- `favoritesProvider` — `keepAlive` Notifier со списком id избранных
- `isFavoriteProvider(productId)` — family провайдер, возвращает `bool`
- Иконка ❤️ на карточке товара, которая тогглит избранное
- При logout — список избранного сбрасывается (через `ref.watch(authProvider)` в `build()`)

---

## Задача 2 — «Поиск товаров»

**Прокачивает:** комбинирование провайдеров + `autoDispose` + вычисляемый провайдер

Добавить поиск на главном экране:
- `searchQueryProvider` — `autoDispose` Notifier со строкой поиска (по умолчанию `''`)
- `searchedProductsProvider` — вычисляемый провайдер, который берёт `filteredProductsProvider` и дополнительно фильтрует по строке поиска
- `TextField` на главном экране, который пишет в `searchQueryProvider`

---

## Задача 3 — «Уведомление при добавлении в корзину»

**Прокачивает:** `ref.listen` — единственная концепция из теории, которую ещё не трогал в коде

Показывать `SnackBar` когда товар добавляется или удаляется из корзины:
- В `home_screen.dart` добавить `ref.listen` на `cartItemCountProvider`
- Когда `next > previous` — показать `SnackBar` с текстом «Товар добавлен в корзину»
- Когда `next < previous` — «Товар удалён из корзины»
