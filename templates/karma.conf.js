/**
 * karma.conf.js — QUnit (unit) + OPA5 (integration) çalıştırıcı
 * Hedef dosya: <proje kökü>/karma.conf.js
 *
 * Kurulum:
 *   npm i -D karma karma-ui5 karma-chrome-launcher karma-qunit karma-coverage
 *
 * ⚠️ Bu bir BAŞLANGIÇ noktasıdır. karma-ui5 projenin ui5.yaml'ını okur;
 *    kendi klasör yapına göre `paths` ve test dosya yollarını doğrula.
 *
 * Neden gerekli (UX-006): UX-001 (business logic'i backend'e taşıma) ve
 * UX-002 (controller bölme) refactor'leri TEST OLMADAN yapılırsa regresyon riski
 * kabul edilemez seviyededir. Test altyapısı bu iki maddenin ön koşuludur.
 */
module.exports = function (config) {
    config.set({
        frameworks: ["ui5"],

        ui5: {
            url: "https://ui5.sap.com/1.120.42",
            type: "application",
            paths: {
                webapp: "webapp"
            }
        },

        // Coverage: sadece üretim kaynakları ölçülür, test dosyaları hariç
        preprocessors: {
            "webapp/!(test)/**/*.js": ["coverage"],
            "webapp/*.js": ["coverage"]
        },

        coverageReporter: {
            includeAllSources: true,
            reporters: [
                { type: "html", dir: "coverage" },
                { type: "text-summary" }
            ],
            check: {
                // Mevcut duruma göre başlat, zamanla YÜKSELT.
                // Sıfırdan %80 dayatmak pipeline'ı bloke eder ve araç kapatılır.
                global: {
                    statements: 30,
                    branches: 20,
                    functions: 30,
                    lines: 30
                }
            }
        },

        reporters: ["progress", "coverage"],

        browsers: ["ChromeHeadlessNoSandbox"],
        customLaunchers: {
            ChromeHeadlessNoSandbox: {
                base: "ChromeHeadless",
                flags: ["--no-sandbox", "--disable-gpu"]   // CI container'ları için
            }
        },

        singleRun: true,
        browserConsoleLogOptions: { level: "error" }
    });
};
