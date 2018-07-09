FROM openjdk:slim

EXPOSE 8080
ADD app.jar app.jar
ENTRYPOINT ["java","-jar","app.jar"]

