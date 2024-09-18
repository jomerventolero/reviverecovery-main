FROM node:18-alpine AS builder
WORKDIR /directus

# Add platform-specific packages
ARG TARGETPLATFORM

ENV NODE_OPTIONS=--max-old-space-size=8192

RUN <<EOF
  if [ "$TARGETPLATFORM" = 'linux/arm64' ]; then
  	apk --no-cache add python3 build-base
  	ln -sf /usr/bin/python3 /usr/bin/python
  fi
EOF

COPY package.json . 
RUN corepack enable && corepack prepare

COPY pnpm-lock.yaml . 
RUN pnpm fetch

COPY . . 
RUN <<EOF
  pnpm install --recursive --offline --frozen-lockfile
  npm_config_workspace_concurrency=1 pnpm run build
  pnpm --filter directus deploy --prod dist
  cd dist
  # Regenerate package.json with only the necessary fields
  node -e '
    const fs = require("fs"), f = "package.json", {name, version, type, exports, bin} = require(`./${f}`), {packageManager} = require(`../${f}`);
    fs.writeFileSync(f, JSON.stringify({name, version, type, exports, bin, packageManager}, null, 2));
  '
  mkdir -p database extensions uploads
EOF

# Debugging step to verify if the dist folder is created
RUN ls -l /directus

####################################################################################################
## Production Image

FROM node:18-alpine AS runtime

RUN npm install --global pm2@5

USER node

WORKDIR /directus

EXPOSE 8055

ENV \
  DB_CLIENT="sqlite3" \
  DB_FILENAME="/directus/database/database.sqlite" \
  NODE_ENV="production" \
  NPM_CONFIG_UPDATE_NOTIFIER="false"

COPY --from=builder --chown=node:node /directus/ecosystem.config.cjs . 
COPY --from=builder --chown=node:node /directus/dist .

CMD : \
  && node cli.js bootstrap \
  && pm2-runtime start ecosystem.config.cjs \
  ;
