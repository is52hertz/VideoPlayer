<!--
README.md — written to be both human-friendly on GitHub and learning-friendly
for AI assistants opening the repo. The HTML below renders on github.com.
-->

<p align="right">
  <a href="README.md">English</a> ·
  <a href="README-zh_cn.md">简体中文</a> ·
  <a href="README-zh_tw.md">繁體中文</a> ·
  <a href="README-ja.md">日本語</a> ·
  <a href="README-ko.md">한국어</a> ·
  <b>Русский</b>
</p>

> **Создано с помощью ИИ, под руководством человека.**
> Этот проект разрабатывается от начала до конца с помощью **Claude Code · Kiro CLI · Gemini CLI · Cursor · Antigravity CLI**.
> ИИ занимается реализацией; разработчик выступает в роли **креативного директора и QA**.
> `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` и папки навыков `.claude/` `.gemini/` `.kiro/` закоммичены **специально** — это обучающий проект. Читайте их, форкайте, присылайте PR. Здесь всё предназначено для изучения.

<br />

<p align="center">
  <img src="Icon/Video Player Exports/Video Player-iOS-Default-512x512@1x.png" alt="Video Player icon" width="180" />
</p>

<h1 align="center">Video Player</h1>

<p align="center">
  Нативный, local-first видеоплеер для <b>macOS · iOS · iPadOS</b>,<br/>
  построенный на SwiftUI &amp; AVFoundation в эстетике Liquid&nbsp;Glass.
</p>

<p align="center">
  <img alt="platform" src="https://img.shields.io/badge/platform-iOS%2026%20%7C%20iPadOS%2026%20%7C%20macOS%2026-007AFF?style=flat-square" />
  <img alt="swift" src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img alt="ui" src="https://img.shields.io/badge/UI-SwiftUI-1B7CD5?style=flat-square" />
  <img alt="license" src="https://img.shields.io/badge/license-GPL--3.0-success?style=flat-square" />
</p>

---

## 🎯 Философия проекта

| | |
|---|---|
| **Только нативное** | Никаких Electron, React Native, Flutter или WebView. SwiftUI + AVFoundation. |
| **Local-first** | Никаких аккаунтов, облачной синхронизации или онлайн-скрейпинга. Ваши файлы остаются вашими. |
| **Liquid Glass** | Материалы iOS 26 / iPadOS 26 / macOS 26 — текучая прозрачность, органичное размытие, соответствие HIG. |
| **Workflow на базе ИИ** | Реализация — ИИ, ревью кода — люди. Смотрите `AGENTS.md`. |

---

## ✨ Возможности

- 🎬 **Нативный движок воспроизведения** — `AVPlayer` за чистым протоколом `PlayerEngine`.
- 🪟 **Liquid Glass UI** — `.glassEffect` / `.glassEffectTransition(.materialize)` на iOS 26+.
- 👆 **Touch-first элементы управления iOS** — автоскрывающаяся панель, жест перемотки, glass-пилюли.
- 🔊 **Мост системной громкости** — синхронизация через KVO + `MPVolumeView`, кастомное воссоздание хаптики.
- 🖥️ **Нативная оболочка macOS** — меню окон и жизненный цикл (на iPad — эквивалент iPadOS).
- 🔒 **Ноль телеметрии** — ничего не покидает устройство. Никогда.

### 🚧 Дорожная карта

Полный план — в [`TODO.md`](TODO.md). Главное:

- 🐛 Пилюля громкости не синхронизируется при изменении громкости аппаратными клавишами на переднем плане.
- 📱 Обход Dynamic Island для верхних пилюль в портретном режиме.
- 🎛️ Система жестов: долгое нажатие половины экрана для скорости, двойной тап для перемотки, вертикальные жесты для яркости / громкости.
- ⚡ Speed-пилюля (0.5× / 1× / 2× / 3×) с состоянием выбора в стиле Liquid-Glass.
- 🎞️ Инфо-панель — нижний оверлей в стиле Apple TV с миниатюрой и метаданными.
- 📺 Поддержка PIP и AirPlay.
- 🌀 Физика прогресс-бара и rubber-band обратная связь.

---

## 🏗 Архитектура

```
View  ──▶  ViewModel (@Observable)  ──▶  PlayerEngine  ──▶  AVPlayer
                                   │
                                   └▶  Services
                                       ├─ SystemVolumeManager
                                       └─ AudioSessionManager
```

Строгий MVVM. View никогда не обращаются напрямую к `AVPlayer`, persistence или сервисам. Единственное санкционированное исключение — состояние жестов, чувствительное к производительности (см. `AGENTS.md` § Architecture).

---

## 🤖 С ИИ-ассистентами

Этот репозиторий — рабочий пример **AI-native разработки**. Всё, что нужно ассистенту, чтобы быть продуктивным с первого дня, закоммичено:

| Файл / Папка | Назначение |
|---|---|
| `AGENTS.md` | **Источник истины** — правила, принципы, дисциплина scope, workflow. |
| `CLAUDE.md` / `GEMINI.md` | Точки входа для каждого инструмента (в основном зеркала `AGENTS.md`). |
| `.claude/skills/`  | Специфичные для проекта навыки Claude Code (`glass-know`, `hig-doctor`). |
| `.gemini/skills/`  | Эквиваленты для Gemini CLI. |
| `.kiro/skills/` `.kiro/agents/` | Workflow для Kiro CLI. |
| `TODO.md` | Детальный список задач на следующую итерацию с проверенным scope. |
| `issues-*.md` `Refer/` | Развёрнутые контекстные заметки, на которые ссылаются ассистенты. |

**Пользовательские конфиги НЕ коммитятся.** `*.local.json`, креды, транскрипты и эфемерное состояние — всё в gitignore. Когда вы форкаете, ваши локальные настройки остаются локальными.

> 💡 Впервые в AI-assisted iOS-разработке? Начните с чтения `AGENTS.md`, затем откройте репозиторий в **любом** из перечисленных CLI. Навыки активируются автоматически по контексту.

---

## 🛠 Сборка и запуск

**Требования**

- Xcode 26 (iOS 26 / macOS 26 SDK)
- Swift 6
- Хост macOS 26 (для таргета macOS)

**Начало работы**

```bash
git clone git@github.com:is52hertz/VideoPlayer.git
cd VideoPlayer
open VideoPlayer.xcodeproj
```

**Сборка и тесты из командной строки**

```bash
# Build
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer build

# Test
xcodebuild -project VideoPlayer.xcodeproj -scheme VideoPlayer test
```

**Запуск через Claude Code + XcodeBuildMCP** (рекомендуется для AI-workflow)

```text
> /run         # launches the app on the configured simulator
> /verify      # runs the change end-to-end and reports
```

---

## 🤝 Контрибьютинг

PR приветствуются — проект активно поощряет **форки, эксперименты и обучающие PR**.

- Сначала прочитайте `AGENTS.md`; его правила scope-дисциплины применимы как к людям, так и к ИИ.
- Изменения держите небольшими и сфокусированными. Один коммит = одна логическая единица.
- Сборка должна оставаться зелёной: запускайте `xcodebuild … build` перед пушем.
- Формат коммита: `^(feat|fix|refactor|style|docs|test|chore): .{1,72}$`

Issues, обсуждения и заметки в духе «я узнал X из этого репо» одинаково приветствуются.

---

## 📜 Лицензия

Выпущено под **GNU General Public License v3.0** (GPL-3.0).

> Почему GPL? Этот проект существует, чтобы учить. GPL гарантирует, что производные работы — включая форки, сгенерированные ИИ — останутся открытыми, чтобы следующий ученик тоже мог их изучить. Если вы что-то построите на его основе — поделитесь обратно.

Полный текст — в [`LICENSE`](LICENSE).

---

<p align="center">
  <sub>Сделано с <code>SwiftUI</code> и большим количеством <code>/clear</code>.</sub>
</p>
