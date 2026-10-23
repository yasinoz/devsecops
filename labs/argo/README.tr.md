---
title: ArgoCD ile GitOps
lang: tr
slug: argo
section: security
order: 4
duration: 60
requires: [docker, kubernetes]
status: updated
upstream: labs/argo
---
# ArgoCD ile GitOps

GitOps, CI/CD yaklaşımını tersine çeviriyor: harici bir otomasyon sunucusunun
değişiklikleri kümeye göndermesi yerine, kümenin içindeki bir araç bir Git
reposunu izleyip değişiklikleri çekiyor.

Bu, kümenizin daha temiz biçimde güvenceye alınabileceği anlamına geliyor;
çünkü otomasyon sunucusu için küme yöneticisi bir kullanıcıya ihtiyacınız
kalmıyor. Ayrıca uygulama tanımlarınız — hatta bulut servislerinin altyapı
kurulumu — kesin olarak Git repolarında saklanabiliyor. Tüm dağıtımınızı
sıfırdan yeniden oluşturabilirsiniz.

<!-- outcomes:auto -->
## Bu lab ne işe yarıyor

Derleme sunucusuna küme yöneticisi yetkisi vermek, CI pipeline'ını altyapınızın en yumuşak hedefi yapmanın yolu. GitOps bunu tersine çeviriyor: kümenin içindeki bir aracı Git'ten çekiyor, yani dışarıda hiçbir şeye yazma yetkisi gerekmiyor — ve depo, gerçekte neyin dağıtıldığının kaydı haline geliyor.

**Bu labdan sonra şunları yapabileceksiniz:**

- bir kümeye ArgoCD kurmak
- bir uygulamayı Git deposuna yöneltip dağıtımı ArgoCD'ye bırakmak
- Git'teki bir değişikliğin kimse `kubectl apply` çalıştırmadan kümeye ulaşmasını izlemek
- çekme temelli dağıtımın neden itme temellisinden daha kolay güvenlik altına alındığını açıklamak
<!-- /outcomes:auto -->

<!-- orientation:auto -->
## Bu lab nasıl işliyor

Bunu bir kez okuyun - bu eğitimdeki her lab aynı kurallarla yazıldı.

**Komutları nereye yazacaksınız.** Bir terminal açın ve bu depoyu kopyaladığınız
klasöre gidin. Windows'ta **PowerShell** kullanın (Başlat menüsünde aratın),
macOS veya Linux'ta **Terminal**. Labdaki bütün yollar depo kökünden yazıldı,
yani bir adım aksini söylemedikçe orada kalın.

**`>` ile başlayan satırlar açıklamadır, komut değildir.** Onları yapıştırmayın.
Yalnızca gri kod kutularının içindeki metin yazılır.

**📋 işareti "sıra sizde" demektir.** Onu gördüğünüzde adımı önce kendiniz
deneyin. Hemen altında cevabı saklayan kapalı bir **"Nasıl yapılır?"** oku var;
onu denedikten *sonra* açın, önce değil. Lablar bilerek böyle yazıldı: kendi
çözdüğünüz şeyi hatırlarsınız, yapıştırdığınızı değil.

**Bir komut hata verirse bu normal olabilir.** Bazı adımlar hatanın nasıl
göründüğünü göstermek için bilerek başarısız olur. Bir şeyin bozuk olduğuna
karar vermeden önce komutun üstündeki cümleyi okuyun.

**Takılırsanız** şu sırayla:

1. Komutun üstündeki paragrafı tekrar okuyun - cevap genelde oradadır.
2. **"Nasıl yapılır?"** okunu açın.
3. `hints.md` dosyasını açın, küçük bir yönlendirme verir.
4. `solution.md` dosyasını açın, tam cevap orada. Kullanmak serbest; okumadan
   kopyalamak değil.

**Bitirdiğinizde** en alttaki **Temizlik** bölümünü çalıştırın. Lablar aynı
portları ve container adlarını paylaşıyor; birinden kalan artık diğerini bozar.
<!-- /orientation:auto -->

<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 60 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

Bir **Kubernetes kümesi** çalışıyor olmalı. Docker Desktop
bunu içeriyor: *Settings -> Kubernetes -> Enable Kubernetes*. Kontrol edin:

```
kubectl get nodes
```

En az bir düğüm görmelisiniz ve `STATUS` sütunu `Ready` olmalı. Komut
takılır ya da hata verirse küme henüz başlamamıştır; bir dakika bekleyip
tekrar deneyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Kaynaklar

- [GitOps](https://www.gitops.tech) — yaklaşımı ve benimsenmesini anlatıyor

- [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) — CNCF'deki GitOps
  projesi

- [ArgoCD komut satırı](https://argo-cd.readthedocs.io/en/stable/user-guide/commands/argocd/)

- [Application CRD belirtimi](https://argo-cd.readthedocs.io/en/stable/operator-manual/application.yaml)

- [Kubernetes ve Argo ile GitOps](https://eltons.show/episodes/ecs-c3/) —
  YouTube anlatımı

## ArgoCD kurulumu

ArgoCD'nin kümede çalışan ve projeleriniz için yapılandırılmış Git repolarını
izleyen bir sunucu tarafı bileşeni var. Projeleri kurmak ve yönetmek için
kullanabileceğiniz bir komut satırı aracı da var.

Komut satırını kurarak başlayın —
[tam kurulum dökümanlarını](https://argo-cd.readthedocs.io/en/stable/cli_installation/)
kullanın ya da şu hızlı seçeneklerden birini:

```
# Windows:
choco install argocd-cli

# Mac:
brew install argocd

# Linux:
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

Kurulumunuzu kontrol edin:

```
argocd version
```

> İstemci sürümünü, ardından bir sunucu hatası göreceksiniz — komut satırı
> ArgoCD sunucusuna bağlanamıyor, çünkü onu henüz dağıtmadık.

Argo CD belirtiminin yerel bir kopyası burada:

- [argocd/v3.5.5.yaml](./specs/argocd/v3.5.5.yaml) — bol miktarda kaynak
  kuruyor; Kubernetes'in işlevselliğini genişleten CustomResourceDefinition'lar
  (CRD'ler) dahil. ArgoCD kümeye bir `Application` kaynağı ekliyor.

Sunucu bileşenlerini dağıtın:

```
kubectl apply --server-side -n argocd -f labs/argo/specs/argocd
```
> Burada `--server-side` gerekiyor. Duz `kubectl apply`, manifestin tamamini
> bir annotation'a yaziyor; ArgoCD'nin `applicationsets` CRD'si ise
> Kubernetes'in annotation icin izin verdigi 262KB sinirindan buyuk ve kurulum
> *"metadata.annotations: Too long"* diyerek basarisiz oluyor. Sunucu tarafli
> apply o annotation'i yazmiyor.


Argo, _Application_ adında yeni bir özel nesne tipi kuruyor.

📋 Kümedeki tüm application nesnelerini listeleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Özel nesneler Kubectl'de sıradan nesneler gibi kullanılabiliyor:

```
kubectl get applications
```

</details><br/>

Bu ArgoCD kurulumu bir web arayüzü içeriyor. İlk yönetici parolası bir
Secret'ta saklanıyor — parolayı düz metin olarak görmek için şunu çalıştırın:

```
kubectl -n argocd get secret argocd-initial-admin-secret -o go-template="{{.data.password | base64decode}}"
```

Arayüzü http://localhost:30881 adresinde açın, `admin` kullanıcı adı ve
Secret'tan aldığınız parolayla giriş yapın.

> Kendinden imzalı bir sertifikayla HTTPS'e yönlendirileceksiniz, dolayısıyla
> tarayıcınızdaki güvenlik uyarısını kabul etmeniz gerekecek.

https://localhost:30881/settings/clusters adresini açın — ArgoCD yerel kümeye
kayıtlı, dolayısıyla uygulamaları yönetebiliyor, ama henüz hiç uygulama yok.

## Git sunucusunu yapılandırmak

ArgoCD uygulamaları, izlenecek bir kaynak kod reposuyla yapılandırılmış
birimler olarak dağıtıyor. Reponun içeriği standart Kubernetes YAML'ı, Helm
chart'ı veya Kustomize olabiliyor.

ArgoCD repoyu izliyor ve bir değişiklik olduğunda — yani çalışan uygulama
kaynak repodaki belirtimlerle senkron olmaktan çıktığında — değişiklikleri
çekip uygulamayı güncelliyor.

Dağıtımı basit tutmak için yerel bir Git sunucusu çalıştıracağız:

- [gitea/gitea.yaml](./specs/gitea/gitea.yaml), Jenkins lab'ında kullandığımız
  Gitea sunucusunun Kubernetes'te çalışacak şekilde yapılandırılmış hâli

Git sunucusunu dağıtın:

```
kubectl apply -f labs/argo/specs/gitea
```

http://localhost:30300/ adresini açın ve site hazır olduğunda `student`
kullanıcı adı ve `student` parolasıyla giriş yapın.

Yeni Git sunucusunu bu repo için remote olarak ekleyip içeriğin bir kopyasını
gönderin:

```
# yerel Git sunucusunu ekle:
git remote add labs-argo http://localhost:30300/student/labs.git

git push labs-argo main
```

> Bu lab'ın eski sürümü `main:master` gönderiyordu, çünkü o günün ArgoCD
> sürümü varsayılan olarak `master` dalını bekliyordu. ArgoCD artık varsayılan
> olarak `HEAD`'i — yani Git sunucusunun kendi varsayılan dalını — izliyor;
> dolayısıyla `main` göndermek yeterli ve ikinci bir dal adına gerek yok.

Şimdi ArgoCD komut satırını ArgoCD sunucusuna bağlayın, **Secret'tan aldığınız
parolayı kullanarak**:

```
argocd login localhost:30881 --insecure --username admin --password <parolaniz>

argocd cluster list
```

> Uzak bir Kubernetes kümesine dağıtım yapmak için yeni kümeler
> ekleyebilirsiniz. Uygulamalar komut satırıyla veya arayüzle yönetilebilir.

## Uygulama dağıtmak

`labs/argo/project/whoami` klasöründeki uygulama için bir application
oluşturun — o klasör basit bir whoami uygulama belirtimi içeriyor:

```
argocd app create whoami --repo http://gitea.infra.svc.cluster.local:3000/student/labs.git --path labs/argo/project/whoami --dest-server https://kubernetes.default.svc --dest-namespace default --sync-policy auto --self-heal
```

> Application oluşturmak tanımı Kubernetes'te saklıyor ve senkronizasyon
> politikasını _auto_ olarak ayarladık — dolayısıyla hemen dağıtılacak.

Uygulamaları Kubernetes YAML'ı dağıtarak da oluşturabilirsiniz. Aynı
uygulamanın [Application nesnesi](./specs/apps/whoami.yaml) hâli burada —
`targetRevision: HEAD` kullanıyor, dolayısıyla Git sunucusunun varsayılan
dalının adı ne olursa olsun onu izliyor.

📋 Yeni application'ın ayrıntılarını Argo komut satırıyla kontrol edin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Application'lar da birer Kubernetes nesnesi — onları Kubectl ile
sorgulayabilirsiniz. Ama temel bilgiyi okunabilir biçimde Argo komut
satırından alıyorsunuz:

```
argocd app list

argocd app get whoami
```

</details><br/>


Yeni application'ı arayüzde de görebilirsiniz:
https://localhost:30881/applications. Durumun _Synced_ olduğunu göreceksiniz
ve uygulamayı açarsanız tüm Kubernetes kaynaklarını göreceksiniz.

ArgoCD uygulamayı repodaki YAML belirtimlerinden dağıtıyor — bakımı gereken
pipeline veya script yok. Uygulamayı http://localhost:30010/ adresinde test
edebilirsiniz.


## Lab

Şimdi GitOps'u iş başında görelim: uygulamanın Docker imaj etiketini
değiştirip yeni Pod'larla bir rollout tetikleyeceğiz.

Kubernetes [deployment.yaml](./project/whoami/deployment.yaml) dosyasını
düzenleyip iki değişiklik yapın:

- imaj etiketini `ghcr.io/yasinoz/courselabs/whoami-lab:21.09-4` yapın
- replica sayısını 3 yapın

Değişikliklerinizi yerel Git sunucusuna göndererek güncellemeyi tetikleyin.

Bu ArgoCD application'ı kendi kendini iyileştirecek (self-heal) şekilde
ayarlanmış; yani bir yönetici kaynakları kaldırırsa ArgoCD onları yeniden
oluşturacak. Kubernetes Deployment nesnesini silerek bunu doğrulayın.


> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___

<!-- troubleshooting:auto -->
## Takılırsanız

**`The connection to the server ... was refused`** - küme çalışmıyor. Docker
Desktop'ta Kubernetes'i açın ve başlamasını bekleyin.

**`provided port is already allocated`** - önceki bir labdan kalan Service o
NodePort'u hâlâ tutuyor. `kubectl get svc -A` ile bulun ve o labın oluşturduğu
namespace'i silin.

**`failed calling webhook ... service not found`** - **admission** labından
kalanlar API sunucusunu engelliyor; hiçbir şey oluşturamazsınız, namespace
bile. O labın Cleanup bölümünde webhook yapılandırmalarını kaldıran iki komut
var.

**Pod `ContainerCreating` ya da `Pending`de takılı** - genellikle imaj hâlâ
iniyor; ilk seferde birkaç dakika sürebilir. `kubectl describe pod <ad>` ile
bakın ve en alttaki **Events** bölümünü okuyun: pod'un neyi beklediğini tam
olarak söylüyor.

**Pod `CrashLoopBackOff`de** - konteyner başlayıp çıkıyor. Sebep günlüklerinde:
`kubectl logs <ad>`. Son yeniden başlatmadan önceki çalıştırmayı görmek için
`--previous` ekleyin.

Hâlâ takılıysanız: aşağıdaki **Cleanup** bölümü her şeyi sıfırlıyor, labı
temiz bir kümeyle baştan yapabilirsiniz.


## Temizlik

ArgoCD'de uygulamaları silmek çalışan uygulamayı kaldırmıyor — cascade
bayrağını kullanmazsanız:

```
argocd app delete whoami --cascade
```

> ArgoCD bunu gerçekten yapmak istediğinizi onaylamanızı istiyor :)

Sonra lab namespace'lerini silin; bu ArgoCD'yi ve Gitea'yı kaldıracak:

```
kubectl delete ns -l kubernetes.courselabs.co=argo
```

Ve Git remote'unu kaldırın:

```
git remote rm labs-argo
```

Namespace'leri silmek ArgoCD'nin özel kaynak tanımlarını (CRD) **kaldırmaz** -
onlar küme geneli nesneler, hiçbir namespace'in içinde durmuyorlar. Tek
başlarına zararsızlar ama sonraki lablarda `kubectl get crd` çıktısını
karıştırıyorlar; onları da silin:

```
kubectl delete crd applications.argoproj.io applicationsets.argoproj.io appprojects.argoproj.io --ignore-not-found
```
