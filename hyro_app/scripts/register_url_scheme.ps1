# ═══════════════════════════════════════════════════════════════════
# Registra el esquema personalizado io.supabase.hyroapp:// en Windows
# para que el navegador pueda redirigir de vuelta a la app.
#
# USO: Ejecutar como Administrador (o usuario normal para HKCU)
#   powershell -ExecutionPolicy Bypass -File .\register_url_scheme.ps1
# ═══════════════════════════════════════════════════════════════════

param(
    [string]$ExePath
)

$scheme = "io.supabase.hyroapp"

# Si no se pasa la ruta del exe, intentamos encontrarla automáticamente
if (-not $ExePath) {
    # Buscar en la carpeta de build de Flutter
    $buildDir = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Release"
    $candidate = Join-Path $buildDir "hyro_app.exe"

    if (Test-Path $candidate) {
        $ExePath = (Resolve-Path $candidate).Path
    } else {
        # Intentar con Debug
        $buildDir = Join-Path $PSScriptRoot "..\build\windows\x64\runner\Debug"
        $candidate = Join-Path $buildDir "hyro_app.exe"
        if (Test-Path $candidate) {
            $ExePath = (Resolve-Path $candidate).Path
        } else {
            Write-Host "ERROR: No se encontro hyro_app.exe" -ForegroundColor Red
            Write-Host "Usa: .\register_url_scheme.ps1 -ExePath 'C:\ruta\a\hyro_app.exe'"
            exit 1
        }
    }
}

Write-Host "Registrando esquema '$scheme' -> $ExePath" -ForegroundColor Cyan

# Crear las llaves en HKCU (no requiere admin)
$basePath = "HKCU:\Software\Classes\$scheme"

New-Item -Path $basePath -Force | Out-Null
Set-ItemProperty -Path $basePath -Name "(Default)" -Value "Hyro App"
Set-ItemProperty -Path $basePath -Name "URL Protocol" -Value ""

New-Item -Path "$basePath\DefaultIcon" -Force | Out-Null
Set-ItemProperty -Path "$basePath\DefaultIcon" -Name "(Default)" -Value "`"$ExePath`",0"

New-Item -Path "$basePath\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path "$basePath\shell\open\command" -Name "(Default)" -Value "`"$ExePath`" `"%1`""

Write-Host "Listo! El esquema '${scheme}://' ahora abre hyro_app.exe" -ForegroundColor Green
Write-Host ""
Write-Host "Para verificar, abre el navegador y ve a:" -ForegroundColor Yellow
Write-Host "  ${scheme}://test" -ForegroundColor Yellow
