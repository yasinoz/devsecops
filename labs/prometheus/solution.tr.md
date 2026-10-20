# Lab Çözümü

Aralık sorgularının URL sorgu dizesinde `start`, `end` ve `step`
parametrelerini içermesi gerekiyor.

Şu örnek çalışır ama hiç veri döndürmez — çünkü bu tarihler için kayıtlı
metriğiniz olmayacak:

```
curl 'localhost:9090/api/v1/query_range?query=fulfilment_in_flight_total&start=2021-07-11T00:01:30Z&end=2021-07-11T01:00:00Z&step=15s'
```

Şunu göreceksiniz:

```
{"status":"success","data":{"resultType":"matrix","result":[]}}
```

Başlangıç ve bitiş değeri olarak
[RFC 3339](https://datatracker.ietf.org/doc/html/rfc3339) tarihi ya da Unix
zaman damgası kullanabilirsiniz.

PowerShell'de güncel tarihi ve bir saat öncesini şöyle değişkenlere
kaydedebilirsiniz:

```
$now=Get-Date
$end=(Get-Date -Date $now -UFormat %s)
$start=(Get-Date -Date $now.AddHours(-1) -UFormat %s)
```

VEYA Linux/macOS'ta:

```
now=$(date)
end=$(date -d $now +%s)
start="$(date -d "$now - 1 hours" +%s)"
```

Sonra URL'de bu değişkenleri kullanarak API'yi sorgulayın — bu hem PowerShell
hem Bash için çalışır:

```
curl "localhost:9090/api/v1/query_range?query=fulfilment_in_flight_total&start=$start&end=$end&step=30s"
```

___
> [Alıştırmalara](README.tr.md) dönün.
