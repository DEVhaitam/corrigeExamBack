# Stage 1: Build the Quarkus application with Maven
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Cache dependency downloads by resolving dependencies before copying source
COPY pom.xml .
COPY sonar-project.properties .
COPY .mvn .mvn
RUN mvn dependency:go-offline -q -Denforcer.skip=true || true

COPY src src
RUN mvn -Pprod clean package -DskipTests -Denforcer.skip=true

# Stage 2: Minimal JRE runtime image (multi-arch: supports amd64 + arm64)
FROM eclipse-temurin:17-jre
WORKDIR /deployments

COPY --from=build /app/target/quarkus-app/lib/ lib/
COPY --from=build /app/target/quarkus-app/*.jar ./
COPY --from=build /app/target/quarkus-app/app/ app/
COPY --from=build /app/target/quarkus-app/quarkus/ quarkus/

ENV JAVA_OPTS="-Dquarkus.http.host=0.0.0.0 -Djava.util.logging.manager=org.jboss.logmanager.LogManager"
EXPOSE 8080

CMD ["sh", "-c", "java $JAVA_OPTS -jar quarkus-run.jar"]
