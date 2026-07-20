# ==============================================
# Stage 1: Build the .NET application
# ==============================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore project
COPY TestPlaywrightDeploy/TestPlaywrightDeploy.csproj TestPlaywrightDeploy/
RUN dotnet restore TestPlaywrightDeploy/TestPlaywrightDeploy.csproj

# Build and publish
COPY . .
WORKDIR /src/TestPlaywrightDeploy
RUN dotnet publish -c Release -o /app/publish

# ==============================================
# Stage 2: Install Playwright browsers
# ==============================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS playwright

# Install system dependencies required by Playwright browsers
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libdbus-1-3 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2 \
    libatspi2.0-0 libwayland-client0 libwayland-cursor0 \
    libwayland-egl1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Install Playwright CLI and Chromium
RUN dotnet tool install --global Microsoft.Playwright.CLI
ENV PATH="${PATH}:/root/.dotnet/tools"
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN playwright install chromium

# ==============================================
# Stage 3: Runtime image
# ==============================================
FROM mcr.microsoft.com/dotnet/aspnet:10.0

# Install Playwright runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libnss3 libnspr4 libatk1.0-0t64 libatk-bridge2.0-0t64 \
    libcups2t64 libdrm2 libdbus-1-3 libxkbcommon0 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
    libgbm1 libpango-1.0-0 libcairo2 libasound2t64 \
    libatspi2.0-0t64 libwayland-client0 libwayland-cursor0 \
    libwayland-egl1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Copy Playwright Chromium browser from the playwright stage
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
COPY --from=playwright /ms-playwright /ms-playwright

# Copy published .NET application
COPY --from=build /app/publish /app

WORKDIR /app
EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "TestPlaywrightDeploy.dll"]
