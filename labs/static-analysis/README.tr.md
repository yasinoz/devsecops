---
title: Statik Kod Analizi
lang: tr
slug: static-analysis
section: security
order: 1
duration: 45
requires: [docker]
status: updated
upstream: labs/static-analysis
---
# Statik Kod Analizi

Statik analiz araçları, uygulamalarınızın kaynak kodunu inceleyip bilinen
sorunları arar. Araçlar; kötü kodlama pratiklerini, bakımı zor kodu ve bilinen
güvenlik problemlerini içerebilen bir sorun veritabanı kullanır.
[SonarQube](https://www.sonarqube.org) en popüler analizcilerden biri. En iyi
pratikleri ve CVE'leri içeren veritabanlarıyla çok sayıda dili destekliyor.

SonarQube'ün ticari sürümleri var ama biz ücretsiz community sürümünü
çalıştıracağız. Bir sunucu olarak çalışıyor ve kodunuzu derlerken analizi
tetikleyebiliyorsunuz. Masaüstünüzdeki veya build sunucunuzdaki bir SonarQube
istemcisi kodu analiz için gönderip sonuçları yazdırıyor. Bulunan sorunlar
SonarQube sunucusunda saklanıyor ve kritik sorunların build'i başarısız
kılmasını yapılandırabiliyorsunuz.

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

- [Docker Hub'da SonarQube](https://hub.docker.com/_/sonarqube)

- [SonarQube'ü deneyin](https://docs.sonarsource.com/sonarqube-server/latest/try-out-sonarqube/)

- [.NET uygulamalarıyla SonarQube](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/scanners/dotnet/introduction/)

- [Java uygulamaları ve Maven ile SonarQube](https://docs.sonarsource.com/sonarqube-server/latest/analyzing-source-code/scanners/sonarscanner-for-maven/)

- [CNCF DevSecOps radarında SonarQube](https://radar.cncf.io/2021-09-devsecops)

## SonarQube'ü çalıştırmak

SonarQube'ü çalıştırarak başlayın — şu
[Docker Compose dosyası](./infra/docker-compose.yml) Docker Hub'daki resmi
imajı kullanıyor ve makinenizde 9000 portunu yayınlıyor:

```
docker compose -f labs/static-analysis/infra/docker-compose.yml up -d
```

SonarQube'ün ayağa kalkması bir iki dakika sürebilir. Container çalıştığında
http://localhost:9000 adresindeki web arayüzüne Sistem Yöneticisi kimlik
bilgileriyle giriş yapın:

- kullanıcı: `admin`
- parola: `admin`

Yeni bir parola belirlemenizi isteyecek — `admin` olmayan herhangi bir şey
olur.

> ⚠️ Container SonarQube 26 çalıştırıyor (upstream lab 9.2 için yazılmıştı).
> Kavramlar değişmedi ama bazı ekranlar yer değiştirdi — özellikle proje
> oluşturma sihirbazı. Aşağıdaki adımlar gördüğünüzle birebir örtüşmezse,
> arayüzdeki etiketler takip etmeye yetecek kadar yakın;
> [SonarQube dökümanları](https://docs.sonarsource.com/sonarqube-server/latest/)
> bağlayıcıdır.

Bu, hiç projesi olmayan yeni bir SonarQube sunucusu, ama kullandığı kuralları
gezebilirsiniz.

📋 .NET uygulamaları için birkaç güvenlik açığı kontrolü bulabilir misiniz?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Arayüzdeki kodlama kuralları tüm kurallar için faydalı dökümantasyon
gösteriyor:

- http://localhost:9000/coding_rules — çok sayıda dil ve analiz tipi için
  kodlama kuralları

- http://localhost:9000/coding_rules?languages=cs&types=VULNERABILITY — C#
  uygulamaları için güvenlik açıkları

- http://localhost:9000/coding_rules?languages=cs&open=csharpsquid%3AS5445&types=VULNERABILITY —
  C# için bilinen bir OWASP güvenlik açığı

</details>

Yalnızca kendi dilinizin kurallarını gezmek bile daha iyi ve daha güvenli kod
yazmanıza yardım edebilir :)


## SonarQube Projesi Oluşturmak

Bir miktar .NET kodunu analiz etmek için kullanabileceğimiz yeni bir proje
oluşturacağız.

http://localhost:9000/projects/create adresini açıp yeni projeyi
yapılandırın:

- **yerel proje** (local project) oluşturma seçeneğini seçin (SonarQube
  GitHub, GitLab ve diğerleriyle entegre olabiliyor; biz bunu elle kuruyoruz)

- _Project key_ (ve görünen ad) alanını `hello-world-cs` yapın

- yeni kod için referans çizgisi sorulduğunda genel ayar yeterli

- projeyi **yerel olarak** analiz etmeyi seçip bir token üretin — adını
  herhangi bir şey yapabilirsiniz, örneğin `devops`

- SonarQube token'ı gösteriyor — kimlik doğrulaması için sonra kullanacağız,
  bu yüzden token'ı kopyalayın (`d19405a6925267bbcd52221c407bc01c2010c82b`
  gibi görünür ama sizinki farklı olacak)

- _Continue_ tıklayın

- uygulama tipi olarak .NET, sonra .NET Core seçin

Proje arayüzü, yerel bir build çalıştırıp kaynağınızı SonarQube sunucusunda
analiz ettirmenin nasıl yapılacağını gösteriyor.

## Docker Build İçinde Analiz Çalıştırmak

Yerel build'imizi Docker ile çalıştıracağız; böylece hiçbir SDK kurmamız
gerekmiyor.

SonarQube token'ınızı terminal oturumunuzda bir değişkene kaydederek
başlayın (elinizde yoksa
[güvenlik sayfanızdan](http://localhost:9000/account/security/) yeni bir tane
oluşturabilirsiniz).

_Bu komutta kendi gerçek token'ınızı kullandığınızdan emin olun:_

```
# macOS veya Linux'ta:
SONAR_TOKEN='<token-degeriniz>'

# veya Windows PowerShell'de:
$SONAR_TOKEN='<token-degeriniz>'
```

Artık token'ı şu [.NET Dockerfile](./hello-world-cs/Dockerfile) için build
argümanı olarak geçirebiliriz:

- bu, opsiyonel SonarQube analiziyle basit bir Hello World uygulaması
  derliyor

- build Docker içinde çalıştığı için SonarQube'e host üzerinden, özel
  `host.docker.internal` adresiyle erişebiliyoruz

- Dockerfile'da `dotnet sonarscanner` komutlarını göreceksiniz; bunlar
  SonarQube'ün proje sayfasında yazdırdığı komutların aynısı

```
docker build -t hello-world-cs --build-arg SONAR_TOKEN=$SONAR_TOKEN ./labs/static-analysis/hello-world-cs

# Linux kullaniyorsaniz `host.docker.internal` adresi tanimli olmayabilir -
# bunun yerine sunu calistirabilirsiniz. Burada eski derleyici gerekiyor,
# cunku 'docker build --network' klasik derleyicinin bayragi; kullanimdan
# kaldirma uyarisi bekleyin:
export DOCKER_BUILDKIT=0

docker build -t hello-world-cs --build-arg SONAR_TOKEN=$SONAR_TOKEN --build-arg SONAR_URL=http://sonarqube:9000 --network infra_default ./labs/static-analysis/hello-world-cs
```

Build tamamlandığında sonuçları SonarQube sunucusuna gönderiyor ve orada proje
için saklanıyorlar.

📋 SonarQube'de projeyi kontrol edin — nasıl görünüyor?

<details>
  <summary>Takıldınız mı?</summary>

Tüm ayrıntıları arayüzde görebilirsiniz:

- genel proje durumu — http://localhost:9000/dashboard?id=hello-world-cs
- sorunlar — http://localhost:9000/project/issues?id=hello-world-cs&resolved=false
- güvenlik odakları — http://localhost:9000/security_hotspots?id=hello-world-cs

</details>

## Kalite Kapılarıyla Build'i Başarısız Kılmak

Projede birkaç sorun var. İdeal olarak, ciddi güvenlik sorunları varsa
build'in başarısız olmasını istiyoruz. Bunu bir
[kalite kapısı (quality gate)](https://docs.sonarsource.com/sonarqube-server/latest/instance-administration/analysis-functions/quality-gates/)
ayarlayarak yapabiliriz. Kapı, projenin analizi geçmesi için karşılaması
gereken koşulları belirtiyor.

http://localhost:9000/quality_gates/ adresini açın. _Sonar way_ adında
varsayılan bir kapının zaten orada olduğunu göreceksiniz. Bu yalnızca yeni
kod üzerinde çalışıyor — önceki analizden bu yana yapılan değişiklikler. Biz
tüm kod üzerinde çalışan bir kalite kapısı istiyoruz:

- varsayılan kapıyı kopyalamak için _Copy_ tıklayın
- yeni kapının adını `courselabs` yapın
- _Add Condition_ tıklayın
- _On Overall Code_ üzerinde çalışmayı seçin
- açılır listeden _Security Rating_ seçin
- operatör olarak _A_'dan kötü (worse than) seçin
- _Add Condition_ tıklayın

Yeni kalite kapınız şuna benzer görünmeli:

![Genel kod üzerinde güvenlik derecesi koşulu olan kalite kapısı](../../img/static-analysis-gate.png)

Artık .NET projesini bu kalite kapısını kullanacak şekilde ayarlayabiliriz ve
genel güvenlik derecesi çok düşükse analiz başarısız olacak.

- projeye geri dönün: http://localhost:9000/dashboard?id=hello-world-cs
- sağ üstteki _Project Settings_ açılır listesinden _Quality Gate_ seçin
- _Always use a Specific Quality Gate_ seçip yeni `courselabs` kapınızı seçin

[Dockerfile](./hello-world-cs/Dockerfile) içindeki build argümanları,
başarısız bir analiz kontrolünün build'i başarısız kılıp kılmayacağını
ayarlamanıza imkân veriyor.

📋 Docker build'i, SonarQube kontrolü başarısız olursa build de başarısız
olacak şekilde çalıştırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Ayarlanacak argümanın adı `SONAR_ENFORCE_GATE`.

Docker Desktop ile:

```
docker build -t hello-world-cs --build-arg SONAR_TOKEN=$SONAR_TOKEN --build-arg SONAR_ENFORCE_GATE=true ./labs/static-analysis/hello-world-cs
```

Ya da Linux'ta Docker Engine ile:

```
export DOCKER_BUILDKIT=0

docker build -t hello-world-cs --build-arg SONAR_TOKEN=$SONAR_TOKEN --build-arg SONAR_ENFORCE_GATE=true --build-arg SONAR_URL=http://sonarqube:9000 --network infra_default ./labs/static-analysis/hello-world-cs
```

</details><br/>

Artık build başarısız oluyor. Dockerfile bir birim test aşaması içerseydi, o
aşama analizden sonra çalışırdı ve testlerden biri başarısız olsaydı build de
başarısız olurdu. Yani build'den çıkan bir imajımız varsa, o imaj tüm testleri
ve güvenlik analizini geçmiş olmak zorunda.

> Olumsuz tarafı, kuralların kaynak kontrolünün dışında olması; kodun eski bir
> sürümünü çekip derlediğinizde kurallar değiştiyse aynı çıktıyı almayabilirsiniz.

## Lab

Sıra bir projeyi analiz etmede sizde — Hello World uygulamasının Java
sürümünü kullanacağız:

- [hello-world-java/Dockerfile](./hello-world-java/Dockerfile) — Maven
  kullanan çok aşamalı bir build. Alıştırmalardaki .NET uygulamasıyla aynı
  build argümanı kümesini kullanarak SonarQube çalıştıracak şekilde
  yapılandırılmış

Analizi etkinleştirerek build'i çalıştırmakla başlayın — **SonarQube'de proje
oluşturmanız gerekmiyor**, analiz Docker'dan tetiklendiğinde projeyi kendisi
oluşturacak. Uygulama nasıl görünüyor? Sonra yeni projeyi `courselabs` kalite
kapınızı kullanacak şekilde ayarlayıp build'i kontroller zorunlu halde
yeniden çalıştırın. Bu kez bir imaj alabiliyor musunuz?

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
docker compose -f labs/static-analysis/infra/docker-compose.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
