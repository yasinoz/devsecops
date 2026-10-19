# Lab Çözümü

`traceparent` başlığının biçimi oldukça karmaşık ve geçersiz bir ID
kullanırsanız taşınmıyor.

[W3C belirtiminde geçerli ID'ler içeren örnek başlıklar](https://www.w3.org/TR/trace-context-1/#examples-of-http-traceparent-headers)
var, onlardan birini kullanabilirsiniz:

```
curl -H "traceparent: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01" localhost:8070/index?all
```

> Döküman ID'lerini içeren bir HTML yanıtı göreceksiniz — web uygulamasının
> döküman API'sini çağırması için doğru URL'yi kullandığınızdan emin olun.

Web uygulamasının loglarını kontrol edin:

```
docker compose -f labs/tracing/web.yml logs fulfilment-web -n 22
```

Şuna benzer bir son log göreceksiniz; bu, curl çağrısının server span'i:

```
Activity.Id:          00-0af7651916cd43dd8448eb211c80319c-6f70aaf42a3e1842-01
Activity.ParentId:    00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01
Activity.ActivitySourceName: OpenTelemetry.Instrumentation.AspNetCore
Activity.DisplayName: Index
Activity.Kind:        Server
Activity.StartTime:   2021-07-19T16:02:30.7422710Z
Activity.Duration:    00:00.0193704
Activity.TagObjects:
    http.host: localhost:8070
    http.method: GET
    http.path: /index
    http.url: http://localhost:8070/index?all
    http.user_agent: curl/7.55.1
    http.route: Index
    http.status_code: 200
```

> İz ID'si `Activity.ParentId` alanında görünüyor. Bu, zincirdeki ilk çağrı ve
> biz bir iz ID'si verdiğimiz için web uygulaması onu parent olarak kullanıyor.

Span ID'si `00-0af7651916cd43dd8448eb211c80319c` ile başlıyor; bu da iz ID'si.

API loglarını kontrol edin:

```
docker compose -f labs/tracing/api.yml logs fulfilment-api -n 1
```

Şuna benzer bir son log kaydı göreceksiniz:

```
2021-07-19 16:02:30.754  INFO 1 --- [p-nio-80-exec-7] i.j.internal.reporters.LoggingReporter   : Span reported: af7651916cd43dd8448eb211c80319c:9ee709025ddee655:2f0d964815ca6846:1 - get
```

Span'in ID'si, curl başlığında verdiğimiz iz ID'siyle başlıyor (başındaki
`00-` hariç; o, iz biçiminin sürüm numarası).

___
> [Alıştırmalara](README.tr.md) dönün.
