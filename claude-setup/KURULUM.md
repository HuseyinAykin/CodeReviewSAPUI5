# Kurulum — Mevcut bir Fiori uygulamasında kullanma

> **Önemli:** Bir `.md` dosyası kendi başına "çalıştırılamaz". Ama Claude Code'da onu
> `/komut` yazarak tetiklenebilir hale getirmenin yolu var: **skill**.
> Bu klasör tam olarak onu kuruyor.

## 1. Repoyu nereye klonlayacaksın?

**Uygulamanın DIŞINA.** İçine klonlarsan uygulamanın git deposunun içinde ikinci bir git deposu oluşur; `git status` kirlenir, playbook yanlışlıkla deploy paketine girebilir.

**Ve OneDrive'ın dışına.** OneDrive senkronizasyonu git depolarıyla iyi geçinmez — dosya kilitleri, senkron çakışmaları ve uzun yol sorunları çıkarır.

Windows'ta önerilen konum:

```
C:\dev\CodeReviewSAPUI5
```

veya

```
C:\Users\<kullanici-adin>\CodeReviewSAPUI5
```

```powershell
git clone https://github.com/HuseyinAykin/CodeReviewSAPUI5.git C:\dev\CodeReviewSAPUI5
```

Klon **bir kere** yapılır; bütün uygulamaların için aynı klonu kullanırsın.

---

## 2. Skill'i nereye kuracaksın?

Claude Code skill'leri üç seviyede arar:

| Seviye | Konum | Kapsam |
|---|---|---|
| **Kullanıcı** | `~/.claude/skills/` → Windows'ta `C:\Users\<sen>\.claude\skills\` | **Bütün projelerin** |
| Proje | `<proje>/.claude/skills/` | Sadece o proje |
| — | Başlattığın dizin **ve repo köküne kadar her üst dizin** taranır | — |

### Birden fazla uygulaman varsa: kullanıcı seviyesi

Örneğin uygulamaların şöyle duruyorsa:

```
...\ddms\UI\apps\
    ├── uygulama-a\
    ├── uygulama-b\
    └── uygulama-c\
```

Tek tek kurmak yerine **bir kere kullanıcı seviyesine kur**, hepsinde çalışsın:

```powershell
cd C:\dev\CodeReviewSAPUI5
.\claude-setup\install.ps1 -User
```

Bu, `C:\Users\<sen>\.claude\skills\fiori-modernizasyon\` altına kurar. Hangi uygulamayı açarsan aç `/fiori-modernizasyon` çalışır. OneDrive'a da bulaşmaz.

### Alternatif: `apps` klasörü seviyesi

Skill'ler başlattığın dizinden **repo köküne kadar** her üst dizinde aranır. `apps` bir git deposunun içindeyse, skill'i `apps\` seviyesine kurarsan altındaki bütün uygulamalar görür:

```powershell
.\claude-setup\install.ps1 -Target "C:\...\ddms\UI\apps"
```

⚠️ Bu klasör OneDrive altındaysa `.claude` klasörü de senkronize olur. Ekiple paylaşmak istiyorsan avantaj, istemiyorsan gürültü.

### Tek uygulama + tooling config'leri

```powershell
.\claude-setup\install.ps1 -Target "C:\...\apps\uygulama-a" -WithTooling
```

`-WithTooling` sadece proje seviyesinde anlamlıdır (ESLint/Prettier/Karma/CI config'leri projeye aittir), `-User` ile birlikte yok sayılır.

---

## 3. Windows'ta çalıştırma

İki yol var, ikisi de test edildi:

### PowerShell (yerel)

```powershell
cd C:\dev\CodeReviewSAPUI5
.\claude-setup\install.ps1 -User
```

Kurumsal bilgisayarlarda script çalıştırma engelliyse:

```powershell
powershell -ExecutionPolicy Bypass -File .\claude-setup\install.ps1 -User
```

### Git Bash

Git for Windows kuruluysa `install.sh` da çalışır:

```bash
cd /c/dev/CodeReviewSAPUI5
./claude-setup/install.sh --user
```

> macOS / Linux kullanıyorsan sadece `install.sh` var, aynı parametrelerle.

Kurulum sonrası VS Code'da uygulamayı aç, Claude Code oturumunda yaz:

```
/fiori-modernizasyon
```

Komutu görmüyorsan oturumu yeniden başlat.

---

## Komut modları

| Komut | Ne yapar |
|---|---|
| `/fiori-modernizasyon` | **Tam analiz. Kod DEĞİŞTİRMEZ.** Rapor üretir. |
| `/fiori-modernizasyon duzelt` | Analiz + Quick Win'leri uygular (davranış etkisi olanları sorar) |
| `/fiori-modernizasyon startup` | Sadece açılış performansı / startup lifecycle |
| `/fiori-modernizasyon odata` | Sadece OData V2 / network katmanı |
| `/fiori-modernizasyon tablo` | Sadece tablo/liste performansı |
| `/fiori-modernizasyon UX-003` | Sadece o issue maddesi |

**İlk sefer `duzelt` ile başlama.** Önce düz `/fiori-modernizasyon` çalıştır, raporu oku,
neyin değişeceğini gör. Sonra düzeltmeye geç.

## Neden skill, neden `.md` okutmak değil?

| Yöntem | Nasıl | Artı / Eksi |
|---|---|---|
| **Skill** *(önerilen)* | `/fiori-modernizasyon` | ✅ Tek komut. ✅ `PLAYBOOK.md` **sadece gerektiğinde** okunur → context israfı yok. ✅ Argümanla mod seçimi. |
| `CLAUDE.md` | Projenin köküne kopyala | ✅ Her oturumda otomatik yüklenir. ❌ Komut yok, her seferinde ne istediğini yazman gerekir. ❌ Her oturumda context tüketir. |
| Elle okutmak | "`PLAYBOOK.md`'yi oku ve uygula" | ✅ Kurulum gerekmez. ❌ 1400 satırın tamamı context'e girer. ❌ Her seferinde aynı cümleyi yazarsın. |

Skill yaklaşımında `SKILL.md` (~190 satır) yükleniyor; 1400 satırlık `PLAYBOOK.md` ise
ancak Claude'un gerçekten ihtiyacı olan bölümü için okunuyor.

## İkisini birden kullanmak

Skill + `CLAUDE.md` birlikte de çalışır. Kalıcı kuralları (stack kısıtları, "V4 önerme",
"ölçmeden yüzde verme") `CLAUDE.md`'ye koyarsan her oturumda geçerli olur; derin analizi
skill ile tetiklersin.

```powershell
copy C:\dev\CodeReviewSAPUI5\CLAUDE.md C:\...\apps\uygulama-a\CLAUDE.md
```

⚠️ Uygulamanda zaten bir `CLAUDE.md` varsa **üzerine yazma** — içeriği birleştir.

## Güncelleme

Playbook'u güncellediğinde uygulamalardaki kopyaları tazele:

```powershell
cd C:\dev\CodeReviewSAPUI5
git pull
.\claude-setup\install.ps1 -User -Force
```

```bash
# Git Bash / macOS / Linux
cd ~/CodeReviewSAPUI5 && git pull
./claude-setup/install.sh --user --force
```

`--force` olmadan mevcut dosyalar korunur (kurulum betiği hiçbir şeyin üzerine sessizce yazmaz).

## Sorun giderme

**`/fiori-modernizasyon` menüde çıkmıyor:**
- VS Code'da açtığın klasör, `.claude/` dizininin bulunduğu proje kökü mü? Skill proje köküne göre çözülür.
- Claude Code oturumunu yeniden başlat.
- Kullanıcı seviyesine kurduysan `C:\Users\<sen>\.claude\skills\fiori-modernizasyon\SKILL.md` var mı?
- Proje seviyesine kurduysan `<proje>\.claude\skills\fiori-modernizasyon\SKILL.md` var mı?
- `SKILL.md`'nin **ilk satırı** `---` olmalı; değilse dosyanın tamamı içerik sayılır ve komut oluşmaz.

**Skill çalışıyor ama playbook'a bakmıyor:**
Doğrudan söyle: *"PLAYBOOK.md Bölüm 4'ü oku ve startup lifecycle haritasını çıkar."*

**Analiz çok yüzeysel kalıyor:**
Kapsamı daralt. `/fiori-modernizasyon startup` gibi tek konuya odaklanmış çalıştırmalar,
her şeyi birden istemekten daha derin sonuç verir.

## Kurulumsuz alternatif

Tek seferlik bir bakış için kurulum yapmadan da olur — playbook'u uygulamanın yanına
kopyala ve şunu yaz:

```
../CodeReviewSAPUI5/SAPUI5-MODERNIZATION-PLAYBOOK.md dosyasını oku.
Bölüm 3'teki master prompt'a göre bu uygulamayı analiz et.
Önce Bölüm 4'e göre startup lifecycle'ı çıkar, sonra refactor planı üret.
```
