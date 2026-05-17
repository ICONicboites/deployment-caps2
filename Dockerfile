# Multi-stage build: build frontend, include into backend resources, build backend jar, produce runtime image

# Frontend build
FROM node:18-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --silent
COPY frontend/ .
RUN npm run build

# Backend build
FROM maven:3.8.8-eclipse-temurin-17 AS backend-build
WORKDIR /app
# copy backend pom and source
COPY backend/pom.xml backend/
COPY backend/ backend/
# copy built frontend into backend resources so Spring Boot serves static files
COPY --from=frontend-build /app/frontend/build backend/src/main/resources/static
# Build the backend jar
RUN mvn -f backend/pom.xml clean package -DskipTests -q

# Runtime image
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=backend-build /app/backend/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
