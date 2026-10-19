# Lab Çözümü

Varsayılan registry Docker Hub'dır — `docker.io` alan adını kullanır — ve
varsayılan imaj etiketi `latest`'tir.

Yani `kiamol/ch05-pi`, `docker.io/kiamol/ch05-pi:latest` ifadesinin kısa
hâlidir:

```
docker pull kiamol/ch05-pi

docker pull docker.io/kiamol/ch05-pi:latest
```

İmaj listesine bakın, yalnızca bir tane göreceksiniz — bunlar takma ad değil,
aynı adın farklı yazımları:

```
docker image ls kiamol/ch05-pi
```

> `latest` imajlarını kullanırken dikkatli olun — kafa karıştırıcı bir isim,
> çünkü en güncel sürüm olmayabilir.

Diğer registry'ler için referansa alan adını dahil etmeniz gerekiyor; yani
MCR üzerindeki imajların önüne `mcr.microsoft.com/` gelmeli:

```
docker pull mcr.microsoft.com/dotnet/runtime:10.0
```

___
> [Alıştırmalara](README.tr.md) dönün.
