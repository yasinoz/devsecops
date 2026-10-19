---
title: Jaeger ile İzleri Görselleştirmek
lang: tr
slug: jaeger
section: observability
order: 7
duration: 35
requires: [docker]
status: needs-review
upstream: labs/jaeger
---
# Jaeger Çalıştırmak

[Jaeger](https://www.jaegertracing.io) bir dağıtık izleme sistemi — izleri
toplayıp saklıyor ve onları bulup görselleştirmeniz için bir web arayüzü
veriyor. Jaeger başlangıçta kendi veri biçimini kullanıyordu, ama
OpenTelemetry'yi de destekliyor — ve Jaeger 2 doğrudan OpenTelemetry
Collector *üzerine* kurulu.

Jaeger'ı üretim yapılandırmasında, farklı özellikler farklı süreçlerde
çalışacak şekilde çalıştırabilirsiniz; veri deposunu değiştirebilir veya
toplamayı tamponlamak için bir mesaj kuyruğu ekleyebilirsiniz.

## Kaynaklar

- [Jaeger mimarisi](https://www.jaegertracing.io/docs/latest/architecture/) —
  OpenTelemetry terminolojisiyle eşleme

- [Jaeger'a başlangıç](https://www.jaegertracing.io/docs/latest/getting-started/)

- [Uygulamaları OpenTelemetry ile ölçümlemek](https://opentelemetry.io/docs/concepts/instrumentation/) —
  Jaeger tarafından toplanabilir

## Jaeger'ı çalıştırmak

Jaeger'ı basit bir yapılandırmayla, tüm bileşenleri tek bir Docker
container'ında çalışacak şekilde çalıştıracağız:

- [jaeger.yml](./jaeger.yml) — bir tracing ağına bağlı ve varsayılan web
  arayüzü portu olan 16686'yı yayınlayan bir Jaeger container'ı tanımlıyor

Jaeger'ı çalıştırın:

```
docker compose -f labs/jaeger/jaeger.yml up -d
```

Jaeger arayüzünü http://localhost:16686 adresinde açıp üstteki _Search_
menüsüne basın. İzleri burada buluyorsunuz: _Service_ açılır listesi Jaeger'a
span göndermiş her servisi, _Operation_ açılır listesi ise onların içindeki
adlandırılmış işlemleri listeliyor.

Şu anda liste boş, çünkü Jaeger'a henüz hiçbir şey span göndermedi.

> Bu lab'ın eski sürümü buraya Jaeger'ın kendi `jaeger-query` izlerine bakarak
> başlıyordu — Jaeger 1 kendini izliyordu. Jaeger 2 kendi izlemesini
> bağlamıyor (dağıttığı yapılandırmada tam olarak bunun için bir TODO var),
> dolayısıyla ona gerçek span göndermeden bakacak bir şey yok. Sırada bunu
> yapacağız.

Jaeger span'leri birkaç farklı biçimde kabul ediyor. Varsayılan
yapılandırması OTLP (OpenTelemetry protokolü), eski Jaeger protokolleri ve
Zipkin için alıcıları açık tutuyor — yani bunlardan herhangi biriyle
ölçümlenmiş uygulamalar ek yapılandırma gerekmeden ona rapor edebiliyor.

## Jaeger'a iz göndermek

Kullanacağımız demo uygulamasının, hepsi OpenTelemetry ile dağıtık izleme
kurulmuş üç bileşeni var:

- [apps.yml](./apps.yml) — web uygulaması, döküman servisi API'si ve bir
  yetkilendirme servisi API'si için container'ları tanımlıyor. Hepsi iz
  span'lerini Jaeger container'ına gönderecek şekilde yapılandırılmış.

Uygulama container'larını çalıştırın:

```
docker compose -f labs/jaeger/apps.yml up -d
```

Web arayüzünün ana sayfasını http://localhost:8070 adresinde açın, sonra
http://localhost:16686/search adresindeki Jaeger aramanızı yenileyin.

> Servis listesinde artık `Fulfilment.Web` görmelisiniz.

📋 Web uygulamasına yapılan ana sayfa isteğinin izini açın. Bu izde kaç span
var?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Arama arayüzünde _Service_ alanını `Fulfilment.Web`, _Operation_ alanını `/`
yapın. _Find Traces_ tıklayın ve tek bir sonuç görmelisiniz.

O izi açıp ayrıntıları genişletin. Yalnızca bir span var: tarayıcı isteğinize
verilen sunucu yanıtı.

</details><br/>

İzler, Jaeger'ın topladığı span'lerden derleniyor. Hangi servisten ne
beklendiğine dair önceden bir bilgi yok; her şey Jaeger'a ulaşan span'lerden
geriye dönük kuruluyor.

Tek span'li bir iz tamamen geçerli — çağrı zincirinde başka HTTP isteği
olmadığı anlamına geliyor.

Şimdi [döküman listesi sayfasına](http://localhost:8070/) dönüp, kullanıcı
alanı için varsayılan değeri kullanarak _Go_ düğmesine basın.

📋 Yeni isteğinizin izini bulun. Bunda daha fazla span var mı?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Jaeger aramasında çok daha fazla servis göreceksiniz. Hâlâ `Fulfilment.Web`
istiyoruz ama hangi işlemi istediğiniz her zaman belli olmuyor; bu yüzden
operation için _all_ seçip _Find Traces_ tıklayabilirsiniz.

İstediğiniz iz, birden fazla servisten birden fazla span ile listelenmiş olan.

</details><br/>

İzi açıp ayrıntıları genişletin; uygulamalarınıza izleme eklemenin gerçek
değerini göreceksiniz:

![Birden fazla servisten span içeren iz zaman çizelgesi](../../img/jaeger-web-trace.png)

Üstteki grafik toplam iz süresini ve onun içinde her span'in süresini
gösteriyor. Bu örnekte tüm istek 1.01 saniye sürmüş ve web uygulamasının iki
ardışık HTTP çağrısı yaptığını net biçimde görebiliyorsunuz.

Grafiğin altında her span'in ayrıntıları var; etiketleri ve ek bilgileri
görmek için genişletebilirsiniz.

Etiketler, ek ayrıntı kaydetmek için span'lerinize koyduğunuz anahtar-değer
çiftleri. Bazıları gelenekseldir ve bileşenler arasında ortak görürsünüz
(`http.method`, `http.status_code`, `span.kind`), ama koleksiyon serbest —
faydalı olan her şeyi ekleyebilirsiniz.

İz zaman çizelgesi en faydalı görünüm, ama sağ üstteki açılır listeden
diğerlerine geçebilirsiniz:

- _Trace Statistics_ — span'ler hakkında düşük seviyeli zamanlama ayrıntıları
- _Trace JSON_ — tam ham veri

📋 Döküman listesini aldığınızda çağrı izi nasıl — ve çağrının hangi kısmı en
çok zaman alıyor?

<details>
  <summary>Biraz yardım lazım mı?</summary>

Tüm span'leri genişletin ve bol ayrıntı göreceksiniz:

- web uygulaması, kullanıcının düğmeye basmasıyla bir POST isteği alıyor
    - bu en üstteki span; istemciye verilen sunucu yanıtı

- web uygulaması yetkilendirme servisini çağırıyor
    - burada iki span var çünkü iki bileşen de iz yakalıyor — web
      uygulamasından gelen client çağrısı ve yetkilendirme servisinden gelen
      sunucu yanıtı

- yetkilendirme servisi harici bir web adresini çağırıyor (aslında bir blog)
    - burada tek span var, yetkilendirme servisinin client çağrısı; çünkü blog
      sunucusundan iz ayrıntısı alamıyoruz

- web uygulaması döküman servisini çağırıyor
    - burada da iki span var, iki bileşen de iz span'i kaydediyor: web
      sunucusundan client çağrısı ve API sunucusundan server çağrısı

Zincirdeki en uzun çağrı, https://blog.sixeyed.com adresine yapılan harici
istek.

</details><br/>

Uygulama bileşenleri, gelen ve giden HTTP çağrıları için iz span'leri kaydedip
göndermek üzere OpenTelemetry kütüphanelerini kullanıyor. Farklı teknolojiler
kullanıyorlar (ASP.NET ve Spring Boot) ama iz biçimi aynı olduğu için Jaeger
tüm span'leri doğru ize derleyebiliyor.

Uygulamaların hiçbirinde iz toplamak ve göndermek için fazladan koda ihtiyaç
olmadı; yalnızca ölçümleme kütüphanesi bağlandı:

- .NET uygulamasında bu,
  [Tracing](https://github.com/courselabs/fulfilment/blob/main/src/fulfilment-frontend/Fulfilment.Core/Services/Tracing.cs#L11)
  sınıfındaki `AddTracing` uzantı metodunda yapılıyor

- Spring Boot uygulamasında kod olmadan,
  [pom.xml](https://github.com/courselabs/fulfilment/blob/main/src/fulfilment-api/pom.xml#L42)
  dosyasında referans verilen `opentracing-spring-jaeger-web-starter` paketi
  kullanılarak yapılıyor

## Lab

Dağıtık izleme, aşina olmadığınız bir uygulamadaki özelliklerin iç yapısını
keşfetmek için harika.

Web uygulamasındaki [Submit document](http://localhost:8070/Submit) sayfasını
açın ve sayfadaki varsayılan alan değerleriyle _Go_ tıklayın.

Döküman gönderme işleminin çağrı yığınını çizmek için Jaeger'ı kullanın;
dökümanı aslında hangi sınıfın hangi metodu oluşturuyor?

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
## Temizlik

Bu lab'ın container'larını kaldırın:

```
docker compose -f labs/jaeger/jaeger.yml down
docker compose -f labs/jaeger/apps.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
