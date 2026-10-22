---
title: Registry Üzerindeki İmajlara Erişmek
lang: tr
slug: registries
section: cicd
order: 3
duration: 30
requires: [docker]
status: needs-review
upstream: labs/registries
---

# Registry Üzerindeki İmajlara Erişmek

*Registry*, Docker imajlarını saklayan sunucudur. En popüleri Docker Hub ama
registry API'si standart; kendi registry'nizi bulutta veya yerelde özel imaj
deponuz olarak çalıştırabilirsiniz.

Kurumlar kendi registry'lerini çalıştırıyor: build pipeline'ından çıkan sürümleri
uzun vadeli saklamak için, ya da imajları üretim ortamıyla aynı ağ bölgesinde
erişilebilir kılmak için.

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

Süre: yaklaşık 30 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [İmaj çekmek (pull)](https://docs.docker.com/engine/reference/commandline/image_pull/)
- [İmaj göndermek (push)](https://docs.docker.com/engine/reference/commandline/image_push/)
- [Registry API belirtimi](https://github.com/opencontainers/distribution-spec/blob/main/spec.md#endpoints)
- [Docker Registry](https://docs.docker.com/registry/) — kendi registry'nizi
  container içinde çalıştırmak için :)

<details>
  <summary>Komut satırına genel bakış</summary>

Registry'lerle çalışmak için de `image` komutlarını kullanıyorsunuz. En
popüler komutların kısayolları var:

```
docker image --help

docker pull --help

docker push --help

docker tag --help
```

</details><br/>


## İmaj göndermek

Derlediğiniz imajlar yalnızca sizin makinenizde saklanır.

İmajları paylaşmak için onları bir *registry*'ye göndermeniz gerekiyor — Docker
Hub gibi. Docker Hub'da imaj adının kullanıcı adınızı içermesi gerekir; Docker
Hub sahipliği bununla belirliyor.

[Docker Hub'a kayıt olduğunuzdan](https://hub.docker.com/signup/) emin olun.
Sonra Docker ID'nizi bir değişkene kaydedin, sonraki komutlarda kullanacağız:

```
# Linux veya macOS'ta:
dockerId='<docker-hub-kullanici-adiniz>'

# VEYA PowerShell ile:
$dockerId='<docker-hub-kullanici-adiniz>'
```

> Bu, e-posta adresiniz *değil*, Hub kullanıcı adınız. Benim kendi kullandığım:
> `$dockerId='sixeyed'`

Artık adında Docker ID'niz bulunan bir imaj derleyebilirsiniz:

```
docker build -t ${dockerId}/curl:26.10 -f labs/images/curl/Dockerfile.v2 labs/images/curl

docker image ls '*/curl'
```

📋 Şimdi kendi `curl:26.10` imajınızı Docker Hub'a gönderin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# henuz giris yapmadiysaniz:
docker login -u ${dockerId}

# imajinizi gonderin:
docker push ${dockerId}/curl:26.10
```

</details><br/>

Docker Hub imajları herkese açıktır (özel imaj da oluşturabilirsiniz). Şu
komutu çalıştırıp imajınızı Docker Hub'da açın:

```
echo "https://hub.docker.com/r/${dockerId}/curl/tags"
```

## Etiketler ve referanslar

İmaj adları (doğru adıyla *referans*) üç parçadan oluşur:

- container registry'nin alan adı
- repository adı — uygulamayı ve sahibini belirtir
- etiket (tag) — herhangi bir şey olabilir ama genellikle sürümleme için
  kullanılır

Tek bir imajın birden fazla referansı olabilir; bunlar takma ad gibidir —
imajın kopyası değil, aynı imajın farklı adlarıdır.

Etiketler tipik olarak sürümleme için kullanılır; yani `sixeyed/curl:26.09` ve
`sixeyed/curl:26.10` için aynı sahibin yayınladığı aynı uygulamanın farklı
sürümleri diyebilirsiniz.

`tag` komutuyla imajınıza yeni bir referans ekleyin:

```
docker tag ${dockerId}/curl:26.10 ${dockerId}/curl:26.11

docker image ls '*/curl'
```

> Artık bir sürü curl imajınız var ama tüm takma adların imaj ID'si aynı

📋 Tüm `curl` imaj etiketlerinizi Docker Hub'a gönderin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# etiketleri tek tek gonderebilirsiniz:
docker push ${dockerId}/curl:26.11

# ya da repository'nin tum yerel etiketlerini:
docker push --all-tags ${dockerId}/curl
```

</details><br/>

> Bol miktarda `Layer already exists` çıktısı göreceksiniz — registry'ler de
> Docker motoruyla aynı katman önbellekleme yaklaşımını kullanıyor.

## Yerel registry çalıştırmak

Gerçek uygulamaların Docker imajları büyük olabilir — yüzlerce megabayt, hatta
gigabaytlar. Büyük imajları indirmek container'ların başlama süresine
ekleniyor, bu yüzden kurumlar genellikle kendi registry'lerini bulutta veya
veri merkezinde çalıştırıyor.

Tüm registry'ler aynı şekilde çalışır, dolayısıyla neredeyse birbirinin yerine
geçebilirler. Azure veya AWS üzerinde çalışıyorsanız
[Azure Container Registry](https://azure.microsoft.com/en-gb/services/container-registry/)
ya da [Amazon Elastic Container Registry](https://aws.amazon.com/ecr/)
kullanırdınız.

Yerel ortamda, resmi [Docker Registry](https://hub.docker.com/_/registry)
imajını kullanarak container içinde kendi registry'nizi barındırabilirsiniz:

```
docker run -d -p 5000:5000 --name registry registry:3.1.2

docker logs registry
```

Yerel registry alan adınız `localhost:5000`; yerelde push ve pull yapmak için
bunu imaj referanslarına dahil edebilirsiniz.

Tam imaj referans biçimi şöyle:

- `[registry-alan-adi]/[repository-adi]:[etiket]`

📋 Alpine imajını etiketleyip yerel registry'nize gönderin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# tag komutu bir takma ad olusturur, bu ad registry alan adini icerebilir:
docker tag alpine localhost:5000/alpine

# referansta alan adi olmasi, Docker'a hangi registry'yi kullanacagini soyler:
docker push localhost:5000/alpine
```

</details><br/>

> Docker Desktop `localhost` registry'lerine izin verecek şekilde
> yapılandırılmış, ama her Docker kurulumunda bu yok. Push sırasında hata
> alırsanız
> [güvensiz registry'lere izin vermeniz](https://docs.docker.com/registry/insecure/#deploy-a-plain-http-registry)
> gerekiyor.

Açık kaynak registry'nin Docker Hub gibi bir web arayüzü yok ama REST API ile
çalışabilirsiniz:

```
curl --head localhost:5000/v2/

curl localhost:5000/v2/alpine/tags/list
```

> Her imajın bir etiketi vardır — siz vermezseniz Docker varsayılanı kullanır.

Yerel imajınızı kaldırıp registry'den yeniden çekebilirsiniz:

```
docker image rm localhost:5000/alpine

docker pull localhost:5000/alpine
```

📋 Alpine imajı için birkaç etiket daha oluşturup gönderin — registry'de
mevcut olduklarını kontrol edin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# imaj etiketinde herhangi bir metin kullanabilirsiniz:
docker tag alpine localhost:5000/alpine:26.11

docker tag alpine localhost:5000/alpine:local

docker push --all-tags localhost:5000/alpine

curl localhost:5000/v2/alpine/tags/list
```

</details><br/>

> Varsayılan etiketi ve yeni etiketlerinizi görmelisiniz.

## Lab

İmaj referansları, Docker'ın registry'yi bulmasına ve uygulamanın belirli bir
sürümünü tanımlamasına yetecek kadar bilgi taşır.

Docker, registry ve etiket için varsayılan değerler kullanıyor. Bu
varsayılanlar neler? `kiamol/ch05-pi` imajının tam referansı nedir?

Resmi imajların tamamı Docker Hub'da değil. Microsoft, `mcr.microsoft.com`
adresinde kendi imaj registry'si olan *MCR*'yi kullanıyor. MCR'den
`dotnet/runtime` imajının `10.0` sürümünü çekmek için hangi komutu
kullanırdınız?

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
