# Lab Çözümü

## Logları toplu yüklemek

Index'in `_bulk` uç noktasına bir POST isteği yapın:

```
curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_bulk' --data-binary '@data/logs.json'
```

## Başarılı istek sayısı

Başarılı isteklerin log mesajı `Fulfilment completed` ifadesini içeriyor.

Yalnızca `completed` kelimesine göre eşleştirebilirsiniz, çünkü başka hiçbir
log kaydında kullanılmıyor:

- [match-completed.json](./lab/queries/match-completed.json) — sorguyu
  gösteriyor
- sorgu sonuçlarını dökümanların kendisi olmadan görmek için isteğe `size=0`
  ekleyin

```
curl -H 'Content-Type: application/json' 'localhost:9200/logs/_search?size=0&pretty' --data-binary '@labs/elasticsearch/lab/queries/match-completed.json'
```

> 30 eşleşme var (`hits.total.value` alanında)

## Döküman servisi sorunu olmayan tek hatanın istek ID'si

Error seviyesindeki logların çoğu `document service unavailable` ifadesini
içeren bir mesaja sahip:

- [match-error.json](./lab/queries/match-error.json) — seviyenin error olduğu
  ve mesajın döküman servisi ifadesini içermemesi gereken bir boolean sorgu
  kullanıyor

```
curl -H 'Content-Type: application/json' http://localhost:9200/logs/_search?pretty --data-binary '@labs/elasticsearch/lab/queries/match-error.json'
```

> İstek ID'si 32441751.


___
> [Alıştırmalara](README.tr.md) dönün.
