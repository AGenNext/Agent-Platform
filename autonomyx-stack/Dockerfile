FROM node:22-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM deps AS build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
ENV AUTONOMYX_MVP_PORT=8080
ENV AUTONOMYX_WEBHOOK_PORT=8443
COPY package.json ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
COPY autonomyx.manifest.yaml ./autonomyx.manifest.yaml
COPY bindings ./bindings
EXPOSE 8080 8443
CMD ["node", "dist/mvp/server.js"]
