# Script per creare la keystore Android per Musly
# Questa keystore sarà usata per firmare le build debug e release
# con la stessa chiave, evitando errori di firma incompatibile

$keystorePath = "$PSScriptRoot\android\app\musly-release.keystore"
$keystorePassword = "MuslyApp2024!"
$keyAlias = "musly"
$keyPassword = "MuslyApp2024!"

Write-Host "Creazione keystore per Musly..." -ForegroundColor Green
Write-Host "Percorso: $keystorePath" -ForegroundColor Yellow
Write-Host ""

# Verifica se Java è installato
$javaPath = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $javaPath) {
    Write-Host "ERRORE: 'keytool' non trovato." -ForegroundColor Red
    Write-Host "Assicurati di avere Java JDK installato e keytool nel PATH." -ForegroundColor Red
    Write-Host ""
    Write-Host "Puoi scaricare Java JDK da: https://adoptium.net/" -ForegroundColor Cyan
    exit 1
}

# Verifica se esiste già una keystore
if (Test-Path $keystorePath) {
    Write-Host "Attenzione: Una keystore esiste già in questo percorso." -ForegroundColor Yellow
    $response = Read-Host "Vuoi sovrascriverla? (s/n)"
    if ($response -ne 's' -and $response -ne 'S') {
        Write-Host "Operazione annullata." -ForegroundColor Yellow
        exit 0
    }
}

# Crea la keystore
Write-Host "Generazione keystore in corso..." -ForegroundColor Cyan

$keytoolArgs = @(
    "-genkey",
    "-v",
    "-keystore", $keystorePath,
    "-storepass", $keystorePassword,
    "-alias", $keyAlias,
    "-keypass", $keyPassword,
    "-keyalg", "RSA",
    "-keysize", "2048",
    "-validity", "10000",
    "-dname", "CN=Musly, OU=Dev, O=Musly, L=Unknown, ST=Unknown, C=IT"
)

try {
    & keytool $keytoolArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "Keystore creata con successo!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Prossimi passaggi:" -ForegroundColor Cyan
        Write-Host "1. Crea il file 'android/key.properties' con questo contenuto:" -ForegroundColor White
        Write-Host ""
        Write-Host "storePassword=MuslyApp2024!"
        Write-Host "keyPassword=MuslyApp2024!"
        Write-Host "keyAlias=musly"
        Write-Host "storeFile=musly-release.keystore"
        Write-Host ""
        Write-Host "2. Aggiungi la keystore base64 a GitHub Secrets:" -ForegroundColor White
        Write-Host "   - Vai su: https://github.com/dddevid/Musly/settings/secrets/actions"
        Write-Host "   - Crea un nuovo secret chiamato: ANDROID_KEYSTORE_BASE64"
        Write-Host "   - Valore: (vedi sotto)"
        Write-Host ""
        Write-Host "Per convertire la keystore in base64, esegui:" -ForegroundColor Yellow
        Write-Host "[Convert]::ToBase64String([IO.File]::ReadAllBytes('$keystorePath'))" -ForegroundColor White
        Write-Host ""
        Write-Host "Oppure su Linux/Mac:" -ForegroundColor Yellow
        Write-Host "base64 -w 0 $keystorePath" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "ERRORE: Creazione keystore fallita." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERRORE: $_" -ForegroundColor Red
    exit 1
}
