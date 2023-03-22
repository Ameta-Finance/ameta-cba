FROM azul/zulu-openjdk:17 AS builder

RUN apt-get update -qq && apt-get install -y wget

COPY . fineract
WORKDIR fineract


RUN ./gradlew --no-daemon -q  -x compileTestJava -x test -x spotlessJavaCheck -x spotlessJava bootJar
RUN mv /fineract/fineract-provider/build/libs/*.jar /fineract/fineract-provider/build/libs/fineract-provider.jar

WORKDIR /app/libs
RUN wget -q https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.23/mysql-connector-java-8.0.23.jar

FROM azul/zulu-openjdk:17 as fineract

# 

COPY --from=builder /fineract/fineract-provider/build/libs/ /app
COPY --from=builder /app/libs /app/libs

ENV TZ="UTC"
ENV FINERACT_HIKARI_DRIVER_SOURCE_CLASS_NAME="com.mysql.cj.jdbc.Driver"
ENV FINERACT_HIKARI_MINIMUM_IDLE="1"
ENV FINERACT_HIKARI_MAXIMUM_POOL_SIZE="20"
ENV FINERACT_HIKARI_IDLE_TIMEOUT="120000"
ENV FINERACT_HIKARI_CONNECTION_TIMEOUT="300000"

ENTRYPOINT ["java", "-Dloader.path=/app/libs/", "-jar", "/app/fineract-provider.jar"]