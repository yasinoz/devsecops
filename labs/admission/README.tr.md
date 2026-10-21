---
title: İş Yükü Politikalarını Uygulamak
lang: tr
slug: admission
section: security
order: 5
duration: 60
requires: [docker, kubernetes]
status: needs-review
upstream: labs/admission
---
# Admission Control (Kabul Denetimi)

Admission control, iş yüklerinin kümede çalışmasına izin verme — ya da
engelleme — sürecidir. Bunu kendi kurallarınızı uygulamak için
kullanabilirsiniz. Onaylı bir registry'den imaj kullanmayan tüm container'ları
engellemek, ya da belirtiminde kaynak limitleri bulunmayan Pod'ları engellemek
isteyebilirsiniz.

Bunu admission controller webhook'larıyla yapabilirsiniz — küme içinde çalışan
ve nesneler oluşturulduğunda kuralları uygulamak üzere API tarafından çağrılan
HTTP sunucuları. Admission controller'lar sizin kendi mantığınızı
kullanabileceği gibi [Open Policy Agent](https://www.openpolicyagent.org) gibi
standart bir aracı da kullanabilir.

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

- [Admission controller kullanmak](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
- [OPA Gatekeeper](https://open-policy-agent.github.io/gatekeeper/website/docs/)
- [Gatekeeper politika kütüphanesi](https://github.com/open-policy-agent/gatekeeper-library)


## Validating ve Mutating Webhook'lar

Kendi admission control mantığınızı kümede çalıştırdığınız bir REST API içinde
yazabilir ve Kubernetes nesnelerine uygulanacak kurallar yapılandırabilirsiniz:

- [şu ValidatingWebhookConfiguration](./specs/validating-webhook/validatingWebhookConfiguration.yaml)
  kümede Pod oluşturulduğunda veya güncellendiğinde devreye giriyor ve özel bir
  webhook sunucusundaki validate metodunu çağırıyor; sunucu, işlemin devam
  etmesine izin verilip verilmediğini döndürüyor

- [şu MutatingWebhookConfiguration](./specs/mutating-webhook/mutatingWebhookConfiguration.yaml) —
  Pod oluşturulduğunda veya güncellendiğinde devreye giriyor ve sunucudaki
  mutate uç noktasını çağırıyor; bu, Kubernetes işlemi yürütmeden önce
  belirtimi düzenleyip değişiklikleri geri gönderebilir.

Kümede bir webhook sunucusu çalıştırabilirdik — bu örnekler bir demo NodeJS web
uygulamasıyla çalışıyor
([GitHub'da kaynak kod](https://github.com/sixeyed/kiamol/tree/master/ch16/docker-images/admission-webhook/src)) —
ama daha yaygın bir alternatif var.

## OPA Gatekeeper'ı çalıştırmak

Özel webhook'ların iki olumsuz tarafı var: kodu kendiniz yazmanız gerekiyor,
bu da bakım yükünüze ekleniyor; ve kuralları küme üzerinden keşfedilebilir
değil, dolayısıyla harici dökümantasyona ihtiyacınız oluyor.

OPA Gatekeeper, admission control'ü genel kural tanımlarıyla
([Rego](https://www.openpolicyagent.org/docs/latest/policy-language/) adında
bir dille) uygulayan bir alternatif.

Admission kurallarını — bir başka CNCF projesi olan — Gatekeeper ile
dağıtacağız. Kubernetes'i yeni nesne tipleriyle genişletiyor ve kendi
kurallarınızı saklamak ve uygulamak için o nesneleri kullanıyorsunuz.

OPA Gatekeeper de karmaşık bir bileşen; onu yönetmenin yükünü kendi
controller'larınızı çalıştırmanın sorunlarıyla takas ediyorsunuz:

- [opa-gatekeeper/v3.23.1.yaml](./specs/opa-gatekeeper/v3.23.1.yaml) — admission
  kurallarını tanımlamak için özel kaynaklar, controller için RBAC ve onu
  çalıştırmak için bir Service ile Deployment dağıtıyor

_OPA'yı dağıtın:_

```
kubectl apply -f labs/admission/specs/opa-gatekeeper
```

📋 Gatekeeper hangi özel kaynak tiplerini kuruyor?

<details>
  <summary>Takıldınız mı?</summary>

CustomResourceDefinition'lara bakın:

```
kubectl get crd
```

Birkaç tane göreceksiniz — asıl çalıştığımız ConstraintTemplate.

</details><br/>

## OPA admission kurallarını dağıtmak

Gatekeeper ile kural uygulamanın iki parçası var:

1. Genel bir kısıt tanımlayan bir _ConstraintTemplate_ oluşturmak (örneğin
   belirli bir namespace'teki container'lar yalnızca belirli bir imaj
   registry'si kullanabilir)

2. Şablondan bir _Constraint_ oluşturmak (örneğin `whoami` namespace'indeki
   container'lar yalnızca Docker Hub'daki `courselabs` repolarından imaj
   kullanabilir)

Kural tanımı Rego genel politika diliyle yapılıyor:

- [requiredLabels-template.yaml](./specs/opa-gatekeeper/templates/requiredLabels-template.yaml) —
  bir nesnede etiket zorunlu kılan basit (!) bir şablon tanımlıyor

- [resourceLimits-template.yaml](./specs/opa-gatekeeper/templates/resourceLimits-template.yaml) —
  container nesnelerinde resources tanımlı olmasını zorunlu kılan daha karmaşık
  bir şablon tanımlıyor

Şablonları oluşturun:

```
kubectl apply -f labs/admission/specs/opa-gatekeeper/templates
```

📋 Özel kaynakları yeniden kontrol edin; Gatekeeper kısıtları Kubernetes'te
nasıl sakliyor sizce?

<details>
  <summary>Takıldınız mı?</summary>

```  
kubectl get crd
```

Kısıt şablonları için yeni CRD'ler görüyorsunuz:

```
policyresourcelimits.constraints.gatekeeper.sh

requiredlabels.constraints.gatekeeper.sh
```

Gatekeeper her kısıt şablonu için bir CRD oluşturuyor; böylece her kısıt bir
Kubernetes kaynağı oluyor.

</details><br/>

Şablonları kullanan kısıtlar şunlar:

- [requiredLabels.yaml](./specs/opa-gatekeeper/constraints/requiredLabels.yaml) —
  Pod'larda `app` ve `version`, namespace'lerde ise
  `kubernetes.courselabs.co` etiketini zorunlu kılıyor

- [resourceLimits.yaml](./specs/opa-gatekeeper/constraints/resourceLimits.yaml) —
  `apod` namespace'indeki tüm Pod'lar için resources belirtilmesini zorunlu
  kılıyor

Kısıtları dağıtın:

```
kubectl apply -f labs/admission/specs/opa-gatekeeper/constraints
```

📋 Zorunlu etiketler namespace kısıtının ayrıntılarını yazdırın. Neyi zorunlu
kıldığı anlaşılıyor mu?

<details>
  <summary>Takıldınız mı?</summary>

Kısıt tipi bir CRD olduğu için nesneleri her zamanki gibi listeleyebilirsiniz:

```  
kubectl get requiredlabels

kubectl describe requiredlabels requiredlabels-ns
```

Kuralın mevcut tüm ihlallerini göreceksiniz ve neyin gerektiği anlaşılır
olmalı — her namespace üzerindeki etiket.

</details><br/>

Rego kolay bir dil değil — ama politika tanımlamanın genel bir yolu. Trivy de
[hatalı yapılandırma kontrol kütüphanesi](https://github.com/aquasecurity/trivy-checks)
için Rego kullanıyor (o kütüphane eskiden appshield adlı bir repoda
duruyordu).

## OPA kurallarını doğrulamak

`labs/admission/specs/pi` klasöründeki bu uygulama YAML'ı, namespace ve Pod'lar
için tanımlı tüm OPA kurallarını ihlal ediyor.

📋 Uygulamayı dağıtın. Çalışıyor mu?

<details>
  <summary>Takıldınız mı?</summary>

Kubectl apply kullanın:

```
kubectl apply -f labs/admission/specs/pi
```

Politika ihlali nedeniyle namespace'in oluşturulamadığını, ardından namespace
olmadığı için diğer nesnelerin de oluşturulamadığını söyleyen hatalar
göreceksiniz.

</details>

Bazı politika hataları Kubectl ile oluşturduğunuz nesnelerde oluyor —
dolayısıyla böyle net doğrulama hataları görüyorsunuz.

Düzeltme [fix-1/01-namespace.yaml](./specs/pi/fix-1/01-namespace.yaml)
dosyasında; namespace'e gereken etiketi ekliyor. Düzeltilmiş sürümü dağıtıp
çıktıyı kontrol edin:

```
kubectl apply -f labs/admission/specs/pi/fix-1
```

Kubectl çıktısı tüm nesnelerin oluşturulduğunu söylüyor.
http://localhost:30031 adresinde dinliyor olmalı. Çalışıyor mu? Hayır...
Service oluşturulmuş ama ondan yanıt yok.

📋 Sorunun ne olduğunu görmek için hata ayıklayabilir misiniz?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Service'i tanımlayarak başlayın:

```
kubectl describe svc pi-np -n pi
```

Hiç _Endpoints_ olmadığını göreceksiniz; yani Service'in trafik yönlendireceği
hedef olarak kaydolmuş Pod yok.

Namespace'teki tüm Pod'ları listelemeyi deneyin:

```
kubectl get po -n pi
```

Hiç yok. Hmm. Deployment ve ReplicaSet'ler nasıl?

```
kubectl get deploy,rs -n pi
```

Oluşturulmuşlar ama Pod yok. Sorunu görmek için ReplicaSet'i tanımlayın:

```
kubectl describe rs -n pi
```

Şimdi hatayı göreceksiniz.

</details>

OPA Gatekeeper politikası Pod'ların oluşturulmasını engelliyor — olaylarda
sebebini söyleyen iki uyarı mesajı var:

```
Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [resource-limits] container <pi-web> has no resource limits

Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [requiredlabels-pods] you must provide labels: {"version"}
```

Ama bunu Kubectl'de görmüyorsunuz, çünkü Pod'ları doğrudan siz
oluşturmuyorsunuz — bir Deployment oluşturuyorsunuz, o bir ReplicaSet
oluşturuyor, o da Pod'ları oluşturuyor.

[fix-2/deployment.yaml](./specs/pi/fix-2/deployment.yaml) içindeki Pod şablonu
gereken etiketleri ve kaynakları ekliyor.

📋 fix-2 YAML'ını dağıtın — uygulama şimdi çalışıyor mu?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

```
kubectl apply -f labs/admission/specs/pi/fix-2

kubectl get pods -n pi
```

İyi görünüyor :)

</details>

Uygulamayı şimdi http://localhost:30031 adresinde deneyin. Sınırlı miktarda
CPU ve bellekle çalışıyor ve operasyon açısından yönetimi kolay, çünkü tutarlı
bir etiket kümesine sahip.

## Lab

Sıra bir uygulama dağıtıp admission gereksinimlerini karşıladığından emin
olmada sizde.

Bu lab'ın belirtimlerinden demo Astronomy Picture of the Day uygulamasını
dağıtmayı deneyin:

```
kubectl apply -f labs/admission/specs/apod
```

Kaynaklar, yürürlükteki kısıtları karşılamadığı için başarısız olacak.
Göreviniz belirtimleri düzeltip uygulamayı çalıştırmak — politikalarda hiçbir
değişiklik yapmadan :)

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

Lab'ın tüm namespace'lerini kaldırın; bu diğer tüm nesneleri de kaldırıyor:

```
kubectl delete ns -l kubernetes.courselabs.co=admission
```

CRD'ler hariç:

```
kubectl delete crd -l gatekeeper.sh/system

kubectl delete crd -l gatekeeper.sh/constraint
```

Bir de - **bu onemli** - webhook yapilandirmalari:

```
kubectl delete validatingwebhookconfiguration servicetokenpolicy gatekeeper-validating-webhook-configuration cert-manager-webhook --ignore-not-found

kubectl delete mutatingwebhookconfiguration nonrootpolicy gatekeeper-mutating-webhook-configuration cert-manager-webhook --ignore-not-found
```

> Webhook yapilandirmalari **kume kapsamli**; namespace'leri silmek onlari
> kaldirmiyor. Geride birakirsaniz API sunucusu artik var olmayan bir webhook
> servisini cagirmaya devam eder ve **sonraki butun lablar** *"failed calling
> webhook ... service not found"* hatasiyla coker - namespace bile
> olusturamazsiniz. Bu duruma dusersiniz, yukaridaki iki komut kurtarir.

