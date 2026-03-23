# 1. El esquema es el mismo para todos
$scheme = "io.supabase.hyroapp"

# 2. ¡OJO AQUÍ! Cambiar esta ruta por la ruta exacta donde el compañero clonó el proyecto
# Sugerencia: usando la variable de script $PSScriptRoot para autodescubrir la ruta si el script está en la raíz de la app
### $appPath = "C:\Users\rulie\Documents\Hyro-Application\hyro_app\build\windows\x64\runner\Debug\hyro_app.exe"
$appPath = Join-Path -Path $PSScriptRoot -ChildPath "build\windows\x64\runner\Debug\hyro_app.exe"

# O puedes descomentar la línea de abajo y poner tu ruta a mano si prefieres:
# $appPath = "C:\Users\tu_usuario\Ruta\Al\Proyecto\build\windows\x64\runner\Debug\hyro_app.exe"

if (-Not (Test-Path $appPath)) {
    Write-Host "¡Advertencia! No se encontró el ejecutable en: $appPath" -ForegroundColor Yellow
    Write-Host "Por favor asegúrate de haber compilado la app (flutter build windows) o cambia la ruta en este script." -ForegroundColor Yellow
}

# 3. Ejecutar la magia
Write-Host "Registrando esquema '$scheme'..." -ForegroundColor Cyan

New-Item -Path "HKCU:\Software\Classes\$scheme" -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Classes\$scheme" -Name "(Default)" -Value "URL:$scheme Protocol" -Force | Out-Null
New-ItemProperty -Path "HKCU:\Software\Classes\$scheme" -Name "URL Protocol" -Value "" -Force | Out-Null
New-Item -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Force | Out-Null

# Nota: El argumento debe estar escapado correctamente "`"$appPath`" `"%1`""
New-ItemProperty -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Name "(Default)" -Value "`"$appPath`" `"%1`"" -Force | Out-Null

Write-Host "¡Registro completado! Listo para programar." -ForegroundColor Green
