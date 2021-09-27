FROM rust:slim AS rust

ENV TARGET x86_64-unknown-linux-musl
RUN rustup target add "$TARGET"

RUN mkdir /src
WORKDIR /src
COPY . .
RUN cargo build --release --locked --target "$TARGET" \
 && mv "target/$TARGET/release/element" . \
 && strip element

###################################################################################################

FROM ghcr.io/maxx-timing/oxipng AS element
SHELL ["/bin/ash", "-uo", "pipefail", "-c"]

ENV ELEMENT_VERSION 1.9.0
ENV GPG_KEY E95B7699E80B68A9EAD9A19A2BAA9B8552BD9047

RUN apk add --no-cache \
		ca-certificates \
		tar \
		gnupg \
	&& wget -qO element.tar.gz \
		"https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz" \
	&& wget -qO element.tar.gz.asc \
		"https://github.com/vector-im/element-web/releases/download/v$ELEMENT_VERSION/element-v$ELEMENT_VERSION.tar.gz.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found=''; \
		for server in \
			ha.pool.sks-keyservers.net \
			hkp://keyserver.ubuntu.com:80 \
			hkp://p80.pool.sks-keyservers.net:80 \
			pgp.mit.edu \
		; do \
			echo "Fetching GPG key $GPG_KEY from $server"; \
			gpg --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPG_KEY" && found=yes && break; \
		done; \
		test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPG_KEY" && exit 1; \
	gpg --batch --verify element.tar.gz.asc element.tar.gz \
	&& mkdir -p /opt/element \
	&& tar xfz element.tar.gz --strip-components=1 -C /opt/element \
	&& rm /opt/element/config.sample.json; \
	find /opt/element -name '*.png' | while read file; do \
		oxipng -o6 "$file"; \
	done; \
	find /opt/element -name '*.html' -or -name '*.js' -or -name '*.css' -or -name '*.html' -or -name '*.svg' -or -name '*.json' | while read file; do \
		gzip -k9 "$file"; \
	done

###################################################################################################

FROM scratch

COPY --from=rust /src/element /bin/element
COPY --from=element /opt/element /opt/element

EXPOSE 80
HEALTHCHECK CMD ["/bin/element", "healthcheck"]
CMD ["/bin/element", "server"]
