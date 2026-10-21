---
title: Container İmajları Derlemek
lang: tr
slug: images
section: cicd
order: 2
duration: 40
requires: [docker]
status: updated
upstream: labs/images
---
# Container İmajları Derlemek

*İmaj*, container'ların çalıştığı pakettir. Uygulamanızın her bileşeni için bir
imaj derleyeceksiniz; imajın içinde tüm ön koşullar kurulu ve yapılandırılmış
halde, çalışmaya hazır gelir.

İmajı, container'ın dosya sistemi artı container başlarken Docker'ın hangi
komutu çalıştıracağını söyleyen bir miktar metadata olarak düşünebilirsiniz.

## Kaynaklar

- [Dockerfile sözdizimi](https://docs.docker.com/engine/reference/builder/)
- [İmaj derleme komutu](https://docs.docker.com/engine/reference/commandline/image_build/)


<details>
  <summary>Komut satırına genel bakış</summary>

İmajlarla çalışmak için `image` komutlarını kullanıyorsunuz. Derleme komutunun
kısayolları da var:

```
docker image --help

docker build --help

docker history --help
```

</details><br/>


## Temel imajlar

İmajlar bir hiyerarşi halinde derlenebilir: belirli bir Linux dağıtımını kuran
bir işletim sistemi imajıyla başlayıp, onun üzerine uygulama çalışma ortamınızı
ekleyebilirsiniz.

İmaj derlemeye başlamadan önce derleme çıktısını ayrıntılı hale getirelim;
böylece her Dockerfile komutunu çalışırken göreceksiniz:

```
# macOS veya Linux'ta:
export BUILDKIT_PROGRESS=plain

# VEYA PowerShell ile:
$env:BUILDKIT_PROGRESS='plain'
```

> [BuildKit](https://docs.docker.com/build/buildkit/) Docker'ın derleme
> motoru ve Docker 23'ten beri varsayılan. Varsayılan ayarda çıktıyı derli
> toplu bir özete sıkıştırıyor, bu da komutları tek tek görmenizi engelliyor.
> `BUILDKIT_PROGRESS=plain` her adımı yazdırır — Dockerfile sözdizimini
> öğrenirken istediğiniz şey budur.

Çok basit bir temel imaj derleyeceğiz:

- [temel imaj Dockerfile'ı](./base/Dockerfile)

```
docker build -t courselabs/base ./labs/images/base
```

- `-t` veya `--tag` imaja bir isim verir
- derleme komutunu Dockerfile'ın bulunduğu klasörün yoluyla bitirirsiniz


📋 Sahip olduğunuz tüm imajları listeleyin, sonra 'courselabs' ile başlayanları
filtreleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# tum yerel imajlari listele:
docker image ls

# ve courselabs imajlarini filtrele:
docker image ls 'courselabs/*'
```

</details><br/>

> Bunlar yerel Docker motorunuzun önbelleğinde duran imajlar.

Yeni temel imaj, [resmi Ubuntu imajının](https://hub.docker.com/_/ubuntu)
üzerine hiçbir şey eklemiyor. O imaj da çok farklı
[sürümlerde](https://hub.docker.com/_/ubuntu?tab=tags&page=1&ordering=last_updated)
yayınlanıyor.


📋 Ana Ubuntu imajını çekin, ardından Ubuntu 24.04 sürümünün imajını çekin.


<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker pull ubuntu

# imaj surumleri etiket adinda belirtilir:
docker pull ghcr.io/yasinoz/library/ubuntu:24.04
```

</details><br/>

Tüm Ubuntu imajlarınızı ve kendi temel imajınızı listeleyin:

```
docker image ls --filter reference=ubuntu --filter reference=courselabs/base
```

> ID'lere bakın — üçü de farklı. `ghcr.io/yasinoz/library/ubuntu:24.04` gerçekten farklı bir imaj:
> başka bir Ubuntu sürümü. İnce olan `courselabs/base`. Dockerfile'ı
> `ghcr.io/yasinoz/library/ubuntu:26.04` üzerine hiçbir şey eklemiyor (`latest` şu an onu gösteriyor),
> ama BuildKit her derlemede yeni bir imaj dışa aktardığı için sonuç kendi
> ID'sini alıyor.
>
> Yine de *içerik* birebir aynı — katmanları karşılaştırın:
>
> ```
> docker image inspect courselabs/base --format '{{.RootFS.Layers}}'
>
> docker image inspect ubuntu --format '{{.RootFS.Layers}}'
> ```
>
> Katman ID'leri aynı, imaj ID'si farklı. Ders iki katmanlı: imajlar katman
> paylaşır ve sürüm pinlemek önemlidir, çünkü `latest` kayar, sürüm etiketi
> kaymaz.

## Komutlar ve entrypoint'ler

Dockerfile sözdizimini öğrenmek kolay:

- her imaj başka bir imajdan, `FROM` ile başlamak zorunda
- derlemenin parçası olarak komut çalıştırmak için `RUN` kullanırsınız
- `CMD` ise container başladığında çalışacak komutu belirler

`curl` aracını kuran basit bir örnek:

- [curl Dockerfile](./curl/Dockerfile)

📋 `labs/images/curl` Dockerfile'ından `courselabs/curl` adında bir imaj
derleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker build -t courselabs/curl ./labs/images/curl
```

</details><br/>

Artık bu imajdan bir container çalıştırabilirsiniz ama beklediğiniz gibi
davranmayabilir:

```
# sadece curl'u calistirir:
docker run courselabs/curl 

# URL'i curl'a GECIRMEZ:
docker run courselabs/curl docker.courselabs.co

# curl'u kullanmak icin curl komutunu da yazmak gerekiyor:
docker run courselabs/curl curl --head docker.courselabs.co
```

> `CMD` komutu container'ın çalıştıracağı komutu **tam olarak** belirler.
> Container komutuna seçenek geçiremezsiniz — ama komutu tamamen
> değiştirebilirsiniz.

Güncellenmiş şu Dockerfile daha kullanışlı bir imaj üretiyor:

- [curl Dockerfile - v2](./curl/Dockerfile.v2)

Bu Dockerfile'dan bir v2 imajı derleyin:

```
docker build -t courselabs/curl:v2 -f labs/images/curl/Dockerfile.v2 labs/images/curl
```

- `-f` bayrağı Dockerfile adını belirtir; standart adı kullanmıyorsanız
  gerekiyor

Bu imajdan container'ları daha mantıklı bir sözdizimiyle çalıştırabilirsiniz:

```
docker run courselabs/curl:v2 --head docker.courselabs.co
```

> Container komutundaki `--head` argümanı ve URL, entrypoint'e geçiriliyor

📋 Boyutları karşılaştırmak için tüm `courselabs/curl` imajlarını listeleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
docker image ls courselabs/curl
```

</details><br/>

> v2 imajı daha küçük — yani dosya sisteminde daha az şey var ve saldırı
> yüzeyi daha küçük.


## İmaj hiyerarşisi

`FROM` imajı olarak genellikle işletim sistemi imajları kullanılmaz.
Uygulamanızın ön koşullarının mümkün olduğunca fazlasının zaten kurulmuş
olmasını istersiniz.

[Resmi imajları](https://hub.docker.com/search?q=&type=image&image_filter=official&category=languages)
kullanmalısınız; bunlar proje ekiplerinin baktığı uygulama ve çalışma ortamı
imajlarıdır.

Şu Dockerfile, resmi Nginx imajının üzerine birkaç özel HTML içeriği
paketliyor:

- [web Dockerfile](./web/Dockerfile)
- [özel HTML sayfası](./web/index.html)

```
docker build -t courselabs/web ./labs/images/web --pull
```

> `pull` argümanı Docker'a, derlemeye başlamadan önce FROM imajının en güncel
> sürümünü indirmesini söyler.

- klasör yoluna *context* (bağlam) denir; içinde Dockerfile ve onun atıf
  yaptığı dosyalar bulunur — bu örnekte `index.html` dosyası

📋 Yeni imajınızdan, 80 portunu yayınlayarak bir container çalıştırın ve
tarayıcıdan açın.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
# bos olan herhangi bir yerel portu kullanin, ornegin 8090:
docker run -d -p 8090:80 courselabs/web

curl localhost:8090
```

</details><br/>

> Container, resmi imajda yapılandırılmış Nginx kurulumunu kullanarak sizin
> HTML dökümanınızı sunuyor

Docker imajları _katmanlardan_ oluşur. İmaj mantıksal olarak tek bir pakettir
ama fiziksel olarak katman adı verilen çok sayıda küçük dosya halinde saklanır.

Katmanlar salt okunurdur ve imajlar arasında paylaşılabilirler — imajlarınızı
doğru derlerseniz disk alanını ve ağ bant genişliğini çok verimli
kullanırsınız.

Web imajınızı inceleyin; çıktının sonunda katman ID'lerini göreceksiniz:

```
docker inspect courselabs/web
```

📋 Web imajınızın temel aldığı imajı inceleyin. Paylaştıkları katman var mı?
*O* imajın temel aldığı imaj nasıl?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Temel imaj, Alpine üzerinde çalışan Nginx:

```
docker pull ghcr.io/yasinoz/library/nginx:1.31.7-alpine

docker inspect ghcr.io/yasinoz/library/nginx:1.31.7-alpine
```

Alpine'ı da kontrol edebilirsiniz:

```
docker pull ghcr.io/yasinoz/library/alpine:3.24

docker inspect ghcr.io/yasinoz/library/alpine:3.24
```

</details><br/>

> Paylaşılan katmanların tamamını görebiliyorsunuz — web imajı Nginx
> katmanlarının üzerine, Nginx imajı da Alpine katmanlarının üzerine
> derleniyor.

İmaj hiyerarşisinin tamamı şöyle:

```
ghcr.io/yasinoz/library/alpine:3.24
└─ ghcr.io/yasinoz/library/nginx:1.31.7-alpine
    └─ courselabs/web 
```

Bazı imajlar tüm zinciri etiketinde taşır — örneğin
`golang:1.17.3-alpine3.15`. Nginx etiketi Alpine işletim sistemi sürümünü
içermiyor, dolayısıyla onu deneme yanılma ile bulmanız gerekiyor (ya da imaj
derlendiğinde hangi işletim sistemi sürümünün güncel olduğunu bilmeniz).

## Lab

Sıra Dockerfile yazmada sizde.

Bu klasörde basit bir Java uygulaması var ve zaten
`labs/images/java/HelloWorld.class` dosyasına derlenmiş durumda.

Bu uygulamayı paketleyen bir Docker imajı derleyin ve çalıştığını doğrulamak
için bir container başlatın. Container'ınızın çalıştırması gereken komut
`java HelloWorld`.

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
