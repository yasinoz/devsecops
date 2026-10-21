---
title: Çok Aşamalı Build
lang: tr
slug: multi-stage
section: cicd
order: 4
duration: 40
requires: [docker]
status: updated
upstream: labs/multi-stage
---
# Çok Aşamalı Build

Çok aşamalı build'ler standart Dockerfile sözdizimini kullanır; aşamalar
`FROM` komutlarıyla birbirinden ayrılır. Size en az bağımlılıkla,
tekrarlanabilir bir build verirler.

Çok aşamalı build'i her yerde görmeyeceksiniz ama araç setinizi tek merkezde
toplamanın harika bir yolu: geliştiricilerin ve build sunucularının yalnızca
Docker'a ve kaynak koda ihtiyacı olur, tüm araçlar Docker imajlarında paketli
gelir, böylece herkes aynı sürümleri kullanır.

## Kaynaklar

- [Çok aşamalı build dökümantasyonu](https://docs.docker.com/develop/develop-images/multistage-build/)

<details>
  <summary>Örnek Dockerfile'lar</summary>

Çok aşamalı build için standart `docker build` komutu kullanılır. Dockerfile
sözdizimi birden fazla `FROM` komutu içerir; kalıp tüm diller için aynı ama
ayrıntılar dile özgüdür.

Başlıca dillerden örnekler:

- [Maven build kullanan Java uygulaması](https://github.com/sixeyed/widgetario/blob/main/src/products-api/java/Dockerfile)
- [Go modülleri kullanan Go uygulaması](https://github.com/sixeyed/widgetario/blob/main/src/stock-api/golang/Dockerfile)
- [Alpine imajları kullanan .NET uygulaması](https://github.com/sixeyed/widgetario/blob/main/src/web/dotnet/Dockerfile)

</details><br/>

## Çok Aşamalı Dockerfile'lar

*Eski* derleme motoruyla başlayacağız; çünkü o her aşamayı sırayla çalıştırıyor
ve bu, çok aşamalı bir Dockerfile'ın yapısını apaçık gösteriyor. Sonra
BuildKit'e geçip karşılaştıracağız:

```
# macOS veya Linux'ta:
export DOCKER_BUILDKIT=0

# VEYA PowerShell ile:
$env:DOCKER_BUILDKIT=0
```

> Bir uyarı göreceksiniz: _"DEPRECATED: The legacy builder is deprecated and
> will be removed in a future release."_ Bu beklenen bir durum. Docker 23'ten
> beri varsayılan BuildKit ve eski derleyici kaldırılma yolunda — burada
> yalnızca tek bir build için, karşıtlığı görmek üzere kullanıyoruz.

Şöyle bir [basit çok aşamalı Dockerfile](./simple/Dockerfile):

- `base` aşaması Alpine kullanıyor ve birkaç bağımlılık eklemeyi simüle ediyor
- `build` aşaması base üzerine kurulup bir uygulama build'ini simüle ediyor
- `test` aşaması build çıktısından başlayıp otomatik testi simüle ediyor
- son aşama base'den başlayıp build çıktısını kopyalıyor

📋 `labs/multi-stage/simple` Dockerfile'ından `simple` adında bir imaj
derleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# siradan bir build:
docker build -t simple ./labs/multi-stage/simple/
```

</details><br/>

> Tüm aşamalar çalışıyor ama son uygulama imajında yalnızca önceki
> aşamalardan **açıkça** eklenmiş içerik var.

İmajdan bir container çalıştırın; base ve build aşamalarından gelen içeriği
yazdırıyor:

```
docker run simple
```

> Son imajda test aşamasından gelen ek içerik yok.

# BuildKit ve build hedefleri

BuildKit, Docker'ın derleme motoru ve Docker 23'ten beri varsayılan. Çok
aşamalı build'ler için ciddi şekilde optimize edilmiş: aşamaları paralel
çalıştırıyor ve çıktısı kullanılmayan aşamaları atlıyor.

Ortam değişkenini ayarlayarak BuildKit'e geri dönün (ya da yukarıdakini
kaldırın):

```
# macOS veya Linux'ta:
export DOCKER_BUILDKIT=1

# VEYA PowerShell ile: 
$env:DOCKER_BUILDKIT=1
```

Şimdi aynı Dockerfile için build'i tekrarlayın — bu kez Docker BuildKit
kullanacak:

```
docker build -t simple:buildkit ./labs/multi-stage/simple/
```

> Farklı aşamalardan gelen çıktıyı aynı anda göreceksiniz — ve dikkatli
> bakarsanız test aşamasının atlandığını fark edeceksiniz.

📋 Yeni imajdan bir container çalıştırın. Çıktı aynı mı? İmaj ayrıntılarını
karşılaştırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# container'i calistirin - cikti ayni:
docker run simple:buildkit

# imajlari listeleyin - ayni boyutta ama ayni imaj degil:
docker image ls simple
```

</details><br/>

BuildKit test aşamasını atlıyor çünkü çıktısı sonraki aşamalarda
kullanılmıyor. `target` bayrağıyla belirli bir aşamaya kadar imaj derlemeyi
açıkça isteyebilirsiniz:

```
docker build -t simple:test --target test ./labs/multi-stage/simple/
```

- `--target` hedef aşamayı belirtir; Docker, adı verilen aşamaya kadar olan
  (ve o aşama dahil) tüm aşamaları derler

> Bu imaj, test aşamasının çıktısıdır — son aşamanın *değil*.

📋 Test build'inden bir container çalıştırıp build.txt dosyasının içeriğini
yazdırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# burada cikti yok - test asamasinda CMD komutu yok
docker run simple:test

# ciktiyi gormek icin cat komutunu calistirin
docker run simple:test cat /build.txt
```

</details><br/>

> Çıktı, build aşaması artı test aşamasından geliyor.


## Basit bir Go uygulaması

Gerçek çok aşamalı build'ler, build aşamasında uygulamayı derlemek için bir
SDK (Software Development Kit) imajı, derlenmiş uygulamayı paketlemek için de
(build araçları olmayan) daha küçük bir çalışma ortamı imajı kullanır.

Kullandığınız imajlar ve çalıştırdığınız komutlar her dil için farklı, ama
[başlıca platformların tamamı için Docker Hub'da resmi imaj](https://hub.docker.com/search?q=&type=image&image_filter=official&category=languages)
bulabilirsiniz:

- Java uygulamalarını derlemek için [maven](https://hub.docker.com/_/maven) ve
  [gradle](https://hub.docker.com/_/gradle) — çalışma ortamı imajı olarak
  [eclipse-temurin](https://hub.docker.com/_/eclipse-temurin) (Docker Hub'ın
  `openjdk` imajı kullanımdan kaldırıldı)
- [python](https://hub.docker.com/_/python) — bağımlılıklar için Pip kurulu gelir
- Node.js uygulamaları için [node](https://hub.docker.com/_/node) — NPM
  içerdiği için build aşamasında paket kurabilirsiniz
- Go uygulamaları için [golang](https://hub.docker.com/_/golang) — çalışma
  ortamına ihtiyaç duymadıkları için son imaj
  [scratch](https://hub.docker.com/_/scratch)'ten başlayabilir
- .NET uygulamaları için
  [dotnet/sdk](https://hub.docker.com/_/microsoft-dotnet-sdk/); son uygulama
  imajı için [dotnet/runtime](https://hub.docker.com/_/microsoft-dotnet-runtime/)
  veya [dotnet/aspnet](https://hub.docker.com/_/microsoft-dotnet-aspnet/)

Dilleri tek tek ayrıntılı işlemeyeceğiz.
[whoami Dockerfile](./whoami/Dockerfile) bir Go uygulaması üzerinden kalıbın
nasıl çalıştığını gösteriyor:

- builder aşaması Go SDK imajından başlıyor
- uygulamayı derlemek için gereken işletim sistemi paketlerini kuruyor
- sonra kütüphane listesini (`go.mod`) ve kilit dosyasını (`go.sum`) kopyalayıp
  uygulamanın bağımlılıklarını kurmak için `go mod download` çalıştırıyor
- ardından kaynak kodu kopyalayıp uygulamayı derliyor
- son uygulama imajı container ortamını kuruyor
- sonra builder'dan derlenmiş çıktıyı kopyalıyor

📋 `labs/multi-stage/whoami` klasöründen `whoami` adında bir imaj derleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker build -t whoami ./labs/multi-stage/whoami/
```

</details><br/>

> BuildKit'ten gelen tüm aşama çıktısını göreceksiniz.

SDK imajları tüm build araç setini taşıdıkları için genellikle çok büyüktür.
Son aşamada SDK imajı kullanmak istemezsiniz; yoksa bütün o yük uygulama
imajınızda kalır.

📋 `whoami` ve `golang` imajlarının boyutlarını karşılaştırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker pull ghcr.io/yasinoz/library/golang:1.27.2-alpine

docker image ls -f reference=whoami -f reference=golang
```

</details><br/>

> Vay! SDK imajı yüzlerce megabayt; uygulama imajı birkaç megabayt.
>
> Docker 29, eski `SIZE` sütununu `DISK USAGE` ve `CONTENT SIZE` olarak ikiye
> ayırıyor, yani iki sayı göreceksiniz - aradaki fark her iki ölçüde de aynı
> derecede büyük.


Uygulama basit bir web sunucusu. Rastgele bir port yayınlayarak bir container
çalıştırın ve portu bulun:

```
docker run -d -P --name whoami1 whoami

docker port whoami1
```

> `EXPOSE` komutu Docker'a container'ın hedef portunu söyler; `-P` bayrağını
> kullandığınızda Docker expose edilmiş tüm portları yayınlar.

Artık uygulamayı kullanabilirsiniz:

```
curl localhost:<port>
```

> Sunucu yalnızca ortam ve istek hakkında birkaç ayrıntı yazdırıyor.

Container minimal bir imajdan çalışıyor — imajda uygulamanın çalışması için
gerekli olmayan hiçbir şey yok.

Bu, uygulamanın saldırı yüzeyini küçültmeye yardım ediyor. Container içinde
bir shell oturumuna bağlanmayı deneyin:

```
# bu basarisiz olacak
docker exec -it whoami1 sh
```

Shell yok; yani bir saldırgan uygulamayı ele geçirse bile bir istismarı
başlatabilmek için daha çok iş yapması gerekir.

## Lab

Uygulamaların standart HTTP portlarını dinlemek için özel Linux izinlerine
ihtiyacı var — container içinde bile.

whoami uygulaması dinlediği portu yapılandırmak için bir seçenek sunuyor;
böylece standart olmayan bir port kullanıp potansiyel olarak daha sıkı
güvenlikle çalışabilirsiniz.

Bu lab'daki hedefiniz, whoami uygulamasını bir container içinde `-port`
uygulama argümanıyla belirli bir portu dinleyecek şekilde çalıştırmak.
Container'ı `-P` (`--publish-all`) seçeneğiyle çalıştırdığınızda ne oluyor?
Docker yeni portu doğru eşliyor mu?

Çalışan bir container için ne yapmanız gerekiyor?

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
## Temizlik

Bu lab'ın container'larını kaldırın:

```
docker rm -f $(docker ps -aq)
```

> **PowerShell**'de komut ikamesi sözdizimi farklı:
>
> ```
> docker rm -f @(docker ps -aq)
> ```
>
> ⚠️ Her iki sürüm de makinenizdeki **tüm** container'ları kaldırır, yalnızca
> bu lab'ın container'larını değil. Başka bir işiniz çalışıyorsa önce
> `docker ps` ile kontrol edin.
