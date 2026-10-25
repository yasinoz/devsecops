# Lab Çözümü

`labs/dast/uygulama/guvenlik-basliklari.conf` dosyasındaki CSP satırını
bulun:

```
add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'" always;
```

`default-src`'ye düşmeyen yönergeleri ekleyin:

```
add_header Content-Security-Policy "default-src 'self'; frame-ancestors 'none'; form-action 'self'; frame-src 'none'; object-src 'none'; base-uri 'self'" always;
```

Eklenenlerin her biri ayrı bir deliği kapatıyor:

| Yönerge | Neyi engelliyor |
|---|---|
| `form-action 'self'` | Formun başka bir siteye gönderilmesini. Saldırgan sayfaya form enjekte etse bile veri dışarı çıkamıyor. |
| `frame-src 'none'` | Sayfanın başka bir siteyi çerçeve içine gömmesini. |
| `object-src 'none'` | `<object>` ve `<embed>` ile eklenti içeriği yüklenmesini. Eski ama hâlâ işleyen bir saldırı yüzeyi. |
| `base-uri 'self'` | `<base>` etiketiyle bütün göreli bağlantıların başka bir sunucuya yönlendirilmesini. |

Container'ı yeniden oluşturup tarayın:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: Session Management Response Identified [10112] x 1
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 2   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 66
```

`10055` gitti. Geçen kontrol 65'ten 66'ya çıktı.

## İkinci adım: istisnayı kaldırmak

`labs/dast/kurallar.conf` dosyasında `10055` satırını bulun:

```
10055	IGNORE	(CSP)	CSP'yi kademeli siklastiriyoruz; form-action/frame-src bir sonraki surumde. Sahibi: portal ekibi, son tarih 2026-12-31.
```

`IGNORE` yerine `WARN` yazın ve gerekçeyi silin — artık bir gerekçeye gerek
yok, sorun düzeldi:

```
10055	WARN	(CSP)
```

Kapıyı çalıştırın:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -c kurallar.conf
```

```
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 0   WARN-INPROG: 0   INFO: 0   IGNORE: 2   PASS: 66
```

Çıkış kodu **0**. Kapı geçiyor ve artık `10055` için bir istisna taşımıyor.

## Buradaki asıl ders

İstisna satırı ikisinden biri olabilir:

- **Bir karar.** "Bunu şimdilik kabul ediyoruz, sebebi şu, sahibi şu, şu
  tarihte tekrar bakacağız."
- **Bir unutma.** "Bu bulgu can sıkıyordu, sustur gitsin."

İkisi dosyada **birebir aynı** görünüyor. Aralarındaki farkı yaratan tek şey,
yanına yazılan gerekçe ve birinin o tarihte dönüp bakması.

Bu labda sorunu düzelttik ve istisnayı kaldırdık. Kaldırmasaydık ne olurdu?
CSP ileride yanlışlıkla gevşetildiğinde `10055` yine çıkacaktı — ama kural
dosyası onu hâlâ `IGNORE` ettiği için **hiç görünmeyecekti**. Kapı yerinde
duruyor gibi görünürken aslında o konuda kör olacaktı.

> Düzelttiğiniz her bulgu için istisnasını da kaldırın. İstisna listesi,
> temizlenmediği sürece zamanla tarayıcının kör noktalarının listesine
> dönüşüyor.

___
> [Alıştırmalara](README.tr.md) dönün.
