
# ==========================================
# Stage 1: Build Spring Boot Application
# ==========================================
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app

# Install unzip for Gradle Wrapper
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy Gradle configuration first for better caching
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle settings.gradle ./

# Grant execution permission
RUN chmod +x gradlew

# Download dependencies
RUN ./gradlew dependencies --no-daemon

# Copy application source code
COPY src ./src

# Build executable Spring Boot JAR
RUN ./gradlew bootJar --no-daemon -x test


# ==========================================
# Stage 2: Run Spring Boot Application
# ==========================================
FROM eclipse-temurin:21-jre

WORKDIR /app

# Create non-root user for security
RUN useradd --system --uid 1001 spring

# Copy JAR from builder stage
COPY --from=builder --chown=spring:spring /app/build/libs/*.jar app.jar

# Switch to non-root user
USER spring

# Spring Boot default port
EXPOSE 8080

# Start application
ENTRYPOINT ["java", "-jar", "app.jar"]
