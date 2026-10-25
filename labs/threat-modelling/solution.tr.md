# Lab Çözümü

Bu bir atölye olduğu için tek doğru cevap yok. Aşağıdaki model, sınıfta
çıkanların kapsaması beklenenleri gösteriyor — sizinkinde olmayan bir satır
varsa, eksik olmasının bir sebebi olmalı.

## Birinci bölüm: `app-01` için STRIDE

| Harf | Tehdit |
|---|---|
| **S** | 8080 portu iç ağın tamamına açık ve app-01 gelen isteğin web-01'den geldiğini doğrulamıyor. İç ağdaki herhangi bir makine ters vekili atlayıp doğrudan uygulamaya istek gönderebilir — yani web-01'deki bütün filtreleme, oran sınırlama ve TLS zorlaması atlanabilir. |
| **S** | Uygulama veritabanına tek bir paylaşılan hesapla bağlanıyor. Veritabanı tarafında "hangi kullanıcı adına" bilgisi yok; bütün işlemler `siparis_app` olarak görünüyor. |
| **T** | `config.properties` diskte ve uygulama onu okuyor. Sunucuya erişen biri veritabanı adresini değiştirip trafiği kendi sunucusuna yönlendirebilir. |
| **R** | Uygulama günlükleri yerel diskte. Ayrıca işlem kayıtlarında kullanıcı kimliği yoksa "bu siparişi kim iptal etti" sorusunun cevabı yok. |
| **I** | Parola düz metin. Ayrıca hata ayıklama açıksa yığın izleri veritabanı şemasını ve bağlantı dizgisini sızdırabilir. |
| **D** | Tek örnek. Ayrıca bağlantı havuzu sınırlıysa, doğrudan 8080'e yapılan isteklerle havuz tüketilebilir. |
| **E** | Uygulama hangi kullanıcıyla çalışıyor? `root` ise, uygulamadaki bir uzaktan kod çalıştırma açığı doğrudan makinenin tamamı demek. |

**Buradaki asıl bulgu:** `web-01 → app-01` sınırı aslında bir sınır değil.
Şemada çizili ama ağ seviyesinde zorlanmıyor. Modelleme yapmadan bu fark
edilmiyor, çünkü şema doğru görünüyor.

## İkinci bölüm: üç karar

```
Tehdit     : 8080 portunun ic agin tamamina acik olmasi
Harf       : S (kimlik taklidi)
Etki       : Ters vekildeki butun kontroller atlanabilir
Karar      : Ortadan kaldir
Nasil      : Guvenlik duvari kurali - 8080'e yalnizca web-01 adresinden izin
Sahibi     : Ag ekibi
Son tarih  : 2026-12-15
```

```
Tehdit     : Veritabani parolasinin duz metin dosyada durmasi
Harf       : I (bilgi ifsasi)
Etki       : app-01'e erisen herkes musteri verisinin tamamini okuyabilir
Karar      : Azalt
Nasil      : Parola sir kasasina tasinacak, uygulama calisma aninda cekecek
Sahibi     : Uygulama ekibi
Son tarih  : 2027-01-31
```

```
Tehdit     : Tek uygulama ornegi - hizmet kesintisi
Harf       : D (hizmet engelleme)
Etki       : app-01 dustugunde siparis alinamiyor
Karar      : Kabul et
Gerekce    : Is birimi 4 saatlik kurtarma suresini kabul ediyor ve mevcut
             siparis hacminde kesintinin maliyeti yuk devretme altyapisinin
             maliyetinin altinda. Container'a gecisle birlikte zaten uc
             kopya calisacak; ayrica yatirim yapilmayacak.
Sahibi     : Siparis urun sahibi
Son tarih  : 2027-06-30 (gecis tamamlandiginda tekrar bakilacak)
```

Üçüncüsüne dikkat edin: "Kabul et" kararı, gerekçesi yazıldığı anda
tartışılabilir bir şeye dönüşüyor. "4 saat kabul edilebilir" cümlesini bir iş
birimi sahibi onaylıyor; teknik ekibin tek başına verebileceği bir karar
değil.

## Üçüncü bölüm: CI/CD hattı

| Harf | Hat için tehdit |
|---|---|
| **S** | Hat üretime dağıtım yaparken hangi kimliği kullanıyor? Paylaşılan bir hizmet hesabıysa, dağıtımı tetikleyen kişiyi ayırt etmek mümkün değil. |
| **T** | **Jenkinsfile depoda duruyor.** O depoya yazabilen herkes hattın ne yaptığını değiştirebilir — yani tarama adımını silebilir, kendi imajını dağıtabilir. Kod incelemesi zorunlu değilse tek kişi yeter. |
| **T** | Derleme sırasında çekilen bağımlılıklar. `npm install` veya `pip install` dış bir kaynaktan kod indiriyor ve onu derlemenin içine alıyor. |
| **R** | Dağıtım kaydı tutuluyor mu, ve o kaydı hattın kendisi mi yazıyor? Hattı ele geçiren kendi dağıtımını kayıttan silebiliyorsa denetim yok. |
| **I** | Hattın sırları: registry kimlik bilgisi, küme erişim jetonu, imza anahtarı. Derleme günlüklerine basılıyor mu? Çekilen bir depo onları okuyabiliyor mu? |
| **D** | Hat durursa yalnızca yeni sürüm çıkmıyor — ama **acil yama da çıkamıyor**. Güvenlik açığı bulunduğunda düzeltmeyi dağıtacak yol kapalı demek. |
| **E** | Hattın küme yetkisi ne kadar? Tek bir namespace'e dağıtım yetkisi yeterken `cluster-admin` verilmişse, hattaki herhangi bir açık kümenin tamamı demek. |

**Buradaki asıl bulgu:** VM dünyasında üretime dağıtım yapan şey *bir insandı*
ve o insanın yetkisi kurumsal dizinde tanımlıydı. Şimdi dağıtım yapan şey
*bir yazılım* ve onun yetkisi çoğu kurumda hiç gözden geçirilmemiş durumda.
Jenkins kurulurken "çalışsın yeter" diye verilen yetkiler, bugün üretime açık
bir kapı.

Bu yüzden bu eğitimde hat, güvenlik modüllerinin konusu — bir otomasyon aracı
olarak değil, **üretim sistemi** olarak ele alınıyor.

___
> [Alıştırmalara](README.tr.md) dönün.
