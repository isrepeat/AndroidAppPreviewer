# AndroidAppPreviewer

Репозиторий WPF-приложения, native SDK и managed SDK. Корневой `Components.json` перечисляет три описания `Component.json` в каталоге `Projects`.

## Генерация проектов

Из корня репозитория с установленным UDK CLI выполните:

```powershell
udk project generate
```

ProjectTools обновляет `AndroidAppPreviewer.sln` и создаёт проекты WPF и managed SDK, варианты Shared, Static и Dynamic нативного SDK, фильтры и `Files.json`. Для генерации из открытого решения выберите в Visual Studio **Tools → Regenerate UDK Solution**. Команда `udk project check` проверяет актуальность сгенерированных файлов.

Для сборки решения нужен MSBuild из Visual Studio с компонентами C++ и .NET 8. Нативный SDK восстанавливает пакеты UDK через NuGet. Если они находятся в локальном feed, передайте MSBuild `/p:RestoreAdditionalProjectSources=<feed>`.

## Пакеты

После генерации выполните из корня репозитория:

```powershell
udk package build Packages/Windows/AndroidAppPreviewer/Package.json
udk package build Packages/Windows/AndroidAppPreviewerPluginSdk/Package.json
```

Команда `udk package plan` принимает те же пути. Версия пакетов задаётся в `Packages/Version.json`, результаты находятся в `!artifacts/packages/nuget`. Пакет приложения содержит self-contained WPF для Windows x64. Пакет SDK содержит нативные исходники, managed DLL и CMake-интеграцию. Прямые зависимости SDK заданы в `Delivery/NuGet/Delivery.json`.

## Тесты

`AndroidAppPreviewer.Tests.sln` содержит файлы тестов в папках решения. После генерации проектов запускайте нативную проверку через `Tests/NativeProject.Tests.ps1`. После сборки обоих пакетов запускайте `Tests/PackageRelease.Tests.ps1`. Для обоих скриптов параметр `-Source` задаёт feed зависимостей UDK. Инструкция для ABI smoke-теста находится в `Tests/PreviewerSmoke/README.md`.