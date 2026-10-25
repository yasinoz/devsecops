# Sirli depoyu ureten yardimci imaj.
#
# NEDEN IMAJ: hazir bir .git klasorunu depoya koyamayiz - ic ice git
# depolari karisiyor. Depoyu lab sirasinda uretiyoruz, boylece herkeste
# ayni gecmis olusuyor.
#
# NEDEN GORELI YOL: depo ./labs/secret-scanning/sirli-depo altina yaziliyor.
# Ogrenci dosyalari KENDI EDITORUYLE acip duzenleyebiliyor - .gitleaksignore
# ve .gitleaks.toml'u kabuk tirnaklamasiyla ugrasmadan yaziyor. Goreli yol
# PowerShell'de de macOS/Linux kabugunda da ayni sekilde yaziliyor.
FROM alpine:3.24

RUN apk add --no-cache git=2.54.0-r0

COPY kur.sh /kur.sh
RUN chmod +x /kur.sh

ENTRYPOINT ["/kur.sh"]
