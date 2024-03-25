FROM openjdk:8-jdk-alpine
# Environment Variable that defines the endpoint of sentiment-analysis python api.
ENV SA_LOGIC_API_URL http://172.17.0.2:5000
ADD target/container-webapp-0.0.1-SNAPSHOT.jar /
EXPOSE 8080
CMD ["java", "-jar", "container-webapp-0.0.1-SNAPSHOT.jar", "--sa.logic.api.url=${SA_LOGIC_API_URL}"]
