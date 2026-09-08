#!/usr/bin/env bash
#
# SAPUI5 Fiori Modernizasyon skill'ini mevcut bir UI5 projesine kurar.
#
# Kullanım:
#   ./install.sh /yol/uygulama-projesi
#   ./install.sh /yol/uygulama-projesi --with-tooling   # ESLint/Prettier/Karma/CI de kur
#   ./install.sh /yol/uygulama-projesi --force          # mevcut dosyaların üzerine yaz
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET="${1:-}"
WITH_TOOLING=0
FORCE=0

for arg in "${@:2}"; do
    case "$arg" in
        --with-tooling) WITH_TOOLING=1 ;;
        --force)        FORCE=1 ;;
        *) echo "Bilinmeyen parametre: $arg" >&2; exit 1 ;;
    esac
done

if [ -z "$TARGET" ]; then
    cat >&2 <<'USAGE'
Kullanım: ./install.sh <hedef-proje-dizini> [--with-tooling] [--force]

  <hedef-proje-dizini>  SAPUI5 uygulamanızın kök dizini
  --with-tooling        ESLint / Prettier / Karma / CI workflow dosyalarını da kopyalar
  --force               Hedefte var olan dosyaların üzerine yazar
USAGE
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "HATA: '$TARGET' dizini bulunamadı." >&2
    exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

if [ "$TARGET" = "$REPO_ROOT" ]; then
    echo "HATA: Hedef, bu playbook reposunun kendisi. Kurulum hedefi UI5 uygulaman olmalı." >&2
    exit 1
fi

# --- Bilgilendirme: hedef bir UI5 projesi gibi görünüyor mu? ---
if ! find "$TARGET" -name manifest.json -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | grep -q .; then
    echo "UYARI: '$TARGET' altında manifest.json bulunamadı. Yine de kuruluma devam ediliyor."
fi

SKILL_DIR="$TARGET/.claude/skills/fiori-modernizasyon"
mkdir -p "$SKILL_DIR"

# --- Kopyalama yardımcısı: --force yoksa üzerine yazma ---
copy_file() {
    local src="$1" dst="$2"
    if [ ! -f "$src" ]; then
        echo "  ! kaynak yok, atlandı: $src"
        return
    fi
    if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
        echo "  = zaten var, korundu: ${dst#$TARGET/}   (üzerine yazmak için --force)"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  + ${dst#$TARGET/}"
}

echo ""
echo "Hedef: $TARGET"
echo ""
echo "Skill kuruluyor:"
copy_file "$SCRIPT_DIR/.claude/skills/fiori-modernizasyon/SKILL.md" "$SKILL_DIR/SKILL.md"
copy_file "$REPO_ROOT/SAPUI5-MODERNIZATION-PLAYBOOK.md"             "$SKILL_DIR/PLAYBOOK.md"
copy_file "$REPO_ROOT/templates/ANALYSIS-REPORT-TEMPLATE.md"        "$SKILL_DIR/RAPOR-SABLONU.md"

if [ "$WITH_TOOLING" -eq 1 ]; then
    echo ""
    echo "Tooling config'leri kuruluyor:"
    copy_file "$REPO_ROOT/templates/eslint.config.js"          "$TARGET/eslint.config.js"
    copy_file "$REPO_ROOT/templates/.prettierrc.json"          "$TARGET/.prettierrc.json"
    copy_file "$REPO_ROOT/templates/.prettierignore"           "$TARGET/.prettierignore"
    copy_file "$REPO_ROOT/templates/karma.conf.js"             "$TARGET/karma.conf.js"
    copy_file "$REPO_ROOT/templates/github-workflow-verify.yml" "$TARGET/.github/workflows/verify.yml"
    echo ""
    echo "  NOT: package.json script'leri OTOMATİK eklenmedi."
    echo "       templates/package-scripts.jsonc dosyasını elle birleştir."
fi

cat <<EOF

Kurulum tamam.

Kullanım (VS Code'da Claude Code oturumunda):

  /fiori-modernizasyon           → tam analiz, kod değiştirmez
  /fiori-modernizasyon duzelt    → analiz + Quick Win'leri uygular
  /fiori-modernizasyon startup   → sadece açılış performansı
  /fiori-modernizasyon odata     → sadece OData V2 katmanı
  /fiori-modernizasyon UX-001    → sadece o issue

Skill'i görmüyorsan Claude Code oturumunu yeniden başlat ve
projeyi '$TARGET' kökünden açtığından emin ol.
EOF
