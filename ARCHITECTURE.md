# Архитектура AndroidAppPreviewer

Исходники и проекты находятся вместе в Projects: AndroidAppPreviewer.WPF, AndroidAppPreviewerPluginSdk и AndroidAppPreviewerPluginSdk.Managed.

Directory.Build.props задаёт общие каталоги обычных MSBuild-сборок: !artifacts/projects/Windows-x64/msbuild/<имя-проекта>/bin и obj. Для служебного проекта выпуска используется имя PackageRelease. Рабочие каталоги PackageTools находятся отдельно в !artifacts/package-build/<пакет>/<проект>/. Локальные bin/obj и !VS_TMP для новых сборок не используются.

Выпуск описан только в Packages. Build.csproj подключает UniversalDevKit.PackageTools 0.5.0 и перечисляет Package.json. Общая версия продукта — Packages/Version.json. В каждом Package.json локально определены проекты и contents с прямым выбором project/root/path либо source/include/rename; внешнего реестра нет.

У приложения используется dotnet publish, а managed SDK подключается обычным ProjectReference. У SDK используется сборка managed DLL и поставка native-исходников. Files.json рядом с native SDK служит единым списком для CMakeLists.txt и component-sources адаптера.

Тот же Files.json используется GenerateProjects.ps1 для генерации Shared.vcxitems и фильтров Visual Studio. Static.vcxproj импортирует Shared и собирает статическую библиотеку с CRT MDd/MD; его собственные настройки поддерживаются вручную. Dependencies.props генерируется из трёх зависимостей Delivery/NuGet/Delivery.json, поэтому версии локальной native-сборки и поставки SDK имеют один источник. Native-проекты в solution заменяют прежние виртуальные папки с исходниками.

Интеграция потребителя принадлежит Packages/Windows/AndroidAppPreviewerPluginSdk/Delivery/CMake. В пакет она попадает в cmake. Это отдельная роль от собственного CMakeLists.txt native-проекта.

Три прямые NuGet-зависимости SDK и их точные версии определены в Delivery/NuGet/Delivery.json. PackageTools формирует из них nuspec; та же JSON-информация поставляется CMake-мосту. UDK-библиотеки не объединяются и не копируются в PluginSDK.

Tests/PluginSdkConsumer проверяет готовую поставку и восстановленные зависимости в Debug/Release. Tests/PreviewerSmoke проверяет ABI и поведение с прикладным плагином. C ABI xp_get_abi версии 1 и прежние NuGet ID сохранены.