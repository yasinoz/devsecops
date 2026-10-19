# Lab Çözümü

Kubectl apply çıktısı ilk ihlali veriyor:

```
Error from server ([requiredlabels-ns] you must provide labels: {"kubernetes.courselabs.co"}): error when creating "labs//admission//specs//apod//01-namespace.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [requiredlabels-ns] you must provide labels: {"kubernetes.courselabs.co"}
```

Yani namespace belirtimine etiketi eklemeniz gerekiyor; benim çözümüm:

- [01-namespace.yaml](./solution/01-namespace.yaml)

Artık tüm kaynaklar oluşturulabiliyor, ama Deployment'lar hiçbir zaman hedef
ölçeğe ulaşmıyor:

```
kubectl get deploy -n apod
```

ReplicaSet'lerin ayrıntılarını alın (herhangi biri olur):

```
kubectl describe rs -n apod
```

Hataları göreceksiniz:

```
Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [resource-limits] container <web> has no cpu limit[requiredlabels-pods] you must provide labels: {"app", "version"} 
```

Pod belirtimlerinin etiketlere, container belirtimlerinin ise kaynak
limitlerine ihtiyacı var:

- [api.yaml](./solution/api.yaml)
- [log.yaml](./solution/log.yaml)
- [web.yaml](./solution/web.yaml)

Düzeltilmiş belirtimleri uygulayın:

```
kubectl apply -f labs/admission/solution
```

Deployment'ların tamamı hedef ölçeğe ulaşmalı ve uygulama
http://localhost:30016 adresinde çalışıyor olmalı.

___
> [Alıştırmalara](README.tr.md) dönün.
