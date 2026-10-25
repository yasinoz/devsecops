# Lab Çözümü

Kayıt kovasına ana kovadakilerin eşlerini ekleyin ve çıkışı daraltın.
`altyapi-duzeltilmis/main.tf` dosyasına eklenecekler:

```
# Kayit kovasinin sifrelemesi - ayni KMS anahtarini kullaniyor.
resource "aws_s3_bucket_server_side_encryption_configuration" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.arsiv.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "arsiv_kayitlari" {
  bucket = aws_s3_bucket.arsiv_kayitlari.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Kayit kovasi kendi kayitlarini kendisine yaziyor.
resource "aws_s3_bucket_logging" "arsiv_kayitlari" {
  bucket        = aws_s3_bucket.arsiv_kayitlari.id
  target_bucket = aws_s3_bucket.arsiv_kayitlari.id
  target_prefix = "kendi/"
}
```

Güvenlik grubunun çıkış kuralını da daraltın:

```
  egress {
    description = "Yalnizca sirket vekil sunucusuna HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.30.0.0/16"]
  }
```

Tarayın:

```
docker run --rm -v ./labs/iac-security:/is aquasec/trivy:0.76.0 config /is/altyapi-duzeltilmis -q
```

```
Report Summary

┌────────┬───────────┬───────────────────┐
│ Target │   Type    │ Misconfigurations │
├────────┼───────────┼───────────────────┤
│ .      │ terraform │         0         │
└────────┴───────────┴───────────────────┘
```

Sıfır bulgu. Sonra `istisna.yaml` içindeki `AWS-0104` kaydını silip kapıyı
çalıştırın — çıkış kodu `0`, çünkü bulgu artık hiç çıkmıyor. İstisnaya gerek
kalmadı.

## Kayıt kovasının kendini kaydetmesi

Yukarıdaki çözümde kayıt kovası kendi erişim kayıtlarını **kendine**
yazıyor. Tarayıcıyı memnun ediyor ve sonsuz kova zincirini kırıyor, ama
bilmeniz gereken bir tarafı var:

- kayıtlar hakkında kayıt üretiyor, yani kova kendi kendine büyüyor
- kovaya erişimi olan biri kendi izini de silebiliyor — denetim kaydının
  bütün amacı buydu

Gerçek kurulumlarda bunun yerine **kayıtlar ayrı bir hesaba** gönderiliyor;
üretim hesabındaki kimsenin yazma dışında yetkisi olmuyor. O mimaride bu
Terraform dosyasında kayıt kovası hiç bulunmuyor, hedef başka bir hesabın
kovası oluyor.

Yani buradaki "sıfır bulgu", "mimari doğru" demek değil. Tarayıcı kendi
kural listesine göre temiz diyor; kuralların kapsamadığı tasarım soruları
hâlâ sizde.

> Bir tarayıcının sıfır vermesi, sorulması gereken soruların bittiği anlamına
> gelmiyor. Yalnızca o aracın bildiği soruların bittiği anlamına geliyor.

___
> [Alıştırmalara](README.tr.md) dönün.
