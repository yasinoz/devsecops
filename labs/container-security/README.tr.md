---
title: Container Güvenlik Kontrolleri
lang: tr
slug: container-security
section: security
order: 6
duration: 50
requires: [docker, kubernetes]
status: needs-review
upstream: labs/container-security
---
# Container Güvenliği

Uygulamalarınızı Kubernetes'te modelleyip çalıştırmak oldukça kolay, ama
üretime geçmeden önce yapılacak daha çok iş var — ve güvenlik bunların başında
geliyor.

Kubernetes'te uygulama güvenliği çoğunlukla container'ları güvenceye almakla
ilgilidir; o da çoğunlukla Linux güvenlik önlemlerini uygulamakla ilgilidir.
Uygulayabileceğiniz çok sayıda kontrol var, ama her uygulama hepsini
desteklemiyor.

Uygulamalarınızın hangi işletim sistemi özelliklerine ihtiyaç duyduğunu
anlamanız gerekiyor, çünkü kontrol uygulamak onları bozabilir — Go
uygulamaları salt okunur bir dosya sisteminde sorunsuz çalışabilirken Java
uygulamaları hata verecektir.

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

Süre: yaklaşık 50 dakika.

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

- [Kubernetes güvenlik rehberi](https://kubernetes.io/docs/concepts/security/)

- [Pod container'ları için kaynak yönetimi](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)

- [Kubernetes için OWASP kopya kağıdı](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

- [CKS — Certified Kubernetes Security Specialist sertifikası](https://www.cncf.io/certification/cks/)

- [NSA ve CISA'dan küme sıkılaştırma rehberi (pdf)](https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF)

## Kubernetes API sunucusuna erişimi kaldırmak

Varsayılan Kubernetes güvenlik kontrolleri cesaret verici değil.

Pi web uygulamasını çalıştırarak başlayalım; güvenlik sorunlarını kontrol
etmek için onu kullanacağız:

```
kubectl apply -f labs/container-security/specs/pi
```

Pi uygulaması tek bir Pod'da çalışıyor ve siteyi Service üzerinden
http://localhost:30020 adresinde kontrol edebilirsiniz.

[Deployment belirtiminde](./specs/pi/deployment.yaml) güvenlikle ilgili özel
bir şey yok.

Kubernetes varsayılan olarak her Pod'a, içinde bir kimlik doğrulama token'ı
bulunan bir volume bağlıyor; böylece Pod içindeki uygulamalar Kubernetes API
sunucusunu kullanabiliyor. Prometheus ve Fluentd gibi uygulamalar Pod'ları ve
diğer nesneleri bulabilmek için API erişimine ihtiyaç duyuyor — ama neredeyse
hiçbir iş uygulamasının buna ihtiyacı yok.

Token Pi uygulamasında da duruyor:

```
kubectl exec deploy/pi-web -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

Kubernetes kümesiyle kimlik doğrulaması yapmak için gereken tek şey bu (bu tür
token'ları Kubectl ile kullanabilirsiniz) ve ardından Pod ile tamamen aynı
izinlere sahip olurdunuz.

> Kubernetes 1.21'den beri bunlar *bound* (bağlı) token'lar — kısa ömürlü ve bu
> Pod ile hedef kitleye bağlı, dolayısıyla çalınan bir token'ın süresi doluyor.
> Bu, etki alanını küçültüyor; ortadan kaldırmıyor — bu yüzden volume'u yine de
> kaldırıyoruz.

Bu Pod, varsayılan
[Service Account](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)'u
kullanıyor — Pod'ların API'ye erişmek için kullandığı Kubernetes kimliği. Başka
kullanıcılar kendi ihtiyaçları için o hesaba ek izinler vermiş olabilir ve bir
saldırgan Pi uygulamasını ele geçirirse Secret'ları okumaya veya çalışan
uygulamaları silmeye serbest erişimi olabilir.

[fix-1.yaml](./specs/pi/fixes/fix-1.yaml), kimlik doğrulama token'ını
bağlamayacak şekilde ayarlanmış özel bir ServiceAccount oluşturuyor ve Pod
belirtimi o hesabı kullanıyor.

📋 Düzeltmeyi uygulayın. Yeni Pod'da token'ı okuyabiliyor musunuz?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Değişiklikleri gönderin:

```
kubectl apply -f labs/container-security/specs/pi/fixes/fix-1.yaml
```

Yeni Pod'un başlamasını bekleyin:

```
kubectl get po -l app=pi-web --watch
```

Ve token'ı yazdırmayı deneyin:

```
# bir hata goreceksiniz - No such file or directory
kubectl exec deploy/pi-web -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

</details>

Bu, bir güvenlik açığını kapatıyor. Kararlı saldırganları durdurmayacak ama
işlerini bu kadar kolaylaştırmıyor.

## Hesaplama kaynaklarını kısıtlamak

Container süreçleri doğrudan host makinenin işletim sistemi üzerinde çalışıyor.
Varsayılan olarak o makinedeki tüm CPU çekirdeklerine ve tüm belleğe
erişebiliyorlar. Kubernetes kümelerinde genellikle her düğümde bol miktarda Pod
çalışıyor ve hesaplama kaynaklarını kısıtlamazsanız kendinizi bir hizmet
engelleme (denial-of-service) saldırısına açık bırakıyorsunuz.

Pi uygulaması hiçbir hesaplama kısıtı olmadan çalışıyor. Pi'yi yüksek sayıda
ondalık basamakla hesaplamayı deneyin — **bu URL için iki sekme açın**:
http://localhost:30020/pi?dp=100000. Makinenizin CPU'suna bakın; Pi hesaplamak
zahmetli bir iş olduğu için tırmandığını görebilirsiniz.

[fix-2.yaml](./specs/pi/fixes/fix-2.yaml) kaynak kısıtları uyguluyor:

- `requests`, uygulamanızın çalışmak için ihtiyaç duyduğu CPU ve bellek
  miktarını belirtiyor; Kubernetes, Pod'u hangi düğümün çalıştıracağına karar
  verirken düğümlerdeki mevcut kaynak miktarına göre bunu kullanıyor

- `limits`, uygulamanın kullanabileceği CPU ve belleğin katı üst sınırını
  belirtiyor. CPU kısıtlanıyor; yani 0.5 çekirdek ayarlarsanız uygulama %100
  CPU'da çalışabilir ama sunucuda yalnızca 0.5 çekirdeği doldurabilir. Bellek de
  kısıtlanıyor ve uygulama limitin üzerine çıkmaya çalışırsa Pod bellek yetmedi
  (out-of-memory) hatasıyla öldürülebilir.

📋 Düzeltmeyi uygulayın. Pi'yi 100 bin basamağa hesaplamak hâlâ CPU
tırmanmasına yol açıyor mu?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>
  
Değişiklikleri gönderin:

```
kubectl apply -f labs/container-security/specs/pi/fixes/fix-2.yaml
```

Yeni Pod'un başlamasını bekleyin:

```
kubectl get po -l app=pi-web --watch
```

http://localhost:30020/pi?dp=100000 adresini açın — makinenizin CPU'sunda bir
etki görmemelisiniz ama sayfanın yanıt vermesi **çok** daha uzun sürecek.

</details>

Kaynak limitleri, hizmet engelleme saldırısını önlemenin basit bir yolu; ama
uygulamanızın etkili çalışmaya yetecek kaynağa sahip olduğundan emin olmak için
zaman içinde onları değerlendirmeye devam etmeniz gerekiyor (umarız uygulamanız
zamanla daha performanslı olur ve her sürümde limitleri düşürebilirsiniz).

## İşletim sistemi yeteneklerini kısıtlamak

Container süreçleri sunucuda, sunucudaki bir kullanıcıya karşılık gelen bir
kimlikle çalışıyor. Çok sayıda container imajı — resmi imajlar bile — uygulama
süreci için `root` kullanıcısını kullanıyor.

Bu çok kötü. Bir saldırgan container'dan dışarı çıkmayı başarırsa (bu tür
istismarlar keşfedildi), sunucudaki yönetici kullanıcı olur. Yani sunucudaki
diğer container'lara saldırabilir ya da ağdaki başka makinelere erişebilir.

Pi uygulamasının kullanıcı hesabını kontrol edin:

```
kubectl exec deploy/pi-web -- whoami
```

`root` — ve bu imaj kasıtlı olarak güvensiz yapılmış değil.
[Dockerfile'a](https://github.com/sixeyed/kiamol/blob/master/ch05/docker-images/pi/Dockerfile)
bakın — Microsoft'un resmi ASP.NET çalışma ortamı imajını hiçbir özel kurulum
olmadan kullanıyor.

Container süreçleri, standart Kubernetes yapılandırmasıyla ihtiyaç
duyduklarından fazla
[Linux yeteneğine (capability)](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
de sahip. `chown`, dosya sahipliğini değiştirmenizi sağlayan bir Linux komutu —
Pi container'ında mevcut:

```
kubectl exec deploy/pi-web -- chown root:root /app/Pi.Web.dll
```

[fix-3.yaml](./specs/pi/fixes/fix-3.yaml) container'ı root olmayan bir
kullanıcı olarak çalıştırıyor, fazla Linux yeteneklerinin tamamını düşürüyor
(uygulamanın onlara ihtiyacı yok) ve süreçlerin ek ayrıcalık istemesini
engelliyor.

📋 Düzeltmeyi uygulayın. Uygulama nasıl görünüyor?

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>
  
Değişiklikleri gönderin:

```
kubectl apply -f labs/container-security/specs/pi/fixes/fix-3.yaml
```

Yeni Pod'un başlamasını bekleyin:

```
kubectl get po -l app=pi-web --watch
```

http://localhost:30020/ adresini açın — uygulama hâlâ çalışıyor.

</details>

Bu uygulama beklendiği gibi çalışmaya devam ediyor, ama bazı uygulamalarda izin
kaldırmak onların hiç başlamaması anlamına geliyor — kısıtlı yeteneklerle 80
portunu dinlemek başarısız olabilir.

[fix-4.yaml](./specs/pi/fixes/fix-4.yaml) uygulamayı container içinde 5001
portunu dinleyecek şekilde yapılandırıyor; böylece 80 portu için ayrıcalıklı
erişim ihtiyacı ortadan kalkıyor — uygulamanın bunu desteklemesi gerekiyor.

```
kubectl apply -f labs/container-security/specs/pi/fixes/fix-4.yaml
```

> Container portu değişmiş olmasına rağmen uygulama http://localhost:30020
> adresinde çalışmaya devam ediyor, çünkü [Service](./specs/pi/service.yaml)
> hedef portu numarayla değil **adıyla** (`http`) gösteriyor. Orada `80`
> sabitlenmiş olsaydı Service hiçbir şeye işaret etmez hale gelirdi.

___
## Lab

Bu, güvenliğin sonu değil — yalnızca başlangıcı. Container'ları güvenceye almak
imajlarınızı güvenceye almakla başlayan katmanlı bir yaklaşım; ama
sıkılaştırılmış Pi uygulaması varsayılan Pod güvenliğinden iyi bir adım ileride.

Yine de her uygulama bu kontrollerle çalışmayacak. İşte tüm güvenlik
kontrolleri yorum satırına alınmış
[whoami uygulaması için bir Deployment](./specs/whoami/deployment.yaml).

Göreviniz, uygulamayı bozmadan hangi kontrol kümesinin uygulanabileceğini
çözmek. Olduğu gibi dağıtarak başlayın:

```
kubectl apply -f labs/container-security/specs/whoami
```

Uygulamayı http://localhost:30022/ adresinde kullanabildiğinizi doğrulayın.
Sonra uygulama hâlâ çalışır durumda kalacak şekilde, mümkün olan en çok
kontrolü etkinleştirene kadar güvenlik kontrollerini ekleyin.

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

```
kubectl delete all -l kubernetes.courselabs.co=container-security
```
