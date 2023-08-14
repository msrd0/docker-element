# syntax=docker/dockerfile:1.3

FROM --platform=$BUILDPLATFORM rust:slim-bookworm AS builder
SHELL ["/bin/bash", "-uo", "pipefail", "-c"]

# add clang and mold for cross-linking support. should also help with build time.
RUN apt-get -y update \
 && apt-get -y install clang mold
COPY .cargo/config.toml ~/.cargo/config.toml

# install oxipng for the build architecture - we will only run this inside this container
RUN cargo install oxipng -v --locked

# add the rust target for the target architecture
ARG TARGETPLATFORM
RUN if   [ "$TARGETPLATFORM" == "linux/amd64"  ]; then echo "x86_64-unknown-linux-musl" >/.target; \
    elif [ "$TARGETPLATFORM" == "linux/arm64"  ]; then echo "aarch64-unknown-linux-musl" >/.target; \
    elif [ "$TARGETPLATFORM" == "linux/arm/v7" ]; then echo "armv7-unknown-linux-musleabihf" >/.target; \
    else echo "Unknown architecture $TARGETPLATFORM"; exit 1; \
    fi
RUN rustup target add "$(cat /.target)"

# Update this version when a new version of element is released
ENV ELEMENT_VERSION 1.11.38

RUN mkdir /src
WORKDIR /src
COPY . .
RUN cargo build -v --release --locked --target "$(cat /.target)" \
 && mv "target/$(cat /.target)/release/element" .

WORKDIR /
COPY E95B7699E80B68A9EAD9A19A2BAA9B8552BD9047.key .
RUN apt-get -y update \
 && apt-get -y install gpg wget \
 && wget -qO element.tar.gz "https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz" \
 && wget -qO element.tar.gz.asc "https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz.asc" \
 && gpg --batch --import E95B7699E80B68A9EAD9A19A2BAA9B8552BD9047.key \
 && gpg --batch --verify element.tar.gz{.asc,} \
 && mkdir -p /opt/element \
 && tar xfz element.tar.gz --strip-components=1 -C /opt/element \
 && rm /opt/element/config.sample.json; \
    find /opt/element -name '*.png' | while read file; do oxipng -o6 "$file"; done; \
    find /opt/element -name '*.html' -or -name '*.js' -or -name '*.css' -or -name '*.html' -or -name '*.svg' -or -name '*.json' | while read file; do gzip -k9 "$file"; done

########################################################################################################################

FROM --platform=$TARGETPLATFORM scratch

COPY --from=builder /src/element /bin/element
COPY --from=builder /opt/element /opt/element

EXPOSE 80
HEALTHCHECK CMD ["/bin/element", "healthcheck"]
CMD ["/bin/element", "server"]
