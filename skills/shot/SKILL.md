---
name: shot
description: "Use when taking or working with screenshots on this machine — capturing the screen, a region, or one of two monitors, finding the last shot, opening the shots folder, or copying an image to the clipboard. Wraps the already-installed grim and slurp into one command with previews and timestamp stamping. Read this BEFORE calling grim, slurp or wl-copy directly."
license: MIT
metadata:
  opencode/slash: "true"
---

# Снимки экрана

На машине уже стоят `grim` и `slurp` — но голый `grim` требует самому
придумывать имя файла, каталога `~/Pictures/Screenshots` не было, и
превью с подписью не делал. Обвязка лежит в `~/.local/bin/shot`.

**Держись `shot`, а не прямых вызовов grim.** Прямой `grim -o файл` не
сделает превью, не подпишет время и не положит в буфер.

## Команды

| | |
|---|---|
| `shot s` | весь экран |
| `shot r` | область — выделяешь мышью |
| `shot d` | список мониторов |
| `shot d DP-2` | один монитор по порту |
| `shot d Xiaomi` | один монитор по имени |
| `shot t 5` | снимок с таймером, по умолчанию 3 с |
| `shot p` | снимок в буфер обмена |
| `shot last` | путь последнего снимка |
| `shot open` | открыть папку |

Работает как `/shot` в TUI — навык объявлен через `opencode/slash`.

## Куда складывается

```
~/Pictures/Screenshots/<год>/<дата_время>-<вид>[-<монитор>].png
                                   ..._small.png   ← превью 400px
```

Каталог создан с правами 700. Мониторы в имя файла попадают специально:
без этого два снимка разных мониторов в одну секунду затёрли бы друг
друга.

## Мониторы

```
Iiyama North America PLE483 0555861200194 (DP-2)   1280x1024 @ 3440,0
Xiaomi Corporation Mi Monitor 0000000000000 (HDMI-A-1)  3440x1440 @ 0,0
```

`shot d DP-2` снимает левый, `shot d HDMI-A-1` — правый широкий.

У `grim` нет ни `-l`, ни `-d`, а список выходов знает только niri.
Скрипт берёт геометрию из `niri msg outputs` и снимает через `grim -g`.
**Не придумывай `grim -d` — такого флага нет**, будет `invalid option`.

## Что не работает: shot w

Снимок отдельного окна на niri 26.04 не поддерживается:

```
compositor doesn't support the screen capture protocol
```

`grim -T` опирается на расширение `ext-image-capture`, которого в этой
версии нет. Это не поломка скрипта — обойти нельзя, только `shot s`,
`shot r` или `shot d`.

Заодно: niri блокирует `screen-capture` для KeePassXC (в `config.kdl`
правило `block-out-from "screen-capture"`). Даже если бы `-T` работал,
окно с паролями в снимок не попало бы. Так и задумано.

## Разбор вывода niri

`niri msg focused-window` печатает `Window ID 7: (focused)` — **JSON-режима
у этой версии нет**. id вытаскивается так:

```bash
niri msg focused-window | sed -n 's/^Window ID \([0-9]\+\).*/\1/p'
```

## Правила

- Перед ручным вызовом `grim` — прочитать этот файл.
- `wl-copy` в скриптеRedirect'ит вывод в `/dev/null`: он остаётся жить,
  удерживая буфер, и унаследовал бы наш stdout. Из-за этого первый
  вариант скрипта подвисал при вызове из цикла.
- `wl-copy` в скрипте перенаправляет вывод в `/dev/null`: он остаётся
  жить, удерживая буфер, и унаследовал бы наш stdout. Из-за этого первый
  вариант скрипта подвисал при вызове из цикла.
- Тайм-аут на снимок — не ждать дольше 30 с, реально он занимает 1–2 с.
- Снимки содержат то, что на экране. Пароли, токены, личное — в
  `~/Pictures/Screenshots/` не отправлять и в архив класть без
  проверки, см. навык `context-guard-check`.