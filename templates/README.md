# Templates

Fiori/SAPUI5 projesine **doğrudan kopyalanabilir** config dosyaları.
Ana referans: [`../SAPUI5-MODERNIZATION-PLAYBOOK.md`](../SAPUI5-MODERNIZATION-PLAYBOOK.md)

Bu klasör esas olarak **UX-006 (Insufficient Automated Code Quality and Static Analysis)** maddesini kapatmak için hazırlandı — uygulama kodunu görmeye ihtiyaç duymayan tek issue budur.

## Dosyalar

| Template | Hedef konum | Ne yapar |
|---|---|---|
| `eslint.config.js` | `eslint.config.js` | ESLint 9 flat config. Ölü kod, `no-console`, modern JS + **SAPUI5 anti-pattern kuralları** (`sap.ui.getCore()`, `jQuery.sap.*`, sync factory'ler, `innerHTML`, doğrudan DOM erişimi) |
| `.prettierrc.json` | `.prettierrc.json` | Format tutarlılığı (JS/XML/JSON) |
| `.prettierignore` | `.prettierignore` | `dist/`, mock data, `.properties` hariç |
| `ui5.yaml` | `ui5.yaml` | Geliştirme + build. `test/` ve `localService/` bundle'dan hariç |
| `ui5-deploy.yaml` | `ui5-deploy.yaml` | CF/HTML5 App Repo deploy build'i (`ui5-task-zipper`) |
| `karma.conf.js` | `karma.conf.js` | QUnit + OPA5 + coverage |
| `package-scripts.jsonc` | `package.json` içine **birleştir** | `lint` / `format` / `test` / `build` / `verify` script'leri + devDependencies |
| `github-workflow-verify.yml` | `.github/workflows/verify.yml` | CI: lint → format → test → build → **preload doğrulaması** → applicationVersion kontrolü |
| `ANALYSIS-REPORT-TEMPLATE.md` | analiz çıktısı | Playbook Bölüm 11'in doldurulabilir hali + issue kapanış tablosu |

## Kurulum sırası

```bash
# 1. Config dosyalarını kopyala
cp templates/eslint.config.js  templates/.prettierrc.json  templates/.prettierignore  <proje>/
cp templates/karma.conf.js <proje>/
mkdir -p <proje>/.github/workflows
cp templates/github-workflow-verify.yml <proje>/.github/workflows/verify.yml

# 2. package.json'a script + devDependencies'i birleştir (package-scripts.jsonc)

# 3. Bağımlılıkları kur
npm i -D @ui5/cli@^3 @ui5/linter eslint globals prettier \
         karma karma-ui5 karma-qunit karma-chrome-launcher karma-coverage

# 4. İlk taramayı çalıştır — bu, manuel review'a girmeden önceki BAŞLANGIÇ NOKTASIDIR
npx ui5lint --details > ui5lint-baseline.txt
npx eslint webapp      > eslint-baseline.txt 2>&1 || true

# 5. Build doğrula — en büyük startup katili buradan çıkar
npx ui5 build --clean-dest
ls -lh dist/Component-preload.js
```

## Önemli notlar

**`ui5lint` ana araçtır.** ESLint'teki `no-restricted-syntax` kuralları hafif bir yedek katmandır, `ui5lint`'in yerini tutmaz. İkisini birlikte çalıştır.

**Selector'lar doğrulandı.** `eslint.config.js` içindeki 8 `no-restricted-syntax` selector'ı `esquery` + `espree` ile 18 vakaya karşı test edildi: 11 pozitif (`sap.ui.getCore()`, `sap.ui.xmlview`, `sap.ui.xmlfragment`, `sap.ui.controller`, `sap.ui.requireSync`, `jQuery.sap.*`, `new sap.m.Dialog`, `innerHTML=`, `rerender()`, `document.getElementById`, `document.querySelector`) ve 7 negatif (`sap.ui.define`, `sap.ui.require`, `Element.getElementById`, `Fragment.load`, `invalidate()`, `getDomRef()`, `new JSONModel`) — yanlış pozitif yok. Geçersiz bir selector ESLint'i tamamen çökertir, bu yüzden kural eklerken aynı kontrolü tekrarla.

**`@ui5/cli` v3+ zorunlu.** v2'nin terser sürümü `?.` ve `??` syntax'ını parse edemez; kod runtime'da çalışsa bile **build aşamasında patlar** (Playbook 1.1).

**Coverage eşiğini düşük başlat.** `karma.conf.js` içinde %30 ile başlıyor. Sıfırdan %80 dayatmak pipeline'ı bloke eder ve ekip aracı devre dışı bırakır. Zamanla yükselt.

**CI job'ı merge blocker yap.** Branch protection rule olmadan UX-006 kapanmaz — araç kurulmuş ama etkisiz kalır.

**Baseline'ı sakla.** İlk `ui5lint` / `eslint` çıktısını commit'le. Sonraki analizlerde "ne kadar iyileşti" sorusunun tek dürüst cevabı bu karşılaştırmadır.
