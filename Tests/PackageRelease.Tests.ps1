param([string]$CMake, [string]$Source, [string]$NuGet)
$ErrorActionPreference = 'Stop'
$env:DOTNET_CLI_UI_LANGUAGE = 'en-US'
$env:VSLANG = '1033'
[Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$OutputEncoding = [Text.UTF8Encoding]::new($false)
$root = Split-Path -Parent $PSScriptRoot
$version = (Get-Content (Join-Path $root 'Packages/Version.json') -Raw | ConvertFrom-Json).version
foreach ($output in @('AndroidAppPreviewer/app/output/AndroidAppPreviewer.exe', 'AndroidAppPreviewerPluginSdk/managed/output/AndroidAppPreviewer.PluginSDK.dll', 'AndroidAppPreviewerPluginSdk/native/output/cmake/AndroidAppPreviewerPluginSdk.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $root ('!artifacts/package-build/' + $output)) -PathType Leaf)) {
        throw "Missing PackageTools project output: $output"
    }
}
$run = Join-Path $root ('!artifacts/tests/PackageRelease/' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($run)
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Extract-TestPackage([string]$Name, [string]$Id, [string[]]$Required) {
    $archivePath = Join-Path $root "!artifacts/packages/nuget/$Name/$Id.$version.nupkg"
    $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
        foreach ($requiredPath in $Required) { if ($requiredPath -cnotin $entries) { throw "Missing package entry: $requiredPath" } }
        if (@($entries | Where-Object { $_ -match '(^|/)(obj|!artifacts|!tools)/' }).Count) { throw 'Build directories leaked into package.' }
        if (@($entries | Where-Object { $_ -match '^(native|binaries)/' }).Count) { throw 'UDK binaries must be NuGet dependencies, not embedded in PluginSDK.' }
        if ($entries -contains 'include/AndroidAppPreviewerPluginSdk/Internal/Abi/SessionAbi.h') { throw 'Internal header leaked into public include directory.' }
    } finally { $archive.Dispose() }
    $destination = Join-Path $run $Name
    [IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $destination)
    return $destination
}
$previewer = Extract-TestPackage 'AndroidAppPreviewer' 'UniversalDevKit.AndroidAppPreviewer' @('tools/win-x64/AndroidAppPreviewer.exe', 'tools/win-x64/AndroidAppPreviewer.PluginSDK.dll', 'LICENSE.txt', 'README.md')
$sdk = Extract-TestPackage 'AndroidAppPreviewerPluginSdk' 'UniversalDevKit.AndroidAppPreviewer.PluginSDK' @('include/AndroidAppPreviewerPluginSdk/AndroidAppPreviewerPlugin.h', 'src/Internal/Abi/SessionAbi.cpp', 'lib/net8.0/AndroidAppPreviewer.PluginSDK.dll', 'cmake/AndroidAppPreviewerPluginConfig.cmake', 'cmake/UdkNuGetDependencies.cmake', 'cmake/ReadUdkDependencies.ps1', 'cmake/UdkDependencies.xml')
$nuspec = [xml](Get-Content (Join-Path $sdk 'UniversalDevKit.AndroidAppPreviewer.PluginSDK.nuspec') -Raw)
$declared = @($nuspec.package.metadata.dependencies.group.dependency)
$delivery = [xml](Get-Content (Join-Path $root 'Packages/Windows/AndroidAppPreviewerPluginSdk/Delivery/NuGet/Delivery.xml') -Raw)
$expected = $delivery.SelectNodes('/Delivery/Dependencies/Dependency')
if ($declared.Count -ne 3) { throw 'PluginSDK must declare three direct UDK dependencies.' }
foreach ($dependency in $expected) {
    $actual = @($declared | Where-Object id -eq $dependency.id)
    if ($actual.Count -ne 1 -or $actual[0].version -cne ('[' + $dependency.version + ']')) { throw "Wrong NuGet dependency: $($dependency.id)" }
}
if ($nuspec.OuterXml.Contains('WindowsRuntime')) { throw 'Obsolete runtime dependency remains.' }
if (-not $NuGet) {
    $NuGet = Get-ChildItem -Path (Join-Path $root '!tools/NuGet/*/nuget.exe') -File |
        Sort-Object { [version]$_.Directory.Name } -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $NuGet) { throw 'Build the packages with udk package build or pass -NuGet.' }
}
if (-not $Source) { $Source = Join-Path $root '!artifacts/packages/feed' }
$feed = Join-Path $run 'feed'
[void][IO.Directory]::CreateDirectory($feed)
Copy-Item -LiteralPath (Join-Path $root "!artifacts/packages/nuget/AndroidAppPreviewerPluginSdk/UniversalDevKit.AndroidAppPreviewer.PluginSDK.$version.nupkg") -Destination $feed
$packages = Join-Path $run 'packages'
& $nuget install UniversalDevKit.AndroidAppPreviewer.PluginSDK -Version $version -Framework net8.0 -Source ($feed + ';' + $Source) -OutputDirectory $packages -NonInteractive -ForceEnglishOutput -NoCache
if ($LASTEXITCODE -ne 0) { throw 'PluginSDK and its NuGet dependencies could not be restored.' }
$sdk = Join-Path $packages "UniversalDevKit.AndroidAppPreviewer.PluginSDK.$version"
foreach ($dependency in $expected) {
    if (-not (Test-Path -LiteralPath (Join-Path $packages ($dependency.id + '.' + $dependency.version)))) { throw "Dependency was not restored: $($dependency.id)" }
}
if (-not $CMake) {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
    $CMake = @(& $vswhere -latest -products '*' -find 'Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe')[0]
}
& $CMake -S (Join-Path $PSScriptRoot 'PluginSdkConsumer') -B (Join-Path $run 'consumer') -G 'Visual Studio 18 2026' -A x64 '-DCMAKE_CONFIGURATION_TYPES=Debug;Release' "-DSDK_ROOT=$sdk"
if ($LASTEXITCODE -ne 0) { throw 'Native consumer configuration failed.' }
foreach ($configuration in @('Debug', 'Release')) {
    & $CMake --build (Join-Path $run 'consumer') --config $configuration --parallel 2
    if ($LASTEXITCODE -ne 0) { throw "Native consumer $configuration build failed." }
}
$runtime = Join-Path $run 'consumer/Release'
foreach ($name in @('universaldevkit_diagnostic_dynamic.dll', 'libEGL.dll', 'libGLESv2.dll')) {
    if (-not (Test-Path -LiteralPath (Join-Path $runtime $name))) { throw "Consumer runtime DLL was not copied: $name" }
}
Write-Host 'PASS: separate UDK NuGet dependencies, clean restore and native consumers Debug/Release.'