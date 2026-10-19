# Lab Çözümü

Histogram metriği `fulfilment_processing_seconds`.

Döküman işleme süreleri hakkında (uydurma) veri kaydediyor:

```
# HELP fulfilment_processing_seconds Fulfilment processing duration
# TYPE fulfilment_processing_seconds histogram
fulfilment_processing_seconds_sum 202315
fulfilment_processing_seconds_count 31131
fulfilment_processing_seconds_bucket{le="0"} 0
fulfilment_processing_seconds_bucket{le="2"} 3049
fulfilment_processing_seconds_bucket{le="4"} 9270
fulfilment_processing_seconds_bucket{le="6"} 15623
fulfilment_processing_seconds_bucket{le="8"} 21837
fulfilment_processing_seconds_bucket{le="10"} 28067
fulfilment_processing_seconds_bucket{le="12"} 31131
fulfilment_processing_seconds_bucket{le="+Inf"} 31131
```

Histogramlar birden fazla metriği kova (bucket) halinde gruplayarak kaydeder.
Bu örnekte her kova, farklı zaman aralıklarında işlenen döküman sayısını
tutuyor:

| _x_ saniye içinde | Döküman sayısı |
|-|-|
| 2 | 3049|
| 6 | 15623|

Kovalar kümülatiftir, dolayısıyla hesaplamalarda kullanılabilirler:

```
fulfilment_processing_seconds_bucket{le="4"} 9270
fulfilment_processing_seconds_bucket{le="6"} 15623
```

=> işlenmesi 4 ile 6 saniye arasında süren döküman sayısı = 15623-9270 = 6353

Bir histogramda yüzdelik dilim (percentile) hesaplamaya yetecek kadar bilgi
var; örneğin isteklerin %95'i _y_ saniye içinde işlendi.

___
> [Alıştırmalara](README.tr.md) dönün.
