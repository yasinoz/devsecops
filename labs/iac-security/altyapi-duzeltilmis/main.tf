# Siparis arsivi altyapisi - ILK DUZELTME DENEMESI.
#
# Taramada cikan 12 bulgunun her birine karsilik bir degisiklik var;
# hangi blogun hangi bulguyu kapattigi yorumlarda yaziyor.
#
# DIKKAT: bu dosya bitmis degil. Tarayin ve SAYIYA bakin - duzeltme
# bekledigin kadar bulgu kapatmamis olacak. Nedeni labda.

provider "aws" {
  region = "eu-north-1"
}

# AWS-0132: kova musteri yonetimli anahtarla sifrelenmeli.
# Varsayilan SSE-S3 de sifreliyor, ama anahtari AWS yonetiyor; kimin
# ne zaman cozdugunu denetleyemiyorsunuz ve anahtari iptal edemiyorsunuz.
resource "aws_kms_key" "arsiv" {
  description             = "Siparis arsivi kovasi icin musteri yonetimli anahtar"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

resource "aws_s3_bucket" "siparis_arsivi" {
  bucket = "siparis-arsivi-uretim"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "siparis_arsivi" {
  bucket = aws_s3_bucket.siparis_arsivi.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.arsiv.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# AWS-0090: surumleme. Fidye yazilimi ve yanlislikla silme icin tek
# gercek geri donus yolu.
resource "aws_s3_bucket_versioning" "siparis_arsivi" {
  bucket = aws_s3_bucket.siparis_arsivi.id

  versioning_configuration {
    status = "Enabled"
  }
}

# AWS-0089: erisim kaydi. Sizinti oldugunda "kim indirdi" sorusunun
# cevabi ancak onceden acilmis kayitlarda bulunuyor.
#
# Kayitlarin yazilacagi ayri bir kova gerekiyor - asagida tanimlandi.
resource "aws_s3_bucket" "arsiv_kayitlari" {
  bucket = "siparis-arsivi-kayitlari"
}

resource "aws_s3_bucket_logging" "siparis_arsivi" {
  bucket        = aws_s3_bucket.siparis_arsivi.id
  target_bucket = aws_s3_bucket.arsiv_kayitlari.id
  target_prefix = "erisim/"
}

# AWS-0086, AWS-0087, AWS-0091, AWS-0093: dordu birden acik olmali.
# Biri bile false kalirsa kova yanlislikla halka acilabiliyor.
resource "aws_s3_bucket_public_access_block" "siparis_arsivi" {
  bucket = aws_s3_bucket.siparis_arsivi.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AWS-0099: grubun kendi aciklamasi.
resource "aws_security_group" "uygulama" {
  name        = "uygulama-sg"
  description = "Siparis uygulamasi sunuculari"

  # AWS-0107: SSH artik her yerden degil, yalnizca sirket agindan.
  # AWS-0124: her kuralin aciklamasi var.
  ingress {
    description = "Sirket VPN agindan yonetim erisimi"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  # AWS-0104: port 443'e daraltildi. Ama hedef hala 0.0.0.0/0 -
  # tarayici buna ne diyecek, labda goreceksiniz.
  egress {
    description = "Dis servislere HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
