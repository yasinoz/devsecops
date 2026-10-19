# DevSecOps Laboratuvarları / DevSecOps Labs

DevOps ve DevSecOps pratikleri için uygulamalı, **iki dilli** laboratuvarlar.
Her şey kendi makinenizde Docker ile çalışır — bulut hesabı gerekmez.

Hands-on, **bilingual** labs for DevOps and DevSecOps practices. Everything
runs locally with Docker — no cloud account needed.

| | |
|---|---|
| 🇹🇷 **Türkçe** | [index.tr.md](index.tr.md) |
| 🇬🇧 **English** | [index.md](index.md) |
| Kurulum / Setup | [setup/README.tr.md](setup/README.tr.md) · [setup/README.md](setup/README.md) |
| Modernizasyon durumu | [MODERNIZASYON.md](MODERNIZASYON.md) |
| Atıf / Attribution | [ATTRIBUTION.md](ATTRIBUTION.md) |

## Hızlı başlangıç

```
git clone https://github.com/yasinoz/devsecops.git
cd devsecops
docker login
```

`docker login` sınıf ortamında opsiyonel değil: Docker Hub anonim imaj çekme
işlemlerini IP adresi başına sınırlıyor ve aynı bağlantıyı paylaşan bir sınıf
limiti hızla dolduruyor.

## İçerik

19 lab, üç bölüm — tamamı Türkçe ve İngilizce:

- **CI/CD Pipeline** (6) — Jenkins, container imajları, registry'ler, çok
  aşamalı build, Compose ile derleme, uçtan uca pipeline
- **Gözlemlenebilirlik** (7) — Prometheus, metrik yayınlama, Grafana,
  Elasticsearch, Kibana, dağıtık izleme, Jaeger
- **Katmanlı Güvenlik** (6) — statik analiz, güvenlik taraması, altın imajlar,
  ArgoCD ile GitOps, admission control, container güvenlik kontrolleri

Son üç lab bir Kubernetes kümesi gerektirir; kurulum kılavuzunda seçenekler
anlatılıyor.

## Bu repo upstream'den nasıl farklı

Kaynak çalışma Aralık 2021'den beri güncellenmedi. Burada mekanik
modernizasyonun yanında her lab'ın metni de gözden geçirildi: çalışmayan
komutlar, kaymış arayüz anlatımları, kırık bağlantılar ve kullanımdan
kaldırılmış API'ler düzeltildi.

Neyin değiştiği, **neyin doğrulanmadığı** ve neyin bilinçli olarak eski
bırakıldığı [MODERNIZASYON.md](MODERNIZASYON.md) dosyasında.

Upstream'e göre tüm fark:

```
git diff upstream-baseline
```

## Doğrulama

Her push'ta CI çalışır ([.github/workflows/validate.yml](.github/workflows/validate.yml)):
compose v1 kullanımı, pinlenmemiş/eski imaj, kırık bağlantı, frontmatter,
çeviri tamlığı ve TR/EN yapısal eşitlik. Araçlar
[yasinoz/labs-platform](https://github.com/yasinoz/labs-platform) reposunda.

## Emeği Geçenler / Credits

[Elton Stoneman](https://github.com/sixeyed) tarafından hazırlanan
[courselabs/devsecops](https://github.com/courselabs/devsecops) çalışmasından
türetilmiştir; CC BY-SA 4.0 kapsamında kullanılmış ve **aynı lisansla** yeniden
dağıtılmaktadır. Ayrıntı: [ATTRIBUTION.md](ATTRIBUTION.md).

Türkçe çeviri, modernizasyon ve lab altyapısı:
[Mehmet Yasin Özkasapoğlu](https://github.com/yasinoz) — `sudo2go`.

Pratik çalışmanın bir kısmı diğer courselabs çalışmalarından uyarlanmıştır ve
onların da güncellenmiş kopyaları mevcut:

- [yasinoz/docker](https://github.com/yasinoz/docker) — 13 lab
- [yasinoz/kubernetes](https://github.com/yasinoz/kubernetes) — 31 lab
- [yasinoz/observability](https://github.com/yasinoz/observability) — 15 lab
