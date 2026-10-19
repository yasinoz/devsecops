# Lab Çözümü

Çözümümde replica sayısını ve container imajını burada ayarladım:
[lab/deployment.yaml](./lab/deployment.yaml).

O dosyanın içeriğini
[project/whoami/deployment.yaml](./project/whoami/deployment.yaml) dosyasına
kopyalayıp değişikliklerinizi gönderebilirsiniz:

```
git add labs/argo/project/whoami/deployment.yaml

git commit -m 'Bump to build -4'

git push labs-argo main
```

https://localhost:30881/applications/whoami adresindeki ArgoCD web sayfasına
hızlıca dönerseniz iki eski Pod'un kaldırıldığını ve üç yeni Pod'un
başlatıldığını göreceksiniz.

Kendi kendini iyileştirme özelliğini test etmek için Deployment'ı
silebilirsiniz; bu tüm Pod'ları silecek:

```
kubectl delete deploy whoami
```

Web arayüzünü yeniden kontrol edin; silinenlerin yerine yeni Pod'ların
oluşturulduğunu göreceksiniz.

Uygulamayı http://localhost:30010 adresinde test edin; hâlâ çalıştığını
göreceksiniz.

___
> [Alıştırmalara](README.tr.md) dönün.
