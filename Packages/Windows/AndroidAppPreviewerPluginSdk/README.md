# AndroidAppPreviewer Plugin SDK

UniversalDevKit.AndroidAppPreviewer.PluginSDK содержит native-исходники из Projects/AndroidAppPreviewerPluginSdk, managed DLL и CMake-интеграцию. Native-библиотеки UDK в него не копируются.

Прямые NuGet-зависимости — UniversalDevKit.XamlRuntime, UniversalDevKit.OpenGLESRenderer и UniversalDevKit.Diagnostic. Точные версии заданы в Delivery/NuGet/Delivery.json; Helpers восстанавливается транзитивно. ANGLE, его заголовки и лицензии поставляются обычным пакетом OpenGLESRenderer.

Выпуск: dotnet msbuild Packages/Build.csproj -restore -t:PackRepository -p:PreviewerPackage=AndroidAppPreviewerPluginSdk из корня репозитория. Версия продукта — Packages/Version.json; сборщик — закреплённый PackageReference UniversalDevKit.PackageTools. Checkout UDK не нужен.

Для подключения выполните nuget install SDK вместе с зависимостями в общий каталог ID.VERSION. Затем подключите cmake/AndroidAppPreviewerPluginConfig.cmake. Он предоставляет AndroidAppPreviewerPlugin::SDK и android_app_previewer_add_runtime(target). При нестандартном расположении зависимостей задайте ANDROID_APP_PREVIEWER_UDK_PACKAGES_ROOT. C ABI xp_get_abi версии 1 сохранён.

Каталоги SDK: include/AndroidAppPreviewerPluginSdk, src, lib/net8.0 и cmake. Последний содержит UdkDependencies.json из того же Delivery.json: это единый источник версий для nuspec и CMake. Проверка чистого restore и native-потребителя выполняется Tests/PackageRelease.Tests.ps1.