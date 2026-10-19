# Lab İpuçları

Java kurmayı düşünmeyin — resmi
[Eclipse Temurin](https://hub.docker.com/_/eclipse-temurin) imajı bunu sizin
için yapıyor. (Docker Hub'ın eski `openjdk` imajı kullanımdan kaldırıldı, ona
uzanmayın.) Uygulama Java 8 ile derlendi ama yeni JVM'ler eski class
dosyalarını çalıştırmaya devam ediyor, dolayısıyla güncel bir JRE sorun değil.

Dockerfile'ın kendisi basit olacak, ama yolları düşünmeniz gerekiyor. Java
class dosyası Dockerfile'ınızdan farklı bir dizinde olabilir ve Docker
ikisine de context üzerinden erişmek zorunda.

Bir de container içindeki `java` komutunun, imaja kopyaladığınız class
dosyasını bulabilmesi için doğru yolu kullanması gerekiyor.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
