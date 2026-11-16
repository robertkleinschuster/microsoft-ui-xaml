# Reproducible WinUI source product build

This fork builds both x64 Debug (`x64chk`) and Release (`x64fre`) products with
GitHub Actions and publishes each runtime payload and the generated
`Microsoft.WindowsAppSDK.WinUI` package as a workflow artifact. The workflow is in
`.github/workflows/winui-source-product.yml`.

## Runner and disk

The workflow uses `windows-2025-vs2026`, which supplies Visual Studio 2026. The
builds are initialized as `x64chk` and `x64fre` and pin
`VisualStudioVersion` to `18.0`. Release disables profile-guided optimization
with the supported `/nopgo` switch because a shallow Actions checkout does not
contain `origin/main`, which the PGO helper uses as its merge base.
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

# Release product; use /nopgo if the checkout is shallow.
.\init.ps1 x64fre /nopgo /notitle
.\build.cmd product /restore /q
```

The checked-in `controls/dev/dll/Microsoft.UI.Xaml.Common.props` correction
preserves WinUI's Windows SDK target versions after the C++ defaults import.
This was required for the source build against the Windows 11 SDK on VS 2026.

## Run it in GitHub Actions

The workflow runs on pushes to `main` and
`fix/ink-unprocessedinput-pointer-snapshots`, pull requests targeting `main`,
and manual dispatch. It initializes the repository, builds `product`, checks
that both runtime payloads and the NuGet package exist, then uploads separate
Debug and Release artifacts for 14 days. Each artifact includes its source
commit, configuration, and payload file count in `winui-build-info.json`.

The product payload paths are
`BuildOutput/packaging/Debug/runtimes/win10-x64/native` and
`BuildOutput/packaging/Release/runtimes/win10-x64/native`. The package is
`PackageStore/Microsoft.WindowsAppSDK.WinUI.3.0.0-dev.nupkg`.

The upstream WinUI OSS guidance still describes CI as unsupported. This
workflow is the fork's reproducible product-build path; it does not claim that
the upstream repository's full build and test matrix is CI-supported.
