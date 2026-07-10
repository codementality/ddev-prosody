# ddev-prosody

A [DDEV](https://ddev.com) addon that adds Prosody IM's [official Docker image](https://hub.docker.com/r/prosody/prosody) as an additional service, for local development and testing of XMPP clients (e.g. a Drupal module).

## Installation

From your DDEV project root:

```bash
ddev add-on get codementality/ddev-prosody
ddev restart
```

## What you get

- A `prosody` service running alongside your project, reachable from both the host and other DDEV containers (including your `web` container) as `prosody`.
- Ports published directly to the host:
  - `5222` — c2s (client-to-server). This is what a server-side PHP client (e.g. [xmpp-php](../xmpp-php)) or any native XMPP client library will connect to.
  - `5269` — s2s (server federation). Not needed for a single-server dev setup but left open in case you test federation.
  - `5280` — plain HTTP (BOSH, WebSocket, admin).
  - `5281` — HTTPS/WSS (BOSH, WebSocket), using the image's bundled self-signed cert for `localhost`. Browsers/clients will warn about the untrusted CA — that's expected for a local dev cert.
- A minimal `prosody.cfg.lua` (in `.ddev/prosody/prosody.cfg.lua` after install) with:
  - `VirtualHost "localhost"` — the JID domain. Note this is independent of the network address you connect to; `user@localhost` will authenticate fine even though you dial `127.0.0.1:5222`.
  - c2s/s2s encryption not required, and PLAIN auth allowed unencrypted — the image's bundled cert makes TLS *available* (see below), but common PHP XMPP libraries (e.g. xmpp-php) don't support STARTTLS, so port 5222 stays usable without it. Not something to lock down further unless your client actually negotiates TLS.
  - HTTPS/WSS on port 5281 works out of the box. The image's bundled cert key ships `600 root:root`, unreadable by the unprivileged `prosody` user the server runs as — `prosody/docker-entrypoint-wrapper.sh` fixes that permission as root before handing off to the image's real entrypoint.
  - `mod_bosh` and `mod_websocket` enabled, so you can build/test a browser-based client (e.g. Strophe.js) against `http://<project>.ddev.site:5280/http-bind` / `ws://<project>.ddev.site:5280/xmpp-websocket`, or the encrypted equivalents on port 5281, without needing a second addon.
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

This config is intentionally minimal and meant for local development/testing only, not production. HTTPS/WSS (port 5281) is encrypted with a self-signed cert, but plain c2s (port 5222) and BOSH/WebSocket over HTTP (port 5280) are not — deliberately, so PLAIN-auth-only clients like xmpp-php keep working without extra setup. Don't point this config at a real deployment.
