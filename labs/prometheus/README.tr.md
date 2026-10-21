---
title: Prometheus ile Metrik Toplamak
lang: tr
slug: prometheus
section: observability
order: 1
duration: 45
requires: [docker]
status: updated
upstream: labs/prometheus
---
# Prometheus

[Prometheus](https://prometheus.io) açık kaynak bir izleme çözümü. Bir
[CNCF](https://www.cncf.io) projesi (Kubernetes ile aynı vakıf altında) ve
eksiksiz bir izleme bileşenleri takımı barındırıyor.

<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 45 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [Prometheus dökümantasyonu](https://prometheus.io/docs/introduction/overview/)
- [İndirme ve kurulum ayrıntıları](https://prometheus.io/download/)
- [Yapılandırma ve servis keşfi](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)
- [Prometheus HTTP API dökümantasyonu](https://prometheus.io/docs/prometheus/latest/querying/api/)

## Prometheus'u çalıştırmak

Prometheus'u bir Docker container'ında çalıştıracağız:

- [prometheus.yml](./prometheus.yml) — container kurulumu, 9090 portunu
  yayınlıyor
- [config/prometheus.yml](./config/prometheus.yml) — Prometheus yapılandırma
  dosyası

Container'ı başlatın:

```
docker compose -f labs/prometheus/prometheus.yml up -d
```

> Prometheus arayüzünü http://localhost:9090 adresinde açın

Varsayılan sayfa metrik sorgulamanıza imkân veriyor — biraz sonra bunu
yapacağız. Önce birkaç başka sayfaya bakın:

- http://localhost:9090/config (_Status...Configuration_ menüsünden) —
  Prometheus'un kullandığı yapılandırmayı gösteriyor
- http://localhost:9090/targets (_Status...Targets_ menüsünden) — veri
  toplama (scrape) hedeflerinin durumunu gösteriyor

İzlemek istediğimiz hedeflerin hiçbiri çalışmıyor ama Prometheus onları
bulmaya çalışmaya devam edecek.

Şu [Docker Compose dosyası (apps.yml)](./apps.yml) metrik yayınlayan birkaç
örnek uygulama başlatıyor. Container'lar Prometheus ile aynı Docker ağına
bağlanacak ve Prometheus'un bulmayı beklediği DNS adlarını kullanacaklar.

Uygulamaları çalıştırın:

```
docker compose -f labs/prometheus/apps.yml up -d
```

> http://localhost:9090/targets durum sayfasını yenileyin, hedeflerin devreye
> girdiğini göreceksiniz

Prometheus arayüzündeki _Query_ sayfasını açın (http://localhost:9090
adresindeki varsayılan sayfa). İfade kutusunun yanındaki metrik seçici
toplanan tüm metrikleri listeliyor.

> Bu lab'ın eski sürümü `/classic/graph` adresine bağlanıyordu. Prometheus 3
> arayüzü değiştirdi ve klasik arayüz artık açılışta
> `--enable-feature=old-ui` gerektiriyor; dolayısıyla o adres 404 veriyor.

En basit sorgu için yalnızca metrik adı yeterli.

📋 `process_cpu_seconds_total` ve `app_info` sorgularını çalıştırdığınızda ne
görüyorsunuz?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Sorgu ifadesine `process_cpu_seconds_total` yazıp _Execute_ tıklayın.
Çıktıda iki metrik değeri göreceksiniz:

> _Table_ sekmesi her seri için bir satır gösterir: metrik adı, etiketleri ve
> güncel değer.

Bu, node exporter'ın ve döküman işleyicinin ne kadar CPU zamanı kullandığını
söylüyor.

`app_info` sorgulayın; şuna benzer bir çıktı göreceksiniz (sürüm numaraları
sizde farklı olacak, bu imajlar zaman içinde yeniden derleniyor):

|Element|Value|
|-|-|
|`app_info{app_version="1.3.1",assembly_name="Fulfilment.Processor",dotnet_version="3.1.16",instance="fulfilment-processor:9110",job="fulfilment-processor"}`|`1`|
|`app_info{instance="fulfilment-api",java_version="11-jre",job="fulfilment-api",version="0.3.0"}`|`1`|

Bunlar bilgilendirme amaçlı metrikler; döküman işleyici ve REST API için
uygulama ve çalışma ortamı sürüm numaralarını gösteriyorlar.

</details><br/>

Prometheus bir hedeften veri toplarken her metriğe iki etiket ekliyor:

- `job` — yapılandırılmış job'ın adı, genellikle tek bir bileşeni belirtmek
  için kullanılır, örneğin döküman işleyici
- `instance` — hedefin belirli örneği, genellikle bir sunucu veya bir
  container; örneğin `fulfilment-processor:9110` işleyici hedefinin DNS adı ve
  portu

Prometheus her metrik için bir zaman damgası da kaydediyor; yani her veri
parçası için nereden geldiğini ve ne zaman toplandığını biliyorsunuz.

## Zaman serisi verisi

_Table_ sekmesi yalnızca en güncel metrik değerini gösteriyor. Prometheus şu
anda her hedeften 30 saniyede bir veri toplayıp tüm metrikleri zaman serisi
veritabanına kaydediyor.

Bu veriyi keşfetmek için Graph sayfasını kullanabilirsiniz.

📋 `fulfilment_requests_total` metriğini sorgulayın, sonra sorguyu yalnızca
`processed` etiketinin değerini gösterecek şekilde değiştirin.

<details>
  <summary>Biraz yardım lazım mı?</summary>

`fulfilment_requests_total` için bir sorgu çalıştırın; şuna benzer bir çıktı
göreceksiniz:

|Element|Value|
|-|-|
|`fulfilment_requests_total{instance="fulfilment-processor:9110",job="fulfilment-processor",status="failed"}`|`777`|
|`fulfilment_requests_total{instance="fulfilment-processor:9110",job="fulfilment-processor",status="processed"}`|`17701`|

Etiketler süslü parantez içinde gösterilen anahtar-değer çiftleridir ve aynı
sözdizimini sorguda da kullanarak etiketle eşleşen metrikleri
gösterebilirsiniz.

`fulfilment_requests_total{status="processed"}` sorgusu yalnızca işlenmiş
sayısını gösteriyor.

</details><br/>

Prometheus bu sonuca _instant vector_ (anlık vektör) diyor; çünkü yalnızca tek
bir an için veriyi gösteriyor — toplanan en güncel değeri.

_Graph_ sekmesine geçin; sonuçları bir zaman aralığı boyunca, zaman aralığını
seçebileceğiniz bir grafikte göreceksiniz:

> _Graph_ sekmesi her seri için bir çizgi çizer. Bir counter (sayaç) ile çizgi
> yalnızca yükselir — `rate()` fonksiyonunu faydalı kılan şey de budur.

Bu metrik bir counter, dolayısıyla grafik sürekli artıyor.

📋 `fulfilment_in_flight_total` metriği için bir grafik, bir de (etiket
seçicisi olmadan) `fulfilment_requests_total` metriği için bir grafik
oluşturun. Nasıl karşılaştırılıyorlar?

<details>
  <summary>Biraz yardım lazım mı?</summary>

`fulfilment_in_flight_total` bir gauge metriği, dolayısıyla grafik yukarı ve
aşağı giden değerler gösterecek:

> Gauge yukarı ve aşağı gider, bu yüzden grafiği merdiven değil testere dişi
> gibi görünür.

`fulfilment_requests_total` farklı `status` etiketleri için birden fazla
metrik içeriyor; Prometheus her metrik için bir çizgi çiziyor:

> Her etiket kombinasyonu kendi çizgisi olur ve grafiğin altındaki açıklama
> onları isimlendirir.
 
</details><br/>

Prometheus arayüzü veriyi keşfetmek ve basit sorgular kurmak için iyi, ama
onunla tam bir dashboard oluşturamazsınız. Onun için Prometheus HTTP API'sine
sorgu gönderen Grafana'yı kullanacaksınız.

 ## Sorgu API'si

Genellikle sorgu API'siyle doğrudan çalışmazsınız, ama sorgu sonuçlarının ham
verisini görmek için iyi bir kaynak.

curl ile çağırabileceğiniz basit bir HTTP API'si.

_Windows kullanıyorsanız doğru curl komutunu kullanmak için şu script'i
çalıştırın:_

```
# once script'lere izin verin:
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# sonra calistirin:
. ./scripts/windows-tools.ps1
```

İşlemde olan döküman metriği için bir sorgu yapın:

```
curl 'localhost:9090/api/v1/query?query=fulfilment_in_flight_total'
```

JSON biçiminde, şuna benzer bir çıktı göreceksiniz (ama bu kadar düzgün
biçimlendirilmemiş):

```
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "fulfilment_in_flight_total",
          "instance": "fulfilment-processor:9110",
          "job": "fulfilment-processor"
        },
        "value": [
          1626510033.385,
          "71"
        ]
      }
    ]
  }
}
```

Bu bir anlık vektör. Gerçek değer bir metin olarak dönüyor — bu örnekte `71` —
ve değerin kaydedildiği zaman damgasını da içeriyor (Linux epoch olarak;
`1626510033.385`, 17 Temmuz 2021 Cumartesi 08:20:33.385).

📋 API'yi kullanarak `up` metriğini sorgulayın. Yanıt size ne söylüyor?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Sorgu yalnızca metrik adını kullanabilir:

```
curl 'localhost:9090/api/v1/query?query=up'
```

Şuna benzer bir yanıt alacaksınız; sonuçta birden fazla metrik var — her veri
toplama hedefi için bir tane:

```
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "up",
          "instance": "fulfilment-api",
          "job": "fulfilment-api"
        },
        "value": [
          1626510366.389,
          "1"
        ]
      },
      {
        "metric": {
          "__name__": "up",
          "instance": "fulfilment-processor:9110",
          "job": "fulfilment-processor"
        },
        "value": [
          1626510366.389,
          "1"
        ]
      },
      {
        "metric": {
          "__name__": "up",
          "instance": "node-exporter:9100",
          "job": "node-exporter"
        },
        "value": [
          1626510366.389,
          "1"
        ]
      }
    ]
  }
}
```

`up` metriği bir gauge. Prometheus metrikleri herhangi bir ondalık değer
olabilir ama bu metrik yalnızca ikisini kullanıyor: `1` hedefin ayakta
olduğunu ve veri toplandığını, `0` ise hedefin kapalı olduğunu ve veri
toplanamadığını gösteriyor.
 
</details><br/>

API yanıtı her metrik için zaman damgasını, `instance` ve `job` etiketleriyle
birlikte gösteriyor. Metrik adı da aslında bir etiket olarak saklanıyor:
`__name__`.

## Lab

Bazen güncel metrik değerini görmek istersiniz, ama genellikle zaman içinde
değişen değerleri görmek isteriz.

API'yi kullanarak `fulfilment_in_flight_total` metriğinin son bir saatlik
değerlerini sorgulayın.

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
## Temizlik

Bu lab'ın container'larını kaldırın:

```
docker compose -f labs/prometheus/prometheus.yml down
docker compose -f labs/prometheus/apps.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
