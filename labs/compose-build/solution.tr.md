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
docker pull courselabs/rng-api:21.05

docker image ls courselabs/rng-api
```

Bu iki etiket şu an aynı imajın takma adı, ama sonraki sürümde `21.05`
etiketi ilerleyip daha yeni bir build'in takma adı olacak.

___
> [Alıştırmalara](README.tr.md) dönün.
