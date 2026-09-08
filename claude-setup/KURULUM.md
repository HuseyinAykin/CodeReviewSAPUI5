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

## 4. Kurmadan kullanmak — `/add-dir` ve symlink

Kopyalamak istemiyorsan, klonu olduğu yerde bırakıp Claude Code'a gösterebilirsin.
Dokümantasyon bunu açıkça destekliyor:

> `--add-dir` ve `/add-dir` dosya erişimi verir, konfigürasyon keşfi değil —
> **ancak skill'ler ve komutlar istisnadır: Claude Code eklenen her dizindeki
> `.claude/skills/` ve `.claude/commands/` klasörlerini otomatik yükler.**

Bu repo kökünde `.claude/skills/fiori-modernizasyon/` bulunduğu için, klasörü eklemen yeterli:

```
/add-dir "C:\Users\<sen>\...\Claude\CodeReviewSAPUI5"
```

Sonra `/fiori-modernizasyon` kullanılabilir hale gelir.

**Kısıtı:** `/add-dir` oturum başınadır — her yeni Claude Code oturumunda tekrar yazman
gerekir. Kalıcı istiyorsan CLI'ı `--add-dir` parametresiyle başlat, ya da aşağıdaki
symlink yöntemini kullan.

### Symlink — kur ama kopyalama

Dokümantasyondan:

> Enterprise, personal veya project konumlarındaki bir `<skill-name>` girdisi, diskteki
> başka bir dizine **symlink** olabilir. Claude Code symlink'i takip eder ve `SKILL.md`'yi
> hedef dizinden okur.

Böylece `git pull` yaptığında skill de kendiliğinden güncellenir — kurulumu tekrarlamana
gerek kalmaz.

```powershell
# Windows — yönetici PowerShell veya Developer Mode açık olmalı
New-Item -ItemType SymbolicLink `
  -Path  "$HOME\.claude\skills\fiori-modernizasyon" `
  -Target "C:\Users\<sen>\...\Claude\CodeReviewSAPUI5\.claude\skills\fiori-modernizasyon"
```

```bash
# macOS / Linux
ln -s ~/CodeReviewSAPUI5/.claude/skills/fiori-modernizasyon \
      ~/.claude/skills/fiori-modernizasyon
```

⚠️ Symlink'te `PLAYBOOK.md` skill klasörüne kopyalanmaz; `SKILL.md` bu durumda reponun
kökündeki `SAPUI5-MODERNIZATION-PLAYBOOK.md` dosyasını kullanır — ikisi de çalışır.

### Hangisini seçmeli?

| Yöntem | Kalıcı mı | Güncelleme | OneDrive riski |
|---|---|---|---|
| **`install.ps1 -User`** *(önerilen)* | ✅ Her oturumda | `git pull` + `-User -Force` | ❌ Yok — dosyalar `C:\Users\<sen>\.claude\` altına kopyalanır |
| Symlink | ✅ Her oturumda | `git pull` yeter | ⚠️ Klon OneDrive'daysa okuma oradan yapılır |
| `/add-dir` | ❌ Oturum başına | `git pull` yeter | ⚠️ Aynı |

**OneDrive notu:** Klonun OneDrive altındaysa ve "Files On-Demand" açıksa, dosyalar
yalnızca bulutta duruyor olabilir. Claude Code okumaya çalıştığında OneDrive önce indirir —
çalışır ama yavaşlar, çevrimdışıyken de takılabilir. `install.ps1 -User` bu sorunu
tamamen ortadan kaldırır çünkü dosyaları OneDrive dışına kopyalar.

---

## Komut modları

Argüman iki bağımsız eksenden oluşur: **eylem** (kod değişsin mi?) ve **kapsam** (nereye bakılsın?).

| Komut | Kod değişir mi | Kapsam |
|---|---|---|
| `/fiori-modernizasyon` | ❌ Hayır | Tümü |
| `/fiori-modernizasyon startup` | ❌ Hayır | Startup |
| `/fiori-modernizasyon odata` | ❌ Hayır | OData V2 |
| `/fiori-modernizasyon tablo` | ❌ Hayır | Tablo/liste |
| `/fiori-modernizasyon UX-003` | ❌ Hayır | Tek issue |
| **`/fiori-modernizasyon duzelt`** | ✅ **Evet** | Tümü (Quick Win'ler) |
| **`/fiori-modernizasyon duzelt startup`** | ✅ **Evet** | Sadece startup |
| **`/fiori-modernizasyon duzelt UX-003`** | ✅ **Evet** | Sadece UX-003 |

**Kodu değiştiren tek kelime `duzelt`.** Geçmiyorsa hiçbir dosyaya dokunulmaz.

### `duzelt` ne yapar, ne yapmaz

**Yapar:** düşük riskli, ölçülebilir kazançlı düzeltmeleri uygular — kullanılmayan lib
temizliği, `$select` ekleme, lazy dialog, formatter cache, ölü kod, deprecated API,
memory leak.

**Yapmaz:**
- Business behaviour'ı etkileyen değişiklikleri **sormadan** uygulamaz
  (`flexEnabled`, `refreshAfterChange`, `defaultCountMode`, `sap-value-list`,
  `$select` daraltması, client→server filtreleme)
- UX-001'i (business/tax logic'i backend'e taşıma) **asla tek başına** yapmaz
- Kapsam dışına çıkmaz — `duzelt startup` dediysen OData bulgularını raporlar ama uygulamaz

### "Hepsini birden değiştir" modu neden yok

Tek komutla onlarca dosya değiştiğinde, bir regresyon çıktığında hangi değişikliğin
sebep olduğunu bulamazsın. Production uygulamasında bunun bedeli kazançtan büyüktür.

"Hepsini uygula" demek istiyorsan yine de yapabilirsin — skill kapsamı reddetmez, ama
grup grup ilerler: bir kategori uygular, gösterir, onay alır, sonrakine geçer.

### `duzelt` öncesi

Skill kod değiştirmeden önce `git status` kontrol eder ve çalışma alanın kirliyse uyarır.
Yine de alışkanlık haline getir:

```bash
git status          # temiz olmalı
git checkout -b fiori-modernizasyon
```

Böylece beğenmezsen `git checkout .` ile tek komutta geri alırsın.

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

## En son çare: elle okutmak

Skill hiç kurulmadıysa ve `/add-dir` de kullanmıyorsan, playbook'u doğrudan gösterebilirsin.
Her oturumda tekrar yazman gerekir ve 1400 satırın tamamı context'e girer — bu yüzden
sadece tek seferlik bir bakış için mantıklı:

```
"C:\Users\<sen>\...\Claude\CodeReviewSAPUI5\SAPUI5-MODERNIZATION-PLAYBOOK.md"
dosyasını oku. Bölüm 3'teki master prompt'a göre bu uygulamayı analiz et.
Önce Bölüm 4'e göre startup lifecycle'ı çıkar, sonra refactor planı üret.
```
