# Docker Hub'daki 'openjdk' resmi imaji kullanimdan kaldirildi; Java'nin
# resmi dagitimi artik eclipse-temurin uzerinden geliyor.
#
# HelloWorld.class Java 8 ile derlendi ama yeni JVM'ler eski class
# dosyalarini calistirmaya devam ediyor - bu yuzden guncel JRE sorun degil.
FROM eclipse-temurin:25-jre

WORKDIR /app
COPY java/HelloWorld.class .

CMD ["java", "HelloWorld"]
