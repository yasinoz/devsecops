# Lab İpuçları

Yeni job'ınız az önce oluşturduğunuz `manual-gate` job'ına çok benzeyecek —
aynı tip job, farklı bir script yolunu gösteriyor. Hepsini yeniden yazmak
yazık olur; yeni job'ı oluştururken mevcut bir job'ı kopyalamanın bir yolunu
arayın.

İhtiyacınız olan build tetikleyicisi job yapılandırmasındaki _Triggers_
bölümünde. Git sunucusuna belirli aralıklarla "değişen bir şey var mı?" diye
soran seçeneği arıyorsunuz.

Build çalıştığında bol miktarda konsol çıktısı üretiyor. Hata orada — en alta
kaydırmak yerine kırmızıya dönen aşamanın logunu okuyun.

Jenkinsfile'ı düzelttikten sonra commit ve push yapmanız gerekecek.
Tetikleyiciniz doğru kurulduysa hiçbir şeye tıklamanız gerekmez; sonraki
yoklama değişikliği görüp build'i başlatır.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
