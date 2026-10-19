# Modernizasyon Durumu

Bu repo, [courselabs/devsecops](https://github.com/courselabs/devsecops)
çalışmasının **21 Aralık 2021** tarihli son hâlinden türetildi (bu repoda
`upstream-baseline` etiketi). Aradaki yaklaşık dört yılda labların bir kısmı
sessizce bozuldu, bir kısmı çalışıyor ama ekrandaki arayüzle uyuşmuyor.

Bu dosya neyin düzeltildiğini, **neyin hâlâ doğrulanmadığını** ve neyin
bilinçli olarak eski bırakıldığını kayıt altına alır.

```
git diff upstream-baseline --stat      # upstream'e göre tüm değişiklikler
```

---

## 1. Kesin bozukluklar — düzeltildi

| Sorun | Etki | Durum |
|---|---|---|
| `docker-compose` (v1 CLI), 31 çağrı | Compose v1 Haziran 2023'te EOL oldu ve Docker Desktop ile gelmiyor. Öğrencinin **ilk komutu** `command not found` veriyordu. | ✅ `docker compose` (v2) |
| Trivy 0.21.1 | Trivy 0.23'ten itibaren güvenlik açığı veritabanı v2 şemasına geçti ve GHCR'dan OCI artifact olarak dağıtılıyor. 0.21.1 veritabanını **indiremiyor**; tarama lab'ı tamamen çalışmıyordu. | ✅ 0.76.0 |
| OPA Gatekeeper v3.5.2 manifesti | `policy/v1beta1` (PodSecurityPolicy) kullanıyor; bu API **Kubernetes 1.25'te kaldırıldı**. Manifest güncel kümede hiç uygulanmıyordu. | ✅ v3.23.1 (yeniden indirildi) |
| ArgoCD v2.1.2 manifesti | CRD ve RBAC yapısı v3'te tamamen değişti. | ✅ v3.5.5 (yeniden indirildi) |
| Docker Hub `openjdk` imajı | Resmi imaj kullanımdan kaldırıldı. | ✅ `eclipse-temurin` |
| .NET 6 | Destek Kasım 2024'te bitti. | ✅ .NET 10 |
| Kırık göreli bağlantılar (8 adet) | Windows ters bölü işaretleri (`\lab\queries\x.json`) ve mutlak yollar (`/img/x.png`). GitHub'da ve sitede tıklanmıyordu. | ✅ düzeltildi |
| Hiç commit edilmemiş 4 ekran görüntüsü | Prometheus lab'ı var olmayan 4 PNG'ye atıf yapıyordu — öğrenci kırık resim görüyordu. | ⚠️ açıklayıcı metinle değiştirildi; ekran görüntüleri **yeniden alınmalı** |
| Satır sonları | Windows'ta CRLF ile checkout edilen script, Linux container'da `bad interpreter` veriyordu. | ✅ `.gitattributes` ile LF |

## 2. Çalışıyor ama arayüz uyuşmuyordu — güncellendi

Bunlar "hata vermiyor ama anlaşılmıyor" sınıfı. Lab adımları 2021 arayüzünü
anlatıyordu, öğrenci ekranda başka bir şey görüyordu.

| Bileşen | Önce | Sonra | Not |
|---|---|---|---|
| Grafana | 8.0.5 | 13.2.4 | Gezinme tamamen değişti. Lab adımları **yeniden yazıldı** (Connections > Data sources, Dashboards > New, Transformations, Back to dashboard, Export as JSON). Ekran görüntüleri Grafana 8'den; lab başında açıkça uyarılıyor. |
| Prometheus | 2.28.1 | 3.15.0 | Arayüz yenilendi. |
| Elasticsearch / Kibana / Logstash | 7.10 | 9.5.5 | Güvenlik 8.x'ten itibaren varsayılan açık; compose'lara `xpack.security.enabled=false` **eklendi**. Ayrıca: `_type` alanı 8'de kaldırıldı, sistem index'leri `_cat/indices`'te gizlendi (`expand_wildcards=all` gerekiyor), Kibana'da "index pattern" → "data view". Hepsi lab metinlerine işlendi. |
| Jaeger | 1.24 | 2.22.0 | v2 yapılandırması çok farklı: OTLP varsayılan 4317/4318'de, eski Thrift ucu kapalı. Uygulama tarafı **gözden geçirilmeli**. |
| Jenkins | 2.319.1 | 2.580.1-lts-jdk21 | Blue Ocean bakımsız kaldı; lab yerleşik Pipeline + Stage View'a taşındı. |
| Git sunucusu | Gogs 0.12.3 | Gitea 28.2.0 | Gogs fiilen bakımsız. Gitea'da ilk kullanıcı CLI ile oluşturuluyor; lab adımı eklendi. |
| SonarQube | 9.2.1 | 26.10.0.133078-community | Arayüz ve kalite kapısı ekranları değişti. |

## 3. Bilinçli olarak ESKİ bırakılanlar

**Bunları güncellemeyin.** Tarama ve analiz labları bu imajlardaki gerçek
CVE'leri bulmak üzere kurgulandı; güncellenirse lab anlamsız hale gelir.

| İmaj | Kullanan lab | Sebep |
|---|---|---|
| `nginx:1.7` | scanning | Trivy taramasında yüzlerce CVE göstermek |
| `alpine:3.8` | scanning, golden-images | Temel katman açıklarını göstermek |
| `python:3.4-alpine` | scanning | CVE-2019-15903 dahil kritik bulgular |
| `openjdk:8-jre-alpine` | golden-images | Altın imaj karşılaştırma tabanı |

Bu liste `_platform/VERSIONS.yaml` içindeki `intentionally_vulnerable`
bölümünde tutuluyor; lint aracı bu imajları uyarı üretmeden geçiyor.

## 4. DOĞRULANMAYANLAR

Bu bölüm dürüstlük içindir. Aşağıdakiler **kod olarak düzeltildi ama uçtan uca
çalıştırılmadı** — modernizasyon sırasında bu makinede Docker motoru kapalıydı.

Her lab'ın frontmatter'ında `status` alanı bunu taşır:

- `updated` — modernize edildi **ve** uçtan uca çalıştırıldı
- `needs-review` — modernize edildi, canlı test **edilmedi**
- `upstream` — henüz dokunulmadı

Şu an **19 lab'ın tamamı `needs-review`**. Sitede bu lablar `beta` etiketiyle
görünüyor ve öğrenciye uçtan uca doğrulanmadığı yazılıyor.

### İlk dersten önce mutlaka çalıştırılmalı

1. **`ghcr.io/yasinoz/labs-jenkins:1.0.0` yayınlandı ve erişilebilir.** ✅

   CI iş akışı (`build-images.yml`) çalıştı, imaj `linux/amd64` ve
   `linux/arm64` olarak GHCR'a gitti (Apple Silicon öğrenciler kapsandı) ve
   anonim çekmeye açık — öğrencinin GHCR'a giriş yapması gerekmiyor
   (doğrulandı: anonim manifest sorgusu HTTP 200).

   Eklenti sürümleri pinlenmedi (bkz. `images/jenkins/plugins.txt` içindeki
   açıklama), bu yüzden imajı yeniden derlerseniz eklenti sürümleri
   değişebilir. `1.0.0` etiketi sabit kaldığı sürece ders tekrar edilebilir.

   GHCR erişilemezse compose yerelde derler (hem `image` hem `build` tanımlı):
   ```
   docker compose -f labs/jenkins/infra/docker-compose.yml build
   ```

   **Yine de doğrulanmadı:** imajın İÇİ. Jenkins'in gerçekten eklentilerle
   açıldığı, `casc.yaml`'ın okunduğu ve student/student ile giriş yapıldığı
   çalıştırılarak teyit edilmedi.

2. **Jenkins lab'ı** — Gitea'da kullanıcı oluşturma, kimlik bilgisi ekleme ve
   `input` bloğunun duraklattığı aşamanın yerleşik arayüzde nasıl göründüğü.
   Ekran görüntüsü (`img/jenkins-manual-gate.png`) Blue Ocean dönemine ait,
   yenilenmeli.

3. **Elasticsearch / Kibana / Logstash** — kapatıldı. ✅ (çalıştırılmadı)
   `xpack.security.enabled=false`, `discovery.type=single-node` ve sabit heap
   eklendi; Kibana için sabit `encryptedSavedObjects` anahtarı verildi (yoksa
   her restart'ta kaydedilen dashboard'lar açılmıyor).

4. **Jaeger lab'ı — araştırıldı, kod düzeltildi.** ✅ (çalıştırılmadı)

   Jaeger v2 tamamen yeniden yazıldı (OpenTelemetry Collector üzerine), bu
   yüzden örnek uygulamaların kullandığı eski Jaeger protokolünün kapanmış
   olmasından şüphelendim. Dağıtılan v2.22.0 yapılandırması kontrol edildi:

   ```yaml
   receivers: [otlp, jaeger, zipkin]
   jaeger:
     protocols: [grpc, thrift_binary, thrift_compact, thrift_http]
   ```

   Eski protokollerin tamamı varsayılan olarak açık — yani uygulamalar ek
   yapılandırma olmadan rapor edebiliyor, compose'da değişiklik gerekmedi.

   **Ama** aynı yapılandırmada Jaeger'ın kendi izlemesi için bir TODO var:
   v2 kendini izlemiyor. Lab'ın ilk alıştırması `jaeger-query` servisinin
   izlerine bakmayı söylüyordu ve o liste artık boş dönüyor — bölüm yeniden
   kurgulandı, span/etiket anlatımı gerçek izlerin olduğu yere taşındı.
   Kullanılmayan `jaeger-query-span.png` ekran görüntüsü artık referans
   edilmiyor.

5. **Grafana lab'ı** — metin yeniden yazıldı ✅, **ekran görüntüleri hâlâ
   Grafana 8'den**. Lab başında bunun açık uyarısı var ama görsellerin
   yenilenmesi gerekiyor. Aynı durum Kibana ve Jenkins lablarındaki görseller
   için de geçerli.

6. **Kubernetes gerektiren üç lab** (argo, admission, container-security) —
   manifestler yenilendi ama güncel bir kümede uygulanmadı.

## 5. Çeviri durumu

| | Lab | Durum |
|---|---|---|
| ✅ | index, setup | EN yeniden yazıldı + TR çevrildi |
| ✅ | **CI/CD (6)** | jenkins, images, registries, multi-stage, compose-build, pipeline |
| ✅ | **Gözlemlenebilirlik (7)** | prometheus, prometheus/metrics, grafana, elasticsearch, kibana, tracing, jaeger |
| ✅ | **Katmanlı Güvenlik (6)** | static-analysis, scanning, golden-images, argo, admission, container-security |

**DevSecOps track'inin çevirisi tamamlandı: 19/19 lab + index + setup.**

Lint tümüyle temiz: `compose`, `pins`, `stale`, `i18n`, `links`,
`frontmatter`, `parity` — hepsi 0 bulgu. CI'da artık `i18n` ve `parity`
**hata** kontrolü (repoda `.github/i18n-required` dosyası var): eksik bir TR
karşılığı ya da TR/EN arasında düşmüş bir adım build'i kırar. Henüz
çevrilmekte olan diğer üç repoda aynı kontrol bilgilendirme amaçlı kalıyor.

Çeviri sırasında her lab'ın İngilizcesi de gözden geçirildi; bulunan içerik
hataları (kırık komut, kaymış arayüz anlatımı, boş bağlantı, yazım hatası) EN
tarafında da düzeltildi. Ayrıntı: `git log`.

Çeviri bekleyen lablar sitede İngilizce gösteriliyor ve öğrenciye bunun çeviri
olmadığı açıkça yazılıyor — "çevrildi" diye işaretlenip aslında çevrilmemiş bir
lab yayına çıkamaz, çünkü dil durumu dosya varlığından okunuyor.

Çeviri yaparken `_platform/docs/CEVIRI-SOZLUGU.md` bağlayıcıdır: terim
tablosu, üslup ve çevrilmeyecek bölümler orada.

## 6. Araçlar

Tümü `yasinoz/labs-platform` reposunda, sıfır bağımlılık (PyYAML bile yok).

```bash
cd ../labs-platform

# Dersi bozan sorunları ara
python tools/lab-lint.py ../devsecops

# Mekanik düzeltmeleri uygula (önce --dry-run)
python tools/modernize.py ../devsecops --dry-run
python tools/modernize.py ../devsecops --apply

# manifest.json + index tablolarını üret
python tools/make-manifest.py ../devsecops --write-frontmatter

# Vendor'lanmış kurulum manifestlerini yenile
python tools/fetch-manifests.py --repo-root .. --apply
```

Sürüm matrisi tek yerde: `_platform/VERSIONS.yaml`. Bir imajı güncellemek
istiyorsanız orayı değiştirip `modernize.py` çalıştırın; lint aracı da aynı
dosyayı okuduğu için matris ile repo arasındaki fark otomatik yakalanır.

CI (`.github/workflows/validate.yml`) her push'ta lint çalıştırıyor. Çeviri
kontrolü şimdilik hata saymıyor (`|| true`); tüm lablar çevrildiğinde o satır
kaldırılacak.
