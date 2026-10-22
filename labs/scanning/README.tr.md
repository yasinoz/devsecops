---
title: Güvenlik Taraması
lang: tr
slug: scanning
section: security
order: 2
duration: 45
requires: [docker]
status: updated
upstream: labs/scanning
---
# Güvenlik Taraması

Tarayıcılar, bir dosya sistemindeki veya container imajındaki ikili dosyaları
inceleyip bilinen güvenlik açıklarını arar. Genellikle birden fazla veritabanı
kullanarak ikili dosyanın hangi uygulamadan olduğunu, uygulamanın hangi
sürümde olduğunu ve o sürüm için CVE (Common Vulnerabilities and Exposures)
bulunup bulunmadığını belirler.

Container imajı taramak için birkaç araç var —
[Clair](https://quay.github.io/clair/) ve [Snyk](https://snyk.io) popüler
seçenekler. Biz [Trivy](https://trivy.dev/latest/docs/) kullanacağız; ücretsiz,
açık kaynak ve container içinde çalışıyor, dolayısıyla bir pipeline'a güzelce
entegre edilebiliyor. Trivy container imajlarındaki ikili dosyaları
tarayabildiği gibi Dockerfile ve Kubernetes manifestleri üzerinde statik analiz
de yapabiliyor.

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

- [Trivy dökümantasyonu](https://trivy.dev/latest/docs/)

- [GitHub'da Trivy](https://github.com/aquasecurity/trivy)

- [Hatalı yapılandırma için Trivy politikaları](https://trivy.dev/latest/docs/misconfiguration/policy/builtin/)

- [CNCF DevSecOps radarında Trivy](https://radar.cncf.io/2021-09-devsecops)

## Trivy ile İmaj Taraması

Trivy bir komut satırı aracı, ama makinemize kurmamız gerekmiyor; Trivy'yi
geliştiren Aqua Security'nin yayınladığı
[Docker imajını](https://hub.docker.com/r/aquasec/trivy) kullanabiliriz.

Bir Trivy container'ı çalıştırın — şu
[Docker Compose dosyası](./docker-compose.yml) yerel repo klasörünüzü
container dosya sistemine bağlıyor, böylece Trivy o dosyaları görebiliyor:

```
docker compose -f labs/scanning/docker-compose.yml run trivy
```

Trivy container'ına bağlandınız. Çalıştırabileceğiniz komutlara bakın, sonra
Docker Hub'daki bir imajı tarayın:

```
trivy

trivy image ghcr.io/yasinoz/sixeyed/whoami:24.07
```

> İlk çalıştırmada Trivy güvenlik açığı veritabanını indirecek; bu bir iki
> dakika sürebilir

Bu imajda güvenlik açığı yok — çünkü `FROM scratch` ile derlenmiş ve içindeki
tek ikili dosyalar uygulama ile birkaç bağımlılık.

📋 Docker Hub'daki `python:3.4-alpine` imajını tarayın. Nasıl görünüyor?

<details>
  <summary>Takıldınız mı?</summary>

Şunu çalıştırın:

```
trivy image python:3.4-alpine
```

</details>

Burada bol miktarda sorun var; high ve critical seviyeler dahil. Bunlardan
biri şu [buffer over-read güvenlik açığı](https://avd.aquasec.com/nvd/cve-2019-15903)
ve kulağa hiç iyi gelmiyor.

> Bu resmi bir imaj, ama Python 3.4'ün desteği 2019'da bitti — imaj on yıllık.
> Resmi imajlar yeni sürümler çıktığında Docker Hub'dan kaldırılmıyor, çünkü bu
> insanların build'lerini bozardı; bağımlılıklarınızı güncel tutmak
> registry'nin değil sizin sorumluluğunuz.

Bu Trivy container'ı yerel Docker motorunuzla konuşacak şekilde kurulmuş; yani
Docker Hub'daki imajların yanında kendi imajlarınızı da tarayabilirsiniz.

**Başka bir terminal açın** ve çok eski bir Nginx sürümü kullanan
[bu Dockerfile'dan](./web/Dockerfile) bir web sitesi imajı derleyin:

```
docker build -t courselabs/web:nginx-1.14 ./labs/scanning/web
```

📋 Yeni derlediğiniz imajı Trivy ile tarayın. Yayına çıkmaya uygun mu?

<details>
  <summary>Takıldınız mı?</summary>

Trivy yerel Docker motorunuzu kullanabiliyor, dolayısıyla imaj
önbelleğinize erişebiliyor:

```
trivy image courselabs/web:nginx-1.14
```

Bol miktarda hata göreceksiniz — bendeki çalıştırmada o kadar çoktu ki
terminal tamponunu aştı.

Yalnızca kritik sorunları yazdırmak için şunu deneyin:

```
trivy image -s CRITICAL courselabs/web:nginx-1.14
```

40'ın üzerinde kritik hata göreceksiniz...

</details>

> İmaj taramasını, imajlar derlendikten sonra pipeline'ınıza dahil etmek iyi
> olur — işletim sistemi araçlarındaki sorunları da uygulamanızın kullandığı
> kütüphanelerdeki sorunları da bulur.

## Kütüphane Taraması

Trivy kaynak kod klasörlerini de tarayabiliyor, ama kodunuzu analiz etmiyor
(onu [statik analiz lab'ında](../static-analysis/README.tr.md) SonarQube
yapıyor). Trivy kütüphane listelerini arıyor (örneğin Node.js uygulamaları
için `package-lock.json`) ve her kütüphaneyi CVE'ler için tarıyor.

📋 `/labs/scanning/python` içindeki Python bağımlılıklarını taramayı deneyin.

<details>
  <summary>Takıldınız mı?</summary>

```
trivy filesystem /labs/scanning/python/
```

Yine bol miktarda. Seçenekler farklı tarama tipleri için tutarlı, dolayısıyla
kritik sorunlarla sınırlayabilirsiniz:

```
trivy filesystem -s CRITICAL /labs/scanning/python/
```

</details>

Herkese açık Git repolarını da tarayabilirsiniz. Bu, bol miktarda demo
uygulaması içeren bir Kubernetes kitabı reposunu tarıyor:

```
trivy repository https://github.com/sixeyed/kiamol
```

Uygulama bağımlılıklarında bulgular göreceksiniz — hangileri olduğu ne zaman
çalıştırdığınıza bağlı, çünkü Trivy'nin veritabanı sürekli güncelleniyor ve
repo da değişiyor. Zaten asıl nokta bu: bir tarama, bugün bilinenlerin anlık
görüntüsüdür.

> Pipeline'ınız kütüphane taramasını — ve kullandığınız açık kaynak projeler
> için repo taramasını — build aşamasından **önce** içerebilir; böylece kritik
> bir sorun varsa build hızlıca başarısız olur ve düzeltilebilir.

## Kod-olarak-Altyapı Taraması

Trivy'nin son özelliği, kod-olarak-altyapı yapılandırma dosyalarını taramak.
Terraform ve CloudFormation yapılandırmalarını desteklediği gibi Dockerfile ve
Kubernetes YAML dosyalarını da destekliyor.

📋 `/labs/scanning/docker` içindeki Dockerfile'ı ve `/labs/scanning/kubernetes`
içindeki Kubernetes manifestini tarayın.

<details>
  <summary>Takıldınız mı?</summary>

`config` komutu hatalı yapılandırmaları arıyor:

```
trivy config /labs/scanning/docker

trivy config /labs/scanning/kubernetes
```

</details>

Bir dizi öneri göreceksiniz — bunlar container imajlarınız ve dağıtım
manifestleriniz için en iyi pratikler.

## Lab

`trivy` komutlarını container içinde çalıştırıyorduk. Bu CI ile güzel
çalışıyor, çünkü Trivy komut satırını build agent'ınıza kurup aynı komutları
pipeline'ınızda kullanabilirsiniz.

Olumsuz tarafı, geliştiricilerin bu akışı kullanmayacak olması; dolayısıyla
sorunlar yalnızca build çalıştığında bulunuyor. Alternatif olarak taramayı çok
aşamalı bir Dockerfile'da ayrı bir aşama olarak ekleyebilirsiniz:

- [hello-world-cs/Dockerfile](./hello-world-cs/Dockerfile) — uygulama imajını
  taramak için bir aşamayla .NET uygulaması derliyor; Trivy komutu HIGH
  önem derecesindeki sorunları arayacak ve varsa sıfır dışında bir çıkış kodu
  döndürecek şekilde ayarlanmış

Build'i çalıştırıp Trivy testinin koştuğunu doğrulayın. İmaj alabiliyor
musunuz? Başarısızlıklar varsa işletim sistemi araçlarıyla ilgili olabilir —
o durumda Dockerfile'da tek bir değişiklikle düzeltebilirsiniz.

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
docker compose -f labs/scanning/docker-compose.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
