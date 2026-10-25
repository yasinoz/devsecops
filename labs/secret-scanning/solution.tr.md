# Lab Çözümü

`sirli-depo` klasöründe `entegrasyon.yml` adında bir dosya oluşturup içine
şunu yazın:

```
entegrasyon:
  anahtar: SPS-4K7M2Q9XB3TR6WZA
```

Önce varsayılan kurallarla tarayın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner
```

```
INF no leaks found
```

Anahtar orada duruyor ama gitleaks onu görmüyor. `SPS-` biçimi varsayılan
kural listesinde yok ve entropi eşiğini de aşmıyor.

Şimdi aynı klasörde `.gitleaks.toml` dosyasını oluşturun:

```
[extend]
useDefault = true

[[rules]]
id = "siparis-servisi-anahtari"
description = "Siparis servisi API anahtari"
regex = '''SPS-[A-Z0-9]{16}'''
```

Tekrar tarayın:

```
docker run --rm -v ./labs/secret-scanning/sirli-depo:/depo zricethezav/gitleaks:v8.30.1 dir /depo --no-banner -v
```

```
Secret:      SPS-4K7M2Q9XB3TR6WZA
RuleID:      siparis-servisi-anahtari
WRN leaks found: 1
```

`RuleID` alanında artık kendi kural adınız duruyor. Bulguyu okuyan kişi
hangi sistemin anahtarının sızdığını doğrudan görüyor.

## `[extend]` neden orada

Bu, alıştırmanın asıl öğrettiği yer. Yapılandırma dosyasını `[extend]`
bölümü olmadan yazarsanız gitleaks **yalnızca sizin kuralınızı** kullanıyor,
yerleşik olanların hepsini bırakıyor.

Farkı görmek için depoda bir de GitHub jetonu bulundurun — `ci.yml` dosyasını
geri koyun:

```
ci:
  token: ghp_K3nR7pQ2vXz9LmW4bYdF6gJ8sC1aU5oI0rNt
```

`[extend]` bölümünü silip tarayın:

```
RuleID:      siparis-servisi-anahtari
WRN leaks found: 1
```

Bir bulgu. GitHub jetonu **kaçtı**.

Şimdi `[extend]` bölümünü geri koyup tarayın:

```
RuleID:      github-pat
RuleID:      siparis-servisi-anahtari
WRN leaks found: 2
```

İki bulgu. Kendi kuralınızı eklerken yerleşik kuralların üstüne yazmak yerine
onlara **eklemiş** oluyorsunuz.

Sahada bu hata şöyle görünüyor: ekip kendi anahtar biçimi için bir kural
yazıyor, tarama çalışıyor, bulgu geliyor, herkes sistemin işlediğini
düşünüyor. Oysa o günden sonra AWS ve GitHub anahtarları hiç kontrol
edilmiyor. Tarayıcı çalışıyor, kapı duruyor, ama kapsam sessizce daralmış.

> Yapılandırmayı değiştirdiğiniz her seferde **daha önce yakalanan bir şeyin
> hâlâ yakalandığını** kontrol edin. Kapsam daralması sessizdir; hata vermez.

___
> [Alıştırmalara](README.tr.md) dönün.
