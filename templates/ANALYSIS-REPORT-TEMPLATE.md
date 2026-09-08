# <Uygulama Adı> — SAPUI5 Modernizasyon Analizi

| | |
|---|---|
| Tarih | |
| Analiz eden | |
| UI5 Runtime | 1.120.42 |
| OData | V2 |
| Deployment | BTP CF + Work Zone |
| Analiz edilen dosya sayısı | |

---

## 0. Yönetici Özeti

**En kritik 3 bulgu:**
1.
2.
3.

**Toplam tahmini startup kazancı:** … ms (ölçülmüş / tahmini — belirt)
**Business behaviour etkisi olan değişiklik sayısı:** …
**Önerilen ilk sprint kapsamı:** …

---

## 1. Startup Lifecycle — Mevcut Durum

> Playbook Bölüm 4'teki faz haritasını GERÇEK ÖLÇÜMLERLE doldur.
> Ölçüm koşulu: cold start / warm start, 3 tekrar medyanı, throttling belirt.

**Ölçüm koşulları:** cache: … | throttling: … | tekrar: 3, medyan

| Adım | Süre (ms) | Request | Boyut (KB) | Critical path? | Not |
|---|---|---|---|---|---|
| FLP → Component load | | | | ✅ | |
| Component-preload.js | | | | ✅ | var mı? |
| manifest.json | | | | ✅ | |
| i18n bundle | | | | ✅ | supportedLocales? |
| $metadata | | | | ✅ | boyut? |
| flex data (LREP) | | | | ❌ | flexEnabled? |
| Ek lib'ler | | | | ⚠️ | hangileri? |
| Custom CSS | | | | ⚠️ | |
| onInit içi read'ler | | | | ⚠️ | waterfall mı? |
| İlk $batch | | | | ✅ | $select var mı? |
| İlk tablo render | | | | ✅ | satır sayısı? |
| **TOPLAM** | | | | | |

**Tespit edilen critical path:**
```
… → … → … → …
```

**Critical path DIŞINDA olup şu an eager yüklenenler (lazy adayları):**
-

---

## 2. Kritik Problemler

### [CRITICAL] <Başlık>
| | |
|---|---|
| **Dosya** | `path/to/file.js:42` |
| **İlgili issue** | UX-00… / — |
| **Playbook bölümü** | 5.… |

**Problem:**

**Neden problem:**

**Performans etkisi:**

**Önerilen çözüm:**

**Kod örneği:**
```js
// ÖNCE

// SONRA
```

**Business behaviour etkisi:** Yok / **VAR** → …
**Test gereksinimi:**

---

### [HIGH] <Başlık>
*(aynı format)*

### [MEDIUM] <Başlık>

### [LOW] <Başlık>

---

## 3. Quick Wins

> Az kod değişikliği, yüksek kazanç. Bunlar ilk sprint'e girer.

| # | Değişiklik | Dosya | Efor | Beklenen kazanç | Risk |
|---|---|---|---|---|---|
| 1 | | | XS/S/M | | |

---

## 4. Mimari Problemler

| # | Problem | Etkilenen dosyalar | Önerilen yapı | Efor |
|---|---|---|---|---|

**Controller büyüklük tablosu (UX-002):**

| Controller | Satır | Fonksiyon | Sorumluluk sayısı | Aksiyon |
|---|---|---|---|---|

---

## 5. Performance Problemleri

### 5.1 Startup
### 5.2 OData / Network

**Request envanteri:**

| # | Request | Ne zaman | $select? | Boyut | Gerekli mi? | Aksiyon |
|---|---|---|---|---|---|---|

### 5.3 Rendering
### 5.4 Memory

**Leak kontrolü:**

| Kaynak | attach/create | detach/destroy | Durum |
|---|---|---|---|
| EventBus | | | |
| Route matched | | | |
| Timer | | | |
| Dialog / Fragment | | | |
| Device handler | | | |

---

## 6. Modernizasyon Önerileri

| # | ESKİ | YENİ | Dosya | Gerekçe |
|---|---|---|---|---|

**`ui5lint` çıktısı özeti:**
```
(npx ui5lint --details çıktısını buraya yapıştır)
```

---

## 7. Refactor Edilmiş Kod

> Teorik öneri değil — production-ready kod. Tam dosya veya net diff.

---

## 8. Beklenen Kazanç

| # | Değişiklik | Startup | Network | Rendering | Memory | Maintainability |
|---|---|---|---|---|---|---|
| 1 | | | | | | |

**Ölçülmüş öncesi/sonrası:**

| Metrik | Önce | Sonra | Δ |
|---|---|---|---|
| Cold start | | | |
| Warm start | | | |
| Toplam request | | | |
| Transfer boyutu | | | |
| $metadata boyutu | | | |
| Component-preload.js | | | |
| İlk $batch response | | | |
| İlk tablo render | | | |
| Heap (5× aç/kapa) | | | |

---

## 9. Son Mimari

```
webapp/
  …
```

**Neden bu yapı:**

---

## 10. Uygulanmayan / Reddedilen Öneriler

> Bu bölüm önemli. Neyi **bilerek** yapmadığını göstermek, yaptıklarından az değerli değildir.

| # | Öneri | Kaynak | Neden uygulanmadı |
|---|---|---|---|
| 1 | | PDF UX-00… / genel best practice | |

---

## 11. Issue Kapanış Durumu

| Issue | Durum | Yapılanlar | Kalan |
|---|---|---|---|
| UX-001 Frontend business/tax calc | 🔴 Açık / 🟡 Kısmi / 🟢 Kapalı | | |
| UX-002 God-controller | | | |
| UX-003 DOM manipulation | | | |
| UX-004 UI processing perf | | | |
| UX-005 Cache / versioning | | | |
| UX-006 Static analysis | | | |
