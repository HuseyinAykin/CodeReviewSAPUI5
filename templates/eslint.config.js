/**
 * ESLint flat config — SAPUI5 1.120 (Freestyle, OData V2)
 * Hedef dosya: <proje kökü>/eslint.config.js   (ESLint 9+)
 *
 * Kurulum:
 *   npm i -D eslint globals
 *
 * NOT: Deprecated UI5 API tespitinde ASIL araç `ui5lint`'tir (SAP resmi).
 * Buradaki no-restricted-syntax kuralları hafif bir yedek katmandır —
 * ui5lint'in yerini TUTMAZ, onunla birlikte çalışır.
 *
 * ESLint 8 kullanıyorsan bu dosya yerine .eslintrc.json gerekir;
 * kural gövdeleri aynen taşınabilir, sadece sarmalayıcı yapı değişir.
 */
const globals = require("globals");

module.exports = [
    {
        files: ["webapp/**/*.js"],
        ignores: ["webapp/test/**", "webapp/localService/**", "dist/**"],

        languageOptions: {
            // 1.120 sadece evergreen browser destekler → ES2022 güvenli.
            ecmaVersion: 2022,
            // UI5 1.x AMD (sap.ui.define) kullanır — ESM DEĞİL.
            sourceType: "script",
            globals: {
                ...globals.browser,
                sap: "readonly",
                jQuery: "readonly",
                QUnit: "readonly",
                sinon: "readonly",
                opaTest: "readonly"
            }
        },

        rules: {
            /* --- Ölü kod / okunabilirlik (Playbook 5.18) --- */
            "no-unused-vars": ["error", { args: "none" }],
            "no-undef": "error",
            "no-console": "warn",              // → sap/base/Log kullan
            "no-debugger": "error",
            "no-alert": "error",
            "no-empty": ["error", { allowEmptyCatch: false }],

            /* --- Modern JS (Playbook 1.1) --- */
            "no-var": "error",
            "prefer-const": "error",
            "eqeqeq": ["error", "smart"],

            /* --- Güvenlik (Playbook 5.11 / UX-003) --- */
            "no-eval": "error",
            "no-implied-eval": "error",
            "no-new-func": "error",
            "no-script-url": "error",

            /* --- SAPUI5 anti-pattern'ları (Playbook 5.3 / 5.6 / 7) --- */
            "no-restricted-syntax": [
                "error",
                {
                    selector:
                        "CallExpression[callee.object.object.name='sap'][callee.object.property.name='ui'][callee.property.name='getCore']",
                    message:
                        "sap.ui.getCore() 1.118+ deprecated. Element.getElementById / Core.ready / EventBus.getInstance / Library.load / Theming / Localization kullan (Playbook 7.1)."
                },
                {
                    selector:
                        "CallExpression[callee.object.object.name='sap'][callee.object.property.name='ui'][callee.property.name=/^(view|xmlview|jsview|htmlview|fragment|xmlfragment|jsfragment|htmlfragment|controller|component|extensionpoint)$/]",
                    message:
                        "Senkron + deprecated factory. Async karşılığını kullan: XMLView.create / Fragment.load / Controller.create / Component.create (Playbook 7.2)."
                },
                {
                    selector: "CallExpression[callee.object.object.name='sap'][callee.object.property.name='ui'][callee.property.name='requireSync']",
                    message: "sap.ui.requireSync senkron yükleme yapar. sap.ui.define / sap.ui.require kullan (Playbook 5.3)."
                },
                {
                    selector: "MemberExpression[object.object.name='jQuery'][object.property.name='sap']",
                    message: "jQuery.sap.* deprecated. sap/base/* modüler karşılıklarını kullan (Playbook 7.3)."
                },
                {
                    selector: "NewExpression[callee.object.object.name='sap']",
                    message:
                        "Global sap.* üzerinden kontrol yaratma. sap.ui.define ile explicit import et (Playbook 7.4)."
                },
                {
                    selector: "AssignmentExpression[left.property.name=/^(innerHTML|outerHTML)$/]",
                    message:
                        "innerHTML/outerHTML — XSS riski + UI5 render'ında silinir. Declarative binding kullan (UX-003, Playbook 5.11)."
                },
                {
                    selector: "CallExpression[callee.property.name='rerender']",
                    message: "rerender() 1.70'te deprecated. invalidate() kullan (Playbook 7.5)."
                },
                {
                    selector:
                        "CallExpression[callee.object.name='document'][callee.property.name=/^(getElementById|querySelector|querySelectorAll|write)$/]",
                    message:
                        "Doğrudan DOM erişimi. UI5 kontrol API'sini kullan; ölçüm için getDomRef() + null kontrolü (UX-003, Playbook 5.6)."
                }
            ]
        }
    },

    /* Test dosyaları: konsol ve global'ler serbest */
    {
        files: ["webapp/test/**/*.js"],
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: "script",
            globals: {
                ...globals.browser,
                sap: "readonly",
                QUnit: "readonly",
                sinon: "readonly",
                opaTest: "readonly"
            }
        },
        rules: {
            "no-console": "off",
            "no-unused-vars": ["warn", { args: "none" }]
        }
    }
];
