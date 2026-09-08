# Kurulum — Mevcut bir Fiori uygulamasında kullanma

> **Önemli:** Bir `.md` dosyası kendi başına "çalıştırılamaz". Ama Claude Code'da onu
> `/komut` yazarak tetiklenebilir hale getirmenin yolu var: **skill**.
> Bu klasör tam olarak onu kuruyor.

## Hızlı kurulum

```bash
# 1. Bu repoyu bir kere klonla (uygulamanın DIŞINA)
git clone https://github.com/HuseyinAykin/CodeReviewSAPUI5.git ~/CodeReviewSAPUI5

# 2. Uygulamana kur
cd ~/CodeReviewSAPUI5
./claude-setup/install.sh /yol/fiori-uygulaman

# Tooling config'leriyle birlikte (ESLint + Prettier + Karma + CI):
./claude-setup/install.sh /yol/fiori-uygulaman --with-tooling
```

Kurulum şunları oluşturur:

```
fiori-uygulaman/
└── .claude/
    └── skills/
        └── fiori-modernizasyon/
            ├── SKILL.md          ← /fiori-modernizasyon komutu
            ├── PLAYBOOK.md       ← ihtiyaç oldukça okunan referans
            └── RAPOR-SABLONU.md
```

Sonra VS Code'da uygulamayı aç, Claude Code oturumu başlat ve yaz:

```
/fiori-modernizasyon
```

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

```bash
cp ~/CodeReviewSAPUI5/CLAUDE.md /yol/fiori-uygulaman/CLAUDE.md
```

⚠️ Uygulamanda zaten bir `CLAUDE.md` varsa **üzerine yazma** — içeriği birleştir.

## Güncelleme

Playbook'u güncellediğinde uygulamalardaki kopyaları tazele:

```bash
cd ~/CodeReviewSAPUI5 && git pull
./claude-setup/install.sh /yol/fiori-uygulaman --force
```

`--force` olmadan mevcut dosyalar korunur (kurulum betiği hiçbir şeyin üzerine sessizce yazmaz).

## Sorun giderme

**`/fiori-modernizasyon` menüde çıkmıyor:**
- VS Code'da açtığın klasör, `.claude/` dizininin bulunduğu proje kökü mü? Skill proje köküne göre çözülür.
- Claude Code oturumunu yeniden başlat.
- `ls .claude/skills/fiori-modernizasyon/SKILL.md` ile dosyanın yerinde olduğunu doğrula.
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
