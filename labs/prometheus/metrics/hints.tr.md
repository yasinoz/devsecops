# Lab İpuçları

Döküman işleyicinin metrikleri http://localhost:9110/metrics adresinde.

Her metriğin, `#` ile başlayan bir miktar dökümantasyonu var:

```
# HELP process_num_threads Total number of threads
# TYPE process_num_threads gauge
process_num_threads 16
```

`HELP` metni metrik hakkında temel bilgi veriyor. Histogramı bulmak için
`TYPE` satırlarında arama yapabilirsiniz.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
