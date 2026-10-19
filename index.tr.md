---
title: DevSecOps Laboratuvarları
lang: tr
slug: index
section: index
order: 0
status: updated
upstream: index.md
---
# DevSecOps Laboratuvarları

DevOps ve DevSecOps pratikleri için uygulamalı laboratuvarlar. Her şey kendi
makinenizde Docker ile çalışır — bulut hesabı yok, kredi kartı yok.

> 🇬🇧 [English version](index.md)

## Ön Koşullar

İlk lab'a başlamadan **önce** şunları yapın:

1. **[Ortamınızı kurun](setup/README.tr.md)** — Docker, Git ve bir terminal.
2. **Lab dosyalarını indirin:**

   ```
   git clone https://github.com/yasinoz/devsecops.git
   cd devsecops
   ```

3. **Docker Hub'a giriş yapın** (ücretsiz hesap). Sınıf ortamında bu opsiyonel
   değil: Docker Hub anonim imaj çekme işlemlerini *IP adresi başına*
   sınırlıyor. Aynı ofis bağlantısını paylaşan yirmi kişi limiti doldurur ve
   lab'ın ortasında `toomanyrequests` hatası alır.

   ```
   docker login
   ```

4. _Opsiyonel ama önerilir_ — repoyu gezmek ve dosyaları düzenlemek için
   [Visual Studio Code](https://code.visualstudio.com).

Son bölümdeki bazı lablar **Kubernetes kümesi** gerektirir. Kurulum kılavuzunda
seçenekler anlatılıyor; en kolayı Docker Desktop içinden Kubernetes'i
etkinleştirmek.

<!-- labs:start -->

## CI/CD Pipeline

Jenkins ile otomasyon, container imajları ve sürüm pipeline'ları.

| Lab | Süre | Gerekir |
|---|---|---|
| [Jenkins ile Otomasyon](labs/jenkins/README.tr.md) | 45 dk | docker |
| [Container İmajları Derlemek](labs/images/README.tr.md) | 40 dk | docker |
| [Registry Üzerindeki İmajlara Erişmek](labs/registries/README.tr.md) | 30 dk | docker |
| [Çok Aşamalı Build](labs/multi-stage/README.tr.md) | 40 dk | docker |
| [Compose ile Uygulama Derlemek](labs/compose-build/README.tr.md) | 45 dk | docker |
| [Jenkins ile Docker İmajı Derlemek](labs/pipeline/README.tr.md) | 60 dk | docker |

## Gözlemlenebilirlik

Metrikler, loglar ve dağıtık izler — sisteminizin ne yaptığını bilmek.

| Lab | Süre | Gerekir |
|---|---|---|
| [Prometheus ile Metrik Toplamak](labs/prometheus/README.tr.md) | 45 dk | docker |
| [Metrik Yayınlamak](labs/prometheus/metrics/README.tr.md) | 40 dk | docker |
| [Grafana ile Metrikleri Görselleştirmek](labs/grafana/README.tr.md) | 40 dk | docker |
| [Logları Elasticsearch'te Saklamak](labs/elasticsearch/README.tr.md) | 45 dk | docker |
| [Kibana ile Log Aramak](labs/kibana/README.tr.md) | 45 dk | docker |
| [Dağıtık İzleme](labs/tracing/README.tr.md) | 45 dk | docker |
| [Jaeger ile İzleri Görselleştirmek](labs/jaeger/README.tr.md) | 35 dk | docker |

## Katmanlı Güvenlik

Güvenliği öne almak — statik analiz, tarama, altın imajlar ve politika uygulama.

| Lab | Süre | Gerekir |
|---|---|---|
| [Statik Kod Analizi](labs/static-analysis/README.md) _(EN)_ | 45 dk | docker |
| [Güvenlik Taraması](labs/scanning/README.md) _(EN)_ | 45 dk | docker |
| [Altın İmaj Kütüphaneleri](labs/golden-images/README.md) _(EN)_ | 50 dk | docker |
| [ArgoCD ile GitOps](labs/argo/README.md) _(EN)_ | 60 dk | docker, kubernetes |
| [İş Yükü Politikalarını Uygulamak](labs/admission/README.md) _(EN)_ | 60 dk | docker, kubernetes |
| [Container Güvenlik Kontrolleri](labs/container-security/README.md) _(EN)_ | 50 dk | docker, kubernetes |

<!-- labs:end -->

## Bir lab nasıl işler

Her lab aynı kalıbı izler:

- **Kaynaklar** — gerçek dökümantasyona bağlantılar. İş yerinde lab'ı değil
  bunları kullanacaksınız.
- **Anlatım** — adım adım yönlendirme. Komutlar kopyala-yapıştır çalışır.
- 📋 **Görevler** — bunları kendiniz çözeceksiniz. Cevap hemen altındaki
  `Takıldınız mı?` bloğunda gizli; önce deneyin, sonra bakın.
- **Lab** — anlatımı olmayan, daha zor bir alıştırma. `hints.tr.md` yol
  gösterir, `solution.tr.md` cevabı verir.
- **Temizlik** — mutlaka çalıştırın; yoksa sonraki lab aynı portlar için
  kavga eder.

## Durum ve bilinen eksikler

Lablar 2021 tarihli bir kaynaktan modernize edildi. Neyin değiştiği, neyin
doğrulandığı ve neyin hâlâ elle çalıştırılması gerektiği
[MODERNIZASYON.md](MODERNIZASYON.md) dosyasında. Sitede `beta` işaretli lablar
güncellendi ama uçtan uca çalıştırılmadı.

Bozuk bir şey bulursanız issue açın — bu gerçekten faydalı, çünkü derste
patlayan bir lab, hiç olmayan lab'dan kötüdür.

## Emeği Geçenler

[Elton Stoneman](https://github.com/sixeyed) tarafından hazırlanan
[courselabs/devsecops](https://github.com/courselabs/devsecops) çalışmasından
türetilmiştir; CC BY-SA 4.0 kapsamında kullanılmış ve yeniden dağıtılmıştır.
Ayrıntı: [ATTRIBUTION.md](ATTRIBUTION.md).

Türkçe çeviri, modernizasyon ve lab altyapısı:
[Mehmet Yasin Özkasapoğlu](https://github.com/yasinoz) — `sudo2go`.
