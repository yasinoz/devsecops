---
title: Jenkins ile Docker İmajı Derlemek
lang: tr
slug: pipeline
section: cicd
order: 6
duration: 60
requires: [docker]
status: updated
upstream: labs/pipeline
---
# Jenkins ile Docker İmajı Derlemek

Docker motoruna erişimi olan container'lar çalıştırabilirsiniz — böylece
container içindeki uygulama, başka container'lar çalıştırmak veya imaj
derlemek için Docker komut satırını kullanabilir. Bu, temiz bir CI/CD kurulumu
sağlıyor: Jenkins'i bir container içinde çalıştırıp, uygulamalarınızı çok
aşamalı Dockerfile'larla derleyen pipeline'lar kullanıyorsunuz. Pipeline'lar
ayrıca işlevselliği hızlıca sınamak için yeni imajlardan container
çalıştırabiliyor.

Bu yaklaşımla tüm build altyapınız taşınabilir hale geliyor. Jenkins
sunucusunu herhangi bir Docker motorunda çalıştırıp, pipeline'larınızı
yükleyip, başka hiçbir araç kurmadan her tür yazılımı derleyebilirsiniz.
Kimlik bilgilerini de Jenkins'te saklayabilirsiniz; böylece diğer servislerle
kimlik doğrulaması yapıp pipeline'dan Docker Hub'a imaj gönderebilir ya da
üretim ortamınıza dağıtım yapabilirsiniz.

<!-- outcomes:auto -->
## Bu lab ne işe yarıyor

Container tabanlı CI'ın bütün amacı, derleme sunucusunda hiçbir şeyin kurulu olmaması — ne JDK, ne .NET SDK, ne Node. Derleme araçları container içinde geliyor. Bu da pipeline'ınızı taşınabilir ve tekrarlanabilir yapıyor; modern CI sistemlerinin çoğunun arkasındaki desen bu.

**Bu labdan sonra şunları yapabileceksiniz:**

- Jenkins pipeline'ından container içinde derleme çalıştırmak
- çok aşamalı derlemeyle pipeline'ın tek adımda derleyip paketlemesini sağlamak
- CI'dan Compose ile çok imajlı bir uygulama derlemek
- derlenen imajları pipeline'ın parçası olarak registry'ye göndermek
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

Süre: yaklaşık 60 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [Container içinden Docker motoruna erişmek](https://docs.docker.com/engine/security/#docker-daemon-attack-surface)

- [Jenkins'te kimlik bilgisi saklamak](https://www.jenkins.io/doc/book/using/using-credentials/)

- [Pipeline'larda kimlik bilgileriyle çalışmak](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/#handling-credentials)

## Basit Bir Java İmajı Derlemek

[Bu Dockerfile'ı](./docker/Dockerfile), [bu Jenkinsfile](./docker/Jenkinsfile)
ile derleyerek başlayacağız. Önceden derlenmiş bir Java uygulamasını bir
Docker imajına paketleyip imajdan bir container çalıştıracak. Build veya test
aşamaları başarısız olursa pipeline da başarısız olur.

Önce şu [Docker Compose belirtimiyle](./infra/docker-compose.yml) Jenkins ve
Gitea'yı çalıştırın:

```
docker compose -f labs/pipeline/infra/docker-compose.yml up -d
```

> Jenkins servisi Docker socket'ini bağlayacak şekilde yapılandırılmış;
> container, üzerinde çalıştığı Docker motoruyla bu sayede konuşabiliyor.

Bu, boş veritabanlı yeni bir Gitea sunucusu; önce kullanıcınızı oluşturun:

```
docker compose -f labs/pipeline/infra/docker-compose.yml exec -u git gitea gitea admin user create --admin --username student --password student --email student@labs.local --must-change-password=false
```

Sonra repomuz için hazırlayın:

- http://localhost:3000 adresini açın

- `student` kullanıcı adı ve `student` parolasıyla giriş yapın

- _My Repositories_ bölümündeki `+` işaretine tıklayıp yeni bir repo oluşturun

- repo adını `devsecops` yapın ve _Create Repository_ tıklayın

Gitea sunucunuzu remote olarak ekleyip repoyu gönderin:

```
# Jenkins labindan kalmis olabilir - gordugunuz hatalari yok sayin:
git remote add gitea http://localhost:3000/student/devsecops.git

git push gitea main
```

Şimdi Jenkins'te şu bilgilerle bir pipeline oluşturabiliriz:

- job adı = `docker`
- Git URL = `http://gitea:3000/student/devsecops.git`
- branch specifier = `refs/heads/main`
- Jenkinsfile yolu = `labs/pipeline/docker/Jenkinsfile`

📋 Jenkins arayüzünü açıp yeni pipeline job'ını oluşturun.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

- http://localhost:8080 adresini açın
- `student` kullanıcı adı ve `student` parolasıyla giriş yapın
- sol menüden _New item_ tıklayın
- proje tipini _Pipeline_ seçin
- pipeline penceresinde açılır listeden _Pipeline script from SCM_ seçin
- pipeline bilgilerini girin

</details>

Kaydedip build'i çalıştırın.

📋 Build çıktısını inceleyin. Derlediği Docker imajının adı ne? Test
container'ının çıktısı ne?

<details>
  <summary>Takıldınız mı?</summary>

_Build_ aşamasının loglarını açın; imaj etiketinin
`docker.io/courselabs/hello-world:1` olduğunu göreceksiniz.

_Test_ aşaması loglarında container çıktısının `Hello, World` metni olduğunu
göreceksiniz.

</details>

Bu basit bir örnek, ama amacımız yalnızca ikili dosyaları imajlara paketlemek
değil — onları kaynak koddan derlemek istiyoruz; bunu da çok aşamalı build ile
yapabiliriz.

## Jenkins'te Çok Aşamalı Build

Çok aşamalı build'in özel bir tarafı yok — dizüstünde çalıştırabildiğimiz her
Docker build'i Jenkins container'ında da aynı şekilde çalışır:

- [multi-stage/Dockerfile](./multi-stage/Dockerfile) — aynı Java uygulamasını
  kaynaktan derliyor, dolayısıyla ayrı bir derleme adımına ihtiyacımız kalmıyor

- [multi-stage/Jenkinsfile](./multi-stage/Jenkinsfile) — etiketi üretmek için
  ortam değişkenleri kullanarak imajı derliyor, sonra bir test container'ı
  çalıştırıyor

Bu dosyalar zaten Gitea sunucunuzda; dolayısıyla Jenkins'te
`labs/pipeline/multi-stage/Jenkinsfile` script'ini çalıştıracak yeni bir
pipeline oluşturabilirsiniz.

📋 `multi-stage` adında yeni bir pipeline oluşturup çalıştırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

http://localhost:8080/view/all/newJob adresinde Jenkins arayüzünden yeni bir
öğe oluşturun, adını `multi-stage` yapın, tipini _Pipeline_ seçin ve mevcut
bir pipeline'ı kopyalamak için _Copy from_ kutusuna `docker` yazın.

Script yolunu `labs/pipeline/multi-stage/Jenkinsfile` olarak değiştirin.

_Save_, sonra _Build Now_ tıklayın.

</details>

Build, alışık olduğumuz aşamalarla çalışıyor. Jenkins'in Docker motorunuzu
paylaştığını hatırlayın; derlediği imajlar `docker` komutlarıyla sizin de
kullanımınıza açık.

📋 Build'den çıkan yeni imajın boyutu ne? SDK ile karşılaştırıldığında nasıl?

<details>
  <summary>Takıldınız mı?</summary>

Ayrıntıları görmek için makinenizdeki imajları listeleyebilirsiniz:

```
# pipeline'dan derlenen imaj:
docker image ls courselabs/multi-stage:1

# Docker Hub'daki java sdk imaji:
docker pull ghcr.io/yasinoz/library/eclipse-temurin:25-jdk
docker image ls ghcr.io/yasinoz/library/eclipse-temurin:25-jdk 
```

</details>

> Uygulama imajınız SDK imajından küçük - Java çalışma zamanını taşıyor ama
> derleyiciyi ve derleme araçlarını taşımıyor. Bu Temurin imajlarında kazanç
> 100MB civarında; `-jre` imajı `-jdk`'nın kabaca beşte dördü. Son aşamayı
> daha ince bir imaja (örneğin Alpine tabanlı bir JRE) dayandırırsanız aradaki
> fark çok açılır - [multi-stage lab'ındaki](../multi-stage/README.tr.md)
> `whoami` derlemesi `scratch` ile tam olarak bunu yapıyor.

## Docker Compose ile Derlemek

Bu Jenkins container imajında `docker compose` komutu da kurulu; dolayısıyla
tek komutla birden fazla imaj derleyebiliriz.

Rastgele sayı uygulamasını kaynaktan derleyeceğiz:

- [compose/Jenkinsfile](./compose/Jenkinsfile) — uygulamayı
  `labs/compose-build/rng` klasöründe derliyor; _Push_ aşaması yorum
  satırına alındığı için yalnızca _Build_ aşaması çalışacak

- [API Dockerfile'ı](../compose-build/rng/docker/api/Dockerfile) — .NET SDK ve
  çalışma ortamı imajlarını kullanan çok aşamalı bir build

Yani bu bir .NET uygulaması. Hile yapmadığımızdan emin olmak için, .NET'in
kurulu olmadığını doğrulamak üzere şu komutu Jenkins container'ı içinde
çalıştırın:

```
# bu basarisiz olacak
docker compose -f labs/pipeline/infra/docker-compose.yml exec jenkins dotnet --version
```

> `not found in $PATH` hatası göreceksiniz, çünkü container'da .NET yok. Sorun
> değil; çünkü bu çok aşamalı bir build ve derleme container'ların içinde
> çalışacak.

📋 `labs/pipeline/compose/Jenkinsfile` script yolundan `compose` adında yeni
bir pipeline oluşturup çalıştırın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

http://localhost:8080/view/all/newJob adresinde Jenkins arayüzünden yeni bir
öğe oluşturun, adını `compose` yapın, tipini _Pipeline_ seçin ve mevcut bir
pipeline'ı kopyalamak için _Copy from_ kutusuna `docker` yazın.

Script yolunu `labs/pipeline/compose/Jenkinsfile` olarak değiştirin.

_Save_, sonra _Build Now_ tıklayın.

</details>

Çıktıyı kontrol edin — build başarıyla çalışıp imajlar üretmeli.

📋 Kaç imaj derlendi? İmaj etiketindeki `21.12` kısmı nereden geliyor?

<details>
  <summary>Takıldınız mı?</summary>

_Build_ aşaması logları iki imajın derlendiğini gösterecek:
`courselabs/rng-api:21.12-1` ve `courselabs/rng-web:21.12-1`.

`21.12` sürüm döngüsü; Jenkinsfile'da bir ortam değişkeniyle ayarlanıyor.

</details>

> İmaj etiketindeki registry ve repository adları için ortam değişkenleri
> kullanılıyor; böylece imajların nereye gönderileceği kolayca
> değiştirilebiliyor.

## Docker Hub'a Göndermek

Pipeline'ımızın yayınlama kısmı imajları Docker Hub'a gönderecek. Bunun için
üç şeye ihtiyacınız var:

- bir [Docker Hub hesabı](https://hub.docker.com) — yoksa oluşturun, ücretsiz
  katman yeterli
- Docker Hub kimlik bilgilerinizin Jenkins'te saklanması
- Jenkinsfile'da bir değişiklik: imaj etiketlerinin sizin Docker Hub kullanıcı
  adınızı taşıması

Docker Hub hesabınız olduğunda [ayarlarınıza](https://hub.docker.com/settings/security)
gidip bir erişim belirteci (access token) üretebilirsiniz. Belirteci
kopyalayın — gerçek parolanızı Jenkins'te saklamamak için giriş yaparken onu
kullanacaksınız.

Şimdi Jenkins'te bir kimlik bilgisi oluşturun:

- _Manage Jenkins_ > _Credentials_ > _System_ > _Global credentials_ yolunu
  açın (http://localhost:8080/manage/credentials/store/system/domain/_/)
- _Add Credentials_ tıklayın ve _Kind_ alanının _Username with password_
  olduğundan emin olun
- _Username_ alanına Docker Hub kullanıcı adınızı girin (e-posta adresinizi
  **değil**)
- _Password_ alanına erişim belirtecinizi girin
- _ID_ alanında kimlik bilgisinin adını `docker-hub` yapın

Sonra [Jenkinsfile](compose/Jenkinsfile)'ı düzenleyin:

- `REPOSITORY="courselabs"` ortam değişkeninin değerini kendi Docker Hub
  ID'nizle değiştirin
- _örneğin benim Hub ID'm `sixeyed`, dolayısıyla benim ayarım
  `REPOSITORY="sixeyed"` olacak_
- _Push_ aşamasını yorumdan çıkarın — baştaki `/*` ve sondaki `*/`
  işaretlerini silin

Değişikliklerinizi gönderin:

```
git add labs/pipeline/compose/Jenkinsfile  

git commit -m 'Added push'

git push gitea main
```

📋 `compose` job'ını yeniden çalıştırın ve imajların derlenip kendi kullanıcı
adınız altında Docker Hub'a gönderildiğini doğrulayın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Tüm build aşamalarını kontrol edin. _Push_ aşaması başarısız olursa loglara
bakın. Sorun, Docker Hub'a kimlik doğrulamasıyla ilgili olacak:

- Jenkins'teki `docker-hub` kimlik bilgilerinizin doğru olduğunu kontrol edin
- `REPOSITORY` ortam değişkeninizin kimlik bilgilerindeki Docker Hub ID ile
  eşleştiğini kontrol edin
- imajların, Docker Hub ID'nizi içeren beklenen imaj adıyla derlendiğini
  doğrulayın

Hata mesajı alırsanız sorunun ne olduğu anlaşılır olmalı. Build'i çalıştırmayı
başardığınızda imajların Docker Hub'a gönderildiğini göreceksiniz; benim
örneğim gibi: https://hub.docker.com/r/sixeyed/rng-api/tags

</details>

> Makinenizde Jenkins, Gitea veya .NET kurulu değil, muhtemelen. Ama artık bir
> .NET uygulaması için Docker imajlarını tamamen otomatik bir pipeline ile
> derleyip gönderebiliyorsunuz; pipeline ihtiyaç duyduğu tüm bağımlılıkları
> kendisi getiriyor.


## Lab

Docker imaj etiketleri tipik olarak sürümleme için kullanılır. Bizim
imajlarımız, imaj sürümü olarak bir sürüm döngüsü ve bir build numarası
taşıyor. İmajın daha az belirgin sürümlerini de sunmak istiyoruz, örneğin:

- `courselabs/rng-api:21.12-3` — 21.12 sürümünün 3 numaralı build'i
- `courselabs/rng-api:21.12` — 21.12 sürümünün en son build'i
- `ghcr.io/yasinoz/courselabs/rng-api:latest` — en son sürümün en son build'i

`latest` varsayılan etiket olduğu için kullanıcılar en güncel sürümü almak
için `courselabs/rng-api`, sürümün en son build'ini almak için
`courselabs/rng-api:21.12`, belirli bir build'i çalıştırmak için ise
`courselabs/rng-api:21.12-3` kullanabilir.

İmajları ek etiketlerle derlemek için kullanabileceğimiz birkaç Compose
override dosyası var:

- [labs/compose-build/rng/release.yml](../compose-build/rng/release.yml)
- [labs/compose-build/rng/latest.yml](../compose-build/rng/latest.yml)

[Jenkinsfile](compose/Jenkinsfile)'ı, bu etiketleri ekleyip build'in parçası
olarak Docker Hub'a gönderecek şekilde genişletin. Hedef, her build'in belirli
imaj etiketini göndermesi ve diğer etiketleri güncellemesi; böylece aynı imaj
digest'i için takma ad gibi çalışacaklar:

![](../../img/pipeline-lab.png)

Jenkinsfile değişikliklerinizi Gitea'ya gönderip Jenkins'te yeni bir build
çalıştırmanız gerekecek. Her şey çalıştığında makinenizdeki Docker ile
`latest` imajını çekin. Metadata içinden build bilgisini ve Git hash'ini
bulabiliyor musunuz?

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
docker compose -f labs/pipeline/infra/docker-compose.yml down -v
```

> `-v` isimsiz volume'ları da siler. Olmadan Gitea'nın veritabanı hayatta
> kalır ve lab'ın sonraki çalıştırmasında kullanıcı oluşturma adımı
> `user already exists` hatası verir.

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.

Ve Gitea remote'unu kaldırın:

```
git remote rm gitea
```
