# AndroidAppPreviewer

WPF-приложение из Sources/AndroidAppPreviewer.WPF. Состав NuGet и проект app описаны в Package.xml. После генерации проектов выполните `udk package build Packages/Windows/AndroidAppPreviewer/Package.xml` из корня репозитория.

Пакет UniversalDevKit.AndroidAppPreviewer содержит self-contained Windows x64 приложение в tools/win-x64, шрифты и курсоры. Managed ABI подключён через ProjectReference на локальный PluginSDK. Native DLL прикладного плагина выбирается аргументом `--plugin <path>`.

Версия выпуска задаётся в Packages/Version.json. Подробности — в корневом README.md.