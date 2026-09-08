<#
.SYNOPSIS
    SAPUI5 Fiori Modernizasyon skill'ini kurar (Windows / PowerShell).

.DESCRIPTION
    İki kurulum seviyesi:
      -User            -> $HOME\.claude\skills\  -> BUTUN projelerinde calisir (onerilen)
      -Target <dizin>  -> <dizin>\.claude\skills\ -> sadece o proje

.EXAMPLE
    .\install.ps1 -User

.EXAMPLE
    .\install.ps1 -Target "C:\...\ddms\UI\apps\benim-uygulamam" -WithTooling

.EXAMPLE
    .\install.ps1 -User -Force        # guncelleme: mevcut dosyalarin uzerine yaz
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Target,

    [switch]$User,
    [switch]$WithTooling,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = Split-Path -Parent $ScriptDir

function Show-Usage {
    Write-Host @"
Kullanim:
  .\install.ps1 -User [-Force]
      Skill'i $HOME\.claude\skills\ altina kurar. BUTUN projelerinde kullanilabilir.
      Birden fazla uygulaman varsa onerilen yontem budur.

  .\install.ps1 -Target <hedef-proje-dizini> [-WithTooling] [-Force]
      Skill'i sadece o projeye kurar.
      -WithTooling  ESLint / Prettier / Karma / CI workflow dosyalarini da kopyalar.

  -Force   Hedefte var olan dosyalarin uzerine yazar (guncelleme icin).
"@
    exit 1
}

# --- Seviye secimi ---
if ($User) {
    if ($Target) {
        Write-Error "-User ile birlikte hedef dizin verilemez. Birini sec."
        exit 1
    }
    if ($WithTooling) {
        Write-Host "UYARI: -WithTooling proje seviyesindedir, -User ile birlikte yok sayildi."
        Write-Host "       Config dosyalari icin: .\install.ps1 -Target <uygulaman> -WithTooling"
        $WithTooling = $false
    }
    $SkillRoot  = Join-Path $HOME ".claude/skills"
    $ScopeLabel = "kullanici seviyesi (butun projeler)"
}
else {
    if (-not $Target) { Show-Usage }
    if (-not (Test-Path -LiteralPath $Target -PathType Container)) {
        Write-Error "'$Target' dizini bulunamadi."
        exit 1
    }
    $Target = (Resolve-Path -LiteralPath $Target).Path

    if ($Target -eq $RepoRoot) {
        Write-Error "Hedef, bu playbook reposunun kendisi. Hedef UI5 uygulaman olmali."
        exit 1
    }

    $manifest = Get-ChildItem -LiteralPath $Target -Filter manifest.json -Recurse -Depth 3 -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '[\\/](node_modules|dist)[\\/]' } |
                Select-Object -First 1
    if (-not $manifest) {
        Write-Host "UYARI: '$Target' altinda manifest.json bulunamadi. Kuruluma devam ediliyor."
    }

    $SkillRoot  = Join-Path $Target ".claude/skills"
    $ScopeLabel = "proje seviyesi ($Target)"
}

$SkillDir = Join-Path $SkillRoot "fiori-modernizasyon"
New-Item -ItemType Directory -Path $SkillDir -Force | Out-Null

function Copy-One {
    param([string]$Src, [string]$Dst)

    if (-not (Test-Path -LiteralPath $Src -PathType Leaf)) {
        Write-Host "  ! kaynak yok, atlandi: $Src"
        return
    }
    if ((Test-Path -LiteralPath $Dst -PathType Leaf) -and (-not $Force)) {
        Write-Host "  = zaten var, korundu: $Dst   (guncellemek icin -Force)"
        return
    }
    $parent = Split-Path -Parent $Dst
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $Src -Destination $Dst -Force
    Write-Host "  + $Dst"
}

Write-Host ""
Write-Host "Kurulum seviyesi: $ScopeLabel"
Write-Host ""
Write-Host "Skill kuruluyor:"
Copy-One (Join-Path $RepoRoot  ".claude/skills/fiori-modernizasyon/SKILL.md") (Join-Path $SkillDir "SKILL.md")
Copy-One (Join-Path $RepoRoot  "SAPUI5-MODERNIZATION-PLAYBOOK.md")            (Join-Path $SkillDir "PLAYBOOK.md")
Copy-One (Join-Path $RepoRoot  "templates/ANALYSIS-REPORT-TEMPLATE.md")       (Join-Path $SkillDir "RAPOR-SABLONU.md")

if ($WithTooling) {
    Write-Host ""
    Write-Host "Tooling config'leri kuruluyor:"
    Copy-One (Join-Path $RepoRoot "templates/eslint.config.js")           (Join-Path $Target "eslint.config.js")
    Copy-One (Join-Path $RepoRoot "templates/.prettierrc.json")           (Join-Path $Target ".prettierrc.json")
    Copy-One (Join-Path $RepoRoot "templates/.prettierignore")            (Join-Path $Target ".prettierignore")
    Copy-One (Join-Path $RepoRoot "templates/karma.conf.js")              (Join-Path $Target "karma.conf.js")
    Copy-One (Join-Path $RepoRoot "templates/github-workflow-verify.yml") (Join-Path $Target ".github/workflows/verify.yml")
    Write-Host ""
    Write-Host "  NOT: package.json script'leri OTOMATIK eklenmedi."
    Write-Host "       templates\package-scripts.jsonc dosyasini elle birlestir."
}

Write-Host @"

Kurulum tamam.

VS Code'da Claude Code oturumunda:

  /fiori-modernizasyon           -> tam analiz, kod degistirmez
  /fiori-modernizasyon duzelt    -> analiz + Quick Win'leri uygular
  /fiori-modernizasyon startup   -> sadece acilis performansi
  /fiori-modernizasyon odata     -> sadece OData V2 katmani
  /fiori-modernizasyon UX-001    -> sadece o issue

Komutu gormuyorsan Claude Code oturumunu yeniden baslat.
"@
