$ErrorActionPreference = "Stop"

function Update-ApplicationManifestForLinux {
    param (
        [string] $filePath
    )

    $FileContent = Get-ChildItem $filePath | Get-Content
    $NewFileContent = @()

[string] $newNode = @"
    <Policies>
        <RunAsPolicy CodePackageRef="Code" UserRef="SystemUser" EntryPointType="Setup" />
    </Policies>
"@

[string] $newNode2 = @"
  <Principals>
    <Users>
      <User Name="SystemUser" AccountType="LocalSystem" />
    </Users>
  </Principals>
"@
    for ($i = 0; $i -lt $FileContent.Length; $i++) {
        if ($FileContent[$i] -like "*</ServiceManifestImport>*") {
         
            $NewFileContent += $newNode
        }
        elseif ($FileContent[$i] -like "*</ApplicationManifest>*") {
       
            $NewFileContent += $newNode2
        }

        $NewFileContent += $FileContent[$i]
    }

    $NewFileContent | Set-Content $filePath
}

function Update-ServiceManifestForLinux {
    param (
        [string] $filePath
    )

[string] $newNode = @"
    <SetupEntryPoint>
      <ExeHost>
        <Program>netstat_cap.sh</Program>
        <WorkingFolder>CodePackage</WorkingFolder>
      </ExeHost>
    </SetupEntryPoint>
"@
    $FileContent = Get-ChildItem $filePath | Get-Content
    $NewFileContent = @()

    for ($i = 0; $i -lt $FileContent.Length; $i++) {
        if ($FileContent[$i] -like "*<EntryPoint>*") {
         
            $NewFileContent += $newNode
        }

        $NewFileContent += $FileContent[$i]
    }

    $NewFileContent | Set-Content $filePath
}

$Configuration="Release"
[string] $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

try {
    Push-Location $scriptPath

    Remove-Item $scriptPath\bin\release\FabricObserver\ -Recurse -Force -EA SilentlyContinue

    dotnet publish FabricObserver\FabricObserver.csproj -o bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType\FabricObserverPkg\Code -c $Configuration -r linux-x64 --self-contained true
    dotnet publish FabricObserver\FabricObserver.csproj -o bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType\FabricObserverPkg\Code -c $Configuration -r linux-x64 --self-contained false
    dotnet publish FabricObserver\FabricObserver.csproj -o bin\release\FabricObserver\win-x64\self-contained\FabricObserverType\FabricObserverPkg\Code -c $Configuration -r win-x64 --self-contained true
    dotnet publish FabricObserver\FabricObserver.csproj -o bin\release\FabricObserver\win-x64\framework-dependent\FabricObserverType\FabricObserverPkg\Code -c $Configuration -r win-x64 --self-contained false

    Copy-Item FabricObserver\PackageRoot\* bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType\FabricObserverPkg\ -Recurse
    Copy-Item FabricObserver\PackageRoot\* bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType\FabricObserverPkg\ -Recurse

    Copy-Item FabricObserver\PackageRoot\* bin\release\FabricObserver\win-x64\self-contained\FabricObserverType\FabricObserverPkg\ -Recurse
    Copy-Item FabricObserver\PackageRoot\* bin\release\FabricObserver\win-x64\framework-dependent\FabricObserverType\FabricObserverPkg\ -Recurse

    Copy-Item FabricObserverApp\ApplicationPackageRoot\ApplicationManifest.xml bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType\ApplicationManifest.xml
    Copy-Item FabricObserverApp\ApplicationPackageRoot\ApplicationManifest.xml bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType\ApplicationManifest.xml
    Copy-Item FabricObserverApp\ApplicationPackageRoot\ApplicationManifest.xml bin\release\FabricObserver\win-x64\self-contained\FabricObserverType\ApplicationManifest.xml
    Copy-Item FabricObserverApp\ApplicationPackageRoot\ApplicationManifest.xml bin\release\FabricObserver\win-x64\framework-dependent\FabricObserverType\ApplicationManifest.xml

    Update-ApplicationManifestForLinux "$scriptPath\bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType\ApplicationManifest.xml"
    Update-ApplicationManifestForLinux "$scriptPath\bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType\ApplicationManifest.xml"

    Update-ServiceManifestForLinux "$scriptPath\bin\release\FabricObserver\linux-x64\self-contained\FabricObserverType\FabricObserverPkg\ServiceManifest.xml"
    Update-ServiceManifestForLinux "$scriptPath\bin\release\FabricObserver\linux-x64\framework-dependent\FabricObserverType\FabricObserverPkg\ServiceManifest.xml"
}
finally {
    Pop-Location
}