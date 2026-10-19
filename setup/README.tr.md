---
title: Ortam Kurulumu
lang: tr
slug: setup
section: index
order: 0
status: updated
upstream: setup/README.md
---
# Ortam Kurulumu

Lablarda çok sayıda araç kullanacağız — Jenkins, Prometheus, Elasticsearch,
Trivy ve dahası. Hiçbirini kurmayacaksınız. Her şey container içinde çalışıyor,
dolayısıyla makinenizde tam olarak iki şey olması gerekiyor: **Docker** ve
**Git**.

> Bu eğitim için Docker deneyimi gerekmiyor. Bütün komutlar size veriliyor.

## 1. Git

Git ücretsiz ve açık kaynak:

- [Git'i kurun](https://git-scm.com/downloads) (Windows, macOS, Linux)

Windows'ta bu kurulum size **Git Bash**'i de verir. PowerShell kullanmak
istemiyorsanız kullanışlı bir alternatiftir.

## 2. Docker

### Windows ve macOS — Docker Desktop

- [Docker Desktop'ı kurun](https://www.docker.com/products/docker-desktop)

Kurulum birkaç dakika sürer, Windows'ta yeniden başlatma isteyebilir. Bittiğinde
**Docker Desktop**'ı çalıştırın ve görev çubuğundaki (Windows) veya menü
çubuğundaki (macOS) balina simgesinin hareket etmeyi bırakmasını bekleyin.

> **Lisans notu.** Docker Desktop kişisel kullanım, eğitim ve küçük işletmeler
> için ücretsiz; büyük kurumlar için ücretli abonelik gerekiyor. Şirket
> kurallarınız buna izin vermiyorsa [Rancher Desktop](https://rancherdesktop.io)
> veya [Podman Desktop](https://podman-desktop.io) kullanın — bu lablardaki
> `docker` komutları ikisinde de çalışır.

### Linux — Docker Engine

<details>
  <summary>Linux'ta Docker çalıştırmak</summary>

Windows'ta WSL kullanıyorsanız Docker Desktop kurun — WSL dağıtımınızla entegre
çalışıyor ve çok daha az uğraştırıyor.

- [Docker Engine'i kurun](https://docs.docker.com/engine/install/) (Compose
  eklentisi dahil gelir)

Sonra servisin çalıştığından emin olun ve her komutta `sudo` yazmamak için
kendinizi `docker` grubuna ekleyin:

```
sudo systemctl start docker

sudo usermod -aG docker $USER

newgrp docker
```

Docker'ın açılışta otomatik başlaması için:

```
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

> `docker` grubunda olmak, host üzerinde root erişimine denktir. Kendi lab
> makinenizde sorun değil; paylaşılan bir makinede bilinçli bir karardır.

</details><br />

## 3. Kurulumu doğrulayın

Üç komut. Üçünden de çıktı almanız gerekiyor.

```
git --version
```

```
docker version
```

**İki** bölüm görmelisiniz: `Client:` ve `Server:`. Sadece `Client` görüyorsanız
Docker motoru çalışmıyor — Docker Desktop'ı başlatın ve bekleyin.

```
docker compose version
```

> ⚠️ **Boşluğa** dikkat: `docker compose`, `docker-compose` değil. Eski
> `docker-compose` (v1) komutunun desteği Haziran 2023'te bitti ve artık
> dağıtılmıyor. Buradaki tüm lablar v2 sözdizimini kullanıyor. Lablarda
> herhangi bir yerde `docker-compose` çağrısı görürseniz bu bir hatadır —
> lütfen bildirin.

Sürüm numaralarının başkasıyla aynı olması gerekmiyor. Bir komut hata
veriyorsa şimdi çözün; çalışan bir Docker motoru olmadan bu eğitimde hiçbir şey
yürümez.

<details>
  <summary>Linux'ta "permission denied" mi alıyorsunuz?</summary>

Kullanıcınızı `docker` grubuna ekleyin ve yeni bir oturum açın:

```
sudo usermod -aG docker $USER

# oturumu kapatıp açın, ya da:
su $USER
```

</details><br />

<details>
  <summary>Windows: "no matching manifest for windows/amd64" mi?</summary>

Docker Desktop *Windows container* modunda. Balina simgesine sağ tıklayıp
**Switch to Linux containers** seçin. Linux modu varsayılandır ve bu lablar
onu gerektirir.

</details><br />

## 4. Docker Hub'a giriş yapın

[Ücretsiz Docker Hub hesabı](https://hub.docker.com/signup) oluşturup giriş
yapın:

```
docker login
```

Bu bir bürokrasi değil. Docker Hub anonim imaj çekme işlemlerini **IP adresi
başına** sınırlıyor. Sınıfta herkes tek bir genel IP paylaştığı için limit
üçüncü kişide dolar ve geri kalanlar şunu görür:

```
toomanyrequests: You have reached your pull rate limit
```

Kimlik doğrulamış hesaplar çok daha yüksek bir kotaya sahip ve bu kota IP
yerine kullanıcı başına sayılıyor. Tek bir `docker login` bütün sınıfı kurtarır.

## 5. Kubernetes (yalnızca son üç lab için)

GitOps, admission control ve container güvenliği labları bir küme gerektiriyor.
Tek düğümlü herhangi bir küme işe yarar. Birini seçin:

### Docker Desktop (en kolayı)

**Settings → Kubernetes → Enable Kubernetes → Apply & Restart.** İlk çalıştırma
birkaç dakika sürer.

### k3d, kind veya minikube

<details>
  <summary>Docker Desktop kullanmıyorsanız alternatifler</summary>

Üçü de kümeyi Docker container'ları içinde çalıştırır:

```
# k3d
k3d cluster create labs --port "30000-30100:30000-30100@server:0"

# kind
kind create cluster --name labs

# minikube
minikube start
```

> Lablar servislere 30000+ aralığındaki **NodePort**'lar üzerinden erişiyor.
> k3d'de yukarıdaki port eşlemesi gerekir; kind'da `extraPortMappings`
> yapılandırması; minikube'de `minikube service` veya `minikube tunnel`
> kullanın.

</details><br />

Kontrol edin:

```
kubectl version

kubectl get nodes
```

En az bir düğümün `Ready` olması ve `kubectl` istemci sürümünün **1.30 veya
üstü** olması gerekiyor.

## 6. Docker'a yeterli bellek verin

Elasticsearch, Kibana ve SonarQube ağır çalışır. Docker Desktop'ta:

**Settings → Resources** → belleği en az **6 GB** yapın (8 GB rahat eder).

Bir container kendi kendine 137 çıkış koduyla ölüyorsa bellek yetmemiştir —
akılda tutulacak belirti budur.

## 7. Lab dosyalarını indirin

```
git clone https://github.com/yasinoz/devsecops.git

cd devsecops
```

Tüm lab komutlarını **bu klasörden** çalıştırın, lab dizininin içinden değil.
Lablardaki yollar repo köküne göre yazılmıştır:

```
docker compose -f labs/jenkins/infra/docker-compose.yml up -d
```

> **Windows satır sonları.** Bu repo `.gitattributes` ile satır sonlarını LF'e
> sabitliyor ve bu önemli: CRLF ile checkout edilen bir shell script, Linux
> container içinde `bad interpreter` hatası verir. Bu dosya eklenmeden önce
> klonladıysanız yeniden klonlayın.

## Opsiyonel ama faydalı

- [Visual Studio Code](https://code.visualstudio.com) — repoyu gezmek,
  Dockerfile'ları okumak, YAML'ı doğrulamalı düzenlemek
- [Windows Terminal](https://aka.ms/terminal) — sekmeler, ihtiyaç duyacaksınız
- `kubectl` [otomatik tamamlama](https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/)

## Hazırsınız

[Lab listesine](../index.tr.md) dönün.
