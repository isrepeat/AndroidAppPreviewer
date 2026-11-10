# AndroidAppPreviewer

Репозиторий приложения и native/managed PluginSDK.

## Структура

- Projects/AndroidAppPreviewer.WPF — WPF-приложение и его .csproj.
- Projects/AndroidAppPreviewerPluginSdk — native SDK; Files.json задаёт единый список C++ файлов для Shared-проекта MSBuild, CMake и поставки исходников. Static.vcxproj собирает настоящую статическую библиотеку из Shared.vcxitems.
- Projects/AndroidAppPreviewerPluginSdk.Managed — managed DLL и её .csproj.
- Packages/Build.csproj — единственная точка выпуска, закреплённый PackageReference на UniversalDevKit.PackageTools и список пакетов.
- Packages/Version.json — версия обоих пакетов продукта.
- Packages/Windows/<пакет>/Package.json — локальные проекты сборки и полный состав пакета через project/root/path и source/include.
- Packages/Windows/<пакет>/Delivery — NuGet-описание и интеграция доставки. CMake-интеграция PluginSDK находится в Delivery/CMake.
- Tests/PluginSdkConsumer — потребитель готового SDK; Tests/PreviewerSmoke — проверка ABI и поведения; Tests/PackageRelease.Tests.ps1 — проверка выпуска.

## Выпуск

Требуются Windows и .NET SDK с поддержкой net8.0. Инструмент UniversalDevKit.PackageTools 0.5.0 восстанавливается через PackageReference; checkout UDK не используется. NuGet.exe при необходимости загружается в !tools с проверкой SHA-256.

```powershell
dotnet msbuild Packages/Build.csproj -restore -t:PlanRepositoryPackages
dotnet msbuild Packages/Build.csproj -restore -t:PackRepository
```

Для локального feed на этой машине:

```powershell
dotnet msbuild Packages/Build.csproj -restore -t:PackRepository -p:RestoreAdditionalProjectSources=C:/WORK/Android/Projects/AndroidAppPreviewer/!artifacts/packages/feed
```

Параметр PreviewerPackage выбирает один пакет: -p:PreviewerPackage=AndroidAppPreviewerPluginSdk. Без него выпускаются оба. UdkPackageOutput задаёт каталог результатов, UdkPackageSources — альтернативный источник восстановления зависимостей для проектных адаптеров. Путь локального feed не зашит в проект.

Результаты находятся в !artifacts/packages/nuget/<имя-пакета>. Версия читается из Packages/Version.json без автоматического изменения. Публикация .nupkg в удалённый feed — отдельное действие.

## Проекты и зависимости

Определения projects находятся непосредственно в Package.json. Ключи app, native и managed — локальные имена; name и schemaVersion внутри них не нужны. Пути проектов отсчитываются от корня репозитория. contents с project выбирает результат адаптера напрямую через root/path; именованных artifacts нет. Записи с project идут перед source. Пути source отсчитываются от корня репозитория, include — от выбранного source; пути versionSource и deliveries — от каталога пакета. Рабочие каталоги — !artifacts/package-build/<пакет>/<проект>/. Отдельного реестра Projects нет.

У приложения локальный проект app выполняет dotnet publish; managed SDK подключается его обычным ProjectReference. У PluginSDK native подготавливает исходники из Files.json, managed собирает DLL.

Delivery/NuGet/Delivery.json PluginSDK закрепляет прямые зависимости на XamlRuntime, OpenGLESRenderer и Diagnostic версии 0.1.0. Helpers восстанавливается транзитивно; ANGLE поставляется OpenGLESRenderer. Native-библиотеки не копируются внутрь PluginSDK. Nuspec и cmake/UdkDependencies.json используют одно описание зависимостей.

Потребитель должен выполнить nuget install SDK вместе с зависимостями в общий каталог ID.VERSION. CMake-переменная ANDROID_APP_PREVIEWER_UDK_PACKAGES_ROOT позволяет указать другое расположение пакетов. ID UniversalDevKit.AndroidAppPreviewer и UniversalDevKit.AndroidAppPreviewer.PluginSDK сохранены.

## Разработка и проверки

```powershell
MSBuild.exe AndroidAppPreviewer.sln /restore /p:Configuration=Release /p:Platform=x64
./Tests/NativeProject.Tests.ps1
./Tests/PackageRelease.Tests.ps1
```

Для native-проверок нужен Visual Studio 18 2026 с C++. Собственный native-проект расположен в Projects/AndroidAppPreviewerPluginSdk/CMakeLists.txt: задайте ANDROID_APP_PREVIEWER_UDK_PACKAGES_ROOT и отдельный build под !artifacts/projects/Windows-x64/cmake/AndroidAppPreviewerPluginSdk. Путь к font для smoke-проверки — Projects/AndroidAppPreviewer.WPF/Resources/Fonts/Roboto-Regular.ttf.

Сборка solution выполняется из Developer PowerShell Visual Studio: solution теперь содержит C++-проект, поэтому нужен MSBuild из Visual Studio, а не dotnet msbuild. Для первой локальной сборки добавьте /p:RestoreAdditionalProjectSources=<feed> с пакетами UDK. Отдельное WPF-приложение по-прежнему можно собрать через dotnet build Projects/AndroidAppPreviewer.WPF/AndroidAppPreviewer.WPF.csproj -c Release.

### Native MSBuild-проекты SDK

- AndroidAppPreviewerPluginSdk.Shared.vcxitems содержит общие исходники и заголовки с фильтрами Internal/Abi, Internal/Bridge, Internal/Rendering и Session.
- AndroidAppPreviewerPluginSdk.Static.vcxproj импортирует Shared и собирает AndroidAppPreviewerPluginSdk.lib для Windows x64 Debug/Release с CRT MDd/MD.
- AndroidAppPreviewerPluginSdk.Dependencies.props содержит точные PackageReference на XamlRuntime, OpenGLESRenderer и Diagnostic. Версии берутся из Delivery/NuGet/Delivery.json; исходники UDK не подключаются.
- GenerateProjects.ps1 обновляет Shared, фильтры и Dependencies.props из Files.json и описания доставки. После изменения списка файлов или версий запустите ./Projects/AndroidAppPreviewerPluginSdk/GenerateProjects.ps1; параметр -Check проверяет актуальность без записи. Static.vcxproj поддерживается вручную.

Tests/NativeProject.Tests.ps1 собирает потребителя через ProjectReference на статическую библиотеку и запускает проверку ABI в Debug/Release с очищенным PATH. Библиотеки Diagnostic и ANGLE доставляются из NuGet. Выпуск PluginSDK сохраняет прежнюю поставку native-исходников и managed DLL: локальная .lib не добавляется в NuGet автоматически.

## Каталоги сборки

Общие пути всех MSBuild-проектов задаёт корневой Directory.Build.props. Обычная сборка solution сохраняет результаты в !artifacts/projects/Windows-x64/msbuild/<имя-проекта>/bin/<Configuration>/<TFM>/, промежуточные файлы и NuGet assets — в obj/ того же проекта. Runtime-specific сборка дополнительно разделяется по RID. Служебный Packages/Build.csproj использует имя каталога PackageRelease.

Проекты приложения и managed SDK используют соответственно каталоги AndroidAppPreviewer.WPF и AndroidAppPreviewerPluginSdk.Managed. PackageTools по-прежнему размещает результаты выпуска в !artifacts/package-build/<пакет>/<проект>/, готовые NuGet — в !artifacts/packages/nuget/<пакет>/, проверки — в !artifacts/tests/.

Native MSBuild-проект использует !artifacts/projects/Windows-x64/msbuild/AndroidAppPreviewerPluginSdk.Static/bin/<Configuration>/ для .lib и obj/<Configuration>/ для промежуточных файлов. Результаты тестового потребителя находятся в !artifacts/tests/NativeProject/.

Старый !VS_TMP больше не используется. Сохранённые настройки previewer.settings.json и логи перенесены к Debug-сборке приложения в новый bin; результаты CheckerboardVerification находятся в !artifacts/tests/CheckerboardVerification. Настройки приложения и его логи по-прежнему сохраняются рядом с запускаемым EXE.