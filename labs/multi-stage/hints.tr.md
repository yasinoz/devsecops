# Lab İpuçları

Uygulamanın [Dockerfile'ı](./whoami/Dockerfile) uygulamayı başlatmak için
`ENTRYPOINT` komutunu kullanıyor; dolayısıyla `docker run` komutuna
geçirdiğiniz argümanlar container'a aktarılıyor.

Dockerfile'daki `EXPOSE` komutu Docker'a uygulamanın hangi portları
dinlemesini beklediğini söylüyor. Bu bilgi imaja metadata olarak gömülüdür;
uygulamanın gerçekten dinlediği portlarla bir bağı yoktur.

Uygulama, imajın beklediğinden farklı bir portu dinliyorsa "tüm portları
yayınla" istediğinizi yapmaz.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
