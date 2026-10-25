# Lab İpuçları

Önce anahtarı depoya koyun. `sirli-depo` klasöründe yeni bir dosya
oluşturmanız yeterli — commit atmanıza gerek yok, çünkü `dir` komutu diskteki
dosyalara bakıyor.

Anahtarı koyduktan sonra bir tarama çalıştırın. Hiçbir şey bulunmaması normal:
gitleaks `SPS-` biçimini tanımıyor. Göreceğiniz bu "temiz" sonuç, alıştırmanın
başlangıç noktası.

Kendi kuralınız deponun kökündeki `.gitleaks.toml` dosyasına yazılıyor.
Gitleaks taradığı klasörde bu isimde bir dosya görürse onu kendiliğinden
kullanıyor, ayrıca bir bayrak geçmenize gerek yok.

Bir kural en az üç alan istiyor: bir `id`, bir `description` ve anahtarı
tarif eden bir `regex`. Kurallar `[[rules]]` başlığı altında yazılıyor —
çift köşeli parantez, çünkü birden fazla kural olabiliyor.

Düzenli ifadeyi `'''` üç tırnak arasına yazarsanız ters bölü kaçışlarıyla
uğraşmazsınız.

Son olarak şunu kontrol edin: kendi kuralınızı ekledikten sonra depodaki
GitHub jetonu hâlâ bulunuyor mu? Bulunmuyorsa yapılandırma dosyanız
varsayılan kuralları devre dışı bırakmış demektir — `[extend]` bölümüne
bakın.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
