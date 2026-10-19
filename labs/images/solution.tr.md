# Lab Çözümü

Örnek bir çözüm:

- [lab/Dockerfile](./lab/Dockerfile)

Yaptığı tek şey, container dosya sisteminde `/app` adında bir çalışma dizini
oluşturup Java class dosyasını içine kopyalamak.

Class dosyası ile Dockerfile farklı dizinlerde olduğu için, Docker'ın her iki
dosyaya da erişebileceği bir context kullanmanız gerekiyor:

```
labs
└─ images   <- context burasi
   └─  java   <- class dosyasini buradan alabiliyor
   └─  lab    <- Dockerfile'i da buradan
```

İmajı bu context ile ve Dockerfile yolunu belirterek derleyin:

```
docker build -t java-hello-world -f labs/images/lab/Dockerfile labs/images
```

İmajdan bir container çalıştırın:

```
docker run java-hello-world
```

> Çıktı `Hello, World` demeli

___
> [Alıştırmalara](README.tr.md) dönün.
