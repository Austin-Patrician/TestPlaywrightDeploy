# ==============================================
# Single-stage build: reliable for testing
# ==============================================
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Restore NuGet packages (layer caching)
COPY TestPlaywrightDeploy/TestPlaywrightDeploy.csproj TestPlaywrightDeploy/
RUN dotnet restore TestPlaywrightDeploy/TestPlaywrightDeploy.csproj

# Copy full source and publish
COPY . .
WORKDIR /src/TestPlaywrightDeploy
RUN dotnet publish -c Release -o /app

# Install Playwright CLI + Chromium browser with all system dependencies
RUN dotnet tool install --global Microsoft.Playwright.CLI
ENV PATH="${PATH}:/root/.dotnet/tools"
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN playwright install --with-deps chromium

# ==============================================
# Runtime
# ==============================================
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright

ENTRYPOINT ["dotnet", "TestPlaywrightDeploy.dll"]