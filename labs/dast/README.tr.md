---
title: Çalışan Uygulamayı Taramak (DAST)
lang: tr
slug: dast
section: security
order: 6
duration: 50
requires: [docker]
status: updated
upstream: labs/dast
---
# Çalışan Uygulamayı Taramak (DAST)

Şimdiye kadarki güvenlik laboratuvarlarının hepsi **duran** bir şeye baktı:
statik analiz kaynak kodunu okudu, imaj taraması paketleri okudu, sır taraması
git geçmişini okudu. Hiçbiri uygulamayı çalıştırmadı.

**DAST** (Dynamic Application Security Testing) tam tersini yapıyor: kaynağa
hiç bakmıyor, çalışan uygulamaya dışarıdan istek gönderip **ne cevap
verdiğine** bakıyor. Saldırganın gördüğü neyse onu görüyor.

Bu neden ayrı bir şey? Çünkü bir uygulamanın davranışı kaynak kodunda
yazanla aynı olmayabilir. Yapılandırma dosyası doğru görünür ama sunucu onu
beklediğiniz gibi uygulamaz; ters vekil sunucu bir başlığı ezer; derleme
sırasında bir ayar kaybolur. Bu labda tam olarak böyle bir durumla
karşılaşacaksınız — ve o an, DAST'ın neden var olduğunun cevabı olacak.

Kullanacağımız araç [OWASP ZAP](https://www.zaproxy.org/). *Baseline* taraması
uygulamayı gezip (spider) gelen yanıtları pasif olarak inceliyor; saldırı
denemiyor, bu yüzden hızlı ve üretim dışı ortamlarda güvenle koşuyor.

<!-- outcomes:auto -->
<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 50 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Bu lab ne işe yarıyor

Bu eğitimdeki diğer güvenlik kontrollerinin hepsi duran bir şeyi okuyor — kaynak, paketler, geçmiş. Hiçbiri uygulamayı çalıştırmıyor, dolayısıyla sunucunun gerçekte ne cevap verdiğini görmüyor. Bir yapılandırma dosyada doğru, hatta yanlış olabilir; hangisi olduğunu yalnızca çalışan uygulamaya gönderilen bir istek söylüyor.

**Bu labdan sonra şunları yapabileceksiniz:**

- çalışan bir uygulamayı OWASP ZAP ile tarayıp raporu okumak
- eksik başlık, çerez bayrağı ve bilgi sızıntısı bulgularını ayırmak
- kod incelemesinden geçen ama tek bir uç noktada çöken kusuru bulmak
- taramayı FAIL, WARN ve gerekçeli IGNORE kurallarıyla kapıya çevirmek
<!-- /outcomes:auto -->

<!-- orientation:auto -->
## Bu lab nasıl işliyor

Bunu bir kez okuyun - bu eğitimdeki her lab aynı kurallarla yazıldı.

**Komutları nereye yazacaksınız.** Bir terminal açın ve bu depoyu kopyaladığınız
klasöre gidin. Windows'ta **PowerShell** kullanın (Başlat menüsünde aratın),
macOS veya Linux'ta **Terminal**. Labdaki bütün yollar depo kökünden yazıldı,
yani bir adım aksini söylemedikçe orada kalın.

**`>` ile başlayan satırlar açıklamadır, komut değildir.** Onları yapıştırmayın.
Yalnızca gri kod kutularının içindeki metin yazılır.

**📋 işareti "sıra sizde" demektir.** Onu gördüğünüzde adımı önce kendiniz
deneyin. Hemen altında cevabı saklayan kapalı bir **"Nasıl yapılır?"** oku var;
onu denedikten *sonra* açın, önce değil. Lablar bilerek böyle yazıldı: kendi
çözdüğünüz şeyi hatırlarsınız, yapıştırdığınızı değil.

**Bir komut hata verirse bu normal olabilir.** Bazı adımlar hatanın nasıl
göründüğünü göstermek için bilerek başarısız olur. Bir şeyin bozuk olduğuna
karar vermeden önce komutun üstündeki cümleyi okuyun.

**Takılırsanız** şu sırayla:

1. Komutun üstündeki paragrafı tekrar okuyun - cevap genelde oradadır.
2. **"Nasıl yapılır?"** okunu açın.
3. `hints.md` dosyasını açın, küçük bir yönlendirme verir.
4. `solution.md` dosyasını açın, tam cevap orada. Kullanmak serbest; okumadan
   kopyalamak değil.

**Bitirdiğinizde** en alttaki **Temizlik** bölümünü çalıştırın. Lablar aynı
portları ve container adlarını paylaşıyor; birinden kalan artık diğerini bozar.
<!-- /orientation:auto -->

## Kaynaklar

- [OWASP ZAP — Baseline taraması](https://www.zaproxy.org/docs/docker/baseline-scan/)

- [OWASP Top 10 — A05:2021 Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

- [OWASP ASVS — V14 Configuration](https://owasp.org/www-project-application-security-verification-standard/)

- [NIST SSDF (SP 800-218) PW.8 — yazılımın test edilmesi](https://csrc.nist.gov/pubs/sp/800/218/final)

## Uygulamayı çalıştırmak

Hedefimiz küçük bir sipariş portalı — nginx üzerinde duran bir sayfa ve bir
giriş uç noktası:

```
docker compose -f labs/dast/docker-compose.yml up -d
```

Tarayıcınızdan http://localhost:8085 adresini açıp bakın. Sıradan bir sayfa:
bir form, bir de "Giris yap" bağlantısı. Gözle bakarak bir sorun
göremezsiniz — zaten mesele de o.

## İlk tarama

ZAP'i uygulamayla aynı Docker ağına bağlayıp çalıştırıyoruz. Uygulamaya
`uygulama` adıyla, container adı üzerinden erişiyor:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -r rapor/rapor.html
```

Tarama bir iki dakika sürüyor. Sonunda şuna benzer bir özet göreceksiniz:

```
WARN-NEW: Cookie No HttpOnly Flag [10010] x 1
WARN-NEW: Missing Anti-clickjacking Header [10020] x 3
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 3
WARN-NEW: Server Leaks Version Information via "Server" HTTP Response Header Field [10036] x 5
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 4
WARN-NEW: Storable and Cacheable Content [10049] x 5
WARN-NEW: Cookie without SameSite Attribute [10054] x 1
WARN-NEW: Permissions Policy Header Not Set [10063] x 5
WARN-NEW: Session Management Response Identified [10112] x 2
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 9
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 11   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 57
```

> Sizdeki sayılar bir iki kalem oynayabilir. ZAP önce siteyi geziyor ve her
> koşuda tam olarak aynı adresleri bulmayabiliyor. Bulguların **cinsi** aynı
> kalıyor, önemli olan o.

Ayrıntılı rapor `labs/dast/rapor/rapor.html` dosyasında. Tarayıcınızla açın;
her bulgunun açıklaması, hangi adreste görüldüğü ve çözüm önerisi orada.

📋 Bu 11 uyarıya bakıp üç gruba ayırın: hangileri eksik bir başlık, hangileri
çerezle ilgili, hangisi bilgi sızdırıyor?

<details>
  <summary>Cevap</summary>

**Eksik güvenlik başlıkları** — tarayıcıya "bu sayfayı nasıl ele al" diyen
yanıt başlıkları yok:

- `10020` Anti-clickjacking — sayfa başkasının iframe'ine konabiliyor
- `10021` X-Content-Type-Options — tarayıcı içerik türünü tahmin ediyor
- `10038` CSP — hangi kaynakların yüklenebileceğine dair kural yok
- `10063` Permissions Policy — kamera, konum gibi yetenekler kısıtlanmamış
- `90004` Cross-Origin-Embedder-Policy — çapraz kaynak yalıtımı yok

**Çerez sorunları** — `/giris` oturum çerezini bayraksız veriyor:

- `10010` HttpOnly yok — JavaScript çerezi okuyabiliyor, yani bir XSS
  doğrudan oturum hırsızlığına dönüşüyor
- `10054` SameSite yok — çerez başka siteden gelen isteklerle de gidiyor

**Bilgi sızıntısı:**

- `10036` Sunucu `Server: nginx/1.31.7` diyerek sürümünü söylüyor. Tek
  başına açık değil ama saldırgana hangi CVE'yi deneyeceğini söylüyor.

Kalan ikisi (`10049`, `10112`) bilgilendirme niteliğinde; birazdan onlara
ayrıca döneceğiz.

</details><br/>

Şuna dikkat edin: bu bulguların **hiçbiri kaynak kodda değil**. `index.html`
dosyasında bir açık yok. Hepsi sunucunun nasıl yapılandırıldığıyla ilgili —
yani statik analizin bakmadığı yerde.

## İlk düzeltme denemesi

`labs/dast/uygulama/` klasöründe `nginx.guvenli.conf` adında ikinci bir
yapılandırma var. Açıp okuyun: eksik olduğu söylenen her başlık orada, her
birinin yanında hangi bulguyu kapattığı yazıyor. Çerez de üç bayrağını almış.

Uygulamaya bunu bağlayalım. `labs/dast/docker-compose.yml` dosyasını açın ve
şu satırdaki dosya adını değiştirin:

```
      - ./uygulama/nginx.conf:/etc/nginx/conf.d/default.conf:ro
```

şöyle olsun:

```
      - ./uygulama/nginx.guvenli.conf:/etc/nginx/conf.d/default.conf:ro
```

Uygulamayı yeniden başlatın:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

Taramayı tekrarlayın:

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Missing Anti-clickjacking Header [10020] x 1
WARN-NEW: X-Content-Type-Options Header Missing [10021] x 1
WARN-NEW: Content Security Policy (CSP) Header Not Set [10038] x 1
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: CSP: Failure to Define Directive with No Fallback [10055] x 4
WARN-NEW: Permissions Policy Header Not Set [10063] x 1
WARN-NEW: Session Management Response Identified [10112] x 1
WARN-NEW: Cross-Origin-Embedder-Policy Header Missing or Invalid [90004] x 3
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 8   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 60
```

11'den 8'e indi, geçen kontrol sayısı 57'den 60'a çıktı. İyi.

**Ama durun.** Anti-clickjacking hâlâ orada. X-Content-Type-Options hâlâ
orada. CSP hâlâ orada. Yapılandırma dosyasında bu başlıkların üçü de yazıyor,
gözünüzle gördünüz.

Bir fark var: eskiden `x 3` diyordu, şimdi `x 1`.

📋 Bu "x 1" hangi adres? Bulun.

<details>
  <summary>Nasıl yapılır?</summary>

Taramayı ayrıntılı çalıştırın; ZAP her bulgunun altında örnek adresleri
yazıyor:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -r rapor/ikinci.html
```

Çıktıda `Missing Anti-clickjacking Header [10020] x 1` satırının altında tek
bir adres göreceksiniz:

```
	http://uygulama/giris (200 OK)
```

Ana sayfa düzeldi. `/giris` düzelmedi.

</details><br/>

### Neden `/giris` düzelmedi

Yapılandırmaya tekrar bakın. `/giris` için ayrı bir `location` bloğu var ve
içinde `add_header` satırları duruyor — çerez ve önbellek başlıkları.

nginx'in kuralı şu: **bir `location` bloğunda `add_header` kullanırsanız, o
blok üst seviyedeki bütün `add_header` satırlarını kaybeder.** Miras yok. Ya
hepsini o blokta tekrar yazarsınız ya da hiçbiri uygulanmaz.

`always` eklemek de kurtarmıyor; `always` başlığın hata yanıtlarında da
görünmesini sağlıyor, mirasla ilgisi yok.

Şimdi bu hatanın neye benzediğini düşünün:

- Yapılandırma dosyasına bakan kişi başlıkları **görüyor**. Kod incelemesi
  geçiyor.
- Statik analiz bir şey demiyor; dosyada yanlış yazılmış bir şey yok.
- Ana sayfayı tarayıcıda açıp başlıkları kontrol eden kişi **doğru**
  sonucu görüyor.
- Yalnızca oturum açan kullanıcı korumasız kalıyor — yani en çok korunması
  gereken istek.

Bu hatayı yakalayan tek şey, çalışan uygulamanın **her** uç noktasına istek
gönderip gelen yanıta bakmak oldu. DAST'ın cevabı olduğu soru bu.

## Tam düzeltme

Aynı klasörde `nginx.tam.conf` var. Farkı şu: başlıklar
`guvenlik-basliklari.conf` adlı ayrı bir dosyaya taşındı ve hem `server` hem
de `location` bloğuna `include` edildi.

Compose dosyasındaki satırı `nginx.tam.conf` yapıp yeniden başlatın, sonra
tarayın:

```
docker compose -f labs/dast/docker-compose.yml up -d --force-recreate
```

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

```
WARN-NEW: Non-Storable Content [10049] x 6
WARN-NEW: CSP: Failure to Define Directive with No Fallback [10055] x 5
WARN-NEW: Session Management Response Identified [10112] x 1
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 3   WARN-INPROG: 0   INFO: 0   IGNORE: 0   PASS: 65
```

11 → 8 → 3. Geçen kontrol 57 → 65.

Kalan üçü gerçek birer kusur değil:

- `10049 Non-Storable Content` — artık önbelleğe alınamıyor olmasını
  bildiriyor. Kuralın diğer yüzü; bilgi.
- `10112 Session Management Response Identified` — ZAP bir oturum çerezi
  gördüğünü söylüyor. Bilgi.
- `10055 CSP: Failure to Define Directive` — bu gerçek bir eksik: CSP'miz
  `default-src` tanımlıyor ama `form-action` gibi bazı yönergeler
  `default-src`'ye düşmüyor, ayrı yazılmaları gerekiyor. Bu labın
  alıştırması tam olarak bu.

> **Sıfır bulgu hedef değil.** Gerçek bir taramada her zaman bir şeyler kalır:
> bilgilendirme kuralları, kabul edilmiş riskler, henüz sırası gelmemiş
> işler. Hedef, kalan her satırın **bilinçli bir karar** olması.

## Kapı: taramayı hattı durduracak hâle getirmek

Rapor tek başına bir şey değiştirmiyor. Hattın durması için taramanın sıfırdan
farklı bir **çıkış kodu** döndürmesi gerekiyor.

Uygulamayı ilk (açık) hâline geri alın — compose dosyasındaki satırı
`nginx.conf` yapıp yeniden başlatın. Sonra taramayı çalıştırıp çıkış koduna
bakın:

```
docker run --rm --network dast-net ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama
```

Windows PowerShell'de `echo $LASTEXITCODE`, macOS veya Linux'ta `echo $?`
yazın. **2** göreceksiniz: "uyarı var" demek.

Bu ham hâliyle kullanışsız. Her yeni bilgilendirme kuralı hattı kırar, ekip
bir hafta sonra kontrolü devre dışı bırakır. İhtiyacımız olan şey bir eşik:
**neyin durduracağını** söylemek.

ZAP bunu bir kural dosyasıyla yapıyor. `labs/dast/kurallar.conf` dosyasını
açıp bakın — her kuralın karşısında üç seçenekten biri var:

- `FAIL` — hattı durdurur
- `WARN` — rapora girer, durdurmaz
- `IGNORE` — hiç görünmez

Dosyada `FAIL` verilenler çerez bayrakları ve temel başlıklar; `IGNORE`
verilenlerin **yanında gerekçesi, sahibi ve son tarihi** yazıyor.

Kural dosyasıyla çalıştırın:

```
docker run --rm --network dast-net -v ./labs/dast:/zap/wrk:rw ghcr.io/zaproxy/zaproxy:2.17.0 zap-baseline.py -t http://uygulama -c kurallar.conf
```

```
FAIL-NEW: Cookie No HttpOnly Flag [10010] x 1
FAIL-NEW: Missing Anti-clickjacking Header [10020] x 3
FAIL-NEW: X-Content-Type-Options Header Missing [10021] x 3
FAIL-NEW: Content Security Policy (CSP) Header Not Set [10038] x 5
FAIL-NEW: Cookie without SameSite Attribute [10054] x 1
FAIL-NEW: 5   FAIL-INPROG: 0   WARN-NEW: 4   WARN-INPROG: 0   INFO: 0   IGNORE: 2   PASS: 57
```

Çıkış kodu **1**: en az bir `FAIL` var, hat durur.

Şimdi compose dosyasını `nginx.tam.conf` yapıp aynı komutu tekrarlayın:

```
FAIL-NEW: 0   FAIL-INPROG: 0   WARN-NEW: 0   WARN-INPROG: 0   INFO: 0   IGNORE: 3   PASS: 65
```

Çıkış kodu **0**: hat geçer.

İşte kapı bu. Kodu okuyan rapor değil, çıkış kodu; neyin durduracağına karar
veren de kural dosyası.

## Lab

Tam düzeltmede kalan `10055 CSP: Failure to Define Directive with No Fallback`
bulgusunu, istisna yazarak değil **gerçekten düzelterek** kapatın.

ZAP şunu söylüyor: CSP'mizde `default-src` var ama bazı yönergeler ona
düşmüyor — tarayıcı onlar için kural bulamıyor ve politikada delik kalıyor.

Yapmanız gerekenler:

- uygulamayı `nginx.tam.conf` ile çalıştırın
- `labs/dast/uygulama/guvenlik-basliklari.conf` içindeki CSP satırını
  eksik yönergeleri de kapsayacak şekilde genişletin
- tarayın, `10055` bulgusunun kaybolduğunu görün
- sonra `kurallar.conf` dosyasından `10055` için yazılmış **`IGNORE`
  satırını `WARN` yapın** ve kapıyı tekrar çalıştırın — hâlâ geçiyor mu?

Son adım bu labın asıl noktası: istisna geçici bir şey olmalı. Sorun
düzeldiğinde istisnanın da kalkması gerekiyor, yoksa bir dahaki sefere aynı
bulgu gerçekten çıktığında kimse görmeyecek.

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.
___

<!-- troubleshooting:auto -->
## Takılırsanız

**`Cannot connect to the Docker daemon`** - Docker Desktop çalışmıyor.
Başlatın ve balina simgesi hareket etmeyi bırakana kadar bekleyin.

**`port is already allocated`** - önceki bir labdan kalan konteyner o portu
hâlâ tutuyor. `docker ps` ile neyin çalıştığına bakın, eskisini
`docker rm -f <ad>` ile kaldırın.

**`The container name "/..." is already in use`** - aynı sebep, aynı çözüm:
`docker rm -f <ad>` deyip komutu tekrar çalıştırın.

**Build sırasında `unable to prepare context: path ... not found`** - yanlış
dizindesiniz. Bu labdaki her komut deponun kök dizininde olduğunuzu varsayıyor.

**Çalışmak yerine kullanım metni basan `docker run`** - bu labdaki bazı
komutlar, yanlış argümanın nasıl göründüğünü göstermek için kasıtlı olarak
başarısız oluyor. Bozuk sanmadan önce komutun çevresindeki açıklamayı okuyun.

Hâlâ takılıysanız: aşağıdaki **Cleanup** bölümü her şeyi sıfırlıyor, labı
temiz bir makineyle baştan yapabilirsiniz.


## Temizlik

Uygulamayı kaldırın:

```
docker compose -f labs/dast/docker-compose.yml down
```

Compose dosyasındaki yapılandırma satırını `nginx.conf` hâline geri aldığınızdan
emin olun; bir sonraki sefere lab baştan başlasın.

Üretilen raporlar `labs/dast/rapor/` klasöründe; o klasör `.gitignore` içinde,
silip silmemek size kalmış.
