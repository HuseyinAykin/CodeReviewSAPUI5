# SAPUI5 / SAP Fiori Modernizasyon & Code Review Playbook

> Kalıcı referans dokümanı. Her yeni Fiori uygulaması analizinde bu dosyayı baştan kullan.
> Amaç: uygulamayı **gerçekten** daha hızlı, daha temiz ve daha sürdürülebilir yapmak — "best practice olduğu için" değişiklik yapmak değil.

---

## İçindekiler

| # | Bölüm | Ne zaman kullanılır |
|---|---|---|
| 0 | [Nasıl kullanılır](#0-nasıl-kullanılır) | İlk okuma |
| 1 | [Proje bağlamı & runtime kısıtları](#1-proje-bağlamı--runtime-kısıtları) | Her analizin başında |
| 2 | [Temel felsefe](#2-temel-felsefe) | Karar verirken |
| 3 | [Master Prompt (kopyala-yapıştır)](#3-master-prompt-kopyala-yapıştır) | Yeni analiz başlatırken |
| 4 | [Startup Lifecycle Haritası](#4-startup-lifecycle-haritası--critical-path) | Performans analizinin temeli |
| 5 | [Audit Checklist (18 kategori)](#5-audit-checklist--18-kategori) | Dosya dosya inceleme |
| 6 | [PDF Issue Mapping (UX-001…UX-006)](#6-pdf-issue-mapping--ux-001ux-006) | Issue list ile eşleştirme |
| 7 | [Deprecated → Modern API tablosu](#7-deprecated--modern-api-tablosu-1120) | Kod modernizasyonu |
| 8 | [Refactor önceliklendirme](#8-refactor-önceliklendirme-etkimaliyet) | Plan çıkarırken |
| 9 | [Pattern kütüphanesi (ÖNCE/SONRA)](#9-pattern-kütüphanesi-öncesonra) | Kod yazarken |
| 10 | [Ölçüm & doğrulama](#10-ölçüm--doğrulama) | Değişiklik sonrası |
| 11 | [Rapor şablonu](#11-rapor-şablonu) | Çıktı üretirken |
| 12 | [Hedef mimari](#12-hedef-mimari) | Son adım |
| 13 | [Anti-öneriler / tuzaklar](#13-anti-öneriler--yapmaman-gerekenler) | Sürekli |

---

## 0. Nasıl kullanılır

1. **Bölüm 3**'teki Master Prompt'u kopyala, yeni bir Claude/Claude Code oturumunda ilk mesaj olarak ver.
2. Proje dosyalarını sırayla gönder. Her dosyayı **bağımsız değil**, önceki dosyalarla birlikte tek bir sistem olarak değerlendir.
3. **Bölüm 4**'ü kullanarak uygulamanın gerçek startup lifecycle'ını çıkar (lokal optimizasyon değil, uçtan uca).
4. **Bölüm 5** checklist'ini dosya tipine göre uygula.
5. Bulguları **Bölüm 11** rapor şablonuna dök.
6. **Bölüm 8**'e göre önceliklendir, en yüksek kazançtan başla.
7. Her değişiklikten sonra **Bölüm 10** ile ölç. Ölçmediysen kazanç iddia etme.

**Dosya inceleme sırası (önerilen):**
`manifest.json` → `Component.js` → `ui5.yaml` / `package.json` / `xs-app.json` → routing target'ları → root view → ana liste/tablo view'u → ilgili controller → formatter/util → fragment'lar → geri kalan controller'lar.

Sebep: startup critical path bu sırayla oluşur. Controller'dan başlarsan mikro-optimizasyon tuzağına düşersin.

---

## 1. Proje bağlamı & runtime kısıtları

| Konu | Değer | Analize etkisi |
|---|---|---|
| SAPUI5 Runtime | **1.120.42** (LTS) | `sap.ui.core.Configuration`, `sap.ui.getCore()` bu sürümde **deprecated**. Yeni modüler API'ler mevcut. |
| OData | **V2** | V4 önerileri (`earlyRequests`, `$$aggregation`, `autoExpandSelect`) **geçerli değil**. V2 karşılıkları kullanılmalı. |
| Deployment | **BTP Cloud Foundry** (HTML5 App Repo + approuter) | ABAP cache-buster (`sap-ui-cachebuster`) mekanizması **geçerli değil**. Cache yönetimi HTML5 App Repo + `applicationVersion` üzerinden. |
| Launchpad | **SAP Build Work Zone** | Uygulama **Component olarak** yüklenir. `index.html` FLP içinde **kullanılmaz** — orayı optimize etmek boşa emek. UI5 core ve ortak lib'ler FLP tarafından zaten yüklenmiştir. |
| Application Type | **Freestyle SAPUI5** | Fiori Elements/annotation tabanlı öneriler doğrudan uygulanamaz; manuel karşılıkları gerekir. |
| Backend | **S/4HANA On-Premise** (Gateway) | `$metadata` boyutu ve Gateway metadata cache kritik. Cloud Connector latency'si her request'e ekleniyor → request **sayısını** azaltmak, boyutu azaltmaktan genelde daha değerli. |

### 1.1 Modern JavaScript — bu runtime'da neler güvenli?

1.120 sadece evergreen browser'ları destekler (IE desteği yok). Bu nedenle **runtime'da** güvenli:

- `const` / `let`, arrow function, template literal, destructuring, spread/rest
- `Promise`, `async` / `await`
- Optional chaining `?.` (ES2020), nullish coalescing `??` (ES2020)
- `Array.prototype.flat/flatMap/includes/find`, `Object.entries/values`, `Object.fromEntries`
- `class` (ancak UI5 kontrolleri için `.extend()` idiomatik olanı)

**Kısıtlar — bunlara dikkat:**

- ❌ **ESM (`import` / `export`) UI5 1.x runtime'ında çalışmaz.** Modül tanımı **her zaman** `sap.ui.define` olmalı. ESM istiyorsan `ui5-tooling-transpile` (Babel) zorunlu — bu ayrı bir karar, build'e maliyet ekler.
- ⚠️ Build toolchain'in de ES2020+ parse edebilmesi lazım: `@ui5/cli` **v3+** (terser 5) gerekli. `@ui5/cli` v2 ile `?.` kullanırsan **minify aşamasında build patlar**.
- ⚠️ ESLint parser'ı `ecmaVersion: 2022` olarak ayarlanmalı, aksi halde false-positive lint hataları alırsın.
- ⚠️ Kurumsal politika eski bir browser zorunlu kılıyorsa yukarıdakiler geçersiz — **önce doğrula.**
- ℹ️ TypeScript opsiyonel bir yol (`@sapui5/types` + `ui5-tooling-transpile`). Performansa etkisi **yok**; sadece maintainability. Mevcut production app için ayrı bir migrasyon projesidir, bu playbook'un kapsamında zorunlu değil.

---

## 2. Temel felsefe

> **"Modern kod = yeni syntax kullanmak değildir. Modern kod; daha az dependency, daha az request, daha az render, daha az lifecycle side-effect ve SAPUI5 binding mekanizmasını doğru kullanmak demektir."**

Her öneri için şu 3 soruyu geç:

1. **Ölçülebilir mi?** Kazancı ms, KB veya request sayısı olarak ifade edebiliyor muyum?
2. **Framework zaten yapıyor mu?** UI5'in kendi yaptığı bir optimizasyonu custom kodla tekrar implement ediyorsam **dur**.
3. **Business behaviour değişiyor mu?** Değişiyorsa açıkça yaz, kullanıcı karar versin.

Cevap "hayır/evet/evet" değilse öneriyi yazma.

**Gereksiz abstraction yasağı:** 3 satırlık bir kodu "mimari olsun" diye 3 dosyaya bölme. Servis katmanı ancak (a) birden fazla controller aynı logic'i kullanıyorsa, (b) logic test edilmesi gereken karmaşıklıktaysa, (c) side-effect izolasyonu gerekiyorsa yaratılır.

---

## 3. Master Prompt (kopyala-yapıştır)

```text
Elimde production'da çalışan bir SAP Fiori / SAPUI5 uygulaması var.
Stack: SAPUI5 1.120.42 | OData V2 | BTP Cloud Foundry | SAP Build Work Zone |
Freestyle SAPUI5 | Backend: S/4HANA On-Premise.

Bu uygulamayı kod kalitesi, mimari, performans, açılış süresi ve bakım kolaylığı
açısından modernize etmek istiyorum.

ÇALIŞMA ŞEKLİN:
- Dosyaları tek tek göndereceğim. Her dosyayı bağımsız DEĞİL, önceki dosyalarla
  birlikte TEK BİR SİSTEM olarak değerlendir.
- Lokal optimizasyon yapma. Önce application startup lifecycle'ını uçtan uca çıkar:
  approuter isteği → FLP component load → manifest → model creation → $metadata →
  routing → initial view render → ilk tablo data request.
- Critical path üzerinde OLMAYAN her şeyi lazy-load etmeye çalış.
- Sonra en yüksek performans kazancından en düşüğe doğru refactor planı üret.

TEKNİK KURALLAR:
- Global sap.* erişimi yok. sap.ui.define ile explicit import.
- Senkron modül yükleme yok. Deprecated API yok.
- Fragment/Dialog gibi başlangıçta gerekmeyen her şey lazy.
- Declarative binding tercih et; manuel UI güncelleme yapma.
- Framework'ün zaten yaptığı optimizasyonu custom kodla tekrar yazma.
- Sadece "best practice" olduğu için değişiklik önerme; her önerinin teknik
  gerekçesi ve ölçülebilir kazancı olsun.
- Bir değişiklik business behaviour'ı etkileyebilecekse AÇIKÇA belirt.

ÖNCELİK SIRASI:
1. Startup performance  2. Runtime performance  3. Gereksiz OData request
4. Rendering  5. Bundle size  6. Memory  7. UI5 best practices
8. Maintainability  9. Modern JavaScript  10. UI/UX modernizasyonu

ÇIKTI FORMATI:
1. Kritik Problemler (CRITICAL / HIGH / MEDIUM / LOW)
2. Quick Wins (az değişiklik, yüksek kazanç)
3. Mimari Problemler
4. Performance Problemleri (startup / OData / rendering / memory ayrı ayrı)
5. Modernizasyon Önerileri (ESKİ pattern → YENİ pattern)
6. Refactor Edilmiş Kod (production-ready, teorik öneri değil)
7. Beklenen Kazanç (startup / network / rendering / memory / maintainability)
8. Son Mimari (sadece gerçekten gerekli klasörler)

Her performans problemi için şu formatı kullan:
  Problem: / Neden problem: / Performans etkisi: / Önerilen çözüm: / Kod örneği:
```

---

## 4. Startup Lifecycle Haritası — Critical Path

Bu stack'te (**Work Zone + CF + Freestyle + OData V2**) uygulama açılışının gerçek sırası:

```
┌─ FAZ A: Platform (uygulama kontrolü DIŞINDA) ─────────────────────────────┐
│  A1  Browser → Work Zone site URL → approuter (xs-app.json)               │
│  A2  approuter → XSUAA auth (yoksa redirect + login roundtrip)            │
│  A3  FLP shell bootstrap: sap-ushell-config + CDM site JSON               │
│  A4  UI5 core + ortak lib'ler (sap.ui.core, sap.m, sap.f, sap.ushell)     │
│      → ✅ Bunlar APP AÇILMADAN ÖNCE yüklenmiştir. Manifest'te bu lib'leri  │
│         listelemek EK MALİYET DEĞİLDİR.                                   │
│  A5  Kullanıcı tile'a tıklar → Navigation service intent resolution       │
└───────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─ FAZ B: Uygulama yüklemesi (SENİN KONTROLÜNDE) ───────────────────────────┐
│  B1  ushell ComponentLoader → app URL (HTML5 App Repo, versiyonlu path)   │
│      ⚠️ index.html BURADA KULLANILMAZ. FLP içinde ölü koddur.             │
│  B2  manifest.json okunur (CDM'de gömülüyse ek request yok)               │
│  B3  Component-preload.js indirilir                                       │
│      ✅ VARSA: 1 request. ❌ YOKSA: her .js/.xml/.properties ayrı request │
│         → 50-200 request. En büyük tek startup maliyeti budur.            │
│  B4  manifest "dependencies.libs" → lazy:false olanlar yüklenir           │
│      ⚠️ sap.ui.comp / sap.ui.table / sap.viz / sap.suite.ui.commons       │
│         FLP'de ön-yüklü DEĞİL → her biri ciddi bir indirme + init         │
│  B5  manifest "resources.css" → render-blocking ek request                │
└───────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─ FAZ C: Component init ───────────────────────────────────────────────────┐
│  C1  Component.init() → UIComponent.prototype.init                        │
│  C2  manifest "models" → model instance'ları yaratılır                    │
│      → OData V2 model: GET $metadata  ⏱️ KRİTİK YOL, blocking             │
│      → ResourceModel (i18n): .properties bundle(ları)                     │
│         ⚠️ supportedLocales tanımlı değilse UI5 fallback zinciri dener    │
│            → tr_TR.properties, tr.properties, .properties = 3 request     │
│            (bulunamayanlar 404). supportedLocales bunu 1'e indirir.       │
│      → JSONModel (url ile): ek request                                    │
│  C3  flexEnabled:true ise → LREP flex data request (/sap/bc/lrep/...)     │
│      ⚠️ Key User Adaptation / variant kullanılmıyorsa saf maliyet         │
│  C4  createContent() → rootView (async olmalı)                            │
│  C5  Router.initialize() → hash parse → route matched                     │
└───────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─ FAZ D: İlk render ───────────────────────────────────────────────────────┐
│  D1  Target view XML yüklenir (preload içindeyse request yok)             │
│  D2  XML parse → control tree oluşturulur                                 │
│  D3  Controller.onInit()  ⚠️ BURADAKİ HER read() STARTUP'A EKLENİR        │
│  D4  onBeforeRendering → renderer → DOM                                   │
│  D5  onAfterRendering                                                     │
└───────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─ FAZ E: İlk veri ─────────────────────────────────────────────────────────┐
│  E1  ListBinding çözülür — $metadata GELMEDEN başlayamaz (C2'ye bağımlı)  │
│  E2  $batch POST → ilk sayfa verisi (+ countMode'a göre $count)           │
│  E3  updateFinished → tablo satırları render edilir                       │
└───────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Critical path — sadece bunlar startup'ı geciktirir

```
Component-preload.js  →  $metadata  →  ilk $batch  →  ilk render
```

Bunun dışındaki **her şey** lazy-load adayıdır. Analize başlarken şu tabloyu doldur:

| Adım | Ölçülen süre | Request sayısı | Boyut | Critical path'te mi? |
|---|---|---|---|---|
| Component-preload.js | | | | ✅ Evet |
| $metadata | | | | ✅ Evet |
| i18n bundle | | | | ✅ Evet (C2 blocking) |
| flex data | | | | ❌ Kaldırılabilir |
| Ek lib'ler | | | | ⚠️ Duruma göre |
| Custom CSS | | | | ⚠️ Render-blocking |
| onInit içi read'ler | | | | ⚠️ Genelde hayır |
| İlk $batch | | | | ✅ Evet |

### 4.2 Sık görülen startup katilleri (etki sırasıyla)

| # | Problem | Tipik etki | Doğrulama |
|---|---|---|---|
| 1 | `Component-preload.js` yok / deploy'a dahil değil | **+1–4 sn**, 50–200 ekstra request | Network → `Component-preload.js` var mı? |
| 2 | `$metadata` çok büyük (S/4 value-list annotation'ları dahil) | **+0.5–3 sn** | Network → `$metadata` response boyutu |
| 3 | Kullanılmayan ağır lib (`sap.ui.comp`, `sap.viz`, `sap.suite.ui.commons`) | **+300–1500 ms** | manifest `libs` vs kodda gerçek kullanım |
| 4 | `onInit` içinde sıralı (waterfall) `read()` çağrıları | **+N × RTT** | Network waterfall: paralel mi, merdiven mi? |
| 5 | `flexEnabled: true` ama adaptation kullanılmıyor | **+100–400 ms** | Network → `/sap/bc/lrep/` request'i var mı? |
| 6 | i18n `supportedLocales` yok → 404 fallback zinciri | **+2 request, +50–200 ms** | Network → 404 `.properties` var mı? |
| 7 | Tüm dialog/fragment `onInit`'te yaratılıyor | **+100–500 ms** + bellek | `onInit` içinde `Fragment.load` var mı? |
| 8 | `async: false` routing / rootView | Değişken, sync blocking | manifest `routing.config.async` |
| 9 | Tabloda `$select` yok → tüm entity alanları | Response boyutu 3–10× | Network → `$batch` response boyutu |
| 10 | Custom CSS dosyası (`resources.css`) | +1 render-blocking request | manifest `sap.ui5.resources` |

---

## 5. Audit Checklist — 18 Kategori

Her maddede: `[ ]` kontrol edilmedi · `[✓]` uygun · `[✗]` bulgu var (rapora yaz).

### 5.1 Startup Performance
- [ ] `Component-preload.js` production build'de üretiliyor ve deploy ediliyor mu?
- [ ] Preload içinde `.view.xml`, `.fragment.xml`, `.properties`, `manifest.json` var mı?
- [ ] `test/`, `localService/`, `mockdata` preload'dan **hariç** tutulmuş mu?
- [ ] `manifest.json` `sap.ui5.dependencies.libs` — her lib kodda gerçekten kullanılıyor mu?
- [ ] Nadiren kullanılan lib'ler `"lazy": true` mi?
- [ ] `minUI5Version` gerçekçi mi (`1.120.0`), gereksiz yüksek değil mi?
- [ ] `flexEnabled` gerçekten gerekli mi? (Key User Adaptation / variant management kullanılıyor mu?)
- [ ] i18n `supportedLocales` + `fallbackLocale` tanımlı mı?
- [ ] Custom CSS var mı, standart UI5 class'larıyla değiştirilebilir mi?
- [ ] `componentUsages` varsa `"lazy": true` mi?
- [ ] `onInit` içinde blocking iş var mı?

### 5.2 Component & Manifest
- [ ] Component `sap.ui.core.IAsyncContentCreation` interface'ini implement ediyor mu?
- [ ] `Component.js` küçük mü (< ~80 satır)? Business logic içeriyor mu?
- [ ] Config manifest'te mi, yoksa JS'e kaçmış mı?
- [ ] `rootView` manifest'te tanımlı mı (JS'te `createContent` override edilmemiş mi)?
- [ ] `routing.config.async: true` mi?
- [ ] `dataSources` doğru tanımlı mı, `localUri` production'a sızmış mı?
- [ ] `sap.app.applicationVersion.version` her deploy'da artıyor mu? (→ cache)
- [ ] `sap.ui5.models` içinde gereksiz eager model var mı?
- [ ] `sap.cloud.service` ve `crossNavigation.inbounds` doğru mu?

### 5.3 Async / Lazy Loading
- [ ] Hiç `sap.ui.xmlview()` / `sap.ui.xmlfragment()` / `sap.ui.controller()` kullanımı var mı? (sync + deprecated)
- [ ] `jQuery.sap.require` var mı? (sync loading)
- [ ] `sap.ui.requireSync` var mı?
- [ ] Dialog/Fragment'lar ilk kullanımda mı yaratılıyor?
- [ ] `Controller.prototype.loadFragment()` (1.93+) kullanılıyor mu?
- [ ] Nadir kullanılan modüller `sap.ui.require()` ile lazy mi çekiliyor?

### 5.4 OData V2 / Network
- [ ] Her list/table binding'inde `$select` var mı?
- [ ] `$expand` gerçekten gerekli mi, yoksa ayrı read daha mı ucuz?
- [ ] `useBatch` açık mı? (V2'de default açık — kapatılmamış olduğunu doğrula)
- [ ] `defaultCountMode` ne? Ayrı `$count` request'i görüyor musun? (`Inline` ile birleştirilebilir)
- [ ] `defaultOperationMode` / `operationMode: "Server"` — client-side filtering yapılmıyor mu?
- [ ] Aynı entity için tekrarlanan (duplicate) read var mı?
- [ ] `refresh()` / `refreshAfterChange` gereksiz tetikleniyor mu?
- [ ] `metadataUrlParams` ile `sap-value-list: "none"` denendi mi? (metadata boyutu ↓)
- [ ] Deferred group (`groupId` / `batchGroupId`) ile request'ler birleştirilebilir mi?
- [ ] `read()` çağrıları waterfall mı, paralel mi?
- [ ] `$top` / `$skip` server-side paging kullanılıyor mu?
- [ ] Filter'lar backend'e mi gidiyor, yoksa tüm veri çekilip frontend'de mi filtreleniyor?

### 5.5 Table Performance
- [ ] `sap.m.Table`: `growing="true"`, `growingThreshold` makul mü (20–50)?
- [ ] `growingScrollToLoad` UX'e uygun mu?
- [ ] `sap.ui.table.Table`: `threshold` ayarlı mı? `rowMode` kullanılıyor mu (1.119+)?
- [ ] `visibleRowCount` / `visibleRowCountMode` (deprecated) hâlâ kullanılıyor mu?
- [ ] 1000+ satır `sap.m.Table` ile mi gösteriliyor? → `sap.ui.table.Table` (virtualization) değerlendir
- [ ] Client-side sort/filter/aggregate yapılıyor mu? → server-side'a taşı
- [ ] Satır başına kaç formatter çalışıyor? (satır × kolon × formatter = gerçek maliyet)
- [ ] Formatter içinde `new Date()`, `NumberFormat.getInstance()` gibi pahalı çağrılar her seferinde mi yaratılıyor?
- [ ] JS'te `bindItems` yapılıyorsa `templateShareable` doğru set edilmiş mi?
- [ ] `updateFinished` / `dataReceived` handler'ında ağır iş var mı?
- [ ] Excel export tüm veriyi frontend'e çekiyor mu?

### 5.6 Rendering
- [ ] Gereksiz `invalidate()` çağrısı var mı?
- [ ] `rerender()` (deprecated) kullanımı var mı?
- [ ] Doğrudan DOM manipulation var mı (`getDomRef()`, `$()`, `innerHTML`, `document.querySelector`)?
- [ ] jQuery ile UI5 kontrolüne müdahale ediliyor mu?
- [ ] `onAfterRendering` içinde DOM'a yazılıyor mu? (her render'da tekrar çalışır)
- [ ] `setModel` tekrar tekrar çağrılıyor mu?
- [ ] Binding yerine manuel `setProperty`/`setText` döngüleri var mı?
- [ ] `busy` state binding ile mi yönetiliyor, manuel mi?

### 5.7 Controller Architecture
- [ ] Controller > 300 satır mı? (god-controller sinyali)
- [ ] Bir controller'da kaç sorumluluk var: OData, business logic, dialog, navigation, validation, export?
- [ ] `BaseController` var mı? (`getModel`, `getRouter`, `getResourceBundle`, `onNavBack`)
- [ ] Business logic frontend'de mi hesaplanıyor? (→ **UX-001**, CRITICAL)
- [ ] Formatter'lar ayrı modülde mi?
- [ ] Aynı kod birden fazla controller'da tekrar ediyor mu?

### 5.8 Models & Bindings
- [ ] Gereksiz JSONModel var mı? (OData verisi JSONModel'e kopyalanıyor mu?)
- [ ] `setSizeLimit` gerekli mi, gereksiz yüksek mi?
- [ ] `OneWay` yeterliyken `TwoWay` mi kullanılıyor?
- [ ] Manuel model refresh (`refresh(true)`) gereksiz mi?
- [ ] Expression binding aşırı karmaşık mı? (→ formatter'a taşı)
- [ ] Named model'ler tutarlı mı?

### 5.9 XML Views
- [ ] View çok mu büyük? (> ~400 satır → fragment'lara böl)
- [ ] Görünmeyen kontroller `visible="false"` ile mi yaratılıyor? → koşullu fragment düşün
- [ ] Gereksiz nested layout (`VBox` içinde `VBox` içinde `HBox`…) var mı?
- [ ] `class="sapUiSmallMargin"` gibi standart class'lar mı, custom CSS mi?
- [ ] `core:require` kullanılıyor mu (view'da modül ihtiyacı için)?
- [ ] Inline JS event handler (`press=".onX()"` yerine karmaşık expression) var mı?

### 5.10 Memory Management
- [ ] `onExit` içinde dialog'lar `destroy()` ediliyor mu?
- [ ] `EventBus.subscribe` için `unsubscribe` var mı?
- [ ] `attachRouteMatched` için `detachRouteMatched` var mı?
- [ ] `setInterval` / `setTimeout` temizleniyor mu?
- [ ] `Device.media.attachHandler` / `Device.orientation` detach ediliyor mu?
- [ ] Manuel `attachEvent` çağrıları detach ediliyor mu?
- [ ] Fragment `addDependent` ile view'a bağlanmış mı? (yoksa model propagation + destroy sorunu)

### 5.11 Security
- [ ] `innerHTML` / `outerHTML` kullanımı var mı?
- [ ] `sap.ui.core.HTML` kontrolü kullanıcı verisiyle besleniyor mu?
- [ ] `FormattedText` içine sanitize edilmemiş içerik giriyor mu?
- [ ] Dinamik URL oluşturuluyorsa `URLListValidator` ile doğrulanıyor mu?
- [ ] URL parametreleri doğrudan binding/DOM'a mı gidiyor?
- [ ] `encodeXML` / `encodeURL` (`sap/base/security/*`) kullanılıyor mu?
- [ ] `eval` / `new Function` var mı?

### 5.12 Accessibility
- [ ] Icon-only button'larda `tooltip` veya `ariaLabelledBy` var mı?
- [ ] `InvisibleText` gerekli yerlerde kullanılıyor mu?
- [ ] Form alanlarında `Label` `labelFor` ile bağlı mı?
- [ ] Renk tek başına anlam taşıyor mu? (ObjectStatus'ta `text` de var mı?)
- [ ] Keyboard navigation kırılmış mı? (custom DOM müdahalesi kaynaklı)

### 5.13 Fiori UX
- [ ] `DynamicPage` / `ObjectPage` kullanılıyor mu, yoksa eski `Page`+manuel header mı?
- [ ] `FilterBar` var mı, filtreleme deneyimi standart mı?
- [ ] `SemanticPage` / semantic action'lar kullanılıyor mu?
- [ ] Content density (`sapUiSizeCompact` / `sapUiSizeCozy`) doğru uygulanmış mı?
- [ ] Mesajlaşma tutarlı mı? (`MessageStrip` / `MessageBox` / `MessageToast` doğru yerde)
- [ ] `IllustratedMessage` (empty state) kullanılıyor mu?
- [ ] Responsive davranış test edilmiş mi (`sap.f.FlexibleColumnLayout` gerekli mi)?
- [ ] `!important` içeren CSS var mı?

### 5.14 Deprecated API'ler
→ Bölüm 7'deki tabloyu uygula. Ek olarak: `ui5lint` çalıştır (Bölüm 5.15).

### 5.15 Build / Bundle
- [ ] `ui5.yaml` `specVersion` güncel mi (3.x)?
- [ ] `framework.version` runtime ile aynı mı (`1.120.42`)?
- [ ] `framework.libraries` gerçek bağımlılıkları mı listeliyor?
- [ ] `ui5 build` production'da `--clean-dest` ile mi çalışıyor?
- [ ] `@ui5/cli` v3+ mı?
- [ ] `@ui5/linter` (`ui5lint`) pipeline'da var mı? → **UX-006**
- [ ] ESLint + Prettier config var mı, CI'da zorunlu mu?
- [ ] `karma-ui5` / QUnit / OPA5 testleri var mı, coverage ölçülüyor mu?
- [ ] `package.json` içinde kullanılmayan dependency var mı?
- [ ] Debug/source dosyaları production paketine giriyor mu?

### 5.16 Cache & Deployment (CF / Work Zone)
- [ ] `manifest.json` `applicationVersion.version` her deploy'da artıyor mu?
- [ ] `mta.yaml` version'ı ile app version tutarlı mı?
- [ ] Work Zone site'ı yeni deploy sonrası yeniden publish/refresh ediliyor mu?
- [ ] `index.html` (standalone erişim için) `Cache-Control: no-cache` alıyor mu?
- [ ] Network'te response'ların `ETag` / `Cache-Control` header'ları ne? (DevTools ile doğrula)
- [ ] Kullanıcılara "cache temizleyin" deniyorsa → süreç bozuk, **UX-005**

### 5.17 Clean Core
- [ ] Vergi / fiyat / indirim / tutar hesabı frontend'de mi? → **UX-001**, CRITICAL
- [ ] Yuvarlama kuralları frontend'de mi tanımlı?
- [ ] Para birimi / ondalık hane mantığı hard-coded mı?
- [ ] İş kuralı (validation) sadece frontend'de mi? (backend'de de olmalı)
- [ ] Konfigürasyon (limit, oran, eşik) koda mı gömülü?

### 5.18 Kod Kalitesi & Ölü Kod
- [ ] Yorum satırına alınmış kod blokları
- [ ] Kullanılmayan fonksiyon / değişken / import
- [ ] `console.log` kalıntıları (→ `sap/base/Log`)
- [ ] Magic number / magic string
- [ ] Kopyala-yapıştır tekrarları
- [ ] Tutarsız isimlendirme
- [ ] `try/catch` ile yutulan hatalar

---

## 6. PDF Issue Mapping — UX-001…UX-006

Issue list'teki maddelerin bu stack (UI5 1.120 / OData V2 / CF / Work Zone) açısından değerlendirmesi.

---

### UX-001 — Business & Tax Calculations Implemented in the Frontend
**Priority:** Very High · **Kategori:** Clean Core / Architecture · **Değerlendirme: ✅ GEÇERLİ ve en kritik madde**

**Neden problem:**
- Vergi/fiyat mantığı frontend'e yayıldığında **tek doğruluk kaynağı (single source of truth) kaybolur**. Aynı hesap backend'de de yapılıyorsa iki uygulama birbirinden sapar; yapılmıyorsa veri bütünlüğü frontend'e emanet edilmiş demektir.
- JavaScript `Number` **IEEE-754 double**'dır. `0.1 + 0.2 !== 0.3`. ABAP tarafındaki `DEC`/`CURR` tipleri ile **birebir aynı yuvarlamayı garanti edemezsin**. Kuruş farkları finansal mutabakat sorunu üretir.
- Vergi oranı/kuralı değiştiğinde **frontend deploy + Work Zone publish + kullanıcı cache** zinciri gerekir. Backend'de bu bir customizing değişikliğidir.
- API'yi doğrudan çağıran (Excel, entegrasyon, başka uygulama) her tüketici bu hesabı **atlar**.
- Denetim/audit izi frontend'de tutulamaz.

**Performans etkisi:** Doğrudan değil — ama hesaplama için ekstra master data (vergi oranları, koşul kayıtları) çekilmesi gerekir → ek OData request ve payload.

**Çözüm deseni:**
1. Hesabı **CDS view / ABAP** tarafına taşı; alan OData entity'sinde hazır gelsin.
2. Kullanıcı girdisine bağlı canlı hesap gerekiyorsa → **OData Function Import / Action** çağır (V2'de `callFunction`).
3. Frontend'de **sadece görüntüleme formatlaması** kalsın (`NumberFormat`, `CurrencyFormat`).
4. Geçiş dönemi: backend değeri ile frontend değerini karşılaştıran geçici bir log ekle, sapma varsa tespit et.

```js
// ❌ ÖNCE — controller içinde vergi hesabı
onQuantityChange: function (oEvent) {
    const fQty   = parseFloat(oEvent.getParameter("value"));
    const fPrice = this.getView().getModel().getProperty("/Item('1')/Price");
    const fNet   = fQty * fPrice;
    const fTax   = fNet * 0.20;                 // oran hard-coded
    const fGross = Math.round((fNet + fTax) * 100) / 100;  // yuvarlama frontend'de
    this.byId("grossField").setText(fGross.toFixed(2));    // binding de yok
}
```

```js
// ✅ SONRA — hesap backend'de, frontend sadece tetikler ve gösterir
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/m/MessageBox"
], function (Controller, MessageBox) {
    "use strict";

    return Controller.extend("my.app.controller.Detail", {

        onQuantityChange: async function (oEvent) {
            const oModel = this.getView().getModel();
            const oCtx   = this.getView().getBindingContext();

            try {
                const oResult = await this._callCalculate(oModel, {
                    ItemId:   oCtx.getProperty("ItemId"),
                    Quantity: oEvent.getParameter("value")
                });
                // Sonuç view model'ine yazılır, UI binding ile güncellenir
                this.getView().getModel("view").setProperty("/pricing", oResult);
            } catch (oError) {
                MessageBox.error(this._getText("priceCalcFailed"));
            }
        },

        _callCalculate: function (oModel, mParams) {
            return new Promise(function (resolve, reject) {
                oModel.callFunction("/CalculateItemPricing", {
                    method: "GET",
                    urlParameters: mParams,
                    success: resolve,
                    error: reject
                });
            });
        }
    });
});
```

**Business behaviour etkisi:** ⚠️ **VAR.** Hesap sonuçları backend'e taşınınca değerler değişebilir (doğrusu bu, ama fark çıkabilir). Geçiş öncesi mutlaka karşılaştırmalı test yapılmalı.

---

### UX-002 — God-Controller / Missing Separation of Concerns
**Priority:** High · **Kategori:** Controller Architecture · **Değerlendirme: ✅ GEÇERLİ**

**Neden problem:**
- Test edilemez: OData, DOM, dialog ve business logic aynı fonksiyonda ise unit test yazmak için tüm framework'ü mock'lamak gerekir.
- Değişiklik riski yüksek: bir düzeltme ilgisiz bir akışı bozar.
- `onInit` şişer → **startup'a doğrudan maliyet** (Faz D3).

**Performans etkisi:** Dolaylı ama gerçek. `onInit` içindeki her satır ilk render'ı geciktirir.

**Çözüm — sadece gerektiği kadar katman:**

```
controller/
  BaseController.js      → getModel/getRouter/getResourceBundle/onNavBack (ortak, ~60 satır)
  Worklist.controller.js → sadece UI event orchestration
model/
  formatter.js           → saf fonksiyonlar, test edilebilir
service/                 → SADECE 2+ controller kullanıyorsa veya karmaşıksa
  ODataService.js
  DialogService.js
```

**⚠️ Aşırıya kaçma:** Tek controller'ın kullandığı 5 satırlık kodu ayrı servise çıkarma. Kriter: **tekrar kullanım + test edilebilirlik + karmaşıklık**. Üçü de yoksa controller'da kalsın.

**Ölçüt:** Controller > 300 satır veya bir fonksiyon > 40 satır → böl.

---

### UX-003 — Direct DOM Manipulation of UI5 Controls
**Priority:** High · **Kategori:** Rendering / Lifecycle · **Değerlendirme: ✅ GEÇERLİ**

**Neden problem:**
- UI5 kontrolleri **kendi DOM'una sahiptir**. Her `invalidate` sonrası renderer DOM'u yeniden üretir → manuel değişikliğin **silinir**. Bu, "bazen çalışıyor bazen çalışmıyor" tipi hataların ana kaynağıdır.
- İç DOM yapısı (`sapMBtn`, `sapMListTblCell` gibi class'lar) **public API değildir**; UI5 upgrade'inde sessizce kırılır.
- Accessibility (ARIA) ve keyboard handling bozulur.
- `innerHTML` ile yazılıyorsa **XSS riski** (bkz. 5.11).

**Performans etkisi:** Manuel DOM okuma (`offsetHeight`, `getBoundingClientRect`) **forced synchronous layout** tetikler; `onAfterRendering` içinde döngüde yapılırsa layout thrashing → satır sayısıyla doğru orantılı donma.

```js
// ❌ ÖNCE
onAfterRendering: function () {
    this.byId("myTable").$().find(".sapMListTblCell").css("background", "#ffcccc");
    document.getElementById(this.byId("hdr").getId()).innerHTML = this._sTitle;
}
```

```xml
<!-- ✅ SONRA — declarative + CustomData ile stil -->
<Text text="{view>/title}" />
<ColumnListItem
    highlight="{= ${Status} === 'E' ? 'Error' : 'None' }">
    <cells>
        <ObjectStatus text="{Status}" state="{path: 'Status', formatter: '.formatter.statusState'}" />
    </cells>
</ColumnListItem>
```

**Kural:** Stil için `addStyleClass()` + CSS class; içerik için binding; hizalama için UI5 layout kontrolleri. `getDomRef()` sadece **ölçüm** için ve mutlaka `null` kontrolüyle.

---

### UX-004 — Performance Inefficiencies Due to Excessive UI Processing
**Priority:** High · **Kategori:** Runtime / Rendering / OData · **Değerlendirme: ✅ GEÇERLİ (en geniş kapsamlı madde)**

Bu madde tek bir problem değil, bir semptom. Alt bileşenlere ayır:

| Alt problem | Belirti | Çözüm |
|---|---|---|
| Aşırı formatter | 500 satır × 8 kolon × formatter = 4000 fonksiyon çağrısı / render | Formatter sayısını azalt, `NumberFormat` instance'ını modül seviyesinde cache'le |
| Client-side sort/filter/aggregate | Tüm veri çekiliyor, JS'te işleniyor | `operationMode: "Server"`, `Sorter`/`Filter` binding'e |
| `$select` yok | Response 3–10× büyük | Binding parametrelerine `$select` |
| Waterfall read | Network merdiveni | `Promise.all` + tek `$batch` |
| Gereksiz `refresh()` | Aynı veri tekrar tekrar çekiliyor | Sadece gerçekten değişen binding'i refresh et |
| Growing kapalı büyük tablo | İlk render'da binlerce DOM node | `growing` + `growingThreshold` veya `sap.ui.table.Table` |
| `onAfterRendering` içinde ağır iş | Her render'da tekrar | `onInit`'e taşı veya idempotent yap |

```js
// ❌ ÖNCE — her satır için yeni formatter instance
formatAmount: function (fValue) {
    const oFormat = sap.ui.core.format.NumberFormat.getCurrencyInstance({ showMeasure: false });
    return oFormat.format(fValue);
}
```

```js
// ✅ SONRA — modül seviyesinde tek instance
sap.ui.define(["sap/ui/core/format/NumberFormat"], function (NumberFormat) {
    "use strict";

    const oCurrencyFormat = NumberFormat.getCurrencyInstance({ showMeasure: false });

    return {
        formatAmount: function (fValue) {
            return fValue == null ? "" : oCurrencyFormat.format(fValue);
        }
    };
});
```

**1000+ / 10.000+ kayıt kuralı — frontend'de ASLA yapılmayacaklar:**
- ❌ Tüm veriyi çekip JS'te `filter()` / `sort()` / `reduce()`
- ❌ Toplam/subtotal hesaplama (→ backend aggregation)
- ❌ Excel export için tüm veriyi belleğe alma (→ backend export servisi veya `sap.ui.export.Spreadsheet` ile **binding üzerinden** stream)
- ❌ Growing kapalı `sap.m.Table`
- ❌ Satır başına birden fazla ağır formatter
- ❌ Client-side duplicate/lookup için `Array.find` döngüsü (O(n²))

---

### UX-005 — Users Manually Clearing the Browser Cache
**Priority:** High · **Kategori:** Deployment / Cache · **Değerlendirme: ✅ GEÇERLİ ama ÖNERİLER STACK'E GÖRE UYARLANMALI**

> ⚠️ **Önemli:** Bu madde için sık verilen `sap-ui-cachebuster` / `/sap/bc/ui5_ui5/.../cachebuster` önerisi **ABAP (on-premise) deployment'a özgüdür**. Bu proje **CF + HTML5 Application Repository** kullandığı için o mekanizma **geçerli değildir**. CF'de içerik versiyonlama HTML5 App Repo tarafından yapılır.

**Kök neden adayları (sırayla doğrula):**

1. **`applicationVersion.version` artmıyor.** `manifest.json` içindeki versiyon her deploy'da artmıyorsa Work Zone / FLP aynı içeriği yeniden kullanabilir.
2. **Work Zone site'ı yeniden publish edilmiyor.** App yeni versiyona geçse bile site content cache eskiyi gösterebilir.
3. **`index.html` uzun süreli cache alıyor.** (Standalone erişimde) `Cache-Control: no-cache` olmalı; hash'li kaynaklar uzun cache alabilir.
4. **`Component-preload.js` yok.** Preload yoksa onlarca ayrı dosya cache'lenir; bunların tutarsız yaşlanması "yarısı yeni yarısı eski" durumu yaratır.
5. **Browser/proxy arası bir katman** (kurumsal proxy, CDN) header'ları eziyor.

**Doğrulama adımları (tahmin etme, ölç):**
```
DevTools → Network → Disable cache KAPALI → hard reload olmadan aç
  1. Component-preload.js response URL'sinde versiyon/hash var mı?
  2. Cache-Control / ETag / Last-Modified header'ları ne?
  3. manifest.json'daki applicationVersion, deploy edilenle aynı mı?
  4. 304 mü 200 (from disk cache) mi dönüyor?
```

**Kalıcı çözüm:**
- CI/CD'de `manifest.json` `applicationVersion.version` + `mta.yaml` `version` **otomatik** artırılsın (semantic-release veya build script).
- Deploy pipeline'ının son adımı Work Zone site refresh/publish olsun.
- `Component-preload.js` üretimi zorunlu hale getirilsin (build kontrolü).
- Kullanıcıya "cache temizle" demek bir çözüm değil, **süreç hatasının belirtisidir** — bunu rapora böyle yaz.

**Business behaviour etkisi:** Yok. Sadece deployment süreci değişir.

---

### UX-006 — Insufficient Automated Code Quality and Static Analysis
**Priority:** High · **Kategori:** Build / Tooling · **Değerlendirme: ✅ GEÇERLİ — ve 1.120 için özellikle değerli**

**Neden problem:** Bu playbook'taki kontrollerin **yarısı otomatize edilebilir**. Manuel review tekrarlanabilir değildir; otomatik kontrol regresyon getirmez.

**Önerilen minimum tooling (öncelik sırasıyla):**

| # | Araç | Ne yakalar | Neden bu stack için önemli |
|---|---|---|---|
| 1 | **`@ui5/linter` (`ui5lint`)** | Deprecated UI5 API, global `sap.*` erişimi, sync loading, manifest sorunları | SAP'ın resmi aracı; **tam olarak bu playbook'un 5.3 + 5.14 maddelerini** otomatize eder. 1.120 → UI5 2.x hazırlığı için de gerekli. |
| 2 | **ESLint** (`ecmaVersion: 2022`) | Genel JS hataları, kullanılmayan değişken, `console.log` | Ölü kod ve tutarsızlık |
| 3 | **Prettier** | Format tutarlılığı | Review gürültüsünü azaltır |
| 4 | **QUnit + `karma-ui5`** | Formatter/util unit test | UX-001/UX-002 refactor'ünün güvenlik ağı |
| 5 | **OPA5** | Kritik akış integration test | Regresyon koruması |
| 6 | **UI5 Support Assistant** | Runtime best-practice ihlalleri | Manuel ama derinlemesine |
| 7 | SonarQube (varsa) | Coverage + kod kokusu trendi | Kurumsal raporlama |

```jsonc
// package.json — scripts (öneri)
{
  "scripts": {
    "lint:ui5":  "ui5lint",
    "lint:js":   "eslint webapp --ext .js",
    "format":    "prettier --write \"webapp/**/*.{js,json,xml}\"",
    "test":      "karma start --single-run",
    "build":     "ui5 build --clean-dest",
    "verify":    "npm run lint:ui5 && npm run lint:js && npm run test"
  }
}
```

CI pipeline'da `npm run verify` **merge blocker** olmalı. Aksi halde araç kurulmuş ama etkisiz kalır.

---

### 6.1 Issue → Playbook bölüm eşlemesi

| Issue | Kategori | Playbook bölümü | Öncelik |
|---|---|---|---|
| UX-001 | Clean Core / Architecture | 5.7, 5.17, 9.6 | 🔴 CRITICAL |
| UX-002 | Controller Architecture | 5.7, 12 | 🟠 HIGH |
| UX-003 | Rendering / Lifecycle / Security | 5.6, 5.11, 9.4 | 🟠 HIGH |
| UX-004 | Runtime / OData / Table | 5.4, 5.5, 5.6, 5.8 | 🟠 HIGH |
| UX-005 | Deployment / Cache | 5.16, 5.1 | 🟠 HIGH |
| UX-006 | Build / Tooling | 5.15 | 🟠 HIGH |

### 6.2 Issue list'te olmayan ama bu stack'te muhtemel ek riskler

Kod geldiğinde bunları da kontrol et — PDF'te yer almıyor ama bu stack'te sık çıkar:

- Startup'ta `Component-preload.js` eksikliği (PDF'te yok, **etkisi UX-004'ten büyük olabilir**)
- `$metadata` boyutu / Gateway metadata cache
- i18n `supportedLocales` eksikliği
- `flexEnabled` gereksiz açık
- Memory leak (EventBus / dialog / timer) — PDF'te yok, production'da uzun oturumlarda kritik
- Accessibility — PDF'te yok, kurumsal uyumluluk gerektirebilir

---

## 7. Deprecated → Modern API Tablosu (1.120)

> Bu tablo `ui5lint` ile otomatik doğrulanabilir. Manuel taramadan önce `ui5lint` çalıştır.

### 7.1 Core erişimi (1.118+ ile modülerleşti)

| ❌ Deprecated | ✅ Modern (1.120) | Modül |
|---|---|---|
| `sap.ui.getCore().byId(id)` | `Element.getElementById(id)` | `sap/ui/core/Element` |
| `sap.ui.getCore().attachInit(fn)` | `Core.ready().then(fn)` | `sap/ui/core/Core` |
| `sap.ui.getCore().getEventBus()` | `EventBus.getInstance()` | `sap/ui/core/EventBus` |
| `sap.ui.getCore().getMessageManager()` | `Messaging` | `sap/ui/core/Messaging` |
| `sap.ui.getCore().loadLibrary(n, {async:true})` | `Library.load({name: n})` | `sap/ui/core/Lib` |
| `sap.ui.getCore().applyTheme(t)` | `Theming.setTheme(t)` | `sap/ui/core/Theming` |
| `sap.ui.getCore().getConfiguration().getLanguage()` | `Localization.getLanguage()` | `sap/base/i18n/Localization` |
| `...getConfiguration().getRTL()` | `Localization.getRTL()` | `sap/base/i18n/Localization` |
| `...getConfiguration().getFormatLocale()` | `Formatting.getLanguageTag()` | `sap/base/i18n/Formatting` |
| `sap.ui.core.Configuration` | `Localization` / `Formatting` / `Theming` / `ControlBehavior` | (yukarıdakiler) |

### 7.2 View / Fragment / Component oluşturma

| ❌ Deprecated (sync) | ✅ Modern (async) |
|---|---|
| `sap.ui.xmlview({...})` | `XMLView.create({...})` → Promise |
| `sap.ui.view({...})` | `View.create({...})` → Promise |
| `sap.ui.xmlfragment(...)` | `Fragment.load({name, controller})` → Promise |
| `sap.ui.fragment(...)` | `Fragment.load(...)` |
| `sap.ui.controller(...)` | `Controller.create({name})` → Promise |
| `sap.ui.component({...})` | `Component.create({...})` → Promise |
| `jQuery.sap.require(...)` | `sap.ui.define([...])` veya `sap.ui.require([...], cb)` |
| `sap.ui.requireSync(...)` | `sap.ui.require([...], cb)` |

**Controller içinde en kısa yol (1.93+):**
```js
// Fragment.load + addDependent + id prefixing hepsi otomatik
const oDialog = await this.loadFragment({ name: "my.app.view.fragment.Filter" });
```

### 7.3 jQuery.sap.* → modüler API

| ❌ | ✅ | Modül |
|---|---|---|
| `jQuery.sap.log` | `Log` | `sap/base/Log` |
| `jQuery.sap.encodeHTML` | `encodeXML` | `sap/base/security/encodeXML` |
| `jQuery.sap.encodeURL` | `encodeURL` | `sap/base/security/encodeURL` |
| `jQuery.sap.validateUrl` | `URLListValidator.validate` | `sap/base/security/URLListValidator` |
| `jQuery.sap.getObject` | `ObjectPath.get` | `sap/base/util/ObjectPath` |
| `jQuery.sap.extend` | `merge` / `extend` | `sap/base/util/merge`, `sap/base/util/extend` |
| `jQuery.sap.delayedCall` | `setTimeout` (+ `onExit`'te `clearTimeout`) | — |
| `jQuery.sap.uid` | `uid` | `sap/base/util/uid` |
| `jQuery.sap.startsWith` | `String.prototype.startsWith` | — |
| `jQuery.sap.isPlainObject` | `isPlainObject` | `sap/base/util/isPlainObject` |

### 7.4 Global kontrol erişimi

| ❌ | ✅ |
|---|---|
| `sap.m.MessageToast.show(...)` | `sap.ui.define(["sap/m/MessageToast"], ...)` |
| `sap.m.MessageBox.error(...)` | `sap.ui.define(["sap/m/MessageBox"], ...)` |
| `new sap.m.Dialog({...})` | `sap.ui.define(["sap/m/Dialog"], ...)` |
| `sap.ui.Device` | `sap.ui.define(["sap/ui/Device"], ...)` |
| `sap.ui.model.Filter` | `sap.ui.define(["sap/ui/model/Filter"], ...)` |

### 7.5 Kontrol seviyesi

| ❌ | ✅ | Not |
|---|---|---|
| `oControl.rerender()` | `oControl.invalidate()` | `rerender` 1.70'te deprecated |
| `sap.ui.table.Table` `visibleRowCount` / `visibleRowCountMode` | `rowMode` aggregation (`sap/ui/table/rowmodes/Fixed\|Auto\|Interactive`) | 1.119+ |
| `sap.ushell.Container.getService("CrossApplicationNavigation")` | `Container.getServiceAsync("Navigation")` | 1.114+; async olan tercih edilmeli |

### 7.6 Manifest / Component

| ❌ | ✅ |
|---|---|
| `Component.js` içinde `createContent()` ile sync rootView | manifest `sap.ui5.rootView` + `IAsyncContentCreation` |
| `routing.config.async` yok/`false` | `IAsyncContentCreation` interface (async'i zorunlu kılar) |
| `manifest: "json"` ayarı eksik | `metadata: { manifest: "json" }` |

---

## 8. Refactor Önceliklendirme (Etki/Maliyet)

Bulguları bu matrise yerleştir. **Sol üstten başla.**

```
        DÜŞÜK MALİYET                    YÜKSEK MALİYET
   ┌──────────────────────────┬──────────────────────────┐
 Y │ 🥇 ÖNCE BUNLAR           │ 🥈 PLANLA                │
 Ü │ • Component-preload      │ • UX-001 backend'e taşı  │
 K │ • Kullanılmayan lib sil  │ • UX-002 controller böl  │
 S │ • i18n supportedLocales  │ • Büyük tablo → ui.table │
 E │ • flexEnabled kapat      │ • Test altyapısı kurmak  │
 K │ • $select ekle           │ • FCL / ObjectPage geçişi│
   │ • ui5lint pipeline'a     │                          │
 E ├──────────────────────────┼──────────────────────────┤
 T │ 🥉 SIRA GELİRSE          │ ❌ YAPMA (gerekçe yoksa) │
 K │ • Deprecated API temizliği│ • Toptan TypeScript      │
 İ │ • const/let, ?., ??      │ • Sırf mimari için servis │
   │ • Formatter cache        │ • Custom cache mekanizması│
 D │ • Dialog lazy load       │ • UI5'in yaptığını yeniden│
 Ü │ • Memory leak temizliği  │   yazmak                  │
 Ş │ • Ölü kod silme          │                          │
 Ü └──────────────────────────┴──────────────────────────┘
```

### 8.1 Standart refactor sırası (deneyimle doğrulanmış)

| Sıra | İş | Beklenen kazanç | Risk |
|---|---|---|---|
| 1 | `Component-preload.js` üretimini garanti et | Startup **-1…-4 sn**, request **-50…-200** | Yok |
| 2 | Kullanılmayan lib'leri kaldır / `lazy: true` | Startup **-200…-1500 ms** | Düşük (runtime hata riski → test et) |
| 3 | `$metadata` küçült (`sap-value-list: none`) | Startup **-200…-2000 ms** | ⚠️ Value help kullanılıyorsa etkiler |
| 4 | `flexEnabled: false` (adaptation kullanılmıyorsa) | Startup **-100…-400 ms**, -1 request | ⚠️ Personalization kaybolur |
| 5 | i18n `supportedLocales` + `fallbackLocale` | **-2 request**, -50…-200 ms | Yok |
| 6 | `onInit` read'lerini `$batch`'te birleştir / lazy yap | Startup **-N × RTT** | Düşük |
| 7 | Tüm binding'lere `$select` | Payload **-50…-90%** | Düşük (eksik alan → test et) |
| 8 | Dialog/Fragment lazy load | Startup **-100…-500 ms**, bellek ↓ | Yok |
| 9 | Client-side sort/filter → server-side | Büyük veride **dramatik** | ⚠️ Davranış farkı olabilir |
| 10 | Tablo growing/threshold ayarı | İlk render **-30…-70%** | Yok |
| 11 | Formatter optimizasyonu / cache | Render **-10…-40%** | Yok |
| 12 | DOM manipulation → declarative binding (UX-003) | Stabilite + render | Orta (görsel regresyon) |
| 13 | Controller bölme (UX-002) | Maintainability | Orta |
| 14 | Business logic backend'e (UX-001) | Doğruluk + Clean Core | ⚠️ **Yüksek** — test şart |
| 15 | Memory leak temizliği | Uzun oturumda stabilite | Yok |
| 16 | Deprecated API temizliği | Upgrade hazırlığı | Düşük |
| 17 | UI/UX modernizasyonu | Kullanıcı algısı | Orta (eğitim gerekebilir) |

> Kazanç aralıkları tipik gözlemlerdir, **garanti değildir**. Her adımdan sonra Bölüm 10'a göre ölç ve gerçek değeri rapora yaz.

---

## 9. Pattern Kütüphanesi (ÖNCE/SONRA)

### 9.1 Component.js — minimal ve async

```js
// ❌ ÖNCE
sap.ui.define(["sap/ui/core/UIComponent", "sap/ui/model/json/JSONModel"],
function (UIComponent, JSONModel) {
    "use strict";
    return UIComponent.extend("my.app.Component", {
        metadata: { manifest: "json" },
        init: function () {
            UIComponent.prototype.init.apply(this, arguments);
            // ⚠️ startup'ta blocking iş
            const oData = jQuery.sap.syncGetJSON("config.json").data;
            this.setModel(new JSONModel(oData), "config");
            this.setModel(new JSONModel({ busy: false, layout: "OneColumn" }), "view");
            this.getRouter().initialize();
            // ⚠️ device model her component'te elle yaratılıyor
            this.setModel(new JSONModel(sap.ui.Device), "device");
        }
    });
});
```

```js
// ✅ SONRA
sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/model/json/JSONModel"
], function (UIComponent, JSONModel) {
    "use strict";

    return UIComponent.extend("my.app.Component", {

        metadata: {
            manifest: "json",
            // rootView + routing otomatik olarak async yaratılır
            interfaces: ["sap.ui.core.IAsyncContentCreation"]
        },

        init: function () {
            UIComponent.prototype.init.apply(this, arguments);

            // Sadece gerçekten UI state — config manifest'te
            this.setModel(new JSONModel({ busy: false }), "view");

            this.getRouter().initialize();
        }
    });
});
```
**`device` model'i hakkında:** `sap.ui.Device` nesnesini manifest'ten JSONModel olarak kurmanın hazır bir yolu yoktur. Gerçekten ihtiyacın varsa Component'te tek satır bırakmak **kabul edilebilir bir istisnadır** — bunun için ayrı bir `models.js` factory dosyası açma:

```js
sap.ui.define([
    "sap/ui/core/UIComponent",
    "sap/ui/model/json/JSONModel",
    "sap/ui/Device"
], function (UIComponent, JSONModel, Device) {
    "use strict";
    // ...init içinde:
    const oDeviceModel = new JSONModel(Device);
    oDeviceModel.setDefaultBindingMode("OneWay");   // ← Device salt okunur olmalı
    this.setModel(oDeviceModel, "device");
});
```

**Daha da iyisi:** Çoğu responsive ihtiyaç `device` model'i olmadan çözülür — `sap.m` kontrollerinin kendi responsive davranışı, `Table` `popinDisplay`/`minScreenWidth`, `sap.f.FlexibleColumnLayout`. `device` model'ini gerçekten binding'de kullanmıyorsan **hiç kurma**.

### 9.2 manifest.json — startup odaklı ayarlar

```jsonc
{
  "sap.app": {
    "id": "my.app",
    "applicationVersion": { "version": "1.4.2" },   // ← her deploy'da ARTIR (UX-005)
    "i18n": {
      "bundleUrl": "i18n/i18n.properties",
      "supportedLocales": ["", "en", "tr"],          // ← 404 fallback zincirini keser
      "fallbackLocale": ""
    },
    "dataSources": {
      "mainService": {
        "uri": "/sap/opu/odata/sap/ZMY_SRV/",
        "type": "OData",
        "settings": { "odataVersion": "2.0" }
      }
    }
  },

  "sap.ui5": {
    "flexEnabled": false,                            // ← adaptation kullanılmıyorsa
    "dependencies": {
      "minUI5Version": "1.120.0",
      "libs": {
        "sap.ui.core": {},
        "sap.m": {},
        "sap.f": {},
        "sap.ui.table": { "lazy": true },             // ← nadiren kullanılıyorsa
        "sap.ui.export": { "lazy": true }             // ← Excel export sadece talep edilince
      }
    },

    "models": {
      "i18n": {
        "type": "sap.ui.model.resource.ResourceModel",
        "settings": {
          "bundleName": "my.app.i18n.i18n",
          "supportedLocales": ["", "en", "tr"],
          "fallbackLocale": ""
        }
      },
      "": {
        "dataSource": "mainService",
        "preload": true,                              // ← metadata erken başlasın
        "settings": {
          "defaultBindingMode": "TwoWay",
          "defaultCountMode": "Inline",               // ← ayrı $count request'ini kaldırır
          "defaultOperationMode": "Server",
          "useBatch": true,
          "refreshAfterChange": false,                // ← her değişiklikte otomatik refresh yok
          "metadataUrlParams": { "sap-value-list": "none" }  // ← metadata boyutu ↓
        }
      }
    },

    "routing": {
      "config": {
        "routerClass": "sap.m.routing.Router",
        "viewType": "XML",
        "viewPath": "my.app.view",
        "controlId": "app",
        "controlAggregation": "pages",
        "transition": "slide"
      },
      "routes": [ /* ... */ ],
      "targets": { /* ... */ }
    }
  }
}
```

> ⚠️ **`defaultCountMode`, `refreshAfterChange`, `sap-value-list` ve `flexEnabled` davranış değiştirir.**
> Değiştirmeden önce mevcut değeri **network trace ile doğrula**, sonra fonksiyonel test yap.
> `refreshAfterChange: false` → CRUD sonrası ilgili binding'i **elle** refresh etmen gerekir.

### 9.3 Lazy Dialog / Fragment

```js
// ❌ ÖNCE — onInit'te yaratılıyor, sync API, destroy yok
onInit: function () {
    this._oDialog = sap.ui.xmlfragment("my.app.view.fragment.Filter", this);
    this.getView().addDependent(this._oDialog);
}
```

```js
// ✅ SONRA — ilk kullanımda, async, tek instance, temizlenmiş
onOpenFilter: async function () {
    this._pFilterDialog ??= this.loadFragment({
        name: "my.app.view.fragment.Filter"
    });
    const oDialog = await this._pFilterDialog;
    oDialog.open();
},

onExit: function () {
    // loadFragment addDependent yaptığı için view destroy'unda temizlenir,
    // ancak view'a bağlanmayan her şeyi burada bırakma:
    if (this._iTimer) {
        clearInterval(this._iTimer);
        this._iTimer = null;
    }
    this.getOwnerComponent().getEventBus()
        .unsubscribe("app", "refresh", this._onRefresh, this);
}
```

### 9.4 DOM manipulation → declarative (UX-003)

```js
// ❌ ÖNCE
_updateStatus: function (sId, bError) {
    const oDom = this.byId(sId).getDomRef();
    oDom.style.color = bError ? "red" : "green";
    oDom.innerHTML = bError ? "<b>Hata</b>" : "OK";   // ⚠️ XSS + render'da silinir
}
```

```xml
<!-- ✅ SONRA -->
<ObjectStatus
    text="{= ${view>/hasError} ? ${i18n>error} : ${i18n>ok} }"
    state="{= ${view>/hasError} ? 'Error' : 'Success' }" />
```

### 9.5 Waterfall read → tek $batch

```js
// ❌ ÖNCE — 3 sıralı RTT
onInit: function () {
    const oModel = this.getOwnerComponent().getModel();
    oModel.read("/Plants", { success: (o1) => {
        oModel.read("/Currencies", { success: (o2) => {
            oModel.read("/Users", { success: (o3) => {
                this._fill(o1, o2, o3);
            }});
        }});
    }});
}
```

```js
// ✅ SONRA — paralel, tek $batch, onInit'i bloklamıyor
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/json/JSONModel"
], function (Controller, JSONModel) {
    "use strict";

    return Controller.extend("my.app.controller.Worklist", {

        onInit: function () {
            // View hemen render olur; value help verisi arkada gelir
            this.getView().setModel(new JSONModel({}), "vh");
            this._loadValueHelpData();
        },

        _loadValueHelpData: async function () {
            const oModel = this.getOwnerComponent().getModel();
            try {
                const [aPlants, aCurrencies, aUsers] = await Promise.all([
                    this._read(oModel, "/Plants",     { "$select": "Plant,Name" }),
                    this._read(oModel, "/Currencies", { "$select": "Code,Text"  }),
                    this._read(oModel, "/Users",      { "$select": "Id,Name"    })
                ]);
                this.getView().getModel("vh").setData({
                    plants: aPlants, currencies: aCurrencies, users: aUsers
                });
            } catch (oError) {
                // sessizce yutma — logla
                this._logError(oError);
            }
        },

        _read: function (oModel, sPath, mUrlParams) {
            return new Promise(function (resolve, reject) {
                oModel.read(sPath, {
                    urlParameters: mUrlParams,
                    success: (oData) => resolve(oData.results),
                    error: reject
                });
            });
        }
    });
});
```
> V2 model `useBatch: true` iken aynı tick içinde tetiklenen read'ler otomatik olarak tek `$batch`'te birleşir. `Promise.all` bunu garanti eder; iç içe callback ise **engeller**.

### 9.6 Tablo binding — $select + server-side

```xml
<!-- ❌ ÖNCE -->
<Table items="{/SalesOrderSet}">
```

```xml
<!-- ✅ SONRA -->
<Table
    id="ordersTable"
    growing="true"
    growingThreshold="30"
    growingScrollToLoad="true"
    items="{
        path: '/SalesOrderSet',
        parameters: {
            select: 'OrderId,CustomerName,NetAmount,Currency,Status,CreatedAt',
            operationMode: 'Server'
        },
        sorter: { path: 'CreatedAt', descending: true }
    }">
```
> Yalnızca **görüntülenen** alanları `select`'e koy. Kolon gizle/göster varsa gizli kolonların alanlarını da eklemen gerekir — aksi halde kolon açıldığında değer boş gelir. Bu, davranış etkisi olan bir değişikliktir.

### 9.7 BaseController (tekrar eden kodu tek yerde topla)

```js
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/core/UIComponent",
    "sap/ui/core/routing/History"
], function (Controller, UIComponent, History) {
    "use strict";

    return Controller.extend("my.app.controller.BaseController", {

        getRouter: function () {
            return UIComponent.getRouterFor(this);
        },

        getModel: function (sName) {
            return this.getView().getModel(sName);
        },

        setModel: function (oModel, sName) {
            this.getView().setModel(oModel, sName);
            return this;
        },

        getResourceBundle: function () {
            return this.getOwnerComponent().getModel("i18n").getResourceBundle();
        },

        getText: function (sKey, aArgs) {
            return this.getResourceBundle().getText(sKey, aArgs);
        },

        onNavBack: function () {
            const sPreviousHash = History.getInstance().getPreviousHash();
            if (sPreviousHash !== undefined) {
                window.history.go(-1);
            } else {
                this.getRouter().navTo("worklist", {}, true /* replace */);
            }
        }
    });
});
```

### 9.8 Memory-safe route handler

```js
// ✅ attach eden, detach da eder
onInit: function () {
    this._onRouteMatched = this._onRouteMatched.bind(this);
    this.getRouter().getRoute("detail")
        .attachPatternMatched(this._onRouteMatched);
},

onExit: function () {
    const oRoute = this.getRouter().getRoute("detail");
    if (oRoute) {
        oRoute.detachPatternMatched(this._onRouteMatched);
    }
}
```

---

## 10. Ölçüm & Doğrulama

> **Ölçmediysen kazanç iddia etme.** Her refactor öncesi/sonrası aynı koşullarda ölç.

### 10.1 Ölçüm protokolü

1. Aynı kullanıcı, aynı client, aynı veri hacmi
2. Browser cache **temiz** (cold start) ve **dolu** (warm start) — ikisini de ölç
3. En az 3 tekrar, medyanı al
4. Network throttling'i belgele (Fast 3G / No throttling)

### 10.2 Ölçüm araçları

| Ne ölçülür | Araç |
|---|---|
| Request sayısı, boyut, waterfall | DevTools → Network (Disable cache açık/kapalı) |
| Startup breakdown (UI5 iç fazları) | UI5 Diagnostics: `Ctrl + Shift + Alt + S` → Performance |
| Interaction ölçümleri | `sap/ui/performance/trace/Interaction` + `sap-ui-xx-measure=true` |
| Best-practice ihlalleri | UI5 Support Assistant (Diagnostics içinde) |
| Render maliyeti | DevTools → Performance → uzun task'lar, "Recalculate Style" / "Layout" |
| Bundle boyutu | `dist/` içinde `Component-preload.js` dosya boyutu |
| Deprecated API / global erişim | `npx ui5lint` |
| Memory leak | DevTools → Memory → Heap snapshot (aç/kapa döngüsünden önce ve sonra) |

### 10.3 Öncesi/sonrası tablosu (rapora ekle)

| Metrik | Önce | Sonra | Δ |
|---|---|---|---|
| Cold start (ilk anlamlı içerik) | | | |
| Warm start | | | |
| Toplam request (startup) | | | |
| Transfer edilen boyut | | | |
| `$metadata` boyutu | | | |
| `Component-preload.js` boyutu | | | |
| İlk `$batch` response boyutu | | | |
| İlk tablo render süresi | | | |
| Heap (5 kez aç/kapa sonrası) | | | |

---

## 11. Rapor Şablonu

```markdown
# <Uygulama Adı> — SAPUI5 Modernizasyon Analizi
Tarih: | Analiz edilen dosyalar: | UI5: 1.120.42 | OData: V2

## 0. Yönetici Özeti
- En kritik 3 bulgu:
- Toplam tahmini startup kazancı:
- Business behaviour etkisi olan değişiklik sayısı:

## 1. Startup Lifecycle — Mevcut Durum
(Bölüm 4'teki faz haritasını gerçek ölçümlerle doldur)
| Adım | Süre | Request | Boyut | Critical path? |

## 2. Kritik Problemler
### [CRITICAL] <Başlık>
**Dosya:** path/to/file.js:42
**Problem:**
**Neden problem:**
**Performans etkisi:**
**Önerilen çözüm:**
**Kod örneği:**
**Business behaviour etkisi:** Yok / VAR → <açıklama>

(HIGH / MEDIUM / LOW aynı formatta)

## 3. Quick Wins
| # | Değişiklik | Dosya | Efor | Beklenen kazanç |

## 4. Mimari Problemler

## 5. Performance Problemleri
### 5.1 Startup   ### 5.2 OData/Network   ### 5.3 Rendering   ### 5.4 Memory

## 6. Modernizasyon Önerileri
| ESKİ | YENİ | Dosya | Gerekçe |

## 7. Refactor Edilmiş Kod
(production-ready, tam dosya veya net diff)

## 8. Beklenen Kazanç
| Değişiklik | Startup | Network | Rendering | Memory | Maintainability |

## 9. Son Mimari
(klasör ağacı — sadece gerçekten gerekli olanlar)

## 10. Uygulanmayan / Reddedilen Öneriler
| Öneri | Neden uygulanmadı |
(Bu bölüm önemli — neyi bilerek yapmadığını göstermek, yaptıklarından az değerli değil)
```

---

## 12. Hedef Mimari

**Küçük/orta uygulama (1–3 view):**
```
webapp/
  Component.js            # minimal, IAsyncContentCreation
  manifest.json           # tüm konfigürasyon burada
  index.html              # sadece standalone erişim için
  controller/
    BaseController.js
    Worklist.controller.js
    Detail.controller.js
  model/
    formatter.js          # saf fonksiyonlar
  view/
    App.view.xml
    Worklist.view.xml
    Detail.view.xml
    fragment/
      FilterDialog.fragment.xml
  i18n/
    i18n.properties
    i18n_tr.properties
```

**Büyük uygulama (servis katmanı gerçekten gerekliyse):**
```
webapp/
  Component.js
  manifest.json
  controller/
    BaseController.js
    <Feature>.controller.js
  service/                # SADECE 2+ tüketici veya karmaşık logic varsa
    ODataService.js       # read/create/update sarmalayıcıları, Promise tabanlı
    DialogService.js      # fragment lifecycle merkezi
  model/
    formatter.js
    models.js             # device/view model factory (gerekiyorsa)
  util/
    Constants.js
    Validator.js
  view/
    <Feature>.view.xml
    fragment/
  i18n/
test/
  unit/                   # QUnit — formatter, util, service
  integration/            # OPA5 — kritik akışlar
```

**Klasör açma kuralı:** Bir klasör ancak **2+ dosya** içerecekse ve o dosyalar **gerçekten farklı bir sorumluluk** taşıyorsa açılır. Tek dosyalık `service/` klasörü açma.

**Kök seviye:**
```
ui5.yaml            # specVersion 3.x, framework 1.120.42
ui5-deploy.yaml     # CF deploy (ui5-task-zipper)
package.json        # scripts: lint:ui5 / lint:js / test / build / verify
xs-app.json         # approuter routes
mta.yaml            # version ← applicationVersion ile senkron
.eslintrc / eslint.config.js
.prettierrc
karma.conf.js
```

---

## 13. Anti-Öneriler — Yapmaman Gerekenler

| ❌ Yapma | Neden |
|---|---|
| Sırf "modern" diye tüm kodu `class` syntax'ına çevirmek | UI5 `.extend()` idiomatiktir; kazanç yok, risk var |
| Framework'ün yaptığı cache'i custom kodla tekrar yazmak | UI5 model cache, preload cache zaten var |
| Her fonksiyonu ayrı servise çıkarmak | Okunabilirlik düşer, dosya sayısı artar, kazanç yok |
| Ölçmeden "%40 hızlandı" demek | Doğrulanamaz iddia, güven kaybı |
| `sap-ui-cachebuster` önermek (bu stack'te) | ABAP deployment mekanizması; CF'de geçersiz |
| OData V4 önerileri uygulamak | Bu proje V2; `autoExpandSelect`, `$$aggregation` yok |
| Tüm veriyi çekip client'ta işlemek | Ölçeklenmez; 10.000 kayıtta browser kilitlenir |
| `!important` ile CSS düzeltmek | Tema uyumunu ve gelecek upgrade'i kırar |
| `setTimeout` ile render'ı "beklemek" | Race condition; `attachEventOnce("afterRendering")` veya Promise kullan |
| Business logic'i frontend'e taşıyıp "daha hızlı" demek | UX-001; doğruluk performanstan önce gelir |
| Deprecated API'yi "çalışıyor" diye bırakmak | UI5 2.x'te kaldırılacak; upgrade borcunu büyütür |
| Tek seferde 40 dosyayı birden refactor etmek | Regresyon kaynağı bulunamaz; küçük, ölçülebilir adımlar |

---

## Ek A — Hızlı Komut Referansı

```bash
# Statik analiz (SAP resmi aracı — deprecated API + global erişim yakalar)
npx ui5lint
npx ui5lint --details          # açıklamalı çıktı

# Lint + format
npx eslint webapp --ext .js
npx prettier --write "webapp/**/*.{js,json,xml}"

# Test
npm test                        # karma + QUnit/OPA5

# Production build (Component-preload üretir)
npx ui5 build --clean-dest

# Build çıktısını doğrula
ls -lh dist/Component-preload.js          # var mı, boyutu ne?
grep -c "sap.ui.predefine" dist/Component-preload.js   # içerik dolu mu?

# Local çalıştırma
npx ui5 serve --open index.html
npx ui5 serve --config ui5.yaml --port 8080
```

## Ek B — Browser'da hızlı teşhis

```
Ctrl + Shift + Alt + S     → UI5 Diagnostics (Technical Info, Performance, Support Assistant)
Ctrl + Shift + Alt + P     → Technical Information (UI5 versiyonu, bootstrap)

URL parametreleri (sadece TEST ortamında):
  ?sap-ui-debug=true              → debug kaynakları (preload devre dışı — yavaş, bilinçli kullan)
  ?sap-ui-xx-measure=true         → interaction ölçümü
  ?sap-language=EN                → dil testi
```

**Konsoldan hızlı kontrol:**
```js
// Startup'ta kaç request gitti, ne kadar sürdü?
performance.getEntriesByType("resource")
  .map(r => ({ name: r.name.split("/").pop(), ms: Math.round(r.duration), kb: Math.round(r.transferSize/1024) }))
  .sort((a, b) => b.ms - a.ms)
  .slice(0, 20);
```

---

*Bu doküman yaşayan bir belgedir. Her yeni analizde öğrendiğini Bölüm 6.2, 8.1 ve 13'e ekle.*
