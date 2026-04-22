FROM python:3.11-slim AS backend-base
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM node:20-slim AS frontend-build
WORKDIR /frontend
COPY frontend/package.json .
RUN npm install
COPY frontend/ .
RUN npm run build

FROM backend-base AS final
WORKDIR /app
COPY backend/ ./backend/
COPY --from=frontend-build /frontend/dist ./frontend/dist
RUN mkdir -p /app/data/files

ENV PYTHONPATH=/app
EXPOSE 8000
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
