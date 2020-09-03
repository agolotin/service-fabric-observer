[string] $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

function Build-SFPkg {
    param (
        [string]
        $packageId,

        [string]
        $basePath
    )

    $ProgressPreference = "SilentlyContinue"

    [string] $outputDir = "$scriptPath\bin\release\FabricObserver\SFPkgs"
    [string] $zipPath = "$outputDir\$($packageId).zip"
    [System.IO.Directory]::CreateDirectory($outputDir) | Out-Null

    Compress-Archive "$basePath\*"  $zipPath -Force

    Move-Item -Path $zipPath -Destination ($zipPath.Replace(".zip", ".sfpkg"))
}

try {
    Push-Location $scriptPath

    Build-SFPkg "FabricObserver.Linux.SelfContained" "$scriptPath\bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType"
    Build-SFPkg "FabricObserver.Linux.FrameworkDependent" "$scriptPath\bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType"

    Build-SFPkg "FabricObserver.Windows.SelfContained" "$scriptPath\bin\release\FabricObserver\win-x64\self-contained\FabricObserverType"
    Build-SFPkg "FabricObserver.Windows.FrameworkDependent" "$scriptPath\bin\release\FabricObserver\win-x64\framework-dependent\FabricObserverType"
}
finally {
    Pop-Location
}