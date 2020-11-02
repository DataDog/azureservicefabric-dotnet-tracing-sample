
$SvcFabRoot="D:\SvcFab"

if (-not (Test-Path env:DD_TRACER_VERSION)) { $env:DD_TRACER_VERSION = '1.19.2' }

$env:DD_DOTNET_TRACER_HOME="${SvcFabRoot}\datadog-tracer-home\v${env:DD_TRACER_VERSION}"
[System.Environment]::SetEnvironmentVariable('DD_DOTNET_TRACER_HOME', $env:DD_DOTNET_TRACER_HOME, [System.EnvironmentVariableTarget]::Machine)

$download_tracer=$TRUE
if (Test-Path -Path $env:DD_DOTNET_TRACER_HOME -PathType Container) { 
  # This version is already installed
  $download_tracer=$FALSE
}

if ($download_tracer) {

  if (-not (Test-Path env:DD_TRACER_URL)) { $env:DD_TRACER_URL = "https://github.com/DataDog/dd-trace-dotnet/releases/download/v${env:DD_TRACER_VERSION}/windows-tracer-home.zip" }
  
  Write-Host "[DatadogInstall.ps1] Downloading ${env:DD_TRACER_URL} (specified by environment variable DD_TRACER_URL)"
  Invoke-WebRequest $env:DD_TRACER_URL -OutFile .\windows-tracer-home.zip

  Write-Host "[DatadogInstall.ps1] Installing Datadog APM"
  Expand-Archive -Force -Path 'windows-tracer-home.zip' -DestinationPath $env:DD_DOTNET_TRACER_HOME

}

$LOG_BASIS_PATH="${SvcFabRoot}\datadog-logs"
if (-not (Test-Path -Path $LOG_BASIS_PATH -PathType Container)) { 
  New-Item -ItemType Directory -Force -Path $LOG_BASIS_PATH
}

$VERSION_LOG_PATH="${LOG_BASIS_PATH}\v${env:DD_TRACER_VERSION}"

if (-not (Test-Path -Path $VERSION_LOG_PATH -PathType Container)) { 
  New-Item -ItemType Directory -Force -Path $VERSION_LOG_PATH
}
  
$env:DD_TRACE_LOG_PATH="${VERSION_LOG_PATH}\dotnet-profiler.log"
[System.Environment]::SetEnvironmentVariable('DD_TRACE_LOG_PATH', $env:DD_TRACE_LOG_PATH, [System.EnvironmentVariableTarget]::Machine)

$bitness_path="win-x86"
if ($env:PROCESSOR_ARCHITECTURE -like '*64*') { $bitness_path='win-x64' }

if (-not (Test-Path env:DD_TRACE_DEBUG)) { $env:DD_TRACE_DEBUG = 'false' }
[System.Environment]::SetEnvironmentVariable('DD_TRACE_DEBUG', $env:DD_TRACE_DEBUG,[System.EnvironmentVariableTarget]::Machine)

[System.Environment]::SetEnvironmentVariable('DD_INTEGRATIONS', "$env:DD_DOTNET_TRACER_HOME\integrations.json", [System.EnvironmentVariableTarget]::Machine)

[System.Environment]::SetEnvironmentVariable('COR_ENABLE_PROFILING', "0", [System.EnvironmentVariableTarget]::Machine) # Enable per app
[System.Environment]::SetEnvironmentVariable('COR_PROFILER', "{846F5F1C-F9AE-4B07-969E-05C26BC060D8}", [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('COR_PROFILER_PATH', "${env:DD_DOTNET_TRACER_HOME}\${bitness_path}\Datadog.Trace.ClrProfiler.Native.dll", [System.EnvironmentVariableTarget]::Machine)

[System.Environment]::SetEnvironmentVariable('CORECLR_ENABLE_PROFILING', "0", [System.EnvironmentVariableTarget]::Machine) # Enable per app
[System.Environment]::SetEnvironmentVariable('CORECLR_PROFILER', "{846F5F1C-F9AE-4B07-969E-05C26BC060D8}", [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('CORECLR_PROFILER_PATH', "${env:DD_DOTNET_TRACER_HOME}\${bitness_path}\Datadog.Trace.ClrProfiler.Native.dll", [System.EnvironmentVariableTarget]::Machine)
