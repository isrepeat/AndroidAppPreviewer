# Архитектура AndroidAppPreviewer

`Components.json` использует схему UDK v5. Каждый `Component.json` задаёт тип проекта, исходники и настройки генерации. Расширение WPF `AndroidAppPreviewer.WPF.targets` задаёт ресурсы, ссылку на managed SDK и зависимость от AvalonEdit. Нативный SDK подключает настройки MSBuild и PackageReference через `Build.props` и `AndroidAppPreviewerPluginSdk.Dependencies.props`.

`Directory.Build.props` задаёт каталоги MSBuild под `!artifacts/projects/Windows-x64/msbuild`. ProjectTools раскрывает маски файлов нативного SDK в `Files.json`, который используют его CMake-проект и адаптер упаковки исходников.

Пакеты описаны в `Packages/Windows`. Приложение использует `dotnet publish` и включает managed SDK через ProjectReference. Пакет SDK включает managed DLL и нативные исходники. `Delivery/NuGet/Delivery.json` задаёт зависимости для NuGet и поставляемой CMake-интеграции. Версии нативных PackageReference согласуются с этим описанием.

`AndroidAppPreviewer.Tests.sln` группирует файлы проверок. NativeProject проверяет статическую библиотеку SDK через MSBuild, PluginSdkConsumer проверяет готовый пакет через CMake, PreviewerSmoke проверяет ABI и поведение с прикладным плагином.