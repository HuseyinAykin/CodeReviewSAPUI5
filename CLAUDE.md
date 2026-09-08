# CLAUDE.md

Bu repo bir **SAPUI5 / SAP Fiori modernizasyon & code review referans dokümanıdır** — uygulama kodu içermez.

## Ana kaynak

Herhangi bir SAPUI5/Fiori analiz, review veya refactor işine başlamadan **önce** oku:

📘 `SAPUI5-MODERNIZATION-PLAYBOOK.md`

## Hedef stack

SAPUI5 **1.120.42** · OData **V2** · BTP **Cloud Foundry** (HTML5 App Repo + approuter) · SAP **Build Work Zone** · **Freestyle** SAPUI5 · Backend **S/4HANA On-Premise**

Bu stack'e özgü, sık yapılan hatalar:
- OData **V4** önerileri (`autoExpandSelect`, `earlyRequests`, `$$aggregation`) **geçerli değil**
- ABAP'a özgü `sap-ui-cachebuster` **geçerli değil** — CF'de versiyonlama HTML5 App Repo'da
- Work Zone'da uygulama **Component olarak** yüklenir; `index.html` FLP içinde **kullanılmaz**
- UI5 core ve `sap.m`/`sap.f` FLP tarafından **zaten yüklenmiştir** — manifest'te listelemek ek maliyet değildir
- ESM (`import`/`export`) UI5 1.x runtime'ında **çalışmaz** — her modül `sap.ui.define`

## Çalışma kuralları

1. **Lokal optimizasyon yapma.** Önce startup lifecycle'ı uçtan uca çıkar (Playbook Bölüm 4), sonra critical path dışındaki her şeyi lazy-load et.
2. **Dosyaları tek sistem olarak değerlendir.** Bir dosyayı incelerken önceki dosyalarda gördüğün mimariyi hatırla.
3. **Ölçmediysen kazanç iddia etme.** Playbook Bölüm 10'daki protokolü kullan.
4. **Business behaviour etkisi olan her değişikliği açıkça yaz.** Özellikle: `flexEnabled`, `refreshAfterChange`, `defaultCountMode`, `sap-value-list`, `$select` daraltması, client→server filtreleme geçişi.
5. **Framework'ün zaten yaptığını custom kodla tekrar yazma.**
6. **Gereksiz abstraction yaratma.** Servis katmanı ancak (a) 2+ tüketici, (b) test gereksinimi, (c) gerçek karmaşıklık varsa açılır.
7. **Sadece "best practice" olduğu için değişiklik önerme.** Her önerinin ölçülebilir gerekçesi olmalı (Playbook Bölüm 13 — anti-öneriler listesi).

## Yeni analiz başlatırken

- Master prompt: Playbook **Bölüm 3**
- Dosya inceleme sırası: `manifest.json` → `Component.js` → `ui5.yaml`/`package.json`/`xs-app.json` → routing target'ları → root view → ana tablo view'u → controller → formatter/util → fragment'lar
- Rapor iskeleti: `templates/ANALYSIS-REPORT-TEMPLATE.md`
- Manuel review'dan önce statik analizi çalıştır: `npx ui5lint --details`

## Bu repoyu güncellerken

Yeni bir analizde öğrenilen kalıcı bilgiyi Playbook'un şu bölümlerine ekle:
- **6.2** — issue list'te olmayan ama sık çıkan riskler
- **8.1** — refactor sırası ve gerçekleşen kazanç aralıkları
- **13** — anti-öneriler
