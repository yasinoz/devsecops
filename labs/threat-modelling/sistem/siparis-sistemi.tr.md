# Sipariş Sistemi — mevcut mimari

Bu, modelleyeceğimiz sistem. Eğitimdeki laboratuvarlarda gördüğünüz sipariş
servisinin kurumsal hâli.

## Bugünkü kurulum (sanal makineler)

```
  Internet
     │
     │  443/tcp
     ▼
┌─────────────────┐
│  web-01 (VM)    │   httpd 2.4, ters vekil
│  DMZ ag          │   TLS burada sonlaniyor
└────────┬────────┘
         │  8080/tcp
         ▼
┌─────────────────┐
│  app-01 (VM)    │   uygulama sunucusu
│  ic ag           │   siparis is mantigi
└────────┬────────┘
         │  1433/tcp
         ▼
┌─────────────────┐
│  sql-01 (VM)    │   veritabani
│  veri agi        │   siparis + musteri verisi
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  SAN depolama   │   LUN, gece yedegi
└─────────────────┘
```

**Bilinen ayrıntılar:**

- `web-01` üzerindeki httpd `root` olarak başlıyor, sonra `apache`
  kullanıcısına düşüyor
- `app-01` veritabanına `siparis_app` hesabıyla bağlanıyor; parola
  uygulamanın `config.properties` dosyasında düz metin
- `sql-01` yalnızca iç ağdan erişilebilir, ama **bütün** iç ağdan
- Yedekler gece SAN üzerinde LUN kopyası olarak alınıyor, şifreli değil
- Üç VM'e de yöneticiler RDP/SSH ile doğrudan bağlanıyor
- Yama işlemi aylık bakım penceresinde elle yapılıyor
- Günlükler her sunucunun kendi diskinde, 30 gün

## Hedeflenen kurulum (container)

Aynı sistem, bu eğitimde kurduğunuz yapıya taşınmış hâli:

```
  Internet
     │
     ▼
┌──────────────────────────────────────┐
│  Kubernetes kumesi                   │
│                                      │
│  ┌────────┐   ┌────────┐   ┌──────┐ │
│  │ ingress│──▶│  app   │──▶│ sql  │ │
│  │        │   │ (3 kop)│   │(stf) │ │
│  └────────┘   └────────┘   └──────┘ │
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

**Bilinen ayrıntılar:**

- İmajlar CI hattında derleniyor, registry'ye gönderiliyor
- Kümeye dağıtım GitOps ile; dağıtım bildirimi git deposunda
- Veritabanı parolası Kubernetes `Secret` nesnesinde
- Kümeye erişim `kubectl` ile, kimlik doğrulama kurumsal dizinden
- Günlükler merkezî bir toplayıcıya akıyor
- Yama = imajın yeniden derlenmesi ve dağıtılması
