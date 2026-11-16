# Reproducible WinUI source product build

This fork builds the x64 Debug product with GitHub Actions and publishes the
runtime payload and generated `Microsoft.WindowsAppSDK.WinUI` package as a
workflow artifact. The workflow is in
`.github/workflows/winui-source-product.yml`.

## Runner and disk

The workflow uses `windows-2025-vs2026`, which supplies Visual Studio 2026. The
build is initialized as `x64chk` and pins `VisualStudioVersion` to `18.0`.
Before restore, the workflow removes only optional Android, Java, Go, Python,
Ruby, and package caches unrelated to WinUI, then requires at least 36 GiB
free. The product build uses about 22 GiB of intermediates on the measured
local build; NuGet restore and first-time tool setup need additional room.

## Build steps

From a clean checkout on Windows with the repository's `.vsconfig` components
installed in Visual Studio 2026:

```powershell
$env:VisualStudioVersion = '18.0'
$env:NuGetAudit = 'false'
.\init.ps1 x64chk /notitle
.\initrun.ps1 -Flavor x64chk .\build.cmd product /restore /q
```

The checked-in `controls/dev/dll/Microsoft.UI.Xaml.Common.props` correction
preserves WinUI's Windows SDK target versions after the C++ defaults import.
This was required for the source build against the Windows 11 SDK on VS 2026.

## Run it in GitHub Actions

The workflow runs on pushes to `main` and
`fix/ink-unprocessedinput-pointer-snapshots`, pull requests targeting `main`,
and manual dispatch. It initializes the repository, builds `product`, checks
that both the runtime payload and NuGet package exist, then uploads them for 14
days. The artifact includes the source commit and payload file count in
`winui-build-info.json`.

The product payload path is
`BuildOutput/packaging/Debug/runtimes/win10-x64/native`. The package is
`PackageStore/Microsoft.WindowsAppSDK.WinUI.3.0.0-dev.nupkg`.

The upstream WinUI OSS guidance still describes CI as unsupported. This
workflow is the fork's reproducible product-build path; it does not claim that
the upstream repository's full build and test matrix is CI-supported.
