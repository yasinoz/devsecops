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
| `nginx:1.14` | scanning | Trivy taramasında yüzlerce CVE göstermek (216 CVE, 31 kritik) |
| `ghcr.io/yasinoz/library/alpine:3.8` | scanning, golden-images | Temel katman açıklarını göstermek |
| `python:3.4-alpine` | scanning | CVE-2019-15903 dahil kritik bulgular |
| `ghcr.io/yasinoz/library/amazoncorretto:8` | golden-images | Altın imaj karşılaştırma tabanı (Java 8, runtime'da JDK) |

Bu liste `_platform/VERSIONS.yaml` içindeki `intentionally_vulnerable`
bölümünde tutuluyor; lint aracı bu imajları uyarı üretmeden geçiyor.

## 4. Modernizasyon sırasında doğrulanamayanlar (tarihsel kayıt)

> **Bu bölüm artık geçmişi anlatıyor.** Buradaki maddelerin tamamı o günden
> sonra çalıştırılarak doğrulandı; sonuçlar **bölüm 5**'te. Bölüm, hangi
> riskin nerede görüldüğünü ve nasıl araştırıldığını kayıt altında tutmak
> için duruyor — özellikle Jenkins imajındaki üç JCasC hatasının bulunma
> yöntemi ilerideki değişikliklerde yine işe yarar.

Aşağıdakiler, yazıldıkları sırada **kod olarak düzeltilmiş ama uçtan uca
çalıştırılmamıştı** — modernizasyon sırasında bu makinede Docker motoru
kapalıydı.

Her lab'ın frontmatter'ında `status` alanı bunu taşır:

- `updated` — modernize edildi **ve** uçtan uca çalıştırıldı
- `needs-review` — modernize edildi, canlı test **edilmedi**
- `upstream` — henüz dokunulmadı

O gün 19 lab'ın tamamı `needs-review` idi; bugün tamamı `updated`.

### İlk dersten önce mutlaka çalıştırılmalı

1. **`ghcr.io/yasinoz/labs-jenkins:1.0.1` — çalıştırılarak doğrulandı.** ✅

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

   **İmajın içi 20.10.2026'da çalıştırılarak doğrulandı:**

   - Jenkins `Jenkins is fully up and running` noktasına ulaşıyor
   - `casc.yaml` uygulanıyor (sistem mesajı, `numExecutors: 2`, `mode: NORMAL`
     API'den teyit edildi)
   - `student` / `student` girişi çalışıyor (HTTP 200, `authenticated: true`),
     anonim erişim reddediliyor (HTTP 403), yanlış parola 401
   - Jenkins içinde `docker` 29.9.1 ve `kubectl` v1.37.1 var,
     `docker.sock` üzerinden host konteynerleri listelenebiliyor
   - `plugins.txt`'teki eklentilerin tamamı yüklü
   - Gitea HTTP 200

   **1.0.0 bozuktu — kullanılmamalı.** İlk yayınlanan imajda Jenkins hiç
   açılmıyordu (exit 5) ve bu ancak çalıştırılınca ortaya çıktı. Üç ayrı hata
   vardı:

   | Hata | Yazdığım | Doğrusu |
   | --- | --- | --- |
   | `authorizationStrategy` sembolü | `loggedInAuthenticationStrategy` | `loggedInUsersCanDoAnything` |
   | `crumbIssuer` alt alanı | `standard: { excludeClientIPFromCrumb: true }` | `crumbIssuer: "standard"` (alt alan kabul etmiyor) |
   | `casc.yaml` konumu | `/var/jenkins_home/casc.yaml` | `/var/jenkins_config/casc.yaml` |

   Sondaki en sinsisiydi: `/var/jenkins_home` temel imajda `VOLUME`. Oraya
   kopyalanan dosya yalnızca volume ilk oluşurken yazılır; sonra imaj
   güncellense bile compose aynı anonim volume'ü koruyup eski kopyayı okur.
   Yani yapılandırma düzeltmeleri kullanıcıya hiç ulaşmıyordu. Dosya artık
   volume'ün dışında.

   Geçerli JCasC sembollerini tahmin etmek yerine, imaj CasC olmadan açılıp
   `/configuration-as-code/schema` ucundan şema çekilerek bulundu; düzeltilmiş
   dosya da yeniden derlemeden önce `/configuration-as-code/checkNewSource`
   ile doğrulandı (`The configuration can be applied`). Aynı yöntem
   ilerideki casc değişiklikleri için de kullanılabilir.

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

## 5. Doğrulama koşusu — 23 Ekim 2026

**19 lab'ın tamamı bu makinede öğrenci gibi çalıştırıldı.** Ortam: Docker
29.9.1 (containerd snapshotter), kubectl v1.36.1, Docker Desktop Kubernetes
kümesi, Windows 11.

### Bulunan ve düzeltilen hatalar

| # | Lab | Hata | Etki |
|---|---|---|---|
| 1 | registries | `docker tag alpine ...` deniyor ama `alpine` hiç çekilmiyor | **Öğrenci duruyordu:** `No such image: alpine:latest` |
| 2 | multi-stage | `-f reference=golang` ayna referansını görmüyor | **Lab'ın dersi kayboluyordu:** metin "SDK imajı yüzlerce megabayt" diyor, öğrenci yalnızca 19 MB'lık imajı görüyordu |
| 3 | container-security | Git Bash konteyner içi yolu yeniden yazıyor | **Ders tersine dönüyordu:** "token orada duruyor" denen yerde öğrenci "dosya yok" görüyordu |
| 4 | images | `--filter reference=ubuntu` aynadakini görmüyor | "üçünün de ID'si farklı" denirken iki imaj çıkıyordu |
| 5 | admission | `apod` namespace'i temizlikte kalıyor | Etiket tabanlı silme, etiketi eklemek zaten alıştırmanın kendisi |
| 6 | admission | `gatekeeper-system` namespace'i temizlikte kalıyor | Lab bittikten 161 dk sonra dört pod hâlâ ayaktaydı |
| 7 | *(repo)* | lint 15 "pinlenmemiş imaj" hatası veriyordu | **CI kırmızıydı.** Aynalama `kiamol/` önekini `ghcr.io/yasinoz/kiamol/` yapınca istisna eşleşmeyi bıraktı |

1–4 iki dilde de düzeltildi. 7 için lab içeriğine dokunulmadı.

### Doğrulanan

- **10 compose yığını** ayağa kalkıyor: compose-build, prometheus, grafana,
  elasticsearch, kibana, tracing, jaeger, static-analysis, scanning, jenkins,
  pipeline. Servis durumları ve yayınlanan portlar tek tek ölçüldü
  (`scripts/verify-stacks.sh`).
- **Üç Kubernetes lab'ı** canlı kümede: `argo` (ArgoCD 7/7 pod ayakta, Gitea
  çalışıyor), `admission` (etiketsiz namespace `[requiredlabels-ns]` ile
  reddediliyor, fix-1 kabul ediliyor, fix-2 ile pod kalkıyor),
  `container-security` (fix-4 sonrası `nobody`/uid 65534, salt okunur dosya
  sistemi).
- **golden-images zinciri**: kütüphane derleniyor, app-1 585 MB → 353 MB,
  app-2 475 MB → 353 MB; ikisi de aynı altın imaj tabanında buluşuyor.
- **51 imaj referansı**: 43'ü registry'de mevcut, 8'i golden-images lab'ında
  yerelde derleniyor. Şüpheli görünen etiketlerin hepsi gerçek
  (nginx:1.31.7-alpine, maven:3.10-eclipse-temurin-25-noble, alpine:3.24,
  golang:1.27.2-alpine, ubuntu:26.04).
- **Lint tümüyle temiz**: 0 bulgu, 0 hata.

### Hata OLMAYAN bulgu

`tracing` ve `jaeger` yığınları ilk denemede kalkmadı. Sebep lab değil,
makinedeki geçici DNS hatasıydı (`lookup ghcr.io: getaddrinfow ... temporary
error`). Aynı imajların var olduğu manifest sorgusuyla zaten doğrulanmıştı;
tekrar koşulduğunda ikisi de çalıştı. Lab hatası diye raporlanmadı.

### Hâlâ yapılmamış

- `argocd` CLI adımları (CLI bu makinede kurulu değil; lab kurulumunu
  anlatıyor, öğrencinin yapacağı adım).
- Grafana, Kibana ve Jenkins lablarındaki **ekran görüntüleri** hâlâ eski
  sürümlerden. Metinler güncel, lab başında uyarı var.
- Docker Hub push adımı (registries lab'ı) — öğrencinin kendi hesabını
  gerektiriyor.

## 6. Çeviri durumu

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

## 7. Araçlar

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
