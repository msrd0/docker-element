# docker-element [![Rust](https://github.com/msrd0/docker-element/actions/workflows/rust.yml/badge.svg)](https://github.com/msrd0/docker-element/actions/workflows/rust.yml) [![Rust](https://github.com/msrd0/docker-element/actions/workflows/rust.yml/badge.svg)](https://github.com/msrd0/docker-element/actions/workflows/rust.yml)

Docker Image: [`ghcr.io/msrd0/element`](https://github.com/users/msrd0/packages/container/package/element)

This docker image contains [Element](https://github.com/vector-im/element-web), a matrix client, served by a custom
server written in Rust that creates a config based on environment variables, and allows the docker image to be created
from `scratch` instead of a distribution's image.

## Environment Variables

- `DEFAULT_HS_URL`: The default homeserver url. This should be the full url to your matrix server, which
  might be different from the domain part of your username. Defaults to `https://matrix.org` if not
  present.

- `DEFAULT_IS_URL`: The default integration server url. Defaults to `https://vector.im`.
- `INTEGRATIONS_UI_URL`: Defaults to `https://scalar.vector.im`.
- `INTEGRATIONS_REST_URL`: Defaults to `https://scalar.vector.im/api`.

- `BRAND`: The branding of your matrix client. Defaults to `Element`.

- `DEFAULT_THEME`: The default theme of the client. Defaults to `dark`.

- `DEFAULT_COUNTRY_CODE`: Defaults to `DE`.
