FROM maven:3.10-eclipse-temurin-25-noble AS builder
ARG SONAR_PROJECT='hello-world-java'
ARG SONAR_URL='http://host.docker.internal:9000'
ARG SONAR_TOKEN=''
ARG SONAR_ENFORCE_GATE='false'

WORKDIR /usr/src/helloworld
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY . .
RUN mvn package

RUN if [ "$SONAR_TOKEN" != "" ] ; then \
        mvn sonar:sonar \
        -Dsonar.projectKey=$SONAR_PROJECT \
        -Dsonar.host.url=$SONAR_URL \
        -Dsonar.token=$SONAR_TOKEN \
        -Dsonar.qualitygate.wait=$SONAR_ENFORCE_GATE ; \
    fi

# app
FROM eclipse-temurin:25-jre

WORKDIR /app
COPY --from=builder /usr/src/helloworld/target/helloworld-0.1.0.jar .

ENTRYPOINT ["java", "-jar", "/app/helloworld-0.1.0.jar"]
