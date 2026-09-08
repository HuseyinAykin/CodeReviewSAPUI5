#!/usr/bin/env bash
#
# SAPUI5 Fiori Modernizasyon skill'ini kurar.
#
# İKİ KURULUM SEVİYESİ:
#   --user            → ~/.claude/skills/  → BÜTÜN projelerinde çalışır (önerilen)
#   <hedef-dizin>     → <hedef>/.claude/skills/  → sadece o proje
#
# Kullanım:
#   ./install.sh --user
#   ./install.sh --user --force
#   ./install.sh /yol/fiori-uygulaman
#   ./install.sh /yol/fiori-uygulaman --with-tooling
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TARGET=""
USER_LEVEL=0
WITH_TOOLING=0
FORCE=0

for arg in "$@"; do
    case "$arg" in
        --user)         USER_LEVEL=1 ;;
        --with-tooling) WITH_TOOLING=1 ;;
        --force)        FORCE=1 ;;
        -h|--help)      TARGET="__help__" ;;
        -*)             echo "Bilinmeyen parametre: $arg" >&2; exit 1 ;;
        *)              TARGET="$arg" ;;
    esac
done

usage() {
    cat >&2 <<'USAGE'
Kullanım:
  ./install.sh --user [--force]
      Skill'i ~/.claude/skills/ altına kurar. BÜTÜN projelerinde kullanılabilir.
      Birden fazla uygulaman varsa önerilen yöntem budur.

  ./install.sh <hedef-proje-dizini> [--with-tooling] [--force]
      Skill'i sadece o projeye kurar (<hedef>/.claude/skills/).
      --with-tooling  ESLint / Prettier / Karma / CI workflow dosyalarını da kopyalar.

  --force   Hedefte var olan dosyaların üzerine yazar (güncelleme için).
USAGE
    exit 1
}

[ "$TARGET" = "__help__" ] && usage

if [ "$USER_LEVEL" -eq 1 ]; then
    if [ -n "$TARGET" ]; then
        echo "HATA: --user ile birlikte hedef dizin verilemez. Birini seç." >&2
        exit 1
    fi
    if [ "$WITH_TOOLING" -eq 1 ]; then
        echo "UYARI: --with-tooling proje seviyesindedir, --user ile birlikte yok sayıldı."
        echo "       Config dosyaları için: ./install.sh /yol/uygulaman --with-tooling"
        WITH_TOOLING=0
    fi
    SKILL_ROOT="$HOME/.claude/skills"
    SCOPE_LABEL="kullanıcı seviyesi (bütün projeler)"
else
    [ -z "$TARGET" ] && usage
    [ ! -d "$TARGET" ] && { echo "HATA: '$TARGET' dizini bulunamadı." >&2; exit 1; }
    TARGET="$(cd "$TARGET" && pwd)"
    if [ "$TARGET" = "$REPO_ROOT" ]; then
        echo "HATA: Hedef, bu playbook reposunun kendisi. Hedef UI5 uygulaman olmalı." >&2
        exit 1
    fi
    if ! find "$TARGET" -maxdepth 4 -name manifest.json \
         -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | grep -q .; then
        echo "UYARI: '$TARGET' altında manifest.json bulunamadı. Kuruluma devam ediliyor."
    fi
    SKILL_ROOT="$TARGET/.claude/skills"
    SCOPE_LABEL="proje seviyesi ($TARGET)"
fi

SKILL_DIR="$SKILL_ROOT/fiori-modernizasyon"
mkdir -p "$SKILL_DIR"

copy_file() {
    local src="$1" dst="$2"
    if [ ! -f "$src" ]; then
        echo "  ! kaynak yok, atlandı: $src"
        return
    fi
    if [ -f "$dst" ] && [ "$FORCE" -eq 0 ]; then
        echo "  = zaten var, korundu: $dst   (güncellemek için --force)"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  + $dst"
}

echo ""
echo "Kurulum seviyesi: $SCOPE_LABEL"
echo ""
echo "Skill kuruluyor:"
copy_file "$REPO_ROOT/.claude/skills/fiori-modernizasyon/SKILL.md" "$SKILL_DIR/SKILL.md"
copy_file "$REPO_ROOT/SAPUI5-MODERNIZATION-PLAYBOOK.md"             "$SKILL_DIR/PLAYBOOK.md"
copy_file "$REPO_ROOT/templates/ANALYSIS-REPORT-TEMPLATE.md"        "$SKILL_DIR/RAPOR-SABLONU.md"

if [ "$WITH_TOOLING" -eq 1 ]; then
    echo ""
    echo "Tooling config'leri kuruluyor:"
    copy_file "$REPO_ROOT/templates/eslint.config.js"           "$TARGET/eslint.config.js"
    copy_file "$REPO_ROOT/templates/.prettierrc.json"           "$TARGET/.prettierrc.json"
    copy_file "$REPO_ROOT/templates/.prettierignore"            "$TARGET/.prettierignore"
    copy_file "$REPO_ROOT/templates/karma.conf.js"              "$TARGET/karma.conf.js"
    copy_file "$REPO_ROOT/templates/github-workflow-verify.yml" "$TARGET/.github/workflows/verify.yml"
    echo ""
    echo "  NOT: package.json script'leri OTOMATİK eklenmedi."
    echo "       templates/package-scripts.jsonc dosyasını elle birleştir."
fi

cat <<'EOF'

Kurulum tamam.

VS Code'da Claude Code oturumunda:

  /fiori-modernizasyon           → tam analiz, kod değiştirmez
  /fiori-modernizasyon duzelt    → analiz + Quick Win'leri uygular
  /fiori-modernizasyon startup   → sadece açılış performansı
  /fiori-modernizasyon odata     → sadece OData V2 katmanı
  /fiori-modernizasyon UX-001    → sadece o issue

Komutu görmüyorsan Claude Code oturumunu yeniden başlat.
EOF
