param([Parameter(Mandatory)][string]$Path, [switch]$NativeSources)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
$settings = [System.Xml.XmlReaderSettings]::new()
$settings.DtdProcessing = [System.Xml.DtdProcessing]::Prohibit
$reader = [System.Xml.XmlReader]::Create($Path, $settings)
$document = [System.Xml.XmlDocument]::new()
try { $document.Load($reader) } finally { $reader.Dispose() }
if ($NativeSources) {
    $projects = $document.SelectNodes('/Component/Projects/Project[@projectType="native"]')
    if ($projects.Count -ne 1) { throw "Expected one native project in $Path." }
    $project = $projects[0]
    @{
        sources = @($project.SelectNodes('Sources/Source') | ForEach-Object InnerText)
        excludeSources = @($project.SelectNodes('ExcludeSources/Source') | ForEach-Object InnerText)
    } | ConvertTo-Json -Compress
    return
}
$dependencies = @(foreach ($node in $document.SelectNodes('/Delivery/Dependencies/Dependency')) {
    $id = $node.GetAttribute('id')
    $version = $node.GetAttribute('version')
    if ($id -cnotmatch '^[A-Za-z0-9_.-]+$' -or $version -cnotmatch '^[0-9]+(?:\.[0-9]+){2,3}(?:[-+][A-Za-z0-9.-]+)?$') {
        throw "Invalid PluginSDK dependency in $Path."
    }
    @{ id = $id; version = $version }
})
if (-not $dependencies.Count) { throw "Missing PluginSDK dependencies in $Path." }
@{ dependencies = $dependencies } | ConvertTo-Json -Compress