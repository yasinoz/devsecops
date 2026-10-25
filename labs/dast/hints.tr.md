# Lab İpuçları

Önce bulgunun ne dediğini okuyun. ZAP raporunda `10055` bulgusunun açıklaması
hangi yönergelerin eksik olduğunu adlarıyla yazıyor — tahmin etmenize gerek
yok.

Sorunun kaynağı şu: `default-src` bir *geri düşme* (fallback) kuralı, ama
bütün yönergeler ona düşmüyor. Form gönderiminin nereye gidebileceği,
sayfanın hangi çerçeveleri gömebileceği ve eklenti içeriğinin nereden
gelebileceği ayrı ayrı söylenmek zorunda.

CSP satırındaki yönergeler noktalı virgülle ayrılıyor. Mevcut satıra yeni
yönergeleri eklemeniz yeterli, baştan yazmanıza gerek yok.

Değişikliği yaptıktan sonra container'ı `--force-recreate` ile yeniden
başlatmayı unutmayın; yoksa nginx eski yapılandırmayla çalışmaya devam eder.

İkinci adımda `kurallar.conf` dosyasındaki `10055` satırını `IGNORE` yerine
`WARN` yapıyorsunuz. Bunu yaptıktan sonra kapının hâlâ geçmesini bekliyoruz —
çünkü bulgu artık hiç çıkmıyor. Geçmiyorsa CSP düzeltmeniz eksik kalmış
demektir.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
