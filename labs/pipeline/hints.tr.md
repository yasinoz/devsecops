# Lab İpuçları

Jenkinsfile'daki Docker Compose komutlarına dikkatli bakın; tam modeli
oluşturmak için zaten birden fazla Compose dosyası yüklediklerini
göreceksiniz.

Ek override dosyalarını kullanan **ilave** build ve push komutlarına
ihtiyacınız olacak, çünkü imajların doğru etiketle derlenmesi gerekiyor.

`latest` imaj etiketini çektiğinizde metadata'yı okumak için inceleyebilirsiniz.
Etiketlerin (label) içinde faydalı bilgiler bulacaksınız.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
