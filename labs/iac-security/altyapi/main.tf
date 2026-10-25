# Siparis arsivi altyapisi - BUGUNKU HALI.
#
# Bu dosyada "kasitli olarak zafiyet eklenmis" bir sey yok. Bunlar bir
# Terraform dosyasinin varsayilan hali: kovayi tanimliyorsunuz, guvenlik
# grubunu aciyorsunuz, calisiyor. Soylenmeyen her sey saglayicinin
# varsayilanina dusuyor - ve bulutta varsayilanlar guvenli degil, kolay.
#
# Bu dosya hicbir yere uygulanmadi. terraform apply calismadi, AWS hesabi
# yok, kimlik bilgisi yok. Tarayici dosyayi OKUYOR. IaC guvenliginin
# tamami bu cumlede: kaynak daha var olmadan kontrol ediliyor.

provider "aws" {
  region = "eu-north-1"
}

# Siparis gecmisinin arsivlendigi kova.
resource "aws_s3_bucket" "siparis_arsivi" {
  bucket = "siparis-arsivi-uretim"
}

resource "aws_s3_bucket_public_access_block" "siparis_arsivi" {
  bucket = aws_s3_bucket.siparis_arsivi.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Uygulama sunucularinin guvenlik grubu.
resource "aws_security_group" "uygulama" {
  name = "uygulama-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
