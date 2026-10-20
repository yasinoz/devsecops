FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS builder
ARG BUILD_VERSION=1.0.0

WORKDIR /src
COPY src/Numbers.Web/Numbers.Web.csproj .
RUN dotnet restore

COPY src/Numbers.Web/ .
RUN dotnet publish -c Release /p:Version=$BUILD_VERSION -o /out Numbers.Web.csproj

# app image
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine

# .NET 8'den itibaren resmi runtime imajlari 80 yerine 8080 dinliyor ve
# root olmayan kullaniciyla calisiyor. Lab compose dosyalari ve servisler
# arasi URL'ler 80 portunu bekledigi icin eski varsayilani geri aliyoruz.
ENV ASPNETCORE_HTTP_PORTS=80

ENV RngApi__Url=http://numbers-api/rng

ENTRYPOINT ["dotnet", "/app/Numbers.Web.dll"]

WORKDIR /app
COPY --from=builder /out/ .

ARG BUILD_TAG=local
ARG COMMIT_SHA=local
LABEL build_tag=${BUILD_TAG}
LABEL commit_sha=${COMMIT_SHA}