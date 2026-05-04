# Find Java in common Flutter/Android locations
$javaPaths = @(
    "C:\flutter\bin\cache\artifacts\java\bin\java.exe",
    "D:\APP PC\sdk\jbr\bin\java.exe",
    "C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
)

foreach ($javaPath in $javaPaths) {
    if (Test-Path $javaPath) {
        $javaHome = Split-Path (Split-Path $javaPath -Parent) -Parent
        Write-Host "Found Java at: $javaHome"
        $env:JAVA_HOME = $javaHome
        break
    }
}

if (-not $env:JAVA_HOME) {
    Write-Host "Java not found. Please install Android Studio or set JAVA_HOME manually."
    exit 1
}

Write-Host "Running signingReport..."
& .\gradlew.bat signingReport
