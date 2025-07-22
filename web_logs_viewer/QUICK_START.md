# 🚀 Quick Start - GitHub Pages Setup

## 1️⃣ Активация GitHub Pages (один раз)

1. Перейдите в настройки репозитория: **Settings > Pages**
2. В разделе "Source" выберите **GitHub Actions** 
3. Сохраните настройки

## 2️⃣ Настройка разрешений (один раз)

В **Settings > Actions > General**:
- Workflow permissions: **Read and write permissions** ✅
- Allow GitHub Actions to create and approve pull requests ✅

## 3️⃣ Первый деплой

После настройки Pages:
1. Сделайте commit любых изменений в папке `web_logs_viewer/`
2. Push в ветку `main`
3. Workflow запустится автоматически
4. Через 2-3 минуты приложение будет доступно

## 🌐 URL приложения
```
https://k1yoshisho.github.io/ispect/
```

## 🔧 Ручной запуск деплоя

1. Перейдите в **Actions** tab
2. Выберите "Deploy Web Logs Viewer to GitHub Pages"
3. Нажмите **Run workflow**
4. Выберите ветку `main`
5. Нажмите **Run workflow**

## 📋 Что происходит при деплое

1. **Setup Flutter** - установка Flutter SDK 3.24.0
2. **Dependencies** - `flutter pub get`
3. **Analysis** - проверка кода `flutter analyze`
4. **Build** - сборка `flutter build web --release --base-href /ispect/`
5. **Deploy** - загрузка в GitHub Pages

## ✅ Проверка работы

После деплоя:
- Откройте https://k1yoshisho.github.io/ispect/
- Перетащите .json или .txt файл в Drop Zone
- Или нажмите "Load File" и вставьте содержимое
- Проверьте JSON Viewer

## 🔄 Автообновление

Деплой происходит автоматически при:
- Push в `main` с изменениями в `web_logs_viewer/`
- Изменении workflow файла
- Ручном запуске через Actions

---

**🎯 Готово!** Теперь у вас есть автодеплой Flutter Web приложения в GitHub Pages.
