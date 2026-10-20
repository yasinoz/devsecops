# Lab Çözümü

Lab klasöründe örnek bir çözüm var: `lab/uptime-dashboard.json`. Onu
**Dashboards > New > Import** üzerinden Grafana'ya yükleyebilirsiniz.

### Altyapı satırı

Üst menüden _Add_ tıklayıp _Row_ seçin.

Satır adının üzerine gelin, bir dişli simgesi çıkacak — ona tıklayıp satır
adını _Infrastructure_ yapın.

Orijinal durum tablonuzun üzerine gelin, panel menüsünü (üç nokta) açıp _Edit_
seçin.

PromQL'e bir etiket ekleyin:

```
sum without(job, tier) (up{tier="infrastructure"})
```

_Back_ tıklayın — aynısını zaman çizelgesi paneli için de yapın
(ikisi de aynı sorguyu kullanabilir).

### Backend satırı

_Backend_ için yeni bir satır ekleyin.

Durum tablosunun üzerine gelin, panel menüsünü (üç nokta) açıp
_More... > Duplicate_ seçin.

Yeni paneldeki etiket seçicisini şu PromQL'i kullanacak şekilde düzenleyin:

```
sum without(job, tier) (up{tier="backend"})
```

Zaman çizelgesi panelini de çoğaltıp PromQL'ini backend katmanını filtreleyecek
şekilde aynısını yapın.

### Web satırı

Backend satırındaki adımları web katmanı için tekrarlayın.

### Dashboard'ı kaydetmek

Panelleri doğru satırlara sürükleyip boyutlandırabilirsiniz. Kaydetmek için
sağ üstteki _Save dashboard_ tıklayın.

JSON'u bir dosyaya kaydetmek için (dashboard başlığının yanındaki)
_Export > Export as JSON_ seçeneğini kullanın.

___
> [Alıştırmalara](README.tr.md) dönün.
