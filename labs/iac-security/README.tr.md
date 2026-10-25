---
title: Altyapı Kodunun Güvenliği
lang: tr
slug: iac-security
section: security
order: 9
duration: 45
requires: [docker]
status: updated
upstream: labs/iac-security
---
# Altyapı Kodunun Güvenliği

Sunucuyu, depolama kovasını, güvenlik grubunu artık arayüzden tıklayarak
kurmuyoruz; bir dosyaya yazıp uyguluyoruz. Buna **IaC** (Infrastructure as
Code) diyoruz ve getirdiği şey tekrarlanabilirlik: aynı dosya aynı altyapıyı
kuruyor.

Ama tekrarlanabilirlik iki yönlü çalışıyor. Arayüzden yapılan yanlış bir
ayar bir sunucuyu etkiliyor; **kodda duran yanlış bir ayar, o kod her
uygulandığında yeniden üretiliyor.** Üç ortam, on hesap, otomatik ölçekleme —
hepsi aynı hatayı taşıyor. Hatanın kendisi de aynı kalıyor, çünkü kimse artık
elle düzeltmiyor.

İyi haber şu: altyapı artık bir metin dosyası olduğu için, **kurulmadan önce
okunabiliyor**. Bu labda yazdığımız Terraform kodu hiçbir yere
uygulanmayacak. AWS hesabı yok, kimlik bilgisi yok, `terraform apply` yok.
Tarayıcı dosyayı okuyacak ve kurulacak olan kovanın halka açık olacağını
söyleyecek — kova daha var olmadan.

Aracımız yine [Trivy](https://trivy.dev/). İmaj taramasında paketlere
bakmıştı; `config` komutuyla Terraform, CloudFormation, Kubernetes ve
Dockerfile dosyalarındaki yanlış yapılandırmalara bakıyor.

<!-- outcomes:auto -->
<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 45 dakika.

**Docker Desktop** çalışıyor olmalı. Kontrol edin:

```
docker version
```

Çıktıda bir `Server:` bölümü görüyorsanız hazırsınız. Onun yerine hata
alıyorsanız Docker Desktop'ı başlatın ve balina simgesi hareket etmeyi
bırakana kadar bekleyin.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Bu lab ne işe yarıyor

Arayüzden yapılan yanlış bir tık bir sunucuyu etkiliyor; altyapı kodundaki yanlış bir satır, o kod her uygulandığında her ortamda yeniden kuruluyor. Buna karşılık altyapı artık bir metin dosyası, yani hiçbir şey kurulmadan okunabiliyor — halka açık olacak kova hiç var olmuyor.

**Bu labdan sonra şunları yapabileceksiniz:**

- Terraform'u hiçbir yere uygulamadan yanlış yapılandırmaya karşı taramak
- aracın verdiği önem derecesiyle kendi önceliğinizi ayırmak
- bir kuralı düzeltmenin aynı kurallara tabi yeni altyapı doğurduğunu görmek
- unutulan değil, süresi kendiliğinden dolan bir istisna yazmak
<!-- /outcomes:auto -->

<!-- orientation:auto -->
## Bu lab nasıl işliyor

Bunu bir kez okuyun - bu eğitimdeki her lab aynı kurallarla yazıldı.

**Komutları nereye yazacaksınız.** Bir terminal açın ve bu depoyu kopyaladığınız
klasöre gidin. Windows'ta **PowerShell** kullanın (Başlat menüsünde aratın),
macOS veya Linux'ta **Terminal**. Labdaki bütün yollar depo kökünden yazıldı,
yani bir adım aksini söylemedikçe orada kalın.

**`>` ile başlayan satırlar açıklamadır, komut değildir.** Onları yapıştırmayın.
Yalnızca gri kod kutularının içindeki metin yazılır.

**📋 işareti "sıra sizde" demektir.** Onu gördüğünüzde adımı önce kendiniz
deneyin. Hemen altında cevabı saklayan kapalı bir **"Nasıl yapılır?"** oku var;
onu denedikten *sonra* açın, önce değil. Lablar bilerek böyle yazıldı: kendi
çözdüğünüz şeyi hatırlarsınız, yapıştırdığınızı değil.

**Bir komut hata verirse bu normal olabilir.** Bazı adımlar hatanın nasıl
göründüğünü göstermek için bilerek başarısız olur. Bir şeyin bozuk olduğuna
karar vermeden önce komutun üstündeki cümleyi okuyun.

**Takılırsanız** şu sırayla:

1. Komutun üstündeki paragrafı tekrar okuyun - cevap genelde oradadır.
2. **"Nasıl yapılır?"** okunu açın.
3. `hints.md` dosyasını açın, küçük bir yönlendirme verir.
4. `solution.md` dosyasını açın, tam cevap orada. Kullanmak serbest; okumadan
   kopyalamak değil.

**Bitirdiğinizde** en alttaki **Temizlik** bölümünü çalıştırın. Lablar aynı
portları ve container adlarını paylaşıyor; birinden kalan artık diğerini bozar.
<!-- /orientation:auto -->

## Kaynaklar

- [Trivy — Yanlış yapılandırma taraması](https://trivy.dev/latest/docs/scanner/misconfiguration/)

- [AWS Vulnerability Database — kontrol listesi](https://avd.aquasec.com/misconfig/)

- [OWASP Top 10 — A05:2021 Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/)

- [NIST SSDF (SP 800-218) PW.9 — güvenli varsayılan yapılandırma](https://csrc.nist.gov/pubs/sp/800/218/final)

## Altyapıyı okumak

`labs/iac-security/altyapi/main.tf` dosyasını editörünüzle açın. Uzun değil:
bir S3 kovası, kovanın halka açıklık ayarları ve bir güvenlik grubu.

Okurken şunu arayın: **kasıtlı olarak eklenmiş bir açık görüyor musunuz?**

Göremezsiniz, çünkü yok. Bu dosya bir Terraform dosyasının sıradan hâli.
Kovayı tanımlıyor, grubu açıyor, çalışıyor. Söylenmeyen her şey sağlayıcının
varsayılanına düşüyor — ve bulutta varsayılanlar güvenli değil, *kolay*.

## İlk tarama

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi -q
```

> İlk çalıştırmada Trivy kontrol paketini (checks bundle) internetten
> indiriyor, birkaç saniye sürüyor. Sonraki çalıştırmalarda önbellekten
> okuyor. İnternet erişimi olmayan bir ortamda bu adım başarısız olur.

```
Failures: 12 (UNKNOWN: 0, LOW: 4, MEDIUM: 1, HIGH: 6, CRITICAL: 1)
```

12 bulgu:

```
AWS-0086 (HIGH):     Public access block does not block public ACLs
AWS-0087 (HIGH):     Public access block does not block public policies
AWS-0089 (LOW):      Bucket has logging disabled
AWS-0090 (MEDIUM):   Bucket does not have versioning enabled
AWS-0091 (HIGH):     Public access block does not ignore public ACLs
AWS-0093 (HIGH):     Public access block does not restrict public buckets
AWS-0099 (LOW):      Security group explicitly uses the default description.
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
AWS-0107 (HIGH):     Security group rule allows unrestricted ingress from any IP address.
AWS-0124 (LOW):      Security group rule does not have a description.
AWS-0124 (LOW):      Security group rule does not have a description.
AWS-0132 (HIGH):     Bucket does not encrypt data with a customer managed key.
```

Çıktıda her bulgunun altında dosya adı, satır numarası ve ilgili kod
parçası duruyor. Bir de `https://avd.aquasec.com/misconfig/aws-0086` gibi bir
bağlantı — açın, kuralın neden var olduğu orada yazıyor.

### Burada ne oldu

Bu taramada **hiçbir şey kurulmadı**. Terraform çalışmadı, bir API çağrısı
yapılmadı, bir hesaba bağlanılmadı. Trivy HCL dosyasını okudu ve "bu kod
uygulanırsa ortaya çıkacak kaynak şu kurallara uymuyor" dedi.

Aynı bulguyu çalışan altyapıda bulmanın yolu da var — bulut güvenlik duruşu
araçları bunu yapıyor. Ama o noktada kova çoktan kurulmuş, belki veriyi
almış, belki internete açık kalmış oluyor. Buradaki fark saatler değil,
**kaynağın hiç var olmamış olması.**

## Önem derecesi öncelik değildir

📋 Listedeki tek `CRITICAL` bulgu `AWS-0104` — sınırsız çıkış trafiği. İlk
onu mu düzeltirsiniz?

<details>
  <summary>Cevap</summary>

Muhtemelen hayır.

`AWS-0104` **sınırsız çıkış**: sunucu internetteki herhangi bir adrese
bağlanabiliyor. Gerçek bir risk — veri sızdırmanın en kolay yolu budur. Ama
çoğu mimaride bu bilerek açık bırakılıyor: paket indirme, dış API çağrısı,
güncelleme. Kapatmak bir vekil sunucu altyapısı gerektiriyor.

`AWS-0107` yalnızca `HIGH` ama **SSH portu bütün internete açık**. Bu, dün
akşam tarayan birinin bugün parola denemeye başladığı kapıdır. Düzeltmesi
tek satır: `0.0.0.0/0` yerine şirket ağının aralığı.

Dört adet `HIGH` halka açıklık bulgusu (`0086`, `0087`, `0091`, `0093`) da
birlikte okunmalı: dördü aynı kaynağın dört ayarı ve biri bile `false`
kalırsa kova yanlışlıkla halka açılabiliyor. Tek bir düzeltme, dört bulgu.

**Önem derecesi aracın verdiği puandır; öncelik sizin kararınız.** Aracın
sıralaması sizin mimarinizi, verinizin hassasiyetini ve o kaynağın nereye
bağlı olduğunu bilmiyor.

</details><br/>

## Düzeltmeyi uygulamak

`labs/iac-security/altyapi-duzeltilmis/main.tf` dosyası aynı altyapıyı
düzeltilmiş hâliyle tanımlıyor. Açıp okuyun: her bloğun yanında hangi
bulguyu kapattığı yazıyor — şifreleme için bir KMS anahtarı, sürümleme,
erişim kaydı, halka açıklığın dört ayarı, SSH için daraltılmış aralık,
açıklamalar.

Bu klasörü tarayın:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q
```

```
Failures: 9 (UNKNOWN: 0, LOW: 2, MEDIUM: 1, HIGH: 5, CRITICAL: 1)
```

12'den 9'a indi. Oysa dosyada **on iki düzeltmenin hepsi** var.

📋 Kalan 9 bulguya dikkatle bakın. Neyle ilgililer?

<details>
  <summary>Cevap</summary>

```
AWS-0086 (HIGH):     No public access block so not blocking public acls
AWS-0087 (HIGH):     No public access block so not blocking public policies
AWS-0089 (LOW):      Bucket has logging disabled
AWS-0090 (MEDIUM):   Bucket does not have versioning enabled
AWS-0091 (HIGH):     No public access block so not blocking public acls
AWS-0093 (HIGH):     No public access block so not restricting public buckets
AWS-0094 (LOW):      Bucket does not have a corresponding public access block.
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
AWS-0132 (HIGH):     Bucket does not encrypt data with a customer managed key.
```

Sekizi **yeni bir kova** hakkında: `arsiv_kayitlari`.

`AWS-0089` "erişim kaydı kapalı" diyordu. Düzeltmek için kayıtların
yazılacağı bir kova açmamız gerekti. O kova da bir S3 kovası — yani onun da
şifrelemesi, sürümlemesi, halka açıklık engeli ve erişim kaydı yok.

İlk taramadaki mesajlar "`Public access block does not block...`" diyordu;
şimdi "**No** public access block so not blocking..." diyor. Birinci durumda
blok vardı ama `false`'tu; ikincisinde blok hiç yok.

Dokuzuncusu `AWS-0104`: çıkışı 443'e daralttık ama hedef hâlâ `0.0.0.0/0`.
Port kısıtlandı, adres kısıtlanmadı — kural "herhangi bir IP" diyor ve haklı.

</details><br/>

### Buradaki ders

Altyapı kodunda **düzeltme yeni altyapı doğuruyor.** Bir kuralı sağlamak
için eklediğiniz kaynak, kendisi de aynı kurallara tabi. Kayıt kovası,
yedek kovası, KMS anahtarı, vekil sunucu — hepsi yeni yüzey.

Bu yüzden IaC taraması bir kerelik bir temizlik değil, **her değişiklikte
çalışan bir kontrol** olmak zorunda. Elle "düzelttik, tamam" demek burada
işlemiyor: tam da düzeltirken yeni bir şey açmış oluyorsunuz.

## Kapı

Hattı durduracak hâle getirelim. Trivy, bulgu varken sıfırdan farklı bir kod
döndürmesi için `--exit-code` bekliyor; neyin sayılacağını da `--severity`
belirliyor.

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi -q --severity HIGH,CRITICAL --exit-code 1
```

Çıkış koduna bakın — Windows PowerShell'de `echo $LASTEXITCODE`, macOS veya
Linux'ta `echo $?`. **1** göreceksiniz.

Neden `HIGH,CRITICAL`? Çünkü bu listede dört tane `LOW` var ve üçü
"açıklama yazılmamış" diyor. Doğru uyarılar, ama bir sürümü durdurmaya
değmezler. Hepsini kapıya koyarsanız ekip bir hafta içinde kapıyı kapatır.

> Kapının eşiği, düzeltilmesi beklenen şeyle hattın durmasına değecek şey
> arasındaki kesişim. `LOW` bulgular rapora girer, birikir, sırası
> geldiğinde temizlenir — ama sürümü beklettirmez.

## İstisna: tarihli bir karar

`AWS-0104` düzeltilmiş dosyada hâlâ duruyor ve `CRITICAL`. Çıkışı kapatmak
için bir vekil sunucu altyapısı gerekiyor, o da bu çeyrekte yok. Yani bunu
bir süreliğine kabul edeceğiz.

`labs/iac-security/istisna.yaml` dosyasını açıp bakın. Üç alanı var ve üçü de
zorunlu sayılıyor: hangi bulgu, **neden** kabul edildiği ve **ne zaman**
tekrar bakılacağı.

İstisna olmadan tarayın:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q --severity CRITICAL
```

```
Failures: 1 (CRITICAL: 1)
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
```

Şimdi istisna dosyasıyla:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q --severity CRITICAL --ignorefile /is/istisna.yaml --exit-code 1
```

Bulgu kayboldu, çıkış kodu **0**.

📋 Şimdi asıl soru: `istisna.yaml` içindeki `expired_at` tarihini geçmiş bir
tarihe çevirip aynı komutu çalıştırın. Ne oluyor?

<details>
  <summary>Cevap</summary>

Tarihi örneğin `2026-01-31` yapın ve taramayı tekrarlayın:

```
Failures: 1 (CRITICAL: 1)
AWS-0104 (CRITICAL): Security group rule allows unrestricted egress to any IP address.
```

Çıkış kodu yine **1**. Bulgu geri geldi, kapı yeniden kapandı.

Bu, bu eğitimdeki en önemli mekanizmalardan biri. Diğer araçlarda istisna
yazmak onu **süresiz** susturuyor; gerekçeyi yorum olarak yazıyorsunuz ve
kimse geri dönüp bakmıyor. Burada son tarih aracın kendisinde: tarih
geçtiğinde bulgu kendiliğinden geri geliyor ve birinin yeniden karar vermesi
gerekiyor.

İstisnanın hatırlanması insanın hafızasına değil, aracın işine bırakılmış
oluyor.

Denemeyi bitirdiğinizde tarihi eski hâline (`2027-02-28`) geri alın.

</details><br/>

## Lab

Düzeltilmiş altyapıyı gerçekten temiz hâle getirin.

`labs/iac-security/altyapi-duzeltilmis/main.tf` dosyasını düzenleyip
taramanın **sıfır bulgu** vermesini sağlayın:

```
Report Summary

┌────────┬───────────┬───────────────────┐
│ Target │   Type    │ Misconfigurations │
├────────┼───────────┼───────────────────┤
│ .      │ terraform │         0         │
└────────┴───────────┴───────────────────┘
```

Yapmanız gerekenler:

- kayıt kovasına da ana kovadaki korumaların aynısını verin
- kayıt kovasının kendi erişim kaydı sorusunu çözün — bir kova kendi
  kayıtlarını nereye yazar?
- `AWS-0104` için istisna yazmayı değil, **çıkışı gerçekten daraltmayı**
  deneyin
- sıfıra ulaştığınızda `istisna.yaml` dosyasındaki kaydı silin ve kapıyı
  tekrar çalıştırın — hâlâ geçiyor mu?

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.
___

<!-- troubleshooting:auto -->
## Takılırsanız

**`Cannot connect to the Docker daemon`** - Docker Desktop çalışmıyor.
Başlatın ve balina simgesi hareket etmeyi bırakana kadar bekleyin.

**`port is already allocated`** - önceki bir labdan kalan konteyner o portu
hâlâ tutuyor. `docker ps` ile neyin çalıştığına bakın, eskisini
`docker rm -f <ad>` ile kaldırın.

**`The container name "/..." is already in use`** - aynı sebep, aynı çözüm:
`docker rm -f <ad>` deyip komutu tekrar çalıştırın.

**Build sırasında `unable to prepare context: path ... not found`** - yanlış
dizindesiniz. Bu labdaki her komut deponun kök dizininde olduğunuzu varsayıyor.

**Çalışmak yerine kullanım metni basan `docker run`** - bu labdaki bazı
komutlar, yanlış argümanın nasıl göründüğünü göstermek için kasıtlı olarak
başarısız oluyor. Bozuk sanmadan önce komutun çevresindeki açıklamayı okuyun.

Hâlâ takılıysanız: aşağıdaki **Cleanup** bölümü her şeyi sıfırlıyor, labı
temiz bir makineyle baştan yapabilirsiniz.


## Temizlik

Bu lab hiçbir şey çalıştırmadı — ne container kaldı, ne ağ, ne volume.
Terraform da uygulanmadı, yani bulutta da bir şey oluşmadı.

Değiştirdiğiniz dosyaları geri almak isterseniz:

```
git checkout labs/iac-security
```
