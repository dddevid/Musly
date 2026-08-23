# Build release version with environment variables from .env file
# Usage: .\build_release.ps1 [apk|appbundle|ios|windows|linux|macos|web]

param(
    [string]$Target = "apk"
)

# Read .env file
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(.+?)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "Loaded: $name = ***" -ForegroundColor DarkGray
        }
    }
    Write-Host "Environment variables loaded from .env" -ForegroundColor Green
} else {
    Write-Error ".env file not found!"
    exit 1
}

# Build dart-define arguments
$defines = @()

# Build based on target
$cmd = ""
switch ($Target.ToLower()) {
    "apk" { $cmd = "flutter build apk --release" }
    "appbundle" { $cmd = "flutter build appbundle --release" }
    "ios" { $cmd = "flutter build ios --release" }
    "windows" { $cmd = "flutter build windows --release" }
    "linux" { $cmd = "flutter build linux --release" }
    "macos" { $cmd = "flutter build macos --release" }
    "web" { $cmd = "flutter build web --release" }
    default {
        Write-Error "Unknown target: $Target"
        Write-Host "Valid targets: apk, appbundle, ios, windows, linux, macos, web"
        exit 1
    }
}

Write-Host "Building: $cmd with dart-defines" -ForegroundColor Cyan
& flutter build $Target --release @defines

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build completed successfully!" -ForegroundColor Green
} else {
    Write-Error "Build failed!"
}
