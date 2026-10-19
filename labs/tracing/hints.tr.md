# Lab İpuçları

curl ile şu biçimde bir istek başlığı ekleyebilirsiniz:

```
curl -H "<baslik-adi>: <baslik-degeri>" <url>
```

İz başlıklarını taşımak için farklı standartlar var, ama en yaygın biçim — bu
uygulamaların da kullandığı —
[W3C `traceparent`](https://www.w3.org/TR/trace-context-1/#traceparent-header).

O başlığa geçerli bir ID koyarsanız, her iki container'ın loglarında da
kullanıldığını görmelisiniz.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
