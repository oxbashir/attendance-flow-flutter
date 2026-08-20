# Generates Play Console native-debug-symbols.zip (.so.sym format)
# Run after: flutter build appbundle --release

$ErrorActionPreference = 'Stop'
$engine = 'e672b006cb34c921db85b8e2f482ed3144a4574b'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$base = Join-Path $root 'build\native-symbols-work'
$objcopy = "$env:LOCALAPPDATA\Android\Sdk\ndk\27.0.12077973\toolchains\llvm\prebuilt\windows-x86_64\bin\llvm-objcopy.exe"
$merged = Join-Path $root 'build\app\intermediates\merged_native_libs\release\mergeReleaseNativeLibs\out\lib'
$zipPath = Join-Path $root 'store-assets\native-debug-symbols.zip'

if (-not (Test-Path $merged)) {
  throw 'Merged native libs not found. Run: flutter build appbundle --release'
}
if (-not (Test-Path $objcopy)) {
  throw "llvm-objcopy not found at $objcopy"
}

$engineMap = @{
  'arm64-v8a'   = 'android-arm64-release'
  'armeabi-v7a' = 'android-arm-release'
  'x86_64'      = 'android-x64-release'
}

if (Test-Path $base) { Remove-Item $base -Recurse -Force }
New-Item -ItemType Directory -Force -Path $base | Out-Null

foreach ($abi in @('arm64-v8a', 'armeabi-v7a', 'x86_64')) {
  $abiDir = Join-Path $base $abi
  New-Item -ItemType Directory -Force -Path $abiDir | Out-Null

  $engineZip = Join-Path $base "$($engineMap[$abi]).zip"
  $url = "https://storage.googleapis.com/flutter_infra_release/flutter/$engine/$($engineMap[$abi])/symbols.zip"
  Invoke-WebRequest -Uri $url -OutFile $engineZip -UseBasicParsing
  Expand-Archive -Force -Path $engineZip -DestinationPath (Join-Path $base "engine-$abi")

  $engineSo = Join-Path $base "engine-$abi\libflutter.so"
  & $objcopy --strip-debug $engineSo (Join-Path $abiDir 'libflutter.so.sym')

  foreach ($name in @('libapp.so', 'libdatastore_shared_counter.so')) {
    $input = Join-Path $merged "$abi\$name"
    if (Test-Path $input) {
      & $objcopy --strip-debug $input (Join-Path $abiDir ($name + '.sym'))
    }
  }
}

$x86Dir = Join-Path $base 'x86'
New-Item -ItemType Directory -Force -Path $x86Dir | Out-Null
$dsX86 = Join-Path $merged 'x86\libdatastore_shared_counter.so'
if (Test-Path $dsX86) {
  & $objcopy --strip-debug $dsX86 (Join-Path $x86Dir 'libdatastore_shared_counter.so.sym')
}

if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path @(
  (Join-Path $base 'arm64-v8a'),
  (Join-Path $base 'armeabi-v7a'),
  (Join-Path $base 'x86_64'),
  (Join-Path $base 'x86')
) -DestinationPath $zipPath -CompressionLevel Optimal

Write-Host "Created $zipPath ($((Get-Item $zipPath).Length) bytes)"
