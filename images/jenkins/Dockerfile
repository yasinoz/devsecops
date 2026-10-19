# syntax=docker/dockerfile:1

# Lab ortami icin Jenkins: eklentiler ve yonetici kullanicisi hazir gelir.
#
# Neden ozel imaj: siniftaki 20 ogrencinin her birinin kurulum sihirbazini
# gecip 8 eklenti indirmesi dersin ilk 15 dakikasini yiyor ve Jenkins
# guncelleme merkezine 20 paralel istek guvenilir degil. Eklentiler imaja
# gomulu geldigi icin konteyner saniyeler icinde hazir.
#
# Derleme:
#   docker build -t ghcr.io/yasinoz/labs-jenkins:1.0.0 images/jenkins
# Ya da lab dizininden: docker compose -f labs/jenkins/infra/docker-compose.yml build

# Docker komut satirini resmi imajdan aliyoruz - apt deposu eklemekten
# daha az kirilgan ve surum pinlenebilir.
FROM docker:29.9.1-cli AS dockercli

FROM jenkins/jenkins:2.580.1-lts-jdk21

LABEL org.opencontainers.image.title="sudo2go labs Jenkins" \
      org.opencontainers.image.description="DevOps/DevSecOps lablari icin hazir yapilandirilmis Jenkins" \
      org.opencontainers.image.source="https://github.com/yasinoz/devsecops" \
      org.opencontainers.image.licenses="CC-BY-SA-4.0"

USER root

# Docker komut satiri: pipeline'lar host Docker motorunda imaj derliyor
COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker

# kubectl: GitOps / admission lablari icin
ARG KUBECTL_VERSION=v1.37.1
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) karch=amd64 ;; \
      arm64) karch=arm64 ;; \
      *) echo "desteklenmeyen mimari: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${karch}/kubectl"; \
    chmod +x /usr/local/bin/kubectl; \
    kubectl version --client=true

# NOT: docker.sock erisimi icin imaja grup eklemiyoruz.
#
# Socket'in sahibi ve grubu host'a gore degisir: Docker Desktop'ta (WSL2 ve
# macOS) container icinde root:root 660 olarak gorunur, Linux'ta ise
# root:docker ve docker grubunun kimligi her makinede farkli. Imaja sabit
# kimlikli bir grup gomsek bu kombinasyonlarin yalnizca birinde calisirdi.
#
# Bunun yerine lab compose dosyasi Jenkins'i root olarak calistirir ve bunun
# bilincli bir lab tavizi oldugunu yazar. Container guvenligi labi tam olarak
# bu kararin neden uretimde kabul edilemez oldugunu isliyor.

USER jenkins

# Eklentiler. Surumler bilincli olarak pinlenmedi: jenkins-plugin-cli
# eklentileri bu Jenkins surumuyle UYUMLU en guncel haliyle cozumler.
# Tekrarlanabilirlik imaj etiketiyle saglanir (1.0.0 her zaman ayni katmanlar).
COPY --chown=jenkins:jenkins plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt --latest true

# Configuration as Code: yonetici kullanicisi, guvenlik ve ornek ayarlar
COPY --chown=jenkins:jenkins casc.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
