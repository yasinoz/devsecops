FROM maven:3.10-eclipse-temurin-25-noble AS builder

WORKDIR /usr/src/helloworld
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY . .
RUN mvn package

# app
FROM eclipse-temurin:25-jre

WORKDIR /app
COPY --from=builder /usr/src/helloworld/target/helloworld-0.1.0.jar .

ENTRYPOINT ["java", "-jar", "/app/helloworld-0.1.0.jar"]
