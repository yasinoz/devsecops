# Lab Çözümü

En hızlı yol, elinizdeki job'ı kopyalamak:

- http://localhost:8080/view/all/newJob adresini açın
- job adını `hello-world` yapın
- tipini _Pipeline_ seçin
- en alttaki _Copy from_ kutusuna `manual-gate` yazın
- _OK_ tıklayın

Job yapılandırmasında _Triggers_ bölümüne inip **Poll SCM**'i işaretleyin. Bu,
Git sunucusunu değişiklik için yoklayacak bir zamanlama kuruyor. _Schedule_
kutusuna şunu yazın:

```
* * * * *
```

> Beş yıldız "her dakika" demek. Jenkins repoyu kontrol ediyor ve son build'den
> bu yana bir değişiklik olduysa yeni bir build tetikliyor. Yoklama (polling),
> webhook'a göre israf; ama Git sunucusunun Jenkins'e erişebilmesini
> gerektirmediği için hâlâ yaygın.

_Script Path_ alanını `labs/jenkins/hello-world/Jenkinsfile` yapın, kaydedip
build alın. **Başarısız oluyor.**

Build'i açıp konsol çıktısını okuyun. _Test_ aşaması şu hatayla kırılıyor:

```
Error: Could not find or load main class HelloWorkd
```

`HelloWorkd`. Bu bir yazım hatası — sınıfın adı `HelloWorld`.

`labs/jenkins/hello-world/Jenkinsfile` içindeki `java HelloWorkd` satırını
`java HelloWorld` olacak şekilde düzeltin. Karşılaştırmak isterseniz düzeltilmiş
hâli [bu Jenkinsfile'da](./lab/Jenkinsfile).

Sonra commit ve push:

```
git add labs/jenkins/hello-world/Jenkinsfile

git commit -m 'Fix class name typo'

git push gitea main
```

Jenkins'e dönün ve SCM yoklamasının build'i tetiklemesi için bir dakika kadar
bekleyin (ya da sabrınız yoksa _Build Now_ tıklayın).

Bu kez geçiyor. Build sayfasında `HelloWorld.class` dosyasını içeren bir
**Archived Artifacts** bölümü göreceksiniz — bu, Jenkinsfile'daki
`post { success { ... } }` bloğundaki `archiveArtifacts` adımından geliyor.
Arşivleme, workspace temizlendikten sonra build çıktısını saklamanın yoludur.

___
> [Alıştırmalara](README.tr.md) dönün.
