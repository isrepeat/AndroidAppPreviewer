# Проверка Previewer ABI

CMake-проект собирает PreviewerSmoke из исходников этого репозитория. Используйте Windows x64 и каталог сборки под !artifacts/tests/PreviewerSmoke. Запуск: `PreviewerSmoke.exe <absolute-template-plugin.dll> <absolute-Roboto-Regular.ttf> urn:myapp:xaml`. Шрифт находится в Sources/AndroidAppPreviewer.WPF/Resources/Fonts/Roboto-Regular.ttf.

Проверяются ABI, прикладная сессия, переходы графа, реальные пиксели ANGLE, ввод, resize, отклонение ошибочного XAML и hot reload. Успех — PASS и код 0. Для проверки поставки без прикладного плагина используйте Tests/PackageRelease.Tests.ps1.


При конфигурации передайте ANDROID_APP_PREVIEWER_UDK_PACKAGES_ROOT с каталогом восстановленных NuGet-зависимостей, например !artifacts/tests/PackageRelease/<идентификатор-запуска>/packages после проверки выпуска. Это предоставляет общие публичные заголовки UDK. Smoke-проект собирается отдельно от проверки готового SDK.