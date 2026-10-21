---
title: Altın İmaj Kütüphaneleri
lang: tr
slug: golden-images
section: security
order: 3
duration: 50
requires: [docker]
status: needs-review
upstream: labs/golden-images
---
# Altın İmaj Kütüphaneleri

Docker Hub, önceden paketlenmiş ve çalışmaya hazır açık kaynak yazılım bulmak
için harika bir yer. Ama Docker Hub'a herkes genel imaj gönderebiliyor,
dolayısıyla orada bulduğunuza mutlaka güvenemezsiniz. Resmi imajlara
güvenilebilir, ama sık güncelleniyorlar ve güncellemeleri takip etmeniz
gerekiyor.

Geliştiricilerin uygulamaları için herhangi bir temel imaj kullanmasına izin
vermek iyi bir fikir değil. Bilmeden, arka kapısı açılmış ya da bitcoin
madenciliği yapan kötü niyetli bir imaj kullanabilirler. Temel imajın resmi
olmasını şart koşmak daha iyi bir politika, ama bu kez verimliliğe mal olan ve
uygulamalarınızı güvende tutmayı zorlaştıran çok sayıda sürüm ve varyantla
karşı karşıya kalabilirsiniz.

Kendi temel imaj kümenizi — _altın imajlar_ — oluşturup tüm uygulamaların
bunları kullanmasını zorunlu kılmak en iyi yaklaşım. Böylece kendi onaylı imaj
listenizi derleyip ihtiyacınıza göre şekillendirebiliyorsunuz.

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

## Geliştiricinin Serbest Bölgesi

Önce problemi anlayalım. Şu iki Java uygulaması farklı temel imajlar ve farklı
build kalıpları kullanıyor:

- [app-1/Dockerfile](./apps/app-1/Dockerfile) — Amazon Linux tabanında on
  yıllık bir Java olan Amazon Corretto 8 kullanıyor; uygulamayı derlemek için
  de çalıştırmak için de aynı JDK'yı kullanıyor

- [app-2/Dockerfile](./apps/app-2/Dockerfile) — Eclipse Temurin kullanıyor;
  derleme için JDK, çalışma zamanı için JRE ile çok aşamalı bir build; bunlar
  Debian tabanlı imajlar

İki uygulamayı da Compose ile derleyin:

```
docker compose -f labs/golden-images/apps/docker-compose.yml build
```

📋 Yeni imajları listeleyip karşılaştırın. Katmanları inceleyin — iki Java
uygulaması katman önbelleğini iyi kullanıyor mu?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

İmaj referanslarının ikisi de `courselabs/app` ile başlıyor ve `v1` etiketini
kullanıyor, dolayısıyla filtrede bunu kullanabilirsiniz:

```
docker image ls "courselabs/app*:v1"
```

app-2'nin yaklaşık 450MB, app-1'in ise 550MB'ın üzerinde olduğunu
göreceksiniz. Daha basit kurulum olmasına rağmen büyük olan app-1: çalışma
imajında JDK'nin tamamını taşıyor, app-2 ise yalnızca JRE gönderiyor.

Burada katman sayısı değil, katmanların *paylaşılıp paylaşılmadığı* önemli.
Her imajın yalnızca katman özetlerini yazdırın:

```
docker inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' courselabs/app-1:v1

docker inspect -f '{{range .RootFS.Layers}}{{println .}}{{end}}' courselabs/app-2:v1
```

İki listeyi yan yana koyunca hiçbir ortak özet olmadığını görürsünüz.
İkisinde de geçen tek özet `sha256:5f70bf18...` — Docker'ın boş yer tutucu
katmanı; içinde dosya yok, dolayısıyla hiçbir önbellek kazancı değil.

</details>

İkisi de Java uygulaması ve aynı çalışma ortamına ihtiyaç duyuyorlar, ama imaj
hiyerarşileri tamamen ayrışmış — on yıllık bir Amazon Linux JDK'sine karşı
güncel bir Debian Temurin JRE'si. Gerçek hiçbir katmanı paylaşmıyorlar,
dolayısıyla Docker katman önbelleği hiç yeniden kullanılmıyor — imajların güvenliğini hiç
düşünmesek bile disk alanı ve ağ bant genişliği için kötü haber.

## Altın İmaj Kütüphanesi

Kendi temel kütüphanenizi kurmak için desteklemek istediğiniz platformlara ve
varyantlara karar vermeniz gerekiyor. Bir denge kurmanız lazım: yönetilebilir
kalması ve önbelleğin en iyi kullanılması için az sayıda altın imaj
istiyorsunuz, ama uygulamalarınızı da desteklemeniz gerekiyor.

Bu kütüphanede Java uygulamaları için iki imaj kümesi var:

- [Debian tabanlı JDK](./library/java/debian/jdk/Dockerfile) ve
  [Debian tabanlı JRE](./library/java/debian/jre/Dockerfile). Bunlar resmi
  Eclipse Temurin imajları üzerine kuruluyor ve bir Java sürümüne pinlenmiş —
  ama belirli bir işletim sistemi sürümüne değil, çünkü resmi imaj bu
  ayrıntıda bir seçenek sunmuyor

- [Alpine tabanlı JDK](./library/java/alpine/jdk/Dockerfile) ve
  [Alpine tabanlı JRE](./library/java/alpine/jre/Dockerfile). Bunlar tamamen
  sürümlenmiş — açık bir Alpine sürümü ve açık bir OpenJDK apk sürümü.
  Sürümler build argümanı olduğu için güncellemek kolay. Bedeli bakım yükü:
  Alpine paketi yeniden derlediğinde apk sürüm dizgisi değişiyor ve onu takip
  etmeniz gerekiyor. (Bu lab'ın upstream sürümünü bozan şey tam olarak buydu —
  Alpine 3.15'ten bir paket pinlemişti ve o sürüm kullanım ömrünü tamamladı.)

- [library/docker-compose.yml](./library/docker-compose.yml) — kütüphane
  imajlarının build ayrıntılarını taşıyor ve özel bir adlandırma geleneği
  kullanıyor

📋 Kütüphaneyi Compose ile derleyin; `FROM` satırlarındaki imajların en güncel
sürümlerini indirdiğinizden emin olun.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker compose -f ./labs/golden-images/library/docker-compose.yml build --pull
```

</details>

Yeni kütüphane imajlarının boyutlarını ve etiketlerini kontrol edin:

```
docker image ls "courselabs/java*"
```

Alpine sürümleri Debian varyantlarından küçük — aşağıdaki sayılar tek bir
çalıştırmadan, temel imajlar değiştikçe sizdekiler farklı olacak:

```
REPOSITORY        TAG                IMAGE ID       CREATED              SIZE
courselabs/java   jdk-26.10          dbe839e1d807   About a minute ago   271MB       
courselabs/java   jre-26.10          ad98b2279e7f   About a minute ago   184MB       
courselabs/java   jre-debian-26.10   79786bc38074   2 weeks ago          221MB       
courselabs/java   jdk-debian-26.10   0d6d8cde8cc0   2 weeks ago          422MB
```

Artık Java uygulamaları için zorunlu kılabileceğimiz bir imaj kümemiz var —
Alpine tercih edilen, Debian ise ek uyumluluk için mevcut.

## Altın İmajları Kullanmak

İmaj kütüphanesini kullanmak, uygulama Dockerfile'larındaki `FROM` imajını
değiştirmekten ibaret; bunu yaparken onları standart çok aşamalı build
kalıbını kullanacak şekilde de düzeltebiliriz:

- [app-1/Dockerfile.v2](./apps/app-1/Dockerfile.v2) ve
  [app-2/Dockerfile.v2](./apps/app-2/Dockerfile.v2) — ikisi de kütüphanedeki
  JDK ve JRE imajlarını kullanıyor

- [apps/docker-compose-v2.yml](./apps/docker-compose-v2.yml) — uygulamaları v2
  Dockerfile'ları ve `v2` etiketiyle derliyor

Yeni sürümleri derleyin:

```
docker compose -f labs/golden-images/apps/docker-compose-v2.yml build
```


📋 v2 imajlarını listeleyip katmanları karşılaştırın. Artık önbelleği
kullanıyor muyuz?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Bu imajlar `courselabs/app` ile başlıyor ve `v2` etiketini kullanıyor,
dolayısıyla filtrede bunu kullanabilirsiniz:

```
docker image ls "courselabs/app*:v2"
```

İkisi de 340MB civarında — altın JRE imajıyla megabaytına kadar aynı boyutta.
Uygulama ikili dosyaları o kadar küçük ki temel imaja pek bir şey eklemiyorlar.

Katman ID'lerini kontrol etmek için temel imajı ve uygulama imajlarını
inceleyin:

```
docker inspect courselabs/java:jre-26.10

docker inspect courselabs/app-1:v2

docker inspect courselabs/app-2:v2
```

JRE imajında iki katman var — Alpine katmanı artı OpenJDK katmanı. app-1 imajı
bu katmanları yeniden kullanıp iki tane daha ekliyor: biri `/app` klasörünü
oluşturan, diğeri class dosyasını ekleyen. app-2 imajında da dört katman var —
üçünü app-1 ile paylaşıyor, yani yalnızca uygulama ikilisini taşıyan son
katman farklı.

</details>

Tek bir çalıştırmada orijinal v1 uygulama imajları aralarında yaklaşık 860MB
disk tuttu, çünkü hiç katman paylaşmıyorlar. v2 uygulamaları toplamda yaklaşık
185MB tuttu — paylaştıkları JRE imajı. Sizdeki tam sayılar farklı olacak; asıl
nokta oran.

> Dockerfile'larınızdaki temel imajları kontrol etmek için build'inizde
> [Anchore](https://anchore.com) gibi bir araç kullanabilirsiniz; böylece temel
> imajlar kütüphaneden değilse build başarısız olur

## İmaj Önbelleği

İmajlarınızın gerçekte ne kadar yer kapladığını görmek zor, çünkü Docker
_virtual size_ bildiriyor — yani imaj makinenizdeki tek imaj olsaydı ne kadar
depolamaya ihtiyaç duyacağı.

İmaj listesinin çıktısı ne kadar katman paylaşımı olduğunu net göstermiyor:

```
docker image ls "courselabs/app*"
```

v2 uygulamaları için 2x184MB var gibi görünüyor, ama bunun çoğunlukla tek bir
paylaşılan katman kümesi olduğunu biliyoruz.

`docker system` komutları gerçekte ne kadar depolama kullanıldığını görmenizi
ve kullanılmayan veriyi temizlemenizi sağlıyor.

📋 İmajlarınızın ne kadar disk alanı kullandığını görmek ve kullanılmayan
veriyi temizlemek için sistem komutlarını kullanın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Disk kullanımı Linux işletim sistemiyle aynı komutu kullanıyor:

```
docker system df
```

Kaç imaj saklandığını, ne kadar disk kullandıklarını ve ne kadarının geri
kazanılabileceğini göreceksiniz. _Reclaimable_ imajlar hiçbir container
tarafından kullanılmayanlar — hepsini kaldırmak istemezsiniz, çünkü bir
sonraki container çalıştırmanızda imajı yeniden çekmeniz gerekir.

Ama kullanılmayan alanı güvenle temizleyebilirsiniz; bu, hiçbir imaj
tarafından referans edilmeyen katmanları siliyor (bunlara _dangling_ deniyor):

```
docker system prune -f
```

</details>

Çok imaj derliyorsanız sisteminizi düzenli olarak temizlemek isteyeceksiniz.
Build sunucularını temizleyen zamanlanmış bir job da iyi fikir — aktif bir
sunucunun diski Docker imaj katmanlarıyla ne kadar hızlı dolduracağına
şaşıracaksınız.

## Lab

Altın imajımızı kullanması gereken bir Java uygulamamız daha var ve birkaç
başka sorunu da bulunuyor:

- [app-3/Dockerfile](./apps/app-3/Dockerfile) — imaj build için Maven
  kullanıyor; onun için altın imajımız yok ama son uygulama imajında
  kullanılmıyor, dolayısıyla olduğu gibi kalabilir. Çalışma ortamı imajı ise
  kütüphanemizden değil, yine resmi bir Java varyantı.

- [app-3/pom.xml](./apps/app-3/pom.xml) — Maven'da POM dosyası uygulamanın
  kullandığı tüm bağımlılıkları listeliyor. Ama mevcut kurulum kütüphanelerin
  en güncel sürümlerini açıkça kullanmıyor, dolayısıyla tam bir denetim izimiz
  yok.

Bu kurulum size çalışan bir imaj veriyor, ama kaynak kontrolünden hangi
kütüphane sürümlerinin kurulu olduğunu anlayamıyorsunuz:

```
docker build -t app-3:v1 labs/golden-images/apps/app-3
```

Hedefiniz bu dosyaları, çalışma ortamı için altın JRE imajını ve kütüphanelerin
en güncel sürümlerini — micrometer ve JAR eklentisi — kullanacak şekilde
düzeltmek.

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
docker compose -f labs/golden-images/apps/docker-compose.yml down
docker compose -f ./labs/golden-images/library/docker-compose.yml down
docker compose -f labs/golden-images/apps/docker-compose-v2.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
