# Архитектура AndroidAppPreviewer

Исходники и проекты находятся вместе в Projects: AndroidAppPreviewer.WPF, AndroidAppPreviewerPluginSdk и AndroidAppPreviewerPluginSdk.Managed.

Directory.Build.props задаёт общие каталоги обычных MSBuild-сборок: !artifacts/projects/Windows-x64/msbuild/<имя-проекта>/bin и obj. Для служебного проекта выпуска используется имя PackageRelease. Рабочие каталоги PackageTools находятся отдельно в !artifacts/package-build/<пакет>/<проект>/. Локальные bin/obj и !VS_TMP для новых сборок не используются.

Выпуск описан только в Packages. Build.csproj подключает UniversalDevKit.PackageTools 0.5.0 и перечисляет Package.json. Общая версия продукта — Packages/Version.json. В каждом Package.json локально определены проекты и contents с прямым выбором project/root/path либо source/include/rename; внешнего реестра нет.

У приложения используется dotnet publish, а managed SDK подключается обычным ProjectReference. У SDK используется сборка managed DLL и поставка native-исходников. Files.json рядом с native SDK служит единым списком для CMakeLists.txt и component-sources адаптера.

Components.json и Component.json задают общую генерацию ProjectTools: Shared, Static, Dynamic, фильтры и явный Files.json для CMake и упаковки. Маски файлов раскрываются при генерации. Проекты полностью генерируются; пользовательские настройки CRT MDd/MD, артефактов и ANGLE находятся в Build.props. Dependencies.props является поддерживаемым расширением с PackageReference; его версии согласуются с Delivery/NuGet/Delivery.json. Projects/Generate.csproj подключает готовый UniversalDevKit.ProjectTools; собственный скрипт генерации отсутствует. Solution обновляется через закреплённый SolutionInjector, который получает сам ProjectTools.

Интеграция потребителя принадлежит Packages/Windows/AndroidAppPreviewerPluginSdk/Delivery/CMake. В пакет она попадает в cmake. Это отдельная роль от собственного CMakeLists.txt native-проекта.

Три прямые NuGet-зависимости SDK и их точные версии определены в Delivery/NuGet/Delivery.json. PackageTools формирует из них nuspec; та же JSON-информация поставляется CMake-мосту. UDK-библиотеки не объединяются и не копируются в PluginSDK.

Tests/PluginSdkConsumer проверяет готовую поставку и восстановленные зависимости в Debug/Release. Tests/PreviewerSmoke проверяет ABI и поведение с прикладным плагином. C ABI xp_get_abi версии 1 и прежние NuGet ID сохранены.