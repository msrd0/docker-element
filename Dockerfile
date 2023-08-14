FROM alpine as selecter
ARG TARGETPLATFORM
ADD github_artifacts /github_artifacts
RUN set -eux; \
    if [[ $TARGETPLATFORM == "linux/386" ]];    then target="i686-unknown-linux-musl"; fi; \
    if [[ $TARGETPLATFORM == "linux/amd64" ]];  then target="x86_64-unknown-linux-musl"; fi; \
    if [[ $TARGETPLATFORM == "linux/arm/v6" ]]; then target="arm-unknown-linux-musleabihf"; fi; \
    if [[ $TARGETPLATFORM == "linux/arm/v7" ]]; then target="armv7-unknown-linux-musleabihf"; fi; \
    if [[ $TARGETPLATFORM == "linux/arm64" ]];  then target="aarch64-unknown-linux-musl"; fi; \
    cp /github_artifacts/$target/element /element
RUN tee /github_artifacts/element

########################################################################################################################

FROM scratch

COPY --from=builder /src/element /bin/element
COPY --from=builder /opt/element /opt/element

EXPOSE 80
HEALTHCHECK CMD ["/bin/element", "healthcheck"]
CMD ["/bin/element", "server"]
