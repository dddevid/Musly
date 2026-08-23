# Run Flutter with environment variables from .env file
# Usage: .\run_with_env.ps1 [flutter_run_args]

param(
    [string[]]$FlutterArgs = @()
)

# Read .env file
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(.+?)=(.+)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if present
            if ($value.StartsWith('"') -and $value.EndsWith('"')) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
            Write-Host "Loaded: $name = ***" -ForegroundColor DarkGray
        }
    }
    Write-Host "Environment variables loaded from .env" -ForegroundColor Green
} else {
    Write-Warning ".env file not found. Creating from .env.example..."
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "Created .env from .env.example - please edit it with your values!" -ForegroundColor Yellow
    }
    exit 1
}

# Build flutter run command with dart-define
$defines = @()

$cmd = "flutter run $($defines -join ' ') $($FlutterArgs -join ' ')"
Write-Host "Running: $cmd" -ForegroundColor Cyan

# Execute flutter run
& flutter run @defines @FlutterArgs
