FROM eclipse-temurin:25-jdk AS builder

WORKDIR /src
COPY hello-world/src/HelloWorld.java .

RUN mkdir -p /out/bin && \
    javac -d /out/bin HelloWorld.java

# app image
FROM eclipse-temurin:25-jre

WORKDIR /app
COPY --from=builder /out/bin/HelloWorld.class .

CMD java HelloWorld