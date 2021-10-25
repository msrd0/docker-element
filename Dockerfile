FROM rust:slim AS builder
SHELL ["/bin/bash", "-uo", "pipefail", "-c"]

RUN cargo install oxipng --locked

ENV TARGET x86_64-unknown-linux-musl
RUN rustup target add "$TARGET"

# Update this version when a new version of element is released
ENV ELEMENT_VERSION 1.9.3

RUN mkdir /src
WORKDIR /src
COPY . .
RUN cargo build --release --locked --target "$TARGET" \
 && mv "target/$TARGET/release/element" . \
 && strip element

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

FROM scratch

COPY --from=builder /src/element /bin/element
COPY --from=builder /opt/element /opt/element

EXPOSE 80
HEALTHCHECK CMD ["/bin/element", "healthcheck"]
CMD ["/bin/element", "server"]
