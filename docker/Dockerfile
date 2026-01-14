# Build stage
FROM node:22-alpine AS build

# Install pnpm
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

WORKDIR /app

# Copy package files for dependency installation
COPY package.json pnpm-workspace.yaml pnpm-lock.yaml ./
COPY packages/core/package.json ./packages/core/
COPY apps/web/package.json ./apps/web/

RUN pnpm install --frozen-lockfile

# Copy source files
COPY . .

# Build the web app (builds core dependency first via turbo)
RUN pnpm build --filter=@rsvp/web

# Production stage
FROM nginx:alpine

COPY --from=build /app/apps/web/dist /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
