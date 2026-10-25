#!/bin/sh
# Icinde GECMISE gomulu bir sir olan kucuk bir git deposu olusturur.
#
# Depo uc commit'ten olusuyor:
#   1. masum bir yapilandirma
#   2. SIR buraya giriyor
#   3. sir "temizleniyor" - calisma agacindan silindi, GECMISTE duruyor
#
# Ayrica calisma agacinda, AWS dokumantasyonundaki ORNEK anahtari tasiyan
# bir dosya var. Gitleaks onu bilerek yakalamiyor (izin listesinde).
# Labin en onemli dersi o: "tarayici temiz dedi" ile "sir yok" ayni sey degil.
set -e

HEDEF="${1:-/depo}"

# Klasorun KENDISINI silmiyoruz: bagli bir volume oldugunda "Resource busy"
# verir. Icindekileri temizlemek yeterli, boylece betik tekrar calistirilabilir.
mkdir -p "$HEDEF"
find "$HEDEF" -mindepth 1 -delete
cd "$HEDEF"

git init -q
git config user.email "lab@example.com"
git config user.name "Lab"

# --- 1. commit: masum bir yapilandirma ---
cat > config.yml <<'YAML'
app:
  name: siparis-servisi
  port: 8080
YAML
git add config.yml
git commit -q -m "ilk yapilandirma"

# --- 2. commit: SIR buraya giriyor ---
cat > config.yml <<'YAML'
app:
  name: siparis-servisi
  port: 8080
  # TODO: bunu ortam degiskenine tasi
  aws_secret_access_key: 7Hk2pQnR4vTzL9mXbW3dYfJ6gC8sA1eU5oI0rNtP
YAML
git add config.yml
git commit -q -m "s3 baglantisi eklendi"

# --- 3. commit: sir "temizleniyor" ---
cat > config.yml <<'YAML'
app:
  name: siparis-servisi
  port: 8080
  aws_secret_access_key: ${AWS_SECRET_ACCESS_KEY}
YAML
mkdir -p docs
cat > docs/ornek.md <<'MARKDOWN'
# Ornek yapilandirma

Asagidakiler AWS dokumantasyonundaki ORNEK anahtarlar. Gercek degiller.

    aws_access_key_id: AKIAIOSFODNN7EXAMPLE
    aws_secret_access_key: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
MARKDOWN
git add config.yml docs/ornek.md
git commit -q -m "sirri ortam degiskenine tasi"

echo "Depo hazir: $HEDEF"
echo "Calisma agacinda sir YOK, gecmiste VAR - labin konusu bu."
