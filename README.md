# CodeReviewSAPUI5

SAP Fiori / SAPUI5 uygulamaları için kalıcı **modernizasyon & code review referans dokümanı**.

## Ana doküman

📘 **[SAPUI5-MODERNIZATION-PLAYBOOK.md](./SAPUI5-MODERNIZATION-PLAYBOOK.md)**

## Kapsadığı stack

| | |
|---|---|
| SAPUI5 Runtime | 1.120.42 |
| OData | V2 |
| Deployment | SAP BTP Cloud Foundry (HTML5 App Repo + approuter) |
| Launchpad | SAP Build Work Zone |
| Application Type | Freestyle SAPUI5 |
| Backend | S/4HANA On-Premise |

## İçerik

- **Master Prompt** — yeni analiz oturumu başlatmak için kopyala-yapıştır
- **Startup Lifecycle Haritası** — approuter isteğinden ilk tablo `$batch`'ine kadar 5 fazlı critical path analizi
- **18 kategorili audit checklist** — startup, OData, table, rendering, memory, security, a11y, build, cache, Clean Core
- **UX-001…UX-006 issue mapping** — issue list maddelerinin bu stack için değerlendirmesi + çözüm desenleri
- **Deprecated → Modern API tablosu** — 1.120'ye özel (`sap.ui.getCore()`, `jQuery.sap.*`, sync view/fragment API'leri)
- **Refactor önceliklendirme matrisi** — etki/maliyet, 17 adımlık sıralı plan
- **Pattern kütüphanesi** — ÖNCE/SONRA production-ready kod örnekleri
- **Ölçüm protokolü** — kazanç iddiasını doğrulama araçları ve şablonu
- **Rapor şablonu** ve **hedef mimari**
- **Anti-öneriler** — bilinçli olarak yapılmaması gerekenler

## Hazır config'ler

📁 **[`templates/`](./templates/)** — projeye doğrudan kopyalanabilir dosyalar:
ESLint (SAPUI5 anti-pattern kurallarıyla), Prettier, `ui5.yaml`, `ui5-deploy.yaml`,
Karma, `package.json` script'leri, CI workflow ve analiz rapor şablonu.

Bu klasör **UX-006**'yı (statik analiz eksikliği) uygulama kodu görülmeden kapatır.

## Kullanım

### 1. Manuel (herhangi bir Claude oturumunda)

Playbook'un **Bölüm 3 — Master Prompt**'unu kopyalayıp yeni oturumun ilk mesajı olarak ver, ardından proje dosyalarını sırayla gönder.

Önerilen dosya inceleme sırası:
```
manifest.json → Component.js → ui5.yaml / package.json / xs-app.json
→ routing target'ları → root view → ana tablo view'u → ilgili controller
→ formatter/util → fragment'lar → geri kalan controller'lar
```

### 2. Claude Code skill'i olarak *(önerilen)*

Repoyu **uygulamanın dışına** klonla (OneDrive dışına), sonra skill'i kur:

```powershell
# Windows / PowerShell
git clone https://github.com/HuseyinAykin/CodeReviewSAPUI5.git C:\dev\CodeReviewSAPUI5
cd C:\dev\CodeReviewSAPUI5
.\claude-setup\install.ps1 -User
```

```bash
# Git Bash / macOS / Linux
git clone https://github.com/HuseyinAykin/CodeReviewSAPUI5.git ~/CodeReviewSAPUI5
cd ~/CodeReviewSAPUI5
./claude-setup/install.sh --user
```

`--user` / `-User` skill'i `~/.claude/skills/` altına kurar → **bütün projelerinde** çalışır.
Tek bir projeye kurmak ve tooling config'lerini de almak için:

```bash
./claude-setup/install.sh /yol/uygulaman --with-tooling
```

Sonra VS Code'da uygulamayı aç ve yaz:

| Komut | Ne yapar |
|---|---|
| `/fiori-modernizasyon` | Tam analiz, kod değiştirmez |
| `/fiori-modernizasyon duzelt` | Analiz + Quick Win'leri uygular |
| `/fiori-modernizasyon startup` | Sadece açılış performansı |
| `/fiori-modernizasyon odata` | Sadece OData V2 katmanı |
| `/fiori-modernizasyon UX-003` | Sadece o issue |

**Kurmak istemiyorsan:** bu repo kökünde `.claude/skills/` bulunduğu için klasörü
Claude Code'a göstermen de yeterli — `/add-dir "<klon-yolu>"` yaz, `/fiori-modernizasyon`
kullanılabilir hale gelsin. (Oturum başınadır; kalıcı istersen symlink kur.)

Detay, kurulum konumları, symlink ve sorun giderme: 📖 **[`claude-setup/KURULUM.md`](./claude-setup/KURULUM.md)**

### 3. Statik analiz ile başla

Manuel review'a girmeden önce otomatize edilebilen kısmı çalıştır:

```bash
npx ui5lint --details      # deprecated UI5 API + global sap.* erişimi + sync loading
npx eslint webapp --ext .js
npx ui5 build --clean-dest && ls -lh dist/Component-preload.js
```

## Temel ilke

> **Modern kod = yeni syntax kullanmak değildir.**
> Modern kod; daha az dependency, daha az request, daha az render,
> daha az lifecycle side-effect ve SAPUI5 binding mekanizmasını doğru kullanmak demektir.

Her öneri için 3 kontrol:
1. Kazanç **ölçülebilir** mi? (ms / KB / request sayısı)
2. Framework bunu **zaten yapıyor** mu?
3. **Business behaviour** değişiyor mu? Değişiyorsa açıkça yazılmalı.

Üçünden biri sağlanmıyorsa öneri yazılmaz.
