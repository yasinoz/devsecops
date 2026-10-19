# Lab Hints

Don't worry about installing Java - the official [Eclipse Temurin](https://hub.docker.com/_/eclipse-temurin) image does that for you. (Docker Hub's old `openjdk` image is deprecated, so don't reach for that one.) The app was compiled for Java 8, but newer JVMs still run older class files, so a current JRE is fine.

The Dockerfile should be straightforward, but you need to think about the paths. The Java class file may be in a different directory from your Dockerfile, and Docker needs to access both from the context.

Also the Java command inside the container needs to use the correct path to find the class file you copy into the image.

> Need more? Here's the [solution](solution.md).
