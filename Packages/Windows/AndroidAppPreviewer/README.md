# AndroidAppPreviewer

WPF-приложение из Projects/AndroidAppPreviewer.WPF. Состав NuGet описан в Package.json, локальный проект app — в том же Package.json. Выпуск: `dotnet msbuild Packages/Build.csproj -restore -t:PackRepository -p:PreviewerPackage=AndroidAppPreviewer` из корня репозитория.

Пакет UniversalDevKit.AndroidAppPreviewer содержит self-contained Windows x64 приложение в tools/win-x64, шрифты и курсоры. Managed ABI подключён через ProjectReference на локальный PluginSDK. Native DLL прикладного плагина выбирается аргументом `--plugin <path>`.

Версия выпуска принадлежит Packages/Version.json. Сборщик UniversalDevKit.PackageTools восстанавливается как закреплённый PackageReference из Packages/Build.csproj. Подробности — в корневом README.md.