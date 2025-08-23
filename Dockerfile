# Stage 1: Base image with common dependencies
FROM python:3.11-slim-bullseye AS base
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Create a non-root user
RUN addgroup --system app && adduser --system --group app

# Copy and install requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy shared modules that might be needed by services
COPY model /app/model

# Stage 2: Builder for the API service
FROM base AS api_builder
COPY ./services/api /app/services/api

# Stage 3: Final image for the API service
FROM base AS api
COPY --from=api_builder /app /app
USER app
EXPOSE 8080
CMD ["uvicorn", "services.api.main:app", "--host", "0.0.0.0", "--port", "8080"]

# Stage 4: Builder for the Executor service
FROM base AS executor_builder
COPY ./services/executor /app/services/executor
COPY ./contracts /app/contracts

# Stage 5: Final image for the Executor service
FROM base AS executor
COPY --from=executor_builder /app /app
USER app
CMD ["python", "-m", "services.executor.main"]
