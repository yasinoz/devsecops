---
title: Metrik Yayınlamak
lang: tr
slug: prometheus/metrics
section: observability
order: 2
duration: 40
requires: [docker]
status: needs-review
upstream: labs/prometheus/metrics
---
# Metrik Yayınlamak

Dağıtık bir mimaride her bileşeniniz bir HTTP uç noktası açar ve o bileşenle
ilgili tüm metrikleri yayınlar. Metrik biçimi standarttır ve metrikleri farklı
ayrıntı seviyelerinde toplamak isteyeceksiniz.

## Kaynaklar

- [Prometheus yayın (exposition) biçimi](https://prometheus.io/docs/instrumenting/exposition_formats/) — en yaygın metrik biçimi
- [Metrik tipleri](https://prometheus.io/docs/concepts/metric_types/) — Prometheus'taki dört metrik tipi
- [İstemci kütüphaneleri](https://prometheus.io/docs/instrumenting/clientlibs/) — uygulamalara ölçümleme eklemek
- [Exporter'lar](https://prometheus.io/docs/instrumenting/exporters/) — üçüncü parti sistemler için ölçümleme

## Uygulama metrikleri

Basit bir sunucu uygulaması çalıştırarak başlayın. Taklit bir döküman
işleyici ve yaptığı iş hakkında metrikler kaydediyor:

```
docker run -d -p 9110:9110 --name processor courselabs/fulfilment-processor:25.03
```

> Metrik uç noktasını http://localhost:9110/metrics adresinde açın

Bol miktarda metin göreceksiniz, içinde şunun gibi satırlar olacak:

```
# HELP fulfilment_requests_total Fulfilment requests received
# TYPE fulfilment_requests_total counter
fulfilment_requests_total{status="failed"} 0
fulfilment_requests_total{status="processed"} 142

# HELP fulfilment_in_flight_total Fulfilment requests in progress
# TYPE fulfilment_in_flight_total gauge
fulfilment_in_flight_total 142
```

Bu veri, işleyicinin o anda üzerinde çalıştığı döküman sayısını ve şimdiye
kadar işlediği sayıyı kaydediyor.

📋 Sayıları bir yere not edip sayfayı birkaç kez yenileyin. _gauge_ ve
_counter_ metrikleri arasındaki fark ne?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Counter değerleri artabilir veya aynı kalabilir, azalmaz. Genellikle yapılmış
şeyleri saymak için kullanılırlar; o sayı da geriye gitmez.

Birkaç yenilemeden sonra benim işlenmiş sayacım 142'den 4403'e çıktı:

```
# HELP fulfilment_requests_total Fulfilment requests received
# TYPE fulfilment_requests_total counter
fulfilment_requests_total{status="failed"} 180
fulfilment_requests_total{status="processed"} 4403
```

Gauge'lar yukarı veya aşağı gidebilir (ya da aynı kalabilir). Şu anda olup
biten şeylerin sayısının anlık görüntüsünü kaydetmek için kullanılırlar.

Yenilemelerden sonra benim işlemde olan sayacım 142'den 46'ya düştü:

```
# HELP fulfilment_in_flight_total Fulfilment requests in progress
# TYPE fulfilment_in_flight_total gauge
fulfilment_in_flight_total 46
```

</details><br/>

Prometheus aynı tür verinin farklı yönlerini kaydetmek için etiketler
kullanıyor; bu yüzden `fulfilment_requests_total` metriği hem işlenen döküman
sayısı hem de başarısız olanların sayısı için sayaç içeriyor.

📋 Uygulama neden ayrıca başarıyla işlenmiş döküman sayısını da kaydetmiyor?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Daha fazla etiket, kaydedilecek daha fazla veri demek; bu yüzden diğer
metriklerden güvenilir biçimde hesaplanabilen metrikleri üretmemelisiniz.

Başarılı sayıyı, toplamdan hata sayısını çıkararak her zaman
belirleyebilirsiniz:

```
fulfilment_requests_total{status="failed"} 180
fulfilment_requests_total{status="processed"} 4403
```

=> başarıyla işlenen = 4403-180 = 4223

</details><br/>

Şu anda bu uygulama yalnızca özel metrikleri gösteriyor. Prometheus istemci
kütüphaneleri uygulama platformu hakkında yaygın metrikler de üretebiliyor.

İşleyici container'ını kaldırıp, platform çalışma ortamı metriklerini
yayınlayacak şekilde yapılandırılmış yenisini başlatın (bu,
[prometheus-net istemci kütüphanesini](https://github.com/prometheus-net/prometheus-net)
kullanan bir .NET uygulaması):

```
docker rm -f processor

docker run -d -p 9110:9110 --name processor -e Observability__Metrics__IncludeRuntime=true courselabs/fulfilment-processor:25.03
```

> Metrik uç noktasını yine http://localhost:9110/metrics adresinde açın

Uygulama metrikleri yerinde duruyor; yanlarına kullanılan thread sayısı ve
harcanan işlemci zamanı gibi standart metrikler eklendi:

```
# HELP process_num_threads Total number of threads
# TYPE process_num_threads gauge
process_num_threads 16

# HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
# TYPE process_cpu_seconds_total counter
process_cpu_seconds_total 0.47
```

📋 İşlenen döküman sayacına ne oldu?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Sıfırlandı — bu, uygulamanın yeni bir örneği ve yeni bir metrik kümesi var.

Prometheus sıfırlanmaları anlıyor; bu metriği sorgularsanız güncel sayaç
değerlerini uygulamanın önceki örneğinden gelen veriye ekler.

</details><br/>

Uygulama metrikleri, uygulamanızın ne yaptığını ve ne kadar yüklendiğini
söylüyor. Sunucularınızın ne yaptığını görmek için altyapı seviyesinde de
metrik istiyorsunuz.

## Sunucu metrikleri

[node exporter](https://github.com/prometheus/node_exporter) standart sunucu
ayrıntılarını yayınlıyor. Normalde Linux makinelerde bir arka plan servisi
olarak çalıştırırdınız (Windows makineler için
[Windows exporter](https://github.com/prometheus-community/windows_exporter)
da var).

Yayınladığı metrikleri container içinde çalıştırarak görebiliriz.

```
docker run -d -p 9100:9100 --name node prom/node-exporter:v1.9.1
```

> Bu metrikleri http://localhost:9100/metrics adresinde açın

Çok daha fazla metrik göreceksiniz; sistem bilgilerini ve node exporter'ın
kendi uygulama platformuna dair ayrıntıları kaydediyorlar.

📋 Exporter hangi dilde yazılmış? Döküman işleyiciyle aynı olan metrik var mı?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Exporter Go ile yazılmış — Go çalışma ortamıyla ilgili bir sürü metrik
göreceksiniz (sizdeki Go sürümü farklı olacak):

```
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 8

# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.15.8"} 1
```

Kütüphane yazarlarının mümkün olduğunca standart metrikler yayınlaması
teşvik ediliyor. Bir Linux sunucusu ile döküman işleyici uygulaması arasında
çok fazla ortak ölçümleme yok, ama ikisinde de
`process_cpu_seconds_total` ve `process_start_time_seconds` göreceksiniz.

</details><br/>

Aynı tür metriğin farklı sistemlerde yayınlanması onları karşılaştırmanıza
imkân veriyor. Görmek isteyeceğiniz bir ayrıntı seviyesi daha var ve sunucu
ile özel uygulama metriklerinizin arasına oturuyor: uygulamanızı barındıran
çalışma ortamından gelen ölçümleme.

## Çalışma ortamı metrikleri

Tomcat ve ASP.NET gibi uygulama sunucuları, işlenen HTTP istek sayısı gibi
kullanım metriklerini yayınlamalı. Bunlar genellikle istemci kütüphanesinde
standart olarak kaydedilip yayınlanıyor.

Tomcat ve [micrometer istemci kütüphanesini](https://micrometer.io) kullanan
bir Java REST API'si çalıştırın:

```
docker run -d -p 8080:80 courselabs/fulfilment-api:25.03
```

> Metrikleri http://localhost:8080/actuator/prometheus adresinde açın

Bu metrikler JVM (Java çalışma ortamı) ve Tomcat'in (HTTP sunucusu)
performansı hakkında bol ayrıntı içeriyor. Uygulamada bunları kaydeden hiç
kod yok; hepsi
[Spring Boot'un metrik toplamasının](https://docs.spring.io/spring-boot/reference/actuator/metrics.html)
parçası.

Birkaç uygulama uç noktasını açmayı deneyin:

- http://localhost:8080/documents — işlenen dökümanların taklit bir listesini
  gösteriyor
- http://localhost:8080/notfound — 404 bulunamadı sayfası döndürüyor

📋 Metrikleri yenileyin. Uygulamanın sunduğu HTTP istekleri hakkında ne
öğrenebiliyorsunuz?

<details>
  <summary>Biraz yardım lazım mı?</summary>

`http_server_requests_seconds` adında bir metrik var; istek sayısını ve
işlenme süresini, istenen URL ve yanıt koduna göre ayırarak kaydediyor:

```
# HELP http_server_requests_seconds  
# TYPE http_server_requests_seconds summary
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/actuator/prometheus",} 18.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/actuator/prometheus",} 0.1702426
http_server_requests_seconds_count{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/documents",} 2.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="SUCCESS",status="200",uri="/documents",} 0.0521596
http_server_requests_seconds_count{exception="None",method="GET",outcome="CLIENT_ERROR",status="404",uri="/**",} 3.0
http_server_requests_seconds_sum{exception="None",method="GET",outcome="CLIENT_ERROR",status="404",uri="/**",} 0.258512
```

Bu bir summary gauge; istekler için ortalama işlenme süresini göstermek üzere
kullanabilirsiniz, örneğin /documents uç noktası için:

```
http_server_requests_seconds_count=3.0
http_server_requests_seconds_sum=0.258512
```

=> ortalama işlenme süresi = 0.258512 / 3.0 = istek başına 0.086 saniye

</details><br/>

Summary metrikleri her metrik için iki veri kaydeder: kaç kez gerçekleştiği ve
tüm gerçekleşmelerin toplam süresi. Bu, çok fazla veri saklamadan ortalama
hesaplamanıza imkân verir.

## Lab

Counter, gauge ve summary'ye baktık. Bir metrik tipi daha var: histogram.

Döküman işleyicinin metriklerine http://localhost:9110/metrics adresinden
yeniden bakın; bir histogram metriği göreceksiniz. Ne kaydediyor ve veriyi
nasıl kullanabilirsiniz?

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
