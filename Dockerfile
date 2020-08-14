FROM node:10-slim as core

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf \
      --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
	&& apt-get install -y \
	gconf-service libasound2 libatk1.0-0 \
	libc6 libcairo2 libcups2 \
	libdbus-1-3 libexpat1 libfontconfig1 \
	libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 \
	libglib2.0-0 libgtk-3-0 libnspr4 \
	libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 \
	libx11-6 libx11-xcb1 libxcb1 libxcomposite1 \
	libxcursor1 libxdamage1 libxext6 libxfixes3 \
	libxi6 libxrandr2 libxrender1 libxss1 libxtst6 \
	ca-certificates fonts-liberation libappindicator1 \
	libnss3 lsb-release xdg-utils wget

COPY ./docker/files/usr/local/bin/entrypoint /usr/local/bin/entrypoint

# Give the "root" group the same permissions as the "root" user on /etc/passwd
# to allow a user belonging to the root group to add new users; typically the
# docker user (see entrypoint).
RUN chmod g=u /etc/passwd

# We wrap commands run in this container by the following entrypoint that
# creates a user on-the-fly with the container user ID (see USER) and root group
# ID.
ENTRYPOINT [ "/usr/local/bin/entrypoint" ]

# Un-privileged user running the application
ARG DOCKER_USER=1000
USER ${DOCKER_USER}

CMD ["google-chrome-unstable"]

# ---- Development image ----

FROM core as development

CMD ["/bin/bash"]

# ---- Image to publish ----
FROM core as dist

# Switch back to the root user to install dependencies
USER root:root

COPY . /app/
WORKDIR /app/

# Do not download the chromium version bundled with puppeteer
# We are using google-chrome-unstable instead
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true

RUN yarn install --frozen-lockfile

ARG DOCKER_USER=1000
USER ${DOCKER_USER}

CMD ["./cli.js", "stress"]
