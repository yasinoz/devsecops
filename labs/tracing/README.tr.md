---
title: Dağıtık İzleme
lang: tr
slug: tracing
section: observability
order: 6
duration: 45
requires: [docker]
status: updated
upstream: labs/tracing
---
# Uygulama İzleri

İzleme (tracing), gözlemlenebilirliğin üçüncü ayağı — metrikler genel sağlığı
gösterir, loglar ayrıntıya inmenizi sağlar, izler ise bileşenler arasındaki
iletişimi anlamanıza yardım eder.

Bunun için uygulama bileşenlerinizin iz verisi yayması ve alması gerekiyor;
böylece bir toplayıcı tüm izleri saklayıp aynı istemci işlemine ait çağrıları
birbiriyle ilişkilendirebiliyor.

## Kaynaklar

- [OpenTelemetry belirtimi](https://opentelemetry.io/docs/specs/otel/overview/) —
  bu lablar yazıldığında yükselen standarttı; artık *the* standart ve mezun
  olmuş bir CNCF projesi

- [Trace Context](https://www.w3.org/TR/trace-context/) — iz ayrıntılarını HTTP
  başlıklarında taşımak için W3C standardı

## İz yayınlamak

Yeni bir demo uygulamamız var — (uydurma) döküman işleme çözümünün parçası olan
çok basit bir web arayüzü:

- [web.yml](./web.yml) — web uygulamasını tanımlıyor; bir Docker ağına bağlı ve
  8070 portunu yayınlıyor

Uygulamayı çalıştırıp logları kontrol ederek başlayın:

```
docker compose -f labs/tracing/web.yml up -d

docker compose -f labs/tracing/web.yml logs -f fulfilment-web
```

> Bu komut logları takip ediyor; biz uygulamayı kullanırken çalışır halde
> bırakabilirsiniz

http://localhost:8070 adresinden siteyi açın. Görünüşte pek bir şey yok, ama
ihtiyacımız olan tüm iz ayrıntılarını yayan
[OpenTelemetry ölçümleme](https://opentelemetry.io/docs/concepts/instrumentation/)
desteğiyle kurulmuş.

Loglarda şuna benzer bir kayıt göreceksiniz:

```
Activity.Id:          00-1cdb0fc1ee7a91448072c6d391106dd9-ab272d7266d63e46-01
Activity.ActivitySourceName: OpenTelemetry.Instrumentation.AspNetCore
Activity.DisplayName: /
Activity.Kind:        Server
Activity.StartTime:   2021-07-16T08:31:17.1688367Z
Activity.Duration:    00:00.2235717
Activity.TagObjects:
    http.host: localhost:8070
    http.method: GET
    http.path: /
    http.url: http://localhost:8070/
    http.user_agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0
    http.status_code: 200
    otel.status_code: UNSET
Resource associated with Activity:
    service.name: Fulfilment.Web
    service.instance.id: 4b8a603f-34d3-4611-b01c-9e9c35932170
```

> Bu uygulama .NET istemci kütüphanesini kullanıyor. Kütüphane OpenTelemetry
> standartlarını kullanıyor ama kendi adlandırma geleneği var — OpenTelemetry'nin
> _span_ dediği şeye _activity_ diyor.

📋 Bu activity neyi temsil ediyor ve hakkında hangi ayrıntılar kaydediliyor?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Bu activity, web sunucusuna yapılan bir çağrıyı temsil ediyor.

Her durumda span'i (activity'yi) tanımlayan bir ID var; yanında işin türü,
başlangıç zamanı ve süre bulunuyor.

Span hakkındaki önemli ayrıntıları saklamak için etiketler kullanılıyor —
bunlar sunucu çağrıları olduğu için HTTP metodu, URL yolu, yanıt kodu vb.
kaydediliyor.

</details><br/>

Span'de, sunucuda hangi çağrının yapıldığını, ne zaman başlatıldığını, ne kadar
sürdüğünü ve yanıt durumunun ne olduğunu anlamaya yetecek kadar bilgi var.

Tüm uygulama bileşenleriniz böyle loglar yayınladığında, bir işlemdeki tüm ağ
çağrılarını gösteren dağıtık bir iz kurabilirsiniz.

Web sayfasındaki _Go_ düğmesine basın; birkaç saniye sonra
`Documents service unavailable!` hata mesajını göreceksiniz.

📋 Sorunun ne olduğunu görmek için iz loglarını kontrol edin.

<details>
  <summary>Biraz yardım lazım mı?</summary>

Loglardaki hata mesajlarının yukarısına kaydırın; şuna benzer bir iz
göreceksiniz:

```
Activity.DisplayName: HTTP GET
Activity.Kind:        Client
Activity.StartTime:   2021-07-19T15:13:36.1289362Z
Activity.Duration:    00:00:10.0518450
Activity.TagObjects:
    http.method: GET
    http.host: fulfilment-api
    http.url: http://fulfilment-api/documents
    otel.status_code: ERROR
    otel.status_description: Resource temporarily unavailable
```

Bu bir client activity'si; yani span, web bileşeninin başka bir bileşene HTTP
çağrısı yapmasının ayrıntılarını kaydediyor. Etiketler, web uygulamasının
`http://fulfilment-api/documents` adresini çağırmaya çalıştığını ama yanıtın
hata olduğunu söylüyor.

</details><br/>

Tek bir bileşenle bile iz logları faydalı. Kullanıcının gördüğü hatadan
doğrudan "sitede sorun var, fulfilment API sunucusuna erişemiyor" bilgisine
gidebiliyoruz.

Birden fazla bileşen iz yayınladığında durum daha güçlü hale geliyor, çünkü
loglar tüm ağ çağrılarını birbirine bağlamanıza yardım ediyor.

## Bağlam taşıma (context propagation)

HTTP çağrıları istemci isteğinde ve sunucu yanıtında başlıklar içeriyor.
_Context propagation_, başlıklara değer koyarak iz ayrıntılarını HTTP
çağrılarında taşıma işlemidir.

İstemci, iz ID'si gibi ayrıntıları HTTP istek başlıklarına ekliyor. Sunucu
kendi adına HTTP çağrısı yapıyorsa, aldığı HTTP başlıklarını giden tüm
isteklere kopyalayarak iz bilgisini taşıyor.

Bileşenler arası izlemeyi görebilmek için döküman fulfilment API sunucusunu
başlatın:

- [api.yml](./api.yml) — API container'ını, izlemeyi etkinleştiren bir bayrakla
  tanımlıyor; web container'ıyla aynı ağa bağlanıyor ve 8071 portunu
  yayınlıyor.

> Java uygulaması OpenTracing API'sini kullanıyor; o API arşivlendi ve
> OpenTelemetry'ye dahil edildi. Ortam değişkeninin adı bu geçmişi yansıtıyor;
> yaptığı iz taşıma ise hâlâ aynı W3C standardı.

API container'ını çalıştırıp loglarını kontrol edin:

```
docker compose -f labs/tracing/api.yml up -d

docker compose -f labs/tracing/api.yml logs -f fulfilment-api
```

> Bu bir Java Spring Boot uygulaması. Bol miktarda açılış logu göreceksiniz.

Uygulama kökünü http://localhost:8071/documents adresinde açın — bu, sitenin
kullandığı döküman listesi.

📋 Bu loglarda hangi span bilgisini görüyorsunuz?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Bu uygulama tüm iz ayrıntılarını loglara yazdırmıyor, ama orada ilginç bir
miktar bilgi var.

Son loglarda şuna benzer satırlar olacak:

```
2021-07-19 15:27:52.048 DEBUG 1 --- [p-nio-80-exec-3] fulfilment.api.DocumentsController       : ** GET /documents called in trace id: ab5e7e2261cfc919, with baggage: null
...
2021-07-19 15:27:52.095  INFO 1 --- [p-nio-80-exec-3] i.j.internal.reporters.LoggingReporter   : Span reported: ab5e7e2261cfc919:ab5e7e2261cfc919:0:1 - get
```

İlk log bir iz ID'si yazdırıyor, son log ise bir span'in raporlandığını
söylüyor.

</details><br/>

Span'in ID'si, iz ID'si ile başlıyor; bu HTTP çağrısının aynı ilk istemci
isteğinin parçası olan diğerleriyle böyle ilişkilendiriliyor.

http://localhost:8070/ adresindeki web uygulamasına dönüp _Go_ düğmesine
basın.

Artık web uygulaması API'ye erişebiliyor ve döküman API'si için yeni bir log
kümesi göreceksiniz; yeni bir span ID'si kaydedilmiş olacak. Son log şuna
benzer olacak:

```
2021-07-19 15:38:15.431  INFO 1 --- [p-nio-80-exec-5] i.j.internal.reporters.LoggingReporter   : Span reported: 17d93024304cd248919240491e832317:f9689b5465ee1877:a4e1100c185c5340:1 - get
```

Span ID'si yine bir iz ID'si ile başlıyor, ama o ID'nin biçimi `/documents`
URL'sini doğrudan tarayıcınızdan çağırdığınız zamandan farklı

📋 Yeni iz ID'si nereden geldi?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Bu kez ilk istemci çağrısı API değildi — zincirdeki ilk çağrı site, API ise
sonraki.

API logunuzdaki iz ID'sini bulmak için web container'ının iz loglarını
kontrol edin:

```
# API loglarindan cikmak icin Ctrl-C

docker compose -f labs/tracing/web.yml logs fulfilment-web
```

Web uygulamasının API'yi çağırdığı client izine kadar yukarı kaydırın; şuna
benzer bir kayıt göreceksiniz:

```
Activity.Id:          00-17d93024304cd248919240491e832317-a4e1100c185c5340-01
Activity.ParentId:    00-17d93024304cd248919240491e832317-a4ff2ebe2e663c4c-01
Activity.ActivitySourceName: OpenTelemetry.Instrumentation.Http
Activity.DisplayName: HTTP GET
Activity.Kind:        Client
Activity.StartTime:   2021-07-19T15:38:15.4166205Z
Activity.Duration:    00:00.0174145
Activity.TagObjects:
    http.method: GET
    http.host: fulfilment-api
    http.url: http://fulfilment-api/documents
    http.status_code: 200
```

Bu kez API çağrısı başarılı oldu ve activity ID'sinin iz ID'si bileşeni API
loglarındakiyle eşleşiyor; bu örnekte `17d93024304cd248919240491e832317`.

</details><br/>

Web uygulamasının son log kaydına bakarsanız, activity (span) ID'sinde aynı iz
ID'sinin bulunduğunu göreceksiniz. Span'ler yalnızca tamamlandıklarında
loglanıyor, bu yüzden onları ters sırada görüyorsunuz. Gerçek çağrı zinciri
span'lerden kurulabilir:

1. kullanıcı siteye bir POST isteği yapıyor; bu bir server span'i ve zincirdeki
   ilk olduğu için parent ID'si yok, dolayısıyla bir iz ID'si üretiyor

2. site API'ye bir client çağrısı yapıyor; bu span, 1 numaralı span'in ID'sini
   parent ID olarak kullanıyor ve iz ID'sini kendi span ID'sinde koruyor

3. API bir span logluyor. Loglarda çok ayrıntı yok ama bu da bir server
   span'i; 2 numaralı span'in ID'sini parent olarak kullanacak ve 1
   numaradaki iz ID'sini kendi span ID'sinde koruyacak.

En basit seviyede dağıtık izleme, bileşenlerinizin yaptıkları ve aldıkları tüm
HTTP çağrılarının ayrıntılarını kaydetmesidir — _span_'ler. Bileşenler,
çağrıların aynı işleme ait olduğunu belirlemek için HTTP başlığındaki bir
ID'yi kullanır — _trace_ (iz).

## Lab

Web uygulaması OpenTelemetry destekliyor; dolayısıyla OpenTelemetry kullanan
başka bir bileşen tarafından çağrılırsa, kendi ID'sini üretmek yerine o
çağrıdan aldığı iz ID'sini taşıması gerekiyor.

Web uygulamasını tarayıcı dışından çağırmak için curl kullanabilirsiniz.

_Windows kullanıyorsanız doğru curl komutunu kullanmak için şu script'i
çalıştırın:_

```
# once script'lere izin verin:
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# sonra calistirin:
. ./scripts/windows-tools.ps1
```

Sonra siteyi çağırın:

```
curl localhost:8070/index?all
```

curl çağrısına bir iz ID'si ekleyip, sizin ID'nizin web uygulaması ve API'nin
span'lerinde kullanıldığını doğrulayın.

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
## Temizlik

Bu lab'ın container'larını kaldırın:

```
docker compose -f labs/tracing/web.yml down
docker compose -f labs/tracing/api.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
