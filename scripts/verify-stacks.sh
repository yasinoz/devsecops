#!/bin/bash
# Lab compose yiginlarini gercekten ayaga kaldirir ve raporlar.
#
# NEDEN: "docker compose config" yalnizca semayi dogruluyor. Ogrencinin
# yasadigi sey farkli - imaj cekilemiyor, servis hemen cikiyor, port
# dinlenmiyor, saglik kontrolu gecmiyor. Bu betik o asamayi test ediyor.
#
# Her yigin SIRAYLA kaldiriliyor ve inmeden sonrakine gecilmiyor: lablar
# ayni portlari (8080, 9090, 5601 ...) paylasiyor, paralel calistirmak
# gercek olmayan "port already allocated" hatalari uretir.
#
# Kullanim: bash scripts/verify-stacks.sh <cikti-dosyasi> [yigin-adi...]

set -u
OUT="${1:-stack-results.txt}"
shift || true
cd "$(dirname "$0")/.." || exit 1
: > "$OUT"

# yigin adi | compose dosyalari | beklenen portlar (bosluklu)
YIGINLAR=(
  "compose-build|labs/compose-build/rng/docker-compose.yml|8090"
  "prometheus|labs/prometheus/prometheus.yml labs/prometheus/apps.yml|9090 8080"
  "grafana|labs/grafana/grafana.yml labs/grafana/apps.yml|3000"
  "elasticsearch|labs/elasticsearch/compose.yml|9200"
  "kibana|labs/kibana/compose.yml|5601 9200"
  "tracing|labs/tracing/api.yml labs/tracing/web.yml|"
  "jaeger|labs/jaeger/jaeger.yml labs/jaeger/apps.yml|16686"
  "static-analysis|labs/static-analysis/infra/docker-compose.yml|9000"
  "scanning|labs/scanning/docker-compose.yml|"
  "jenkins|labs/jenkins/infra/docker-compose.yml|8080 3000"
  "pipeline|labs/pipeline/infra/docker-compose.yml|8080 3000"
)

SECILEN=("$@")
secildi_mi() {
  [ ${#SECILEN[@]} -eq 0 ] && return 0
  for s in "${SECILEN[@]}"; do [ "$s" = "$1" ] && return 0; done
  return 1
}

yaz() { echo "$@" | tee -a "$OUT"; }

indir() {
  local dosyalar="$1"
  local args=""
  for f in $dosyalar; do args="$args -f $f"; done
  # shellcheck disable=SC2086
  docker compose $args down -v --remove-orphans >/dev/null 2>&1
}

for kayit in "${YIGINLAR[@]}"; do
  IFS='|' read -r ad dosyalar portlar <<< "$kayit"
  secildi_mi "$ad" || continue

  yaz "=============================================="
  yaz "YIGIN: $ad"
  args=""
  for f in $dosyalar; do
    if [ ! -f "$f" ]; then yaz "  HATA: $f yok"; continue 2; fi
    args="$args -f $f"
  done

  indir "$dosyalar"
  basla=$(date +%s)
  # shellcheck disable=SC2086
  if ! docker compose $args up -d >>"$OUT" 2>&1; then
    yaz "  SONUC: KALKMADI (up basarisiz)"
    indir "$dosyalar"
    continue
  fi
  sure=$(( $(date +%s) - basla ))
  yaz "  kalkis suresi: ${sure}s"

  # Servislerin oturmasini bekle
  sleep 25

  # shellcheck disable=SC2086
  durum=$(docker compose $args ps --format '{{.Service}}\t{{.State}}\t{{.Status}}' 2>/dev/null)
  yaz "  servisler:"
  echo "$durum" | while IFS= read -r s; do [ -n "$s" ] && yaz "    $s"; done

  cikan=$(echo "$durum" | grep -ci 'exited\|dead' || true)
  if [ "$cikan" -gt 0 ]; then
    yaz "  UYARI: $cikan servis cikmis - loglar:"
    # shellcheck disable=SC2086
    docker compose $args logs --tail 12 >>"$OUT" 2>&1
  fi

  for p in $portlar; do
    kod=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "http://localhost:$p" 2>/dev/null)
    if [ "$kod" = "000" ]; then
      sleep 20
      kod=$(curl -s -o /dev/null -m 8 -w '%{http_code}' "http://localhost:$p" 2>/dev/null)
    fi
    yaz "  port $p -> http=$kod"
  done

  if [ "$cikan" -gt 0 ]; then yaz "  SONUC: SORUNLU"; else yaz "  SONUC: calisiyor"; fi
  indir "$dosyalar"
done

yaz "=============================================="
yaz "bitti: $(date -u +%H:%M:%S) UTC"
