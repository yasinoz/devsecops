# Lab İpuçları

Kalan bulguların hangi kaynağa ait olduğunu çıktıdan okuyabilirsiniz. Trivy
her bulgunun altında dosya adını, satır numarasını ve kod parçasını yazıyor —
satır numaralarına bakın, hepsi aynı yere işaret ediyor.

Ana kovaya verdiğiniz her koruma için kayıt kovasında da bir eşi gerekiyor:
şifreleme yapılandırması, sürümleme, halka açıklık engeli. Yazdığınız
blokların aynısını ikinci kova için tekrarlamanız yeterli — yalnızca `bucket`
alanını ve kaynak adını değiştireceksiniz.

Kayıt kovasının kendi erişim kaydı biraz düşündürüyor: kayıtlar bir kovaya
yazılıyorsa, o kovanın kayıtları nereye yazılacak? Sonsuza kadar yeni kova
açamazsınız. Bir yerde durmanız gerekiyor ve Terraform bunu engellemiyor.

`AWS-0104` için `cidr_blocks` alanına bakın. Portu daralttınız ama o alan
hâlâ "her yer" diyor. Çıkışın gerçekten nereye gitmesi gerektiğini düşünün —
şirket vekil sunucusunun aralığı gibi somut bir şey.

Son adımda `istisna.yaml` dosyasından kaydı sildiğinizde kapı hâlâ geçmeli;
geçmiyorsa `AWS-0104` düzeltmeniz tutmamış demektir.

> Daha fazlası lazım mı? [Çözüm](solution.tr.md) burada.
