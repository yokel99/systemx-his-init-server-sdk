# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# Stage 2: Production
FROM node:22-alpine
WORKDIR /app

# อัปเดต security patches ของ system packages
RUN apk upgrade --no-cache

# ติดตั้งเฉพาะ production dependencies
COPY package*.json ./
RUN npm install --omit=dev

# คัดลอกโฟลเดอร์ dist ทั้งหมดมาไว้ที่ ./dist
COPY --from=builder /app/dist ./dist

# คัดลอกโฟลเดอร์และไฟล์ที่จำเป็นอื่นๆ มาไว้ที่ Root
COPY --from=builder /app/migrations ./migrations
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/mongo-func.js ./
COPY --from=builder /app/migrate.js ./
COPY --from=builder /app/rollback.js ./

# ใช้ non-root user เพื่อความปลอดภัย
RUN addgroup -S appuser && adduser -S appuser -G appuser \
    && chown -R appuser:appuser /app
USER appuser

ENV PORT=3005
ENV NODE_ENV=production
EXPOSE 3005

# รัน migration ก่อน แล้วจึงเริ่ม server
CMD ["sh", "-c", "node migrate.js && node dist/server.js"]