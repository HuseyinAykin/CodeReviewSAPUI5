---
name: fiori-modernizasyon
description: SAPUI5 / SAP Fiori uygulamalarını startup performansı, OData V2 request optimizasyonu, controller mimarisi, rendering, memory, güvenlik ve Clean Core açısından analiz eder ve refactor eder. Hedef stack SAPUI5 1.120.x + OData V2 + BTP Cloud Foundry + SAP Build Work Zone + Freestyle + S/4HANA On-Premise. Kullanıcı "fiori analizi", "UI5 review", "uygulamayı hızlandır", "açılış süresi", "startup performansı", "Clean Core review", "controller çok büyük", "gereksiz OData çağrısı" dediğinde veya UX-001…UX-006 issue'larından bahsettiğinde kullan.
argument-hint: "[duzelt] [startup | odata | tablo | UX-001..UX-006]"
allowed-tools: Read Grep Glob
---

# SAPUI5 / Fiori Modernizasyon

## Proje tespiti

Bulunan manifest dosyaları:
```!
find . -name manifest.json -not -path "*/node_modules/*" -not -path "*/dist/*" -not -path "*/.git/*" 2>/dev/null | head -5
```

Controller sayısı ve satır sayıları:
```!
find . -name "*.controller.js" -not -path "*/node_modules/*" -not -path "*/dist/*" 2>/dev/null | head -25 | xargs wc -l 2>/dev/null | sort -rn | head -15
```

Build çıktısı durumu:
```!
ls -lh dist/Component-preload.js 2>/dev/null || echo "dist/Component-preload.js YOK (henuz build alinmamis olabilir)"
```

---

## Mod seçimi

Kullanıcının verdiği argüman: `$ARGUMENTS`

Argüman iki bağımsız eksenden oluşur. İkisi birlikte kullanılabilir.

### Eksen 1 — EYLEM (kod değişiyor mu?)

| Kelime | Ne yap |
|---|---|
| *(yok)* veya `analiz` | **Kod DEĞİŞTİRME.** Sadece analiz et ve rapor üret. **Varsayılan.** |
| `duzelt` | Analiz et, sonra bulguları uygula (kurallar Bölüm 3). |

### Eksen 2 — KAPSAM (nereye bakılıyor?)

| Kelime | Kapsam |
|---|---|
| *(yok)* | Tüm kategoriler |
| `startup` | Startup lifecycle + açılış performansı |
| `odata` | OData V2 / network katmanı |
| `tablo` | Tablo / liste performansı |
| `UX-001` … `UX-006` | Sadece o issue maddesi |

### Örnekler

| Komut | Sonuç |
|---|---|
| `/fiori-modernizasyon` | Tüm kategoriler, sadece analiz |
| `/fiori-modernizasyon startup` | Sadece startup, **sadece analiz** |
| `/fiori-modernizasyon duzelt` | Tüm kategoriler, Quick Win'ler uygulanır |
| `/fiori-modernizasyon duzelt startup` | Sadece startup, o alandaki düzeltmeler uygulanır |
| `/fiori-modernizasyon duzelt UX-003` | Sadece UX-003, düzeltmeleri uygulanır |

**`duzelt` geçmiyorsa hiçbir dosyayı değiştirme** — kapsam kelimesi tek başına asla
düzeltme yetkisi vermez. Argüman anlaşılmıyorsa tüm kapsamda `analiz` yap.

### "Hepsini değiştir" diye bir mod YOK — bu bilinçli

Tek komutla onlarca dosyayı değiştirmek, bir regresyon çıktığında hangi değişikliğin
sebep olduğunu bulmayı imkânsız hale getirir. Production uygulamasında bunun bedeli
kazançtan büyüktür.

Kullanıcı "hepsini uygula" derse: kapsamı reddetme, ama **grup grup ilerle** — her turda
bir kategori uygula, sonucu göster, onay al, sonrakine geç.

---

## 1. Değişmez kurallar — bu stack'e özgü

Bunlar sık yapılan hatalardır. **Asla önerme:**

| ❌ Önerme | Neden |
|---|---|
| OData **V4** ayarları (`autoExpandSelect`, `earlyRequests`, `$$aggregation`, `$$updateGroupId`) | Uygulama **V2** kullanıyor. Bu ayarlar V2 modelinde yok. |
| `sap-ui-cachebuster` / `/sap/bc/ui5_ui5/.../~cachebuster` | ABAP on-premise deployment mekanizması. **CF + HTML5 App Repo'da geçersiz.** Versiyonlama `applicationVersion.version` + repo üzerinden. |
| `index.html` optimizasyonu (Work Zone bağlamında) | FLP uygulamayı **Component olarak** yükler; `index.html` kullanılmaz. Sadece standalone erişim için anlamlı. |
| `sap.m` / `sap.f` / `sap.ui.core` manifest'ten çıkarma | Bunlar FLP tarafından **zaten yüklenmiştir**. Listelemek ek maliyet değildir. Asıl hedef `sap.ui.comp`, `sap.ui.table`, `sap.viz`, `sap.suite.ui.commons`. |
| ESM (`import` / `export`) | UI5 1.x runtime'ında **çalışmaz**. Her modül `sap.ui.define`. (Transpile ayrı bir karar.) |
| Fiori Elements / annotation tabanlı çözümler | Uygulama **Freestyle**. Doğrudan uygulanamaz. |

**Runtime notu:** 1.120 evergreen browser destekler → `const/let`, `?.`, `??`, `async/await` **runtime'da güvenli**. Ama `@ui5/cli` v2 kullanılıyorsa `?.` ve `??` **build aşamasında patlar** — önce `package.json`'daki `@ui5/cli` sürümünü kontrol et.

---

## 2. Çalışma akışı

### Adım 1 — Statik analizi önce çalıştır

Manuel taramaya girmeden önce otomatik olanı çalıştır (kullanıcıdan izin iste):

```
npx ui5lint --details
```

`ui5lint` deprecated API, global `sap.*` erişimi ve senkron yüklemeyi senden daha güvenilir yakalar. Çıktısını rapora baseline olarak koy. Araç kurulu değilse belirt, manuel devam et.

### Adım 2 — Dosyaları bu sırayla oku

```
manifest.json → Component.js → ui5.yaml / package.json / xs-app.json
→ routing target'ları → root view → ana liste/tablo view'u → o view'un controller'ı
→ formatter/util → fragment'lar → kalan controller'lar
```

**Neden bu sıra:** startup critical path bu sırayla oluşur. Controller'dan başlarsan mikro-optimizasyon tuzağına düşersin.

**Dosyaları bağımsız değerlendirme.** Her yeni dosyada önceki dosyalarda gördüğün mimariyi hatırla; uygulamayı tek sistem olarak ele al.

### Adım 3 — Startup lifecycle haritasını çıkar

Lokal optimizasyon yapma. Önce şu zinciri gerçek dosyalardan çıkar:

```
FLP Component load → Component-preload.js → manifest → model creation
→ $metadata → routing → initial view render → ilk tablo $batch
```

Detaylı faz haritası ve sık görülen 10 startup katili: **PLAYBOOK.md Bölüm 4**.

Sonra şu ayrımı net yap:
- **Critical path'te olan** → optimize et
- **Critical path'te olmayan** → lazy-load et

### Adım 4 — Checklist'i uygula

Modun kapsamına giren kategorileri **PLAYBOOK.md Bölüm 5**'ten uygula (18 kategori). Tümünü context'e yükleme — sadece ilgili bölümü oku.

### Adım 5 — Raporla

Çıktı formatı aşağıda (Bölüm 4).

---

## 3. `duzelt` modu — ek kurallar

### Önce güvenlik ağı (atlanmaz)

Tek satır kod değiştirmeden önce çalışma alanının temiz olduğunu doğrula:

```
git status --short
```

- **Commit edilmemiş değişiklik varsa:** kullanıcıya söyle ve önce commit/stash etmesini
  iste. Aksi halde senin değişikliklerin onunkilerle karışır ve geri alınamaz.
- **Git deposu değilse:** bunu belirt ve devam etmeden önce onay al. Geri alma imkânı
  olmadan production kodunu değiştirmek kabul edilemez.

Bu adımı kullanıcı "gerek yok" demedikçe atlama.

### Uygulama kuralları

1. **Önce Quick Win'ler.** Az değişiklik + yüksek kazanç + düşük risk. Sıralama için **PLAYBOOK.md Bölüm 8.1**.
2. **Her değişiklik ayrı ve gerekçeli.** Toplu 40 dosyalık refactor yapma — regresyon kaynağı bulunamaz.
3. **Business behaviour etkisi olan değişiklikleri UYGULAMADAN ÖNCE kullanıcıya sor.** Özellikle:
   - `flexEnabled: false` → key user adaptation / variant kaybolur
   - `refreshAfterChange: false` → CRUD sonrası elle refresh gerekir
   - `defaultCountMode` değişimi → sayfalama davranışı
   - `sap-value-list: "none"` → value help metadata'sı gelmez
   - `$select` daraltması → gizli kolonlar boş gelebilir
   - client-side → server-side filtreleme geçişi → filtre semantiği değişebilir
   - **UX-001 (business/tax logic backend'e taşıma) → her zaman sor, asla tek başına yapma**
4. **Test yoksa önce onu söyle.** UX-001 ve UX-002 refactor'leri test altyapısı olmadan kabul edilemez risk taşır.
5. **Ölçmediysen kazanç iddia etme.** "Muhtemelen %40 hızlanır" yazma. Ölçüm protokolü: **PLAYBOOK.md Bölüm 10**.
6. **Kapsam dışına çıkma.** `duzelt startup` verildiyse OData veya tablo bulgularını
   raporla ama **uygulama**. Kullanıcı kapsamı kendisi genişletsin.

### Bitirirken

Değiştirdiğin dosyaları listele ve şunu net söyle:

- Neyi uyguladın
- Neyi **uygulamadın** ve neden (davranış riski / kapsam dışı / onay bekliyor)
- Kullanıcının ne test etmesi gerekiyor
- Ölçüm yaptıysan öncesi/sonrası; yapmadıysan "ölçülmedi" de

---

## 4. Çıktı formatı

```
1. Kritik Problemler        → CRITICAL / HIGH / MEDIUM / LOW
2. Quick Wins               → az değişiklik, yüksek kazanç
3. Mimari Problemler
4. Performance Problemleri  → startup / OData / rendering / memory ayrı ayrı
5. Modernizasyon Önerileri  → ESKİ pattern → YENİ pattern
6. Refactor Edilmiş Kod     → production-ready, teorik değil
7. Beklenen Kazanç
8. Son Mimari
9. Uygulanmayan Öneriler    → neyi bilerek yapmadın
```

Her performans bulgusu şu formatta:

```
Problem:
Neden problem:
Performans etkisi:
Önerilen çözüm:
Kod örneği:
Business behaviour etkisi: Yok / VAR → ...
```

Uzun analizlerde `RAPOR-SABLONU.md` dosyasını doldurulmuş halde üret.

---

## 5. Referans dosyaları

Detaylı içerik ayrı bir playbook dosyasındadır. **Tümünü birden okuma** — sadece ihtiyaç
duyduğun bölümü oku.

### Playbook dosyasını bul

Kuruluma göre iki konumdan birindedir; ilk bulduğunu kullan:

1. `PLAYBOOK.md` — bu skill klasörünün içinde *(install.sh / install.ps1 ile kurulduysa)*
2. `SAPUI5-MODERNIZATION-PLAYBOOK.md` — reponun kökünde *(/add-dir ile referans verildiyse)*

Aynı şekilde rapor şablonu: `RAPOR-SABLONU.md` veya
`templates/ANALYSIS-REPORT-TEMPLATE.md`.

İkisi de yoksa playbook olmadan devam et, ama bunu kullanıcıya söyle — bu skill'in
derinliği o dosyadan gelir.

### Hangi bölüm ne zaman

| Bölüm | Ne zaman oku |
|---|---|
| **4** | Startup lifecycle haritası, critical path, 10 startup katili |
| **5** | 18 kategorili audit checklist |
| **6** | UX-001…UX-006 issue'ları, kök neden ve çözüm desenleri |
| **7** | Deprecated → modern API tablosu (1.120) |
| **8** | Refactor önceliklendirme + 17 adımlık sıra |
| **9** | ÖNCE/SONRA production-ready kod örnekleri |
| **10** | Ölçüm protokolü ve araçlar |
| **13** | Anti-öneriler — öneri yazmadan önce kontrol et |

---

## 6. Yasaklar

- ❌ Sadece "best practice" olduğu için değişiklik önerme. Her önerinin **ölçülebilir** gerekçesi olsun.
- ❌ Framework'ün zaten yaptığı optimizasyonu custom kodla tekrar yazma (model cache, preload cache, binding invalidation).
- ❌ Gereksiz abstraction yaratma. Servis katmanı ancak **(a)** 2+ tüketici, **(b)** test gereksinimi, **(c)** gerçek karmaşıklık varsa açılır. Tek dosyalık `service/` klasörü açma.
- ❌ Ölçmeden yüzde verme.
- ❌ Business logic'i sessizce değiştirme.
- ❌ Tek seferde onlarca dosyayı refactor etme.

Her öneriden önce kendine sor:

> **"Bu değişiklik uygulamayı gerçekten daha hızlı, daha temiz veya daha sürdürülebilir hale getiriyor mu?"**

Cevap hayırsa yazma.
