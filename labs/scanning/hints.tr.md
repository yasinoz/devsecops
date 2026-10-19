# Lab İpuçları

Bu, sıradan bir Docker build'i. Son uygulama aşaması, tarama aşamasından bir
metin dosyası kopyalıyor — bu, BuildKit kullanırken taramanın çalışmasını
garanti etmek için.

Uygulama aşamasının `FROM` imajı .NET çalışma ortamını kullanıyor ama minimal
bir imaj değil.
[Docker Hub'daki .NET çalışma ortamı imajlarına](https://hub.docker.com/_/microsoft-dotnet-runtime/)
bakıp minimal bir işletim sistemine dayanan 10.0 sürümünü bulun.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
