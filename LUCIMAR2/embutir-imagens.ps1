# ============================================================================
#  Embute as imagens em base64 dentro do HTML
#  Gera "Lucimar Antunes - Portatil.html" com tudo embutido
#  Uso: clique direito > "Executar com PowerShell"
# ============================================================================

$ErrorActionPreference = "Stop"
$baseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inputHtml = Join-Path $baseDir "Lucimar Antunes.html"
$outputHtml = Join-Path $baseDir "Lucimar Antunes - Portatil.html"

if (-not (Test-Path $inputHtml)) {
    Write-Host "ERRO: arquivo nao encontrado: $inputHtml" -ForegroundColor Red
    Read-Host "Pressione ENTER para sair"
    exit 1
}

Write-Host "Lendo HTML..." -ForegroundColor Cyan
$html = Get-Content -Path $inputHtml -Raw -Encoding UTF8

# Mapa de extensao -> mime type
$mimeMap = @{
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".jfif" = "image/jpeg"
    ".gif"  = "image/gif"
    ".webp" = "image/webp"
    ".svg"  = "image/svg+xml"
}

# Encontra todas as referencias assets/...
$pattern = 'assets/([^"''\)\s]+\.(png|jpg|jpeg|jfif|gif|webp|svg))'
$matches = [regex]::Matches($html, $pattern)

$assetsToEmbed = @{}
foreach ($m in $matches) {
    $relPath = $m.Groups[1].Value
    if (-not $assetsToEmbed.ContainsKey($relPath)) {
        $assetsToEmbed[$relPath] = $true
    }
}

Write-Host "Encontradas $($assetsToEmbed.Count) referencias unicas a imagens:" -ForegroundColor Cyan
foreach ($key in $assetsToEmbed.Keys) {
    Write-Host "  - $key"
}

$replacedCount = 0
foreach ($relPath in $assetsToEmbed.Keys) {
    $fullPath = Join-Path $baseDir "assets\$relPath"
    if (-not (Test-Path $fullPath)) {
        Write-Host "AVISO: arquivo nao encontrado, pulando: $fullPath" -ForegroundColor Yellow
        continue
    }

    $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
    $mime = $mimeMap[$ext]
    if (-not $mime) {
        Write-Host "AVISO: extensao desconhecida $ext, pulando" -ForegroundColor Yellow
        continue
    }

    Write-Host "Convertendo $relPath..." -ForegroundColor Green
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)
    $b64 = [Convert]::ToBase64String($bytes)
    $dataUri = "data:$mime;base64,$b64"

    # Substitui todas as ocorrencias de "assets/<relPath>"
    $needle = "assets/$relPath"
    $html = $html.Replace($needle, $dataUri)
    $replacedCount++
    $sizeKb = [Math]::Round($bytes.Length / 1024, 1)
    Write-Host "  OK ($sizeKb KB)" -ForegroundColor DarkGray
}

Write-Host "Salvando arquivo portatil..." -ForegroundColor Cyan
[System.IO.File]::WriteAllText($outputHtml, $html, [System.Text.UTF8Encoding]::new($false))

$sizeMb = [Math]::Round((Get-Item $outputHtml).Length / 1MB, 2)
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host "  PRONTO! $replacedCount imagens embutidas." -ForegroundColor Green
Write-Host "  Arquivo gerado: Lucimar Antunes - Portatil.html ($sizeMb MB)" -ForegroundColor Green
Write-Host "  Pode mover esse arquivo pra qualquer lugar." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione ENTER para sair"
