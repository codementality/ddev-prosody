# ddev-prosody

A [DDEV](https://ddev.com) addon that adds Prosody IM's [official Docker image](https://hub.docker.com/r/prosody/prosody) as an additional service, for local development and testing of XMPP clients (e.g. a Drupal module).

## Installation

From your DDEV project root:

```bash
ddev get /path/to/ddev-prosody   # or a git URL once this is pushed somewhere
ddev restart
```

## What you get

- A `prosody` service running alongside your project, reachable from both the host and other DDEV containers (including your `web` container) as `prosody`.
- Ports published directly to the host:
  - `5222` — c2s (client-to-server). This is what a server-side PHP client (e.g. [xmpp-php](../xmpp-php)) or any native XMPP client library will connect to.
  - `5269` — s2s (server federation). Not needed for a single-server dev setup but left open in case you test federation.
  - `5280` — plain HTTP (BOSH, WebSocket, admin).
- A minimal `prosody.cfg.lua` (in `.ddev/prosody/prosody.cfg.lua` after install) with:
  - `VirtualHost "localhost"` — the JID domain. Note this is independent of the network address you connect to; `user@localhost` will authenticate fine even though you dial `127.0.0.1:5222`.
  - TLS not required and HTTPS/WSS disabled — the image's bundled cert is owned by `root` and unreadable by the `prosody` user it runs as, so port 5281 fails to bind. Fine for local dev over plain c2s/HTTP; not something to fix unless you actually need TLS locally.
  - `mod_bosh` and `mod_websocket` enabled, so you can build/test a browser-based client (e.g. Strophe.js) against `http://<project>.ddev.site:5280/http-bind` or `ws://<project>.ddev.site:5280/xmpp-websocket` later, without needing a second addon.
  - Registration locked down (`allow_registration = false`) — create accounts explicitly, see below.

## Creating test accounts

```bash
ddev prosody-adduser testuser localhost secret123
```

This gives you a JID of `testuser@localhost` with password `secret123` to connect with from your client code.

## Connecting from PHP (e.g. xmpp-php)

From the `web` container or the host, connect to:

- Host: `prosody` (from inside DDEV containers) or `127.0.0.1` (from the host)
- Port: `5222`
- JID domain: `localhost`

## Logs

```bash
ddev prosody-logs --follow
```

## Customizing the config

Edit `.ddev/prosody/prosody.cfg.lua` directly, or drop additional `*.cfg.lua` snippets into `.ddev/prosody/conf.d/` (already mounted into the container at `/etc/prosody/conf.d/`). Run `ddev restart` after changes.

## Caveats

This config is intentionally minimal and unencrypted — it's meant for local development/testing only, not production.
