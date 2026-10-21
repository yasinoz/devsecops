# Lab Çözümü

Benim çözümümü [lab/Jenkinsfile](./lab/Jenkinsfile) dosyasında görebilirsiniz:

- latest etiketlerini derleyip gönderen yeni bir aşama ekliyor
- yeni aşamanın build adımında iki Compose komutu var: biri release
  etiketlerini, diğeri latest etiketlerini derliyor
- ikinci aşamada da iki Compose komutu var: release etiketlerini ve latest
  etiketlerini gönderiyor

İmajları yeniden derlemek israf gibi görünebilir, ama Docker'ın önbelleği
yoğun biçimde kullandığını ve yeni build'lerin çok hızlı tamamlandığını
göreceksiniz.

Alternatif olarak `docker image tag` komutuyla mevcut bir imaja yeni etiket
ekleyip onu gönderebilirsiniz, ama bunu Compose ile yapamazsınız; imaj
adlarını sabit yazmanız gerekir.

Buradaki yaklaşım, Compose dosyalarınıza yeni imajlar eklediğinizde de
çalışmaya devam ediyor.

Bir `latest` imajı çekmeyi deneyin:

```
docker pull ghcr.io/yasinoz/courselabs/rng-api:latest
```

Sonra inceleyebilirsiniz:

```
docker inspect ghcr.io/yasinoz/courselabs/rng-api:latest
```

Etiketlerin içinde build etiketini ve commit hash'ini göreceksiniz:

```
"Labels": {
                "build_tag": "compose-7-origin/main",
                "commit_sha": "e2ebdf2ca8bf55d5f38c1095ffcad55bc7866039"
            }
```

> Build etiketi Jenkins job adını, build numarasını ve git branch'ini içeriyor

___
> [Alıştırmalara](README.tr.md) dönün.
