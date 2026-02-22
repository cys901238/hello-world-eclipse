# PowerShell script to build and run HelloWorld in Windows
# Usage: Right-click -> Run with PowerShell or open PowerShell and run: .\run-hello.ps1

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = "D:\\somi-work\\hello-world-eclipse"
if (-Not (Test-Path $repo)) {
  Write-Error "Repository path not found: $repo"
  exit 1
}

Push-Location $repo
try {
  Write-Host "Cleaning and building with Maven..."
  mvn -DskipTests package

  $jar = Get-ChildItem -Path "target" -Filter "hello-world-eclipse-*.jar" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if (-Not $jar) {
    Write-Error "Built jar not found in target/"
    exit 1
  }
  Write-Host "Running jar: $($jar.Name)"
  & java -cp "target\$($jar.Name)" com.example.HelloWorld
} finally {
  Pop-Location
}
