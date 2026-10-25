# Lab İpuçları

`app-01` için tabloyu doldururken şunu hatırlayın: bileşenin kendi ayarları
kadar, **kendisine kimin bağlanabildiği** ve **kendisinin neye
bağlanabildiği** de tehdit üretiyor. app-01 bu sistemde ortada duruyor, yani
iki tarafı birden var.

Sistem tanımındaki şu üç ayrıntı en az üç tehdit üretiyor: parolanın
`config.properties` dosyasında düz metin olması, 8080 portunun iç ağdan
erişilebilir olması, ve günlüklerin sunucunun kendi diskinde durması.

Bir harf için satır bulamıyorsanız zorlamayın. "Bu bileşende inkâr tehdidi
yok" demek geçerli bir cevap — ama nedenini yazın. Boş bırakılan harf ile
"baktık, yok" arasındaki fark, modeli altı ay sonra okuyan kişi için çok
büyük.

Karar bölümünde "Kabul et" seçeneğini doldururken şunu test edin: gerekçeyi
okuyan biri *neden* kabul edildiğini anlıyor mu, yoksa yalnızca *kabul
edildiğini* mi? "Şimdilik yapamıyoruz" bir gerekçe değil; "yapmak için X
gerekiyor, X şu tarihte geliyor" gerekçedir.

CI/CD hattını modellerken en verimli soru şu: **hattın kendisini kim
değiştirebiliyor?** Jenkinsfile depoda duruyorsa, o depoya yazabilen herkes
üretime dağıtım yapabiliyor demektir.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
