---
title: Compose ile Uygulama Derlemek
lang: tr
slug: compose-build
section: cicd
order: 5
duration: 45
requires: [docker]
status: updated
upstream: labs/compose-build
---
# Compose ile Uygulama Derlemek

Docker Compose modelleri derleme zamanı bilgilerini de içerebilir; böylece tek
bir Docker Compose komutuyla birden fazla container imajı derleyebilirsiniz.
Override dosyaları kullanmak, imaj referanslarını özelleştirmenize ve imajı
kaynak koda kadar izlemenizi sağlayan etiketler koymanıza imkân verir.

<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 45 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [Compose build belirtimi](https://docs.docker.com/reference/compose-file/build/)

- [Compose dosyalarında ortam değişkenleri kullanmak](https://docs.docker.com/compose/how-tos/environment-variables/)

<details>
  <summary>Komut satırına genel bakış</summary>

Docker Compose'un imajlarla çalışan komutları var:

```
docker compose build --help

docker compose push --help
```

> Bunlar da diğer komutlar gibi aynı şekilde birden fazla YAML dosyasını
> destekliyor.

</details><br/>

## Compose ile derlemek

Boyunca kullandığımız rastgele sayı uygulamasının tüm kaynak kodu, Dockerfile
ve bir Compose dosyasıyla birlikte `rng` klasöründe:

- [rng/docker-compose.yml](./rng/docker-compose.yml) — context ve Dockerfile
  yollarını içeriyor

Compose'daki tüm yollar, Compose dosyasının bulunduğu konuma göredir.

📋 `rng` klasörüne geçip imajları derleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
cd labs/compose-build/rng

docker compose build 
```

</details><br/>

> Build komutu, belirtimde `build` bölümü olan tüm imajları derler.
> Yapılandırdığınız derleme motorunun çıktısını göreceksiniz — bu lab için
> eski motoru da BuildKit'i de kullanabilirsiniz.

Bu imajların etiketi `21.05-local`. Uygulamayı yerel imajlarınızdan
çalıştırmak için aynı Compose dosyasını kullanabilirsiniz.

📋 Uygulamayı yeni imajlarınızla çalıştırıp çalıştığını test edin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker compose up -d

# uygulamayi http://localhost:8090 adresinde deneyin
```

</details><br/>

> Compose belirtimi, uygulamayı çalıştırmak ve derlemek için gereken tüm
> bilgiyi taşıyor.

## Build argümanları ve imaj etiketleri

Uygulamanızı derleyip çalıştıran tek bir Compose dosyası çok çekici geliyor,
ama çalıştırma ve derleme seçenekleri birbirinden çok farklı; Compose
belirtimlerinizi okunur ve bakımı kolay tutmak için ikisini ayırmak genellikle
daha iyi:

- [core.yml](./rng/core.yml) — rastgele sayı uygulaması için çekirdek
  servisleri ve ağları tanımlıyor

- [build.yml](./rng/build.yml) — servislerin derleme seçeneklerini tanımlıyor;
  build context yolu ve Dockerfile yolu dahil

Birkaç ek yapılandırmayla imajlarınıza faydalı bir denetim izi
ekleyebilirsiniz:

- [rng API Dockerfile'ı](./rng/docker/api/Dockerfile) `ARG` komutlarını
  kullanıyor — bunlar build argümanı olarak verebileceğiniz değerler — ve
  imaja metadata ekliyor; build sürümünü ve Git commit ID'sini etiketlerle
  kaydediyor

- [args.yml](./rng/args.yml) imaj adını değiştiriyor ve build argümanları için
  varsayılan değerleri ayarlıyor. Tüm `${VARIABLES}` değerleri, derlemeyi
  çalıştıran makinedeki ortam değişkenleriyle değiştirilebilir.

📋 Uygulamayı derlemek için tüm bu dosyaları birleştirin, sonra API imajının
etiketlerini inceleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# tam build belirtimi icin tum dosyalari birlestirin:
docker compose -f core.yml -f build.yml -f args.yml build

# bu cikti etiket degerlerini gosteriyor:
docker image inspect --format '{{.Config.Labels}}' courselabs/rng-api:21.05-0
```

</details><br/>

> Etiket değerlerini Compose dosyasındaki varsayılanlar belirliyor.

Makinenizde ortam değişkenleri tanımlayarak Compose dosyalarındaki
varsayılanları geçersiz kılabilirsiniz:

```
# macOS veya Linux:
export RELEASE=2021.07
export BUILD_NUMBER=121

# VEYA PowerShell ile:
$env:RELEASE='2021.07'
$env:BUILD_NUMBER='121'
```

📋 Derlemeyi tekrarlayın. Yeni imaj etiketleri ne oldu? API imajındaki etiket
değerleri ne?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# ayni dosya kumesi:
docker compose -f core.yml -f build.yml -f args.yml build

# etiket artik 2021.07-121

# yeni etiket degerlerini goster:
docker image inspect --format '{{.Config.Labels}}' courselabs/rng-api:2021.07-121
```

</details><br/>

> Farklı build argümanı değerleri bu derleme için önbelleği geçersiz kıldığı
> için Dockerfile komutlarının yeniden çalıştığını göreceksiniz.

Bu etiket değerleri yerelde derlerken pek işe yaramıyor — ama bir Sürekli
Entegrasyon (CI) derlemesinde build servisi tarafından doğru değerlerle
doldurulurlar.

## CI derlemeleri için Docker Compose

Compose, tek bir makinede çok sayıda üretim dışı ortam çalıştırmak için
harika; ama onu bu amaçla kullanmayacaksanız build özelliği Sürekli
Entegrasyon için biçilmiş kaftan. Uygulamalarınızı Jenkins veya GitHub
Actions'ta yalnızca `docker compose build` çalıştırarak kolayca
derleyebilirsiniz.

Bu repoda, yerelde kullandığınız aynı Docker Compose dosyalarıyla RNG
imajlarını derleyen bir GitHub Actions iş akışı da var:

- [rng-build.yml](./github/rng-build.yml) — GitHub iş akışları YAML belirtimi
  kullanır; aşina değilseniz bile aynı `docker compose` komutlarının
  çalıştığını göreceksiniz.

Gerçek imajlar herkese açık bir repoda, dolayısıyla iş akışı çıktısına
gidebilirsiniz:

https://github.com/courselabs/docker/actions/workflows/rng-build.yml

📋 En son build çıktısının içine girin; gönderilen bir imaj etiketi
göreceksiniz. O imajı çekip etiketlerini inceleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# build surumu imaj etiketine ekleniyor, ornegin 39 numarali build icin:
docker pull ghcr.io/yasinoz/courselabs/rng-api:21.05-39

docker image inspect ghcr.io/yasinoz/courselabs/rng-api:21.05-39
```

</details><br/>

İmaj etiketlerinde saklanan gerçek derleme ayrıntılarını göreceksiniz, şuna
benzer:

```
"Labels": {
  "build_tag": "RNG App Docker Image Weekly Build-33-refs/heads/main",
  "commit_sha": "dcd4b265f1406182a2e671b574af44100dbdfdab"
}
```

> Bu, yerelde derlemek için kullandığınız aynı Dockerfile ve Compose
> dosyalarından geliyor.

İmaj etiketleri, çalışan bir container'dan onu üreten build pipeline'ına ve
kaynak kodun tam sürümüne geri izlemenize yardımcı olur.

## Lab

GitHub iş akışına dikkatli bakın; iki ayrı derleme ve gönderme kümesi
çalıştırdığını göreceksiniz — ikinci küme bir Compose override dosyası daha
kullanıyor.

Ekstra Compose dosyasını kullandığınızda fark ne oluyor ve iş akışı bu ikinci
derlemeyi neden çalıştırıyor?

API imajını ikinci derlemedeki etiketten çekin ve `21.05-39` etiketiyle aynı
olup olmadığını kontrol edin.

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
docker compose -f core.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.

Ve `devsecops` kök dizininde değilseniz oraya geri dönün:

```
cd ../../..

pwd

# `devsecops` klasorunde oldugunuzdan emin olun
```
