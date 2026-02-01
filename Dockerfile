FROM debian:bookworm-slim

ARG HUGO_VERSION
ARG GO_VERSION
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(echo ${TARGETARCH} | sed 's/amd64/amd64/;s/arm64/arm64/') && \
    wget -O /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

RUN ARCH=$(echo ${TARGETARCH} | sed 's/amd64/amd64/;s/arm64/arm64/') && \
    wget -O /tmp/hugo.deb "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb" && \
    dpkg -i /tmp/hugo.deb && \
    rm /tmp/hugo.deb

# Install Dart Sass (required for SCSS compilation)
RUN ARCH=$(echo ${TARGETARCH} | sed 's/amd64/x64/;s/arm64/arm64/') && \
    wget -O /tmp/sass.tar.gz "https://github.com/sass/dart-sass/releases/download/1.83.4/dart-sass-1.83.4-linux-${ARCH}.tar.gz" && \
    tar -C /usr/local -xzf /tmp/sass.tar.gz && \
    rm /tmp/sass.tar.gz

ENV PATH="/usr/local/dart-sass:${PATH}"

WORKDIR /site
EXPOSE 1313

CMD ["hugo", "server", "--bind", "0.0.0.0"]
