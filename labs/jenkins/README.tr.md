---
title: Jenkins ile Otomasyon
lang: tr
slug: jenkins
section: cicd
order: 1
duration: 45
requires: [docker]
status: needs-review
upstream: labs/jenkins
---
# Jenkins ile Otomasyon

[Jenkins](https://jenkins.io) muhtemelen en yaygın kullanılan otomasyon
sunucusu — en çok sevilen değil, en çok kullanılan. Uzun zamandır hayatta ve
asıl özelliği genişletilebilirliği: 1.800'den fazla yayınlanmış eklentiden
oluşan bir çerçevesi var, bu sayede her tür uygulamayı derleyebiliyor ve her
üçüncü parti sistemle entegre olabiliyor. Job tanımlamak için bir web arayüzü
var ve bu tanımlar sunucunun dosya sisteminde saklanıyor.

Arayüz ve eklentiler aynı zamanda insanların Jenkins'ten hoşlanmama
sebepleri. Eklentiler düzenli olarak güvenlik bildirimlerine konu oluyor,
yani sık güncellenmeleri gerekiyor; ama otomatikleştirmeleri zahmetli.
Emekli olması gereken tarihten çok sonra hâlâ ayakta tutulan Jenkins
sunucuları görürsünüz — çünkü kimse tam o eklenti setini yeniden
oluşturabileceğinden ve job tanımlarını yeni sunucuya aktarabileceğinden emin
değildir.

Biz Jenkins'i tersinden kullanacağız: **en az eklenti, job tanımları kaynak
kontrolünde.**

## Kaynaklar

- [Jenkinsfile anlatımı](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/)
- [Declarative Pipeline sözdizimi](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Pipeline adım referansı](https://www.jenkins.io/doc/pipeline/steps/)
- [Configuration as Code (JCasC)](https://www.jenkins.io/projects/jcasc/)

## Jenkins'i Çalıştırmak

Jenkins'i ve yerel bir Git sunucusunu ([Gitea](https://about.gitea.com))
başlatın:

```
docker compose -f labs/jenkins/infra/docker-compose.yml up -d
```

> Jenkins imajı [bu Dockerfile ile](../../images/jenkins/Dockerfile)
> derleniyor. Eklentiler ve yönetici kullanıcısı
> [Configuration as Code](../../images/jenkins/casc.yaml) ile imaja gömülü
> geliyor; yani kurulum sihirbazı yok ve logların içinden
> `initialAdminPassword` kazıp çıkarmanız gerekmiyor.

İki container'ın da çalıştığını doğrulayın:

```
docker compose -f labs/jenkins/infra/docker-compose.yml ps
```

### Git sunucusunu hazırlayın

Gitea boş bir veritabanıyla açılıyor; kendinize bir kullanıcı oluşturun:

```
docker compose -f labs/jenkins/infra/docker-compose.yml exec -u git gitea gitea admin user create --admin --username student --password student --email student@labs.local --must-change-password=false
```

> `--must-change-password=false` önemli: bu olmadan Gitea ilk girişte parola
> değiştirmeye zorluyor ve lab'ın devamındaki Jenkins kimlik bilgileri
> çalışmıyor.

http://localhost:3000 adresinden Gitea'ya girin: `student` / `student`.

### Jenkins'e giriş yapın

http://localhost:8080 adresini açın. İlk açılışta bir dakika sürebilir —
Jenkins eklentilerini yüklüyor. Giriş bilgileri:

- kullanıcı: `student`
- parola: `student`

Arayüzü biraz gezin. Tam anlamıyla "web 1.0". Sol menüde ana seçenekler var,
_Manage Jenkins_ (Jenkins yönetimi) dahil; sayfanın ortası job oluşturduktan
sonra job listesini gösteriyor.

## Freestyle Job Oluşturmak

Klasik bir Jenkins job'ıyla başlayalım — adımları web arayüzünde tek tek
kurduğunuz *freestyle* tipi:

- ana ekranda _Create a job_ (job oluştur) tıklayın
- adını `lab-1` verin
- tipini _Freestyle project_ seçin
- _OK_ tıklayın

Yapılandırma sayfasında bir build'in tipik parçaları için bölümler var:
kaynak kod, build tetikleyicileri, build adımları.

Metin yazdıran basit bir script çalıştıracağız:

- _Build Steps_ bölümüne inin
- _Add build step_ tıklayın
- _Execute shell_ seçin
- _Command_ kutusuna şunu yapıştırın:

```
echo "This is build number: $BUILD_NUMBER of job: $JOB_NAME"
```

- _Save_ tıklayın

> Jenkins bir job'ı çalıştırırken
> [bir dizi ortam değişkeni](http://localhost:8080/env-vars.html/) tanımlıyor
> ve adımlarınız bunları okuyabiliyor. Bu script, her çalıştırmada artan build
> numarasını ve job adını yazdırıyor.

Artık job sayfasındasınız. Sol menüden yeniden yapılandırabilirsiniz; orta
bölüm son çalıştırmaları gösteriyor.

_Build Now_ tıklayın. Bittiğinde çıktıya bakın:
http://localhost:8080/job/lab-1/1/console

📋 Job'ı bir kez daha çalıştırın — çıktı nasıl değişti?

<details>
  <summary>Takıldınız mı?</summary>

Tekrar _Build Now_ tıklayın. Tamamlandığında çıktı burada:
http://localhost:8080/job/lab-1/2/console

Job adı aynı; build numarası bir arttı.

</details><br/>

Bu Jenkins sunucusunda gerçek bir pipeline'da kullanacağınız başka araçlar da
kurulu. Sürümlerini yazdırırsanız ne olur?

📋 Job'ı düzenleyip `javac` ve `docker` sürümlerini yazdırın, ardından
`kubectl get nodes` ile Kubernetes düğümlerini listeleyin.

<details>
  <summary>Nasıl yapılacağını bilmiyor musunuz?</summary>

Job sayfasında _Configure_ tıklayın. _Command_ kutusunu güncelleyin:

```
javac --version

docker version

kubectl get nodes
```

_Save_, sonra _Build Now_ tıklayın.

</details><br/>

Build **başarısız oluyor**. Shell komutları bir çıkış kodu döndürür: 0 başarı,
sıfır dışındaki her şey hata demektir. `javac` ve `docker` çalışıyor — Docker
komut satırı imajın içinde ve container'a host'un Docker socket'i bağlanmış
durumda. Ama `kubectl get nodes` konuşacak bir küme bulamıyor, sıfır dışında
bir kodla çıkıyor ve Jenkins adımı başarısız sayıyor.

Bu adımdan sonra başka adımlar olsaydı çalışmazlardı: job ilk hatada durur.

> Peki bu job tanımı tam olarak nerede duruyor? Jenkins sunucusunun dosya
> sisteminde. Yeni bir sunucuya nasıl taşırdınız? Üzerinde yapılan bir
> değişikliği nasıl gözden geçirirdiniz? İşte bu yüzden tanımı kaynak
> kontrolünde tutan [pipeline](https://www.jenkins.io/doc/book/pipeline/)
> yapısını kullanıyoruz.

## Pipeline'lar

Pipeline'lar hâlihazırda kurulu olan `workflow-aggregator` eklentisinden
geliyor. Bir pipeline job'ı, declarative sözdizimiyle yazılmış bir script'i —
*Jenkinsfile*'ı — çalıştırır.

> Bu lab'ın eski sürümü görsel pipeline editörü için *Blue Ocean* arayüzünü
> kullanıyordu. Blue Ocean artık bakımlı değil; Jenkins bugün yerleşik Pipeline
> arayüzünü ve Stage View'ı sunuyor, biz de onu kullanacağız.

Yeni bir job oluşturun:

- http://localhost:8080/view/all/newJob adresini açın
- adını `lab-2` verin
- tipini _Pipeline_ seçin
- _OK_ tıklayın

Sayfanın altındaki _Pipeline_ bölümüne inin. Tanımı _Pipeline script_ olarak
bırakıp şunu yapıştırın:

```
pipeline {
    agent any
    stages {
        stage('Audit') {
            steps {
                echo "This is build number: ${env.BUILD_NUMBER} of job: ${env.JOB_NAME}"
                sh 'javac --version'
            }
        }
    }
}
```

_Save_, sonra _Build Now_ tıklayın.

📋 Job sayfasını açın. Freestyle job'a göre görünüm nasıl farklı?

<details>
  <summary>Takıldınız mı?</summary>

**Stage View** görüyorsunuz — her aşama için bir kolon içeren, her birinin ne
kadar sürdüğünü ve geçip geçmediğini gösteren bir tablo. Tek aşamayla etkileyici
değil; aşama ekledikçe build'in zamanını nerede harcadığını ve nerede
kırıldığını görmenin en hızlı yolu oluyor.

Build'e girip _Console Output_ ile tam logu görebilirsiniz.

</details><br/>

Bu freestyle job'dan iyi, ama tanım hâlâ Jenkins'in içinde duruyor. Sırada onu
Git'e taşımak var.

## Pipeline'ları Kaynak Kontrolünde Tutmak

Sırada [bu Jenkinsfile](./manual-gate/Jenkinsfile) var. Birkaç aşaması var ve
ilginç olanı _Deploy_: devam etmeden önce bir insandan onay istemek için
`input` bloğu kullanıyor.

Önce Jenkins'in çekebilmesi için lab reposunu yerel Git sunucumuza koymamız
gerekiyor.

http://localhost:3000 adresindeki Gitea'da sağ üstteki **+** işaretine tıklayıp
_New Repository_ seçin:

- _Repository Name_ alanına `devsecops` yazın
- diğer her şeyi varsayılan bırakın
- _Create Repository_ tıklayın

Şimdi yerel Gitea sunucunuzu bu repoya remote olarak ekleyip push edin:

```
git remote add gitea http://localhost:3000/student/devsecops.git

git push gitea main
```

> Git istemciniz kimlik bilgisi soracak — `student` / `student` girin.

http://localhost:3000/student/devsecops adresine bakın, tüm lab içeriğini
göreceksiniz. Kendi özel GitHub'ınız.

Jenkins'e dönüp http://localhost:8080/view/all/newJob adresinde bir job daha
oluşturun:

- adını `manual-gate` verin
- tipini _Pipeline_ seçin
- _OK_ tıklayın

_Pipeline_ bölümüne inin:

- _Definition_ alanını **Pipeline script from SCM** yapın
- _SCM_ alanını **Git** yapın
- _Repository URL_ alanına `http://gitea:3000/student/devsecops.git` yazın
- _Credentials_ yanındaki _Add_ → _Jenkins_ ile bir **Username with password**
  kimlik bilgisi ekleyin: kullanıcı `student`, parola `student`. Sonra açılır
  listeden seçin.
- _Branch Specifier_ alanını `*/master` yerine `refs/heads/main` yapın
- _Script Path_ alanına `labs/jenkins/manual-gate/Jenkinsfile` yazın

> Jenkins host adı olarak `localhost` değil `gitea` kullanıyor. İki container
> aynı Docker ağında olduğu için Jenkins `gitea` adını DNS ile çözüyor. *Sizin*
> makinenizden aynı sunucu `localhost:3000`, çünkü yayınlanmış port o.

Kaydedip build'i çalıştırın. _Build_ ve _Test_ aşamalarını geçiyor, sonra
duruyor ve sizi bekliyor.

📋 Job arayüzünde _Deploy_ aşamasının devam etmesini ve build'in bitmesini nasıl
sağlarsınız?

<details>
  <summary>Takıldınız mı?</summary>

Stage View her aşama için bir kutu gösteriyor; tamamlananlar yeşil. _Deploy_
kutusu duraklatılmış durumda bekliyor.

![Jenkins manuel onay noktasında bekliyor](../../img/jenkins-manual-gate.png)

Duraklatılmış aşamanın üzerine gelip çıkan isteme tıklayın (ya da build'i açıp
_Paused for Input_ bağlantısını kullanın). Jenkinsfile'da tanımlanmış onay
penceresi açılacak. _Do it!_ tıklayın, build devam edecek.

</details><br/>

`input` blokları gerçekten faydalı: dağıtımın tamamını otomatikleştirip, insan
kararının önemli olduğu noktada yine de onay isteyebiliyorsunuz.

## Lab

Sıra sizde. Bu repoda basit bir Java uygulaması derleyip çalıştıran başka bir
pipeline var. [Jenkinsfile](hello-world/Jenkinsfile) şu yolda:
`labs/jenkins/hello-world/Jenkinsfile`

- bu pipeline'ı çalıştıracak yeni bir job oluşturun
- SCM'i her dakika değişiklik için yoklayan bir build tetikleyicisi ekleyin
- build başarısız olacak :) Jenkinsfile'ı düzeltip değişikliği Gitea
  sunucunuza push etmeniz gerekecek
- build çalıştığında derlenmiş ikili dosyalar nereye gidiyor?

Düzeltmenizi push etmek için:

```
git add labs/jenkins/hello-world/Jenkinsfile

git commit -m 'Lab solution'

git push gitea main
```

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.

___
## Temizlik

Lab container'larını kaldırın:

```
docker compose -f labs/jenkins/infra/docker-compose.yml down
```

Sonraki lablarda kafa karıştırmaması için Gitea remote'unu kaldırın:

```
git remote rm gitea
```
