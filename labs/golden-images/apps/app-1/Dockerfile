# DELIBERATELY the bad example: one stage, a decade-old Java, and the full
# JDK kept in the runtime image - on a base image from a different vendor
# and a different Linux distro than app-2, so the two share no layers.
#
# Upstream used Docker Hub's `java:8-jdk` here. Both `java` and the `openjdk`
# image that replaced it have been REMOVED from Docker Hub, so this Dockerfile
# no longer built at all. Amazon Corretto 8 keeps every part of the lesson
# intact - ancient runtime, JDK at runtime, unrelated base - and is still
# published for amd64 and arm64.
FROM amazoncorretto:8

WORKDIR /src
COPY HelloWorld.java .

RUN mkdir -p /out/bin && \
    javac -d /out/bin HelloWorld.java

WORKDIR /out/bin
CMD java HelloWorld
