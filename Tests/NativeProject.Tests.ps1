param([string]$Source)

$ErrorActionPreference = 'Stop'
$env:DOTNET_CLI_UI_LANGUAGE = 'en-US'
$env:VSLANG = '1033'
$root = Split-Path -Parent $PSScriptRoot
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$msbuild = @(& $vswhere -latest -products '*' -find MSBuild/Current/Bin/MSBuild.exe)[0]
if (-not $msbuild) {
    throw 'Visual Studio MSBuild with native PackageReference support is required.'
}
if (-not $Source) {
    $Source = Join-Path $root '!artifacts/packages/feed'
}
Push-Location -LiteralPath $root
try {
    & udk project check
} finally {
    Pop-Location
}
if ($LASTEXITCODE -ne 0) { throw 'ProjectTools check failed.' }
$project = Join-Path $PSScriptRoot 'NativeProject/PluginSdkNativeConsumer.vcxproj'
foreach ($configuration in @('Debug', 'Release')) {
    & $msbuild $project /restore /nologo /v:minimal /p:Platform=x64 "/p:Configuration=$configuration" "/p:RestoreAdditionalProjectSources=$Source"
    if ($LASTEXITCODE -ne 0) {
        throw "Static SDK consumer build failed: $configuration"
    }
    $output = Join-Path $root "!artifacts/tests/NativeProject/$configuration/bin"
    $diagnostic = if ($configuration -eq 'Debug') { 'universaldevkit_diagnostic_dynamicd.dll' } else { 'universaldevkit_diagnostic_dynamic.dll' }
    foreach ($name in @($diagnostic, 'libEGL.dll', 'libGLESv2.dll')) {
        if (-not (Test-Path -LiteralPath (Join-Path $output $name) -PathType Leaf)) {
            throw "Missing consumer runtime: $name"
        }
    }
    # Запуск не должен зависеть от DLL в окружении разработчика.
    $savedPath = $env:PATH
    try {
        $env:PATH = [Environment]::SystemDirectory
        & (Join-Path $output 'PluginSdkNativeConsumer.exe')
        if ($LASTEXITCODE -ne 0) {
            throw "Static SDK ABI test failed: $configuration"
        }
    } finally {
        $env:PATH = $savedPath
    }
}
Write-Host 'PASS: Shared project, static SDK, native PackageReference and ABI consumers Debug/Release.'