---
title: Tehdit Modelleme Atölyesi
lang: tr
slug: threat-modelling
section: security
order: 10
duration: 60
requires: []
status: updated
upstream: labs/threat-modelling
---
# Tehdit Modelleme Atölyesi

Bu eğitimdeki bütün güvenlik laboratuvarları bir şeyi **buldu**: statik analiz
kodda bir desen buldu, tarayıcı bir CVE buldu, DAST eksik bir başlık buldu.
Hepsi var olan bir şeye bakıyordu.

Tehdit modelleme bunların hiçbirine benzemiyor, çünkü **henüz var olmayan**
bir şeye bakıyor. Araç yok, tarama yok, çıktı yok. Bir tahta, sistemin
şeması ve birkaç kişi var. Çıktısı bir rapor değil, **kararlar**.

Neden değsin? Çünkü bulduğunuz her zafiyetin bir maliyeti var ve o maliyet
zamanla katlanıyor:

- tasarımda fark edilirse → bir cümlelik karar
- kodda fark edilirse → bir commit
- testte fark edilirse → bir sürüm gecikmesi
- üretimde fark edilirse → bir gece, bir bildirim, belki bir ceza

Tehdit modelleme bu merdivenin en üst basamağı. Ve bu eğitimdeki tek etkinlik
ki çalıştırılacak bir kodu bile gerektirmiyor.

> Bu bir atölye, komut satırı labı değil. Çalıştıracak bir şey yok; okuyacak,
> tartışacak ve yazacaksınız. Grup hâlinde yapılıyorsa en verimli hâli budur.

<!-- outcomes:auto -->
<!-- prereqs:auto -->
## Başlamadan önce

Süre: yaklaşık 60 dakika.

> Bütün komutları **deponun kök dizininden** çalıştırın; bu labdaki yollar ona göre yazıldı.

## Bu lab ne işe yarıyor

Bu eğitimdeki diğer güvenlik etkinliklerinin hepsi var olan bir şeyi inceliyor. Bu, henüz inşa edilmemiş olanı inceliyor — bir kusurun bir sürüme değil bir cümleye mal olduğu tek nokta. Ayrıca eğitimin baştan beri ürettiği soruyu yanıtlıyor: container'a geçmek hangi tehditleri kaldırıyor, hangilerini taşıyor, hangilerini yaratıyor.

**Bu labdan sonra şunları yapabileceksiniz:**

- bir sistemi çizip güvenin gerçekte nerede el değiştirdiğini işaretlemek
- tehditleri hayal gücünden değil kontrol listesinden üretmek
- her tehdit için karar vermek: azalt, kaldır, devret veya kabul et — yazılı
- container'ın hangi tehdidi kaldırdığını, hangisini taşıdığını söylemek
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

- [OWASP Threat Modeling Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html)

- [Microsoft — STRIDE ile tehdit modelleme](https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool-threats)

- [NIST SSDF (SP 800-218) PW.1 — tasarımda güvenlik gereksinimleri](https://csrc.nist.gov/pubs/sp/800/218/final)

- [OWASP ASVS — V1 Architecture, Design and Threat Modeling](https://owasp.org/www-project-application-security-verification-standard/)

## Dört soru

Tehdit modelleme karmaşık görünüyor ama özü dört sorudan ibaret:

1. **Ne inşa ediyoruz?** — sistemin şeması, parçaları, aralarındaki akış
2. **Ne ters gidebilir?** — tehditler
3. **Ne yapacağız?** — her tehdit için bir karar
4. **İyi iş çıkardık mı?** — modelin kendisini gözden geçirmek

Çoğu ekip ikinciyi yapmaya çalışıp birinciyi atlıyor ve dağılıyor. Sırayı
bozmayın.

## 1. Ne inşa ediyoruz

Modelleyeceğimiz sistem şu: eğitimdeki laboratuvarlarda gördüğünüz sipariş
servisinin kurumsal hâli. Önce bugünkü kurulumuyla çalışacağız — httpd,
uygulama sunucusu, SQL sunucusu.

```
  Internet
     │
     │  443/tcp
     ▼
┌─────────────────┐
│  web-01 (VM)    │   httpd 2.4, ters vekil
│  DMZ ag         │   TLS burada sonlaniyor
└────────┬────────┘
         │  8080/tcp
         ▼
┌─────────────────┐
│  app-01 (VM)    │   uygulama sunucusu
│  ic ag          │   siparis is mantigi
└────────┬────────┘
         │  1433/tcp
         ▼
┌─────────────────┐
│  sql-01 (VM)    │   veritabani
│  veri agi       │   siparis + musteri verisi
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SAN depolama   │   LUN, gece yedegi
└─────────────────┘
```

Bilmeniz gereken ayrıntılar:

- `web-01` üzerindeki httpd `root` olarak başlıyor, sonra `apache`
  kullanıcısına düşüyor
- `app-01` veritabanına `siparis_app` hesabıyla bağlanıyor; parola
  uygulamanın `config.properties` dosyasında düz metin
- `sql-01` yalnızca iç ağdan erişilebilir, ama **bütün** iç ağdan
- Yedekler gece SAN üzerinde LUN kopyası olarak alınıyor, şifreli değil
- Üç VM'e de yöneticiler RDP/SSH ile doğrudan bağlanıyor
- Yama işlemi aylık bakım penceresinde elle yapılıyor
- Günlükler her sunucunun kendi diskinde, 30 gün

> Aynı sistemin container'a taşınmış hâli bu labın dördüncü bölümünde;
> oraya geldiğimizde ikisini karşılaştıracağız.

Şemada eksik olan tek şey **güven sınırları** (trust boundary): verinin bir
güven seviyesinden diğerine geçtiği yerler. Tehditler neredeyse her zaman o
çizgilerin üzerinde oturuyor.

📋 Bu sistemde kaç tane güven sınırı var? Nerede?

<details>
  <summary>Cevap</summary>

En az dört tane:

1. **İnternet → web-01.** En belirgin olanı. Karşı taraf tamamen güvenilmez.
2. **web-01 → app-01.** DMZ ile iç ağ arasında. web-01 ele geçirilirse
   saldırgan bu sınırın iç tarafında duruyor olacak.
3. **app-01 → sql-01.** Uygulama ile veri arasında. Uygulamanın yetkisi
   neyse, saldırganın yetkisi de o.
4. **Yönetici → her üç VM.** Ayrı bir sınır, çünkü yönetici erişimi
   uygulamanın akışından tamamen bağımsız bir yol.

Beşincisi tartışmalı ama önemli: **yedek → SAN**. Veri sistemden çıkıp
başka bir yönetim alanına giriyor.

Bu sonuncusu çoğu modelde atlanıyor. Üretim veritabanı sıkı sıkıya korunuyor,
aynı verinin şifresiz yedeği başka bir ekibin yönettiği depolamada duruyor.

</details><br/>

## 2. Ne ters gidebilir: STRIDE

Tehdit üretmek için hayal gücüne güvenmek işe yaramıyor — herkes kendi
bildiği saldırıyı söylüyor ve liste oradan ileri gitmiyor. STRIDE bunun
yerine **kontrol listesi** veriyor. Her bileşen için altı soruyu sırayla
soruyorsunuz:

| Harf | Tehdit | Türkçesi | Sorusu |
|---|---|---|---|
| **S** | Spoofing | Kimlik taklidi | Başkası gibi davranabilir mi? |
| **T** | Tampering | Kurcalama | Veriyi veya kodu değiştirebilir mi? |
| **R** | Repudiation | İnkâr | Yaptığını inkâr edebilir mi? |
| **I** | Information disclosure | Bilgi ifşası | Görmemesi gerekeni görebilir mi? |
| **D** | Denial of service | Hizmet engelleme | Sistemi durdurabilir mi? |
| **E** | Elevation of privilege | Yetki yükseltme | Yetkisini artırabilir mi? |

### Birlikte yapalım: `web-01`

| Harf | Bu sistemdeki karşılığı |
|---|---|
| **S** | TLS sertifikası doğrulanmıyorsa araya giren biri web-01 gibi davranabilir. İç tarafta daha kötüsü var: app-01, kendisine gelen isteğin gerçekten web-01'den geldiğini **doğrulamıyor**. İç ağdaki herhangi bir makine 8080'e doğrudan bağlanabilir. |
| **T** | httpd yapılandırması diskte; sunucuya erişen biri ters vekil kuralını değiştirip trafiği başka yere yönlendirebilir. |
| **R** | Erişim kayıtları aynı sunucuda ve 30 gün. Sunucuyu ele geçiren kendi izini silebilir. |
| **I** | `server_tokens` açık; sürüm bilgisi veriliyor. Hata sayfaları yığın izi gösteriyorsa daha fazlası. |
| **D** | Tek makine. web-01 düşerse sistem komple erişilemez. |
| **E** | httpd `root` olarak başlıyor. Başlangıç anındaki bir açık doğrudan `root` demek. |

Bu altı satır on dakikada çıktı ve hiçbirini bulmak için araç gerekmedi.

📋 Şimdi siz `sql-01` için aynı tabloyu doldurun. Sistem tanımındaki
ayrıntılara dikkat edin — özellikle parolanın nerede durduğuna.

<details>
  <summary>Cevap</summary>

| Harf | `sql-01` için |
|---|---|
| **S** | `siparis_app` parolası `app-01` üzerinde düz metin. app-01'e erişen herkes uygulamanın kimliğiyle veritabanına bağlanabilir — veritabanı açısından bu meşru bir bağlantı. |
| **T** | Aynı hesabın yazma yetkisi var; sipariş kayıtları değiştirilebilir. Uygulamanın `DDL` yetkisi varsa şema da. |
| **R** | Veritabanı denetim kaydı açık mı? Açık değilse "bu kaydı kim değiştirdi" sorusunun cevabı yok. |
| **I** | Müşteri verisi burada. Yedekler **şifresiz** — veriyi almanın en kolay yolu canlı veritabanı değil, gece yedeği. |
| **D** | Tek örnek, yük devretme yok. Ayrıca iç ağdaki herhangi bir makine 1433'e bağlanabildiği için bağlantı havuzunu tüketmek mümkün. |
| **E** | Uygulama hesabı `db_owner` ise SQL enjeksiyonu doğrudan veritabanı yöneticisi yetkisine dönüşüyor. |

Dikkat: bu tehditlerin çoğu `sql-01`'in kendi ayarıyla değil, **başka bir
makinedeki** bir kararla ilgili. Tehdit modelleme bileşen bileşen yapılıyor
ama tehditler bileşenler arasında yaşıyor.

</details><br/>

## 3. Ne yapacağız

Her tehdit için dört seçenek var. "Düzelt" bunlardan yalnızca biri:

- **Azalt (mitigate)** — kontrolü ekle. Parolayı kasaya taşı, hesabı
  kısıtla, yedekleri şifrele.
- **Ortadan kaldır (eliminate)** — özelliği veya yolu sil. Veritabanına iç
  ağın tamamından erişimi kapat, yalnızca app-01'e izin ver.
- **Devret (transfer)** — riski başkasına geçir. Ödeme verisini hiç tutma,
  sağlayıcıya bırak.
- **Kabul et (accept)** — bilinçli olarak yaşa. **Yazılı**, sahibi ve tarihi
  belli.

Son seçenek DAST ve IaC laboratuvarlarındaki istisna satırlarının ta
kendisi. Orada bir dosyaya yazdığınız şeyin kararı burada veriliyor.

Her satır için şu biçimi kullanın:

```
Tehdit     : app-01 uzerindeki duz metin parola ile veritabanina baglanilmasi
Harf       : S (kimlik taklidi)
Etki       : Musteri verisinin tamami okunabilir
Karar      : Azalt
Nasil      : Parola sir kasasina tasinacak, uygulama calisma aninda cekecek
Sahibi     : Uygulama ekibi
Son tarih  : 2027-01-31
```

## 4. Aynı sistem container'da

Şimdi işin ilginç yerine geliyoruz. Aynı sistemi bu eğitimde kurduğunuz
yapıya taşıdınız:

```
  Internet
     │
     ▼
┌──────────────────────────────────────┐
│  Kubernetes kumesi                   │
│                                      │
│  ┌────────┐   ┌────────┐   ┌──────┐  │
│  │ ingress│──▶│  app   │──▶│ sql  │  │
│  │        │   │ (3 kop)│   │(stf) │  │
│  └────────┘   └────────┘   └──────┘  │
│       ▲            ▲                 │
│       │            │                 │
│   TLS burada   imaj: registry        │
└──────────────────────────────────────┘
         ▲
         │  dagitim
┌────────┴────────┐
│  CI/CD hatti    │  Jenkins, imaj derleme, tarama
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  imaj registry  │
└─────────────────┘
```

- İmajlar CI hattında derleniyor, registry'ye gönderiliyor
- Kümeye dağıtım GitOps ile; dağıtım bildirimi git deposunda
- Veritabanı parolası Kubernetes `Secret` nesnesinde
- Kümeye erişim `kubectl` ile, kimlik doğrulama kurumsal dizinden
- Günlükler merkezî bir toplayıcıya akıyor
- Yama = imajın yeniden derlenmesi ve dağıtılması

Tehditler ne oldu?

📋 Üç gruba ayırın: hangi tehditler **kayboldu**, hangileri **yer değiştirdi**,
hangileri **yeni**?

<details>
  <summary>Cevap</summary>

**Kaybolanlar:**

- httpd'nin `root` başlaması — imaj belirli bir kullanıcıyla çalışıyor ve
  bunu Pod Security Standards zorluyor
- "sunucuya girip yapılandırmayı değiştirme" — container'ın dosya sistemi
  salt okunur ve yeniden başlatıldığında imajdan geliyor; değişiklik kalıcı
  olmuyor
- "yama bakım penceresinde elle yapılıyor" — yama imajın yeniden
  derlenmesi, yani hat üzerinden

**Yer değiştirenler:**

- *Parola düz metin dosyada* → Kubernetes `Secret` nesnesinde. Daha iyi, ama
  `Secret` varsayılan olarak yalnızca base64 — şifreli değil. Tehdit
  kaybolmadı, **etcd'ye** ve **RBAC'a** taşındı.
- *İç ağdaki herkes SQL'e bağlanabiliyor* → küme içi ağ politikası sorusu.
  Politika yazılmadıysa durum **aynı**, hatta daha geniş.
- *Yöneticiler VM'lere SSH ile giriyor* → `kubectl exec`. Aynı yetki, farklı
  kapı; ve bu kapının kaydı tutuluyor mu, ayrı soru.

**Yeniler:**

- **Registry.** İmajı oradan alıyorsunuz. Registry ele geçirilirse veya imaj
  etiketi değiştirilirse, kümeye saldırganın kodu dağıtılıyor. VM dünyasında
  bunun karşılığı yoktu.
- **CI/CD hattı.** Hat üretime yazabiliyor. Hattı ele geçiren, üretimi ele
  geçiriyor. Jenkins artık bir yardımcı araç değil, **üretim sistemi**.
- **GitOps deposu.** Dağıtım bildirimi git'te; o depoya yazabilen kişi
  kümeye dağıtım yapabiliyor demek.
- **Tedarik zinciri.** İmaj yüzlerce paket içeriyor. VM'de de içeriyordu ama
  imaj sürekli yeniden derleniyor, yani her derlemede yeni bir şey
  girebiliyor.
- **Küme API'si.** Yanlış yapılandırılmış bir RBAC rolü, tek bir namespace
  yerine kümenin tamamına erişim verebiliyor.

</details><br/>

### Buradan çıkan sonuç

Container'a geçmek güvenliği otomatik olarak artırmıyor. Bazı tehdit
sınıflarını gerçekten yok ediyor — bunlar çoğunlukla *makine bakımıyla*
ilgili olanlar. Karşılığında **yeni ve tanıdık olmayan** bir yüzey açıyor:
imajın nereden geldiği, hattın kime ait olduğu, kümenin kime ne yetki
verdiği.

Bu eğitimdeki modüllerin neden o sırayla dizildiğini de açıklıyor: imaj
derleme, registry, tarama, altın imaj, GitOps, politika zorlama — hepsi
yukarıdaki "yeniler" listesine verilmiş cevaplar.

## Lab

Modeli tamamlayın.

**Birinci bölüm — mevcut sistem.** `app-01` için STRIDE tablosunu doldurun.
Yukarıdaki `web-01` ve `sql-01` tablolarını örnek alın. En az altı tehdit
yazın; her harf için en az bir satır zorlamayın, bazı harfler o bileşen için
boş kalabilir — ama boş bıraktığınızı bilerek bırakın.

**İkinci bölüm — kararlar.** Çıkardığınız tehditlerden **üç tanesini**
seçip karar biçimini doldurun: etki, karar, nasıl, sahibi, son tarih.
Üçünden en az biri "Kabul et" olsun — gerekçesini yazmak zorunda kalın.

**Üçüncü bölüm — yeni mimari.** Container'lı kurulumda **CI/CD hattını**
modelleyin. Hat bir bileşen; STRIDE'ı ona uygulayın. İpucu: hattın üretime
yazma yetkisi var ve kodu bir git deposundan alıyor.

Sonucu sınıfla paylaşın. Bu atölyenin asıl çıktısı tablo değil, tartışma —
aynı sisteme bakan iki kişi farklı tehditler görüyor ve asıl değer orada.

> Takıldınız mı? [İpuçlarına](hints.tr.md) bakın veya
> [çözümü](solution.tr.md) inceleyin.
___

<!-- troubleshooting:auto -->


## Temizlik

Bu atölyede çalıştırılan bir şey olmadı; temizlenecek bir şey de yok.

Çıkardığınız modeli saklayın. Tehdit modeli bir kerelik belge değil:
mimari değiştiğinde tekrar açılıyor ve "bu değişiklik hangi tehditi
etkiliyor" sorusu soruluyor.
