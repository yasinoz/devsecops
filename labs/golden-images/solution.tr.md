# Lab Çözümü

Dockerfile'da son aşamada altın imajı kullanmak için basit bir güncelleme
yeterli:

- [lab/Dockerfile](lab/Dockerfile) — çalışma ortamı için
  `courselabs/java:jre-26.10` kullanıyor

POM dosyası, Micrometer'ın aralık yerine açık bir sürüm, JAR eklentisinin ise
en güncel sürümü kullanacağı şekilde güncellenmeli:

- [lab/pom.xml](lab/pom.xml) — yazıldığı tarihteki en güncel sürümleri
  kullanıyor :)

Örnek çözümü yeni bir etiketle derleyebilirsiniz:

```
docker build -t app-3:v2 ./labs/golden-images/lab/
```

Uygulama imajlarını kontrol edin:

```
docker image ls app-3
```

Tek bir çalıştırmada v2 imajı yaklaşık %30 daha küçük çıktı (sizdeki sayılar
farklı olacak):

```
REPOSITORY   TAG       IMAGE ID       CREATED         SIZE
app-3        v1        90f85a6e8be0   2 minutes ago   221MB
app-3        v2        cbc2c31a0685   2 minutes ago   184MB
```

Katmanları görmek için imajları incelerseniz:

```
docker inspect app-3:v1

docker inspect app-3:v2
```

v1'in farklı bir katman kümesine sahip olduğunu göreceksiniz — derlediğimiz
diğer Java uygulamalarının hiçbiriyle ortaklığı yok. v2, app-1 ve app-2'nin v2
imajlarıyla aynı temel katmanları paylaşıyor; yani onaylı bir temel imajı
zorunlu kılarken katman önbelleğini de en iyi şekilde kullanıyoruz.

___
> [Alıştırmalara](README.tr.md) dönün.
