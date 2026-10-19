# Altin imaj: Alpine'in TAM surumu + OpenJDK'nin TAM apk surumu.
#
# Bu, labin anlattigi "tamamen surumlenmis" yaklasim. Bedeli: Alpine paketi
# yeniden derlendiginde apk surum dizgisi degisiyor ve burayi guncellemek
# gerekiyor. Guncel degeri Alpine'in paket dizininden okuyabilirsiniz:
#   https://pkgs.alpinelinux.org/packages?name=openjdk25&branch=v3.24
#
# Upstream bu dosyada alpine:3.15 + openjdk11=11.0.13_p8-r0 pinliyordu;
# Alpine 3.15 EOL oldugu icin o surum artik cozulmuyordu.
ARG ALPINE_VERSION='3.24'
FROM alpine:${ALPINE_VERSION}

ARG OPENJDK_VERSION='25.0.4_p7-r0'
RUN apk add --no-cache \
    openjdk25-jre=${OPENJDK_VERSION}