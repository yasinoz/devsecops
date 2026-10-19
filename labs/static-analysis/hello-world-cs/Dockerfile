
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS sdk

# Sonar Scanner CLI bir JRE gerektiriyor.
#
# 'openjdk-11-jre' PAKETI ARTIK YOK: .NET 10 SDK imaji daha yeni bir
# Debian uzerinde ve o surum openjdk-11 paketlemiyor, apt-get install
# basarisiz oluyor ve build patliyor. 'default-jre-headless' hangi Debian
# surumu olursa olsun cozulur ve masaustu bagimliligi getirmez.
RUN apt-get update && \
    apt-get install -y --no-install-recommends default-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Install the scanner:
RUN dotnet tool install --tool-path /usr/bin dotnet-sonarscanner

FROM sdk AS build
ARG SONAR_PROJECT='hello-world-cs'
ARG SONAR_URL='http://host.docker.internal:9000'
ARG SONAR_TOKEN=''
ARG SONAR_ENFORCE_GATE='false'

WORKDIR /src
COPY ["hello-world.csproj", "."]
RUN dotnet restore "./hello-world.csproj"

COPY . .
RUN if [ "$SONAR_TOKEN" != "" ] ; then dotnet sonarscanner begin /k:$SONAR_PROJECT /d:sonar.host.url=$SONAR_URL /d:sonar.token=$SONAR_TOKEN /d:sonar.qualitygate.wait=$SONAR_ENFORCE_GATE ; fi
RUN dotnet build "hello-world.csproj" -c Release
RUN if [ "$SONAR_TOKEN" != "" ] ; then dotnet sonarscanner end /d:sonar.token=$SONAR_TOKEN ; fi

RUN dotnet publish "hello-world.csproj" -c Release -o /out

FROM mcr.microsoft.com/dotnet/runtime:10.0
WORKDIR /app
COPY --from=build /out .
ENTRYPOINT ["dotnet", "hello-world.dll"]