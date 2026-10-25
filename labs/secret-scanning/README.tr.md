---
title: Sır Tarama
lang: tr
slug: secret-scanning
section: security
order: 2
duration: 40
requires: [docker]
status: updated
upstream: labs/secret-scanning
---
# Sır Tarama

Parola, API anahtarı, bağlantı dizgisi — bunlara *sır* diyoruz ve kaynak
kodunda durmamaları gerekiyor. Ama duruyorlar. Acelesi olan biri anahtarı
yapılandırma dosyasına yazıyor, "sonra düzeltirim" diyor ve commit'liyor.

Asıl mesele şu: **bir sır git'e girdiğinde silmek onu geri getirmiyor.**
Dosyadan çıkarıp yeni bir commit atarsanız çalışma ağacı temizlenir, geçmiş
temizlenmez. `git log -p` komutunu yazan herkes o anahtarı okuyabilir. Depo
bir kere klonlandıysa artık başkasının diskinde de duruyor.

[gitleaks](https://github.com/gitleaks/gitleaks) tam da bunu arıyor: hem
çalışma ağacını hem de **geçmişin tamamını** tarayıp sır gibi görünen şeyleri
işaretliyor. Bu labda önce sızıntıyı bulacağız, sonra bir daha olmasını
engelleyen kapıyı kuracağız.

<!-- outcomes:auto -->
## Bu lab ne işe yarıyor

Git'e giren bir sır silmekle gitmiyor — çalışma ağacı temizleniyor, geçmiş temizlenmiyor ve depoyu klonlamış olan herkeste zaten bir kopya var. Yani bu bir temizlik işi değil, anahtar döndürme işi; asıl çözüm de sırrın hiç commit'lenememesini sağlayan kapı.

**Bu labdan sonra şunları yapabileceksiniz:**

- bir deponun yalnızca dosyalarını değil geçmişinin tamamını taramak
- bulguyu okuyup hangi anahtarın nerede sızdığını söylemek
- sırrı commit'ten önce durdurmak ve kapıyı çıkış koduna bağlamak
- istisnayı dosyayı atlamak yerine tek bir bulguya daraltmak
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

<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 40 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [gitleaks deposu ve kural listesi](https://github.com/gitleaks/gitleaks)

- [OWASP — Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)

- [NIST SSDF (SP 800-218) PW.4 ve PW.9 — kod bütünlüğü ve yapılandırma](https://csrc.nist.gov/pubs/sp/800/218/final)

## Sırlı depoyu kurmak

Gerçek bir sızıntıyı incelemek için gerçek bir geçmişe ihtiyacımız var.
[demo klasöründeki](./demo/Dockerfile) küçük imaj onu üretiyor — üç commit'lik
bir depo, ikincisinde bir AWS sırrı, üçüncüsünde "temizlenmiş" hâli.

Önce imajı derleyin:

```
docker build -t sirli-depo ./labs/secret-scanning/demo
```

Sonra depoyu oluşturun:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo sirli-depo
```

Depo `labs/secret-scanning/sirli-depo` klasöründe oluştu. Oraya kendi
editörünüzle bakabilirsiniz — bu labda birkaç dosyayı elle yazacağız ve
hepsini o klasörde yazacağız.

> ⚠️ **Windows kullanıyorsanız komutları PowerShell'de çalıştırın.** Git Bash
> bu labdaki `-v ... :/depo` ifadesindeki `/depo` kısmını bir Windows yoluna
> çevirip bozuyor (`invalid volume specification` hatası). PowerShell'de böyle
> bir sorun yok.

## Çalışma ağacını taramak

Elimizdeki dosyalara bakalım. `dir` komutu git'i hiç açmadan, yalnızca
diskteki dosyaları tarıyor:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner
```

Çıktının son satırı:

```
INF no leaks found
```

Temiz. Rapor böyle diyor, yani sorun yok — **öyle mi?**

## Geçmişi taramak

Şimdi aynı depoya git tarafından bakalım. `git` komutu her commit'in
farkını tek tek geziyor:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner -v
```

Bu sefer bulgu var:

```
Finding:     aws_secret_access_key: 7Hk2pQnR4vTzL9mXbW3dYfJ6gC8sA1eU5oI0rNtP
Secret:      7Hk2pQnR4vTzL9mXbW3dYfJ6gC8sA1eU5oI0rNtP
RuleID:      generic-api-key
Entropy:     5.321928
File:        config.yml
Line:        5
Commit:      ea9ceaadc754e297f774db4855aab331ae473cbb
Author:      Lab
Email:       lab@example.com
Date:        2026-10-24T20:27:11Z
Fingerprint: ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

> Sizdeki `Commit` ve `Fingerprint` değerleri farklı olacak — depo sizin
> makinenizde üretildiği için commit kimlikleri her seferinde değişiyor.
> Bunu birazdan kullanacağız, o yüzden çıktıyı açık tutun.

İki tarama arasındaki fark, bu labın tamamı: **dosyalara bakmak yetmiyor,
geçmişe bakmak gerekiyor.** Geliştirici sırrı sildi, commit attı, işini
bitirdiğini düşündü. Anahtar hâlâ orada.

📋 Anahtarın geçmişte gerçekten durduğunu kendi gözünüzle doğrulayın.

<details>
  <summary>Nasıl yapılır?</summary>

Depodaki git geçmişine doğrudan bakabilirsiniz. Makinenizde git kurulu
olmasına gerek yok, demo imajının içindekini kullanıyoruz:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo log -p -- config.yml
```

İkinci commit'in farkında anahtarı düz metin olarak göreceksiniz. Üçüncü
commit onu siliyor ama silme işlemi de geçmişin bir parçası — eski hâli
oradan okunabiliyor.

</details><br/>

### Sızıntı bulunduğunda ne yapılır

Buradaki refleks genelde yanlış oluyor. "Geçmişi temizleyelim" deniyor ve
`git filter-repo` ile commit'ler yeniden yazılıyor. Bu **ikinci** adım, hem
de isteğe bağlı olanı.

**Birinci adım her zaman anahtarı döndürmektir (rotate).** Sır, en az bir
kez bir depoya girdiği andan itibaren yanmıştır: kim klonladı, kimin CI
önbelleğinde kaldı, hangi yedeğe gitti bilinmiyor. Geçmişi temizlemek
anahtarı geçersiz kılmıyor — yalnızca bulmayı zorlaştırıyor.

Yani sıra şu:

1. anahtarı sağlayıcıda iptal edip yenisini üret
2. yeni anahtarı bir sır kasasına koy, koda değil
3. erişim kayıtlarına bak — o anahtarla ne yapılmış
4. *sonra*, istenirse geçmişi yeniden yaz

## Tarayıcının görmediği sır

Depoda `docs/ornek.md` adında bir dosya var. Editörünüzle açıp içine bakın —
`labs/secret-scanning/sirli-depo/docs/ornek.md`.

İki tane AWS anahtarı duruyor. Ama her iki tarama da onları hiç
raporlamadı. Neden?

Çünkü `AKIAIOSFODNN7EXAMPLE` ve `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`,
AWS'nin kendi dökümanlarındaki **örnek** anahtarlar. Gitleaks'in varsayılan
yapılandırmasında bir izin listesi (allowlist) var ve bunlar orada. Tarayıcı
"bu anahtarı dünyadaki her README içeriyor, gerçek olamaz" diyor.

Bu doğru bir karar — aksi hâlde her dökümantasyon dosyası yanlış alarm
üretirdi. Ama şunu da öğretiyor:

> **"Tarayıcı temiz dedi" ile "sır yok" aynı şey değil.** Her tarayıcının bir
> izin listesi, bir kural kümesi ve bir eşiği var. Gördüğü şeyleri bulur,
> görmediklerini bulmaz.

📋 Bu durum sizin kurumunuzda nasıl ters teper? Kendi anahtar biçiminizin
varsayılan kurallarda olmadığını düşünün.

<details>
  <summary>Cevap</summary>

Gitleaks GitHub, AWS, Stripe, Slack gibi **bilinen** sağlayıcıların anahtar
biçimlerini tanıyor. Sizin `SPS-4K7M2Q9XB3TR6WZA` gibi kendi ürettiğiniz
anahtar biçiminizi tanımıyor — yüksek entropili olursa `generic-api-key`
kuralına takılabilir, olmazsa hiç görünmez.

Kendi biçimleriniz için kendi kuralınızı yazmanız gerekiyor. Bu labın
sonundaki alıştırma tam olarak o.

</details><br/>

## Commit'ten önce durdurmak

Bulmak iyi, ama asıl istediğimiz sırrın geçmişe **hiç girmemesi**. Gitleaks
bunun için henüz commit'lenmemiş, yalnızca hazırlanmış (staged) değişikliklere
bakabiliyor.

Önce bir sır hazırlayalım. Editörünüzle `sirli-depo` klasörünün içinde
`ci.yml` adında bir dosya oluşturup şunu yazın:

```
ci:
  token: ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
```

> Bu jeton sahte, hiçbir yere bağlı değil — biçimi gerçeğine benziyor,
> gitleaks'in tanıması için o yeterli.

Dosyayı commit'e hazırlayın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo add ci.yml
```

Şimdi kapıyı çalıştırın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --staged --no-banner -v
```

```
Secret:      ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
RuleID:      github-pat
WRN leaks found: 1
```

Bu sefer kural `generic-api-key` değil `github-pat`. Gitleaks jetonun
biçiminden hangi servise ait olduğunu biliyor — bu, bulguyu okuyan kişi için
çok daha kullanışlı: hangi anahtarı döndüreceğini biliyor.

Önemli olan tarafı: **commit henüz atılmadı.** Sır geçmişe hiç girmedi.

📋 Bu komutun bir kapı olarak işe yaraması için neyin doğru olması lazım?

<details>
  <summary>Cevap</summary>

Çıkış kodunun sıfırdan farklı olması. Otomasyon raporu okumaz, çıkış kodunu
okur. Komutu `-v` olmadan çalıştırıp çıkış koduna bakın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --staged --no-banner
```

Windows PowerShell'de `echo $LASTEXITCODE`, macOS veya Linux'ta `echo $?`
yazın — `1` göreceksiniz. Sızıntı yoksa `0` döner.

Bu, komutu bir `pre-commit` kancasına veya CI işine koyabilmenizi sağlıyor:
kod `1` dönerse commit ya da build durur. Kapıyı kapı yapan şey rapor değil,
bu çıkış kodu.

</details><br/>

Hazırladığımız sırrı geri alın, deponun temiz kalması lazım:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo --entrypoint git sirli-depo -C /depo restore --staged ci.yml
```

Sonra `ci.yml` dosyasını klasörden silin.

## İstisna: bildiğiniz bir bulguyu susturmak

Her bulgu gerçek sır olmuyor. Test verisi, örnek yapılandırma, çoktan
döndürülmüş bir anahtar — bunlar her taramada tekrar tekrar karşınıza çıkar ve
bir süre sonra kimse raporu okumaz olur. Gürültü, kapıyı kapatan en yaygın
sebep.

Gitleaks için istisna, bulgunun **parmak izini** (fingerprint) bir dosyaya
yazmakla oluyor. Önce kendi parmak izinizi alın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner -v
```

`Fingerprint:` satırını kopyalayın. Şuna benziyor ama sizdeki farklı:

```
ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

📋 Bu parmak izini deponun kökündeki `.gitleaksignore` dosyasına yazıp
taramayı tekrarlayın.

<details>
  <summary>Nasıl yapılır?</summary>

Editörünüzle `sirli-depo` klasöründe `.gitleaksignore` adında bir dosya
oluşturun ve tek satır olarak kendi parmak izinizi yazın:

```
ea9ceaadc754e297f774db4855aab331ae473cbb:config.yml:generic-api-key:5
```

Sonra tekrar tarayın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 git /depo --no-banner
```

`no leaks found` görüyorsunuz ve çıkış kodu artık `0`.

</details><br/>

Parmak izi commit kimliğini, dosyayı, kuralı ve satırı birlikte içeriyor.
Yani istisna **o bulguya** özel: aynı dosyaya yeni bir sır girerse parmak izi
değişir ve kapı yine kapanır. Bu, "şu dosyayı hiç tarama" demekten çok daha
dar bir istisna.

> İstisna kaydı bir karardır, bir temizlik değil. Yanına gerekçesini,
> sahibini ve son geçerlilik tarihini yazın. Sessizce susturulan bulgu,
> unutulan bulgudur.

Devam etmeden önce `.gitleaksignore` dosyasını silin.

## Lab

Gitleaks sizin kurumunuzun anahtar biçimini bilmiyor. Sıra onu öğretmekte.

Siparişi işleyen servisin kendi API anahtarları `SPS-` ile başlıyor ve
ardından 16 karakter büyük harf ve rakam geliyor — örneğin
`SPS-4K7M2Q9XB3TR6WZA`. Depoya böyle bir anahtar koyun ve gitleaks'in onu
yakalamasını sağlayın.

Yapmanız gerekenler:

- `sirli-depo` klasörüne bu biçimde bir anahtar içeren bir dosya ekleyin
- önce tarayın — varsayılan kurallarla **yakalanmadığını** görün
- aynı klasörde bir `.gitleaks.toml` yazıp kendi kuralınızı tanımlayın
- tekrar tarayın, bulgunun `RuleID` alanında kendi kural adınızı görün

Dikkat edilecek bir nokta var: kendi yapılandırma dosyanızı yazdığınızda
gitleaks varsayılan kuralları **kullanmayı bırakabilir**. Yani kendi
kuralınızı eklerken GitHub ve AWS anahtarlarını yakalayan kuralları
kaybetmemeniz lazım.

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

Bu labın ürettiklerini kaldırın:

```
docker rmi sirli-depo
```

Demo deposu `labs/secret-scanning/sirli-depo` klasöründe duruyor. Bu klasör
`.gitignore` içinde, yani deponuza karışmıyor; isterseniz silebilirsiniz,
isterseniz bırakın — labı tekrar çalıştırdığınızda zaten sıfırdan üretiliyor.
