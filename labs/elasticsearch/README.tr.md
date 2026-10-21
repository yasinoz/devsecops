---
title: Logları Elasticsearch'te Saklamak
lang: tr
slug: elasticsearch
section: observability
order: 4
duration: 45
requires: [docker]
status: updated
upstream: labs/elasticsearch
---
# Elasticsearch Çalıştırmak

Elasticsearch bir döküman veritabanı — veri biçimi olarak JSON kullanıyor.
Dökümanlar *index* adı verilen koleksiyonlarda saklanıyor ve veri şeması esnek;
yani bir index'teki tüm dökümanların aynı alanlara sahip olması gerekmiyor.

Elasticsearch'ü genel amaçlı bir veri deposu olarak kullanabilirsiniz, ama
özellikle log saklamaya çok uygun; çünkü size bol miktarda ileri düzey sorgu
özelliği sunuyor.

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

- [Index API](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices.html)
  ve [Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
  dökümantasyonu — veri saklamak için
- [Search API dökümantasyonu](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) — veri sorgulamak için
- [Query DSL](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl.html) — veri sorgulama dili


## Elasticsearch'ü çalıştırmak

Elasticsearch bir Java uygulaması. Lisans tarafı hareketli oldu: Elastic 7.10
sonrasında Apache 2.0'dan ayrıldı, sonra 2024'te SSPL ve Elastic License'ın
yanına seçenek olarak AGPL v3'ü ekledi — yani kaynak kod yeniden OSI onaylı
açık kaynak. Biz Elastic'in kendi registry'sindeki resmi imajı kullanıyoruz.

[compose.yml](./compose.yml), Elasticsearch'ü container içinde çalışacak
şekilde kuruyor ve HTTP API'sinin varsayılan portu olan 9200'ü yayınlıyor.

Container'ı başlatın:

```
docker compose -f labs/elasticsearch/compose.yml up -d
```

Logları kontrol edin; Elasticsearch'ün açıldığını göreceksiniz:

```
docker compose -f labs/elasticsearch/compose.yml logs elasticsearch
```

> Bu lab'ın eski sürümü `docker logs <proje>_<servis>_1` kullanıyordu.
> Compose v2 container adlarını alt çizgi değil tire ile üretiyor, dolayısıyla
> o komut _no such container_ hatası veriyor. Logları Compose'dan servis adıyla
> istemek, üretilen container adı ne olursa olsun çalışıyor.

> Bunlar yarı yapılandırılmış loglar


HTTP istekleri yapmak için curl kullanacağız — Windows kullanıyorsanız doğru
curl sürümünü kullanmak için şu script'i çalıştırın:

```
# yalnizca Windows - script'lere izin verin:
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process

# sonra calistirin:
. ./scripts/windows-tools.ps1
```

Şimdi Elasticsearch API'sine basit bir çağrı yapın:

```
curl localhost:9200
```

📋 API yanıtında birkaç temel bilgi var. Hangi sürümü çalıştırıyoruz ve küme
adı ne?

<details>
  <summary>Biraz yardım lazım mı?</summary>

API yanıtı şuna benziyor:

```
{
  "name" : "68d8e3d046c4",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "9yypBMAjRNC0hjMkr-FrEw",
  "version" : {
    "number" : "9.5.5",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "...",
    "build_date" : "...",
    "build_snapshot" : false,
    "lucene_version" : "...",
    "minimum_wire_compatibility_version" : "8.19.0",
    "minimum_index_compatibility_version" : "8.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

Sürüm, Compose dosyasındaki imaj etiketinden geliyor — `9.5.5`. Küme adı
`docker-cluster`; bu, siz bir ad vermediğinizde resmi imajın kullandığı
varsayılan.

</details><br/>

Elasticsearch API'si, kümeyi yönetmek ve dökümanlarla çalışmak için eksiksiz
bir özellik kümesine sahip.

## Döküman index'lemek

Index'leme, Elasticsearch'te veri saklama biçimidir. Başlıca dillerin tamamı
için
[istemci kütüphaneleri](https://www.elastic.co/guide/en/elasticsearch/client/community/current/index.html)
var; yani Elasticsearch'ü uygulamanızla entegre edebilirsiniz.

Bu alıştırmalarda REST API'yi kullanacağız — yeni bir index'e bir döküman
ekleyerek başlayın:

- [fulfilment-requested.json](data/fulfilment-requested.json) — kaynak veri;
  demo fulfilment uygulamasının döküman işleyici loglarının basitleştirilmiş
  bir sürümü

Dökümanı bir HTTP POST isteğiyle index'leyin:

```
curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-requested.json"
```

Çıktı, dökümanı geri almak için kullanabileceğiniz bir ID içeriyor.

📋 Index'in adı ve döküman ID'si ne?

<details>
  <summary>Biraz yardım lazım mı?</summary>

API yanıtı şuna benziyor:

```
{
   "_index":"logs",
   "_id":"ZODwunoBUFcX3q_Yl3rW",
   "_version":1,
   "result":"created",
   "_shards":{
      "total":2,
      "successful":1,
      "failed":0
   },
   "_seq_no":0,
   "_primary_term":1
}
```

Index adı `logs` — index'leri önceden oluşturmanız gerekmiyor, döküman
eklemeye çalıştığınızda Elasticsearch onları oluşturuyor.

> Daha eski Elasticsearch kullandıysanız bu yanıtta bir `_type` alanı
> hatırlıyor olabilirsiniz. Mapping tipleri Elasticsearch 8'de kaldırıldı.

Döküman ID'sini Elasticsearch üretti, çünkü istekte bir ID belirtmedik. Bu
örnekte `ZODwunoBUFcX3q_Yl3rW`.

</details><br/>

Dökümanı bir HTTP GET isteğiyle geri alabilirsiniz — **URL'de kendi döküman
ID'nizi kullanmanız gerekiyor**:

```
curl localhost:9200/logs/_doc/<_id>?pretty
```

> `?pretty` bayrağı yanıtı okunması kolay olacak şekilde biçimlendiriyor.

Bu yapılandırılmış veri — log seviyesi, zaman damgası ve mesaj verisi ayrı
alanlarda saklanıyor.

📋 `labs/elasticsearch/data/fulfilment-completed.json` ve
`labs/elasticsearch/data/fulfilment-errored.json` dosyalarındaki iki dökümanı
daha index'leyerek log ekleyin.

<details>
  <summary>Biraz yardım lazım mı?</summary>

POST istekleri aynı, yalnızca kaynak dosya yolu farklı:

```
curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-completed.json"

curl -H 'Content-Type: application/json' -XPOST 'localhost:9200/logs/_doc' --data-binary "@labs/elasticsearch/data/fulfilment-errored.json"
```

</details><br/>

Index'in tüm dökümanlara sahip olduğunu kontrol etmek için
[CAT (compact and aligned text)](https://www.elastic.co/guide/en/elasticsearch/reference/current/cat.html)
API'sini kullanabilirsiniz:

```
curl localhost:9200/_cat/indices?v=true
```

> Durumun güncellenmesi birkaç dakika sürebilir, ama `logs` index'i için
> `docs.count` kolonunda `3` değerini görmelisiniz.

Artık arayabileceğimiz bir miktar verimiz var.

## Temel arama

Elasticsearch'teki en basit arama, index API'sinin `_search` uç noktasını
çağırıp URL'nin sorgu dizesinde bir arama terimi geçirmektir.

`logs` index'indeki herhangi bir dökümanda `debug` kelimesini arayın:

```
curl 'localhost:9200/logs/_search?q=debug'
```

> Log seviyesi `DEBUG` olan tek bir döküman buluyor — arama büyük/küçük harfe
> duyarlı değil.

Bu temel arama tüm dökümanlardaki tüm alanlara bakıyor. Yanıt her döküman için
bir `score` içeriyor; bu, dökümanın arama terimiyle ne kadar iyi eşleştiğinin
hesabı.

Bir basit sorgu daha: arama teriminin önüne eksi (`-`) eklemek, terimi
içermeyen dökümanları buluyor:

```
curl 'localhost:9200/logs/_search?q=-debug&pretty'
```

> Diğer iki dökümanı buluyor, çünkü hiçbir alanlarında `debug` kelimesi yok.


Elasticsearch Query DSL'i kullanarak JSON içinde daha karmaşık sorgu ifadeleri
yazabilirsiniz. _match query_ kullanan birkaç örnek:

- [queries/match-all.json](queries/match-all.json) index'teki tüm dökümanlarla
  eşleşiyor

- [queries/match-id.json](queries/match-id.json) `message` alanında `21304897`
  terimini içeren tüm dökümanlarla eşleşiyor

- [queries/match-id-level.json](queries/match-id-level.json) `message` alanında
  `21304897` terimi VE `level` alanında `INFO` kelimesi olan tüm dökümanlarla
  eşleşiyor.

Query DSL'i yapılandırılmış veriyle kullanmak daha isabetli olmanızı sağlıyor.
Debug logları arıyorsanız log seviyesi alanına göre arayabilirsiniz; böylece
başka bir alanında "debug" kelimesi geçen dökümanları yanlışlıkla dahil
etmezsiniz.

JSON sorgularını arama API'sine GET isteği olarak, şu URL biçimiyle
gönderiyorsunuz:

```
localhost:9200/<index_name>/_search?pretty=true --data-binary "@<query_file_path>"
```

📋 `21304897` döküman istek ID'sine ait tüm logları, sonra da o istek ID'sinin
yalnızca info loglarını bulmak için sorgular çalıştırın.

<details>
  <summary>Biraz yardım lazım mı?</summary>

`queries` klasöründeki JSON dosyalarını kullanabilirsiniz.

O ID'ye ait tüm logları bulmak için:

```
curl -H 'Content-Type: application/json' localhost:9200/logs/_search?pretty=true --data-binary '@labs/elasticsearch/queries/match-id.json'
```

> İki eşleşme döndürüyor: biri info, biri debug logu.

O ID'nin yalnızca info loglarını bulmak için:

```
curl -H 'Content-Type: application/json' localhost:9200/logs/_search?pretty=true --data-binary '@labs/elasticsearch/queries/match-id-level.json'
```

> Tek bir eşleşme döndürüyor.

</details><br/>

Elasticsearch'te çok sayıda arama özelliği var, dolayısıyla Query DSL
oldukça karmaşık. Burada yalnızca bir giriş yaptık, ama Elasticsearch'ü yoğun
kullanacaksanız dönülmesi gereken bir konu.

## Lab

Index ve arama API'lerini biraz pratik etme zamanı. Index'e tek tek döküman
yüklediniz, ama toplu yüklemek çok daha hızlı.

[data/logs.json](../../data/logs.json) dosyasındaki tüm dökümanları toplu
index'leyerek başlayın (_data dizininin repo kökünde olduğuna dikkat edin_) —
bunun için farklı bir
[Document API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs.html)
kullanmanız gerekecek.

Sonra şunları bulmak için match sorguları yazın:

- kaç döküman isteği başarılı oldu?
- döküman servisiyle ilgili olmayan tek hatanın istek ID'si neydi?

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
<!-- troubleshooting:auto -->
## Takılırsanız

**`Cannot connect to the Docker daemon`** - Docker Desktop çalışmıyor.
Başlatın ve balina simgesi hareket etmeyi bırakana kadar bekleyin.

**`port is already allocated`** - önceki bir labdan kalan konteyner o portu
hâlâ tutuyor. `docker ps` ile neyin çalıştığına bakın, eskisini
`docker rm -f <ad>` ile kaldırın.

**`The container name "/..." is already in use`** - aynı sebep, aynı çözüm:
`docker rm -f <ad>` deyip komutu tekrar çalıştırın.

**Build sırasında `unable to prepare context: path ... not found`** - yanlış
dizindesiniz. Bu labdaki her komut deponun kök dizininde olduğunuzu varsayıyor.

**Çalışmak yerine kullanım metni basan `docker run`** - bu labdaki bazı
komutlar, yanlış argümanın nasıl göründüğünü göstermek için kasıtlı olarak
başarısız oluyor. Bozuk sanmadan önce komutun çevresindeki açıklamayı okuyun.

Hâlâ takılıysanız: aşağıdaki **Cleanup** bölümü her şeyi sıfırlıyor, labı
temiz bir makineyle baştan yapabilirsiniz.


## Temizlik

Bu lab'ın container'larını kaldırın:

```
docker compose -f labs/elasticsearch/compose.yml down
```

> Bu komut yalnızca bu lab'in baslattigi container'lari kaldırır. Tamamen
> temiz bir başlangıç istiyorsanız `docker ps` ile hâlâ çalışan varsa
> görebilirsiniz.
