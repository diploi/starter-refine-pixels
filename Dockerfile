# This will be set by the GitHub action to the folder containing this component.
ARG FOLDER=/app

FROM node:24-slim AS base
ARG FOLDER

# Install dependencies only when needed
FROM base AS deps

COPY . /app
WORKDIR ${FOLDER}

# Install dependencies based on the preferred package manager
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Rebuild the source code only when needed
FROM base AS builder
COPY . /app
WORKDIR ${FOLDER}
COPY --from=deps ${FOLDER}/node_modules ./node_modules

RUN npm run build

# Production image, copy all the built files
# NOTE: Build will be run again in an init-container to allow for runtime ENV
FROM base AS runner

COPY --from=builder --chown=1000:1000 /app /app
WORKDIR ${FOLDER}

ENV NODE_ENV=production

USER 1000:1000

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin
RUN npm i -g serve

EXPOSE 80
ENV PORT=80
ENV HOSTNAME="0.0.0.0"

CMD ["serve", "-s", "-l", "80", "dist"]