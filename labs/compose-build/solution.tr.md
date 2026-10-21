# Lab Çözümü

GitHub derlemesinin ikinci bölümü `latest` Docker Compose dosyasını
kullanıyor:

- [release.yml](./rng/release.yml) farklı imaj etiketleri kullanıyor; ana
  Compose dosyasının kullandığı `BUILD_NUMBER` değişkenini değil, `RELEASE`
  ortam değişkenini kullanıyor

Bu dosyayı birleştirdiğinizde imajlar `21.05` etiketiyle derleniyor; bu da
uygulamanın bu sürümünün numarası.

Kullanıcılar bu sürümün güncel build'ini almak için `21.05`, belirli bir
build'i almak için ise örneğin `21.05-39` kullanabilir:

```
docker pull ghcr.io/yasinoz/courselabs/rng-api:21.05

docker image ls courselabs/rng-api
```

Buradaki *takma ad* kelimesine dikkat. İş akışı iki etiketi iki ayrı
`docker compose build` çalıştırmasında derliyor, bu yüzden kaynak birebir
aynı olsa bile ayrı imajlar çıkıyor - karşılaştırın, digest'ler farklı:

```
docker manifest inspect ghcr.io/yasinoz/courselabs/rng-api:21.05

docker manifest inspect ghcr.io/yasinoz/courselabs/rng-api:21.05-39
```

Tüketici için önemli olan her etiketin verdiği söz: `21.05` size her zaman
o sürümün güncel build'ini verir, `21.05-39` ise her zaman tam olarak o
build'i. Sonraki sürümde `21.05` etiketi ilerler; numaralı etiket asla.

___
> [Alıştırmalara](README.tr.md) dönün.
