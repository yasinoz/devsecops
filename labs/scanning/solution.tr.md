# Lab Çözümü

İmajı derleyin; bir yığın CVE ile başarısız olacak:

```
docker build -t hello-world-cs labs/scanning/hello-world-cs
```

Ne aradığınızı bildiğinizde bu basit bir düzeltme :)

Uygulama imajı, işletim sistemi katmanı olarak Debian kullanan bir .NET
çalışma ortamı imajına dayanıyor:

```
FROM mcr.microsoft.com/dotnet/runtime:10.0 AS app
```

Trivy'nin bulduğu tüm sorunlar işletim sistemi araçlarında ve paketlerinde.
Debian bazı çalışma ortamları için varsayılan işletim sistemi, çünkü en geniş
uyumluluğa sahip — ama potansiyel sorunlu çok daha fazla paket içeriyor.

Alpine işletim sistemi daha iyi bir seçenek, ama Alpine ile diğer Linux
dağıtımları arasında bazı temel farklar olduğu için uygulamalarınızın doğru
çalıştığını test etmeniz gerekiyor.

Dockerfile'ı Alpine çalışma ortamı imajını kullanacak şekilde değiştirin —
[Dockerfile.solution](./hello-world-cs/Dockerfile.solution) dosyasındaki gibi:

```
FROM mcr.microsoft.com/dotnet/runtime:10.0-alpine AS app
```

Yeniden derleyin; HIGH önem derecesinde sorun kalmadığı için imaj üretiliyor
ve bir container çalıştırarak test edebilirsiniz:

```
docker build -t hello-world-cs -f labs/scanning/hello-world-cs/Dockerfile.solution labs/scanning/hello-world-cs

docker run --rm hello-world-cs
```

İyi görünüyor :)

Bu imajın taranmış olduğunu doğrulamak için Trivy'nin sürümünü kontrol
edebiliriz:

```
docker run --rm --entrypoint sh -it hello-world-cs

cat /app/scanner.txt

exit
```

___
> [Alıştırmalara](README.tr.md) dönün.
