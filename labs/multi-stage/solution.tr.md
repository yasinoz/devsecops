# Lab Çözümü

Uygulamayı özel bir portla çalıştırmak için argümanları uygulamaya geçirmeniz
yeterli:

```
# container icinde 5000 portunu dinleyecek sekilde calistir:
docker run -d -P --name whoami2 whoami -port 5000
```

## Sorun giderme

Uygulamanın kullandığı portu kontrol edebilirsiniz — ama çağırmaya
kalkarsanız yanıt alamazsınız:

```
docker port whoami2

curl localhost:<port>
```

Logları kontrol edin, sebebini göreceksiniz: Docker trafiği imajın expose
ettiği port olan 80'e yönlendiriyor. Ama uygulama o portu dinlemiyor:

```
docker logs whoami2
```

## Çözüm

Uygulamayı imajda expose edilmemiş bir port kullanacak şekilde
yapılandırıyorsanız portu **açıkça** eşlemeniz gerekiyor:

```
docker run -d -p 8050:5000 --name whoami3 whoami -port 5000

curl localhost:8050
```

Ya da host portunu Docker'ın rastgele seçmesini istiyorsanız yalnızca hedef
portu belirtin:

```
docker run -d -p :5000 --name whoami4 whoami -port 5000

docker port whoami4

curl localhost:<port>
```
___
> [Alıştırmalara](README.tr.md) dönün.
