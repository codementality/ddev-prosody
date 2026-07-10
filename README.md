# ddev-prosody

A [DDEV](https://ddev.com) addon that adds Prosody IM's [official Docker image](https://hub.docker.com/r/prosody/prosody) as an additional service, for local development and testing of XMPP clients (e.g. a Drupal module).

## Installation

From your DDEV project root:

```bash
ddev add-on get /path/to/ddev-prosody   # or a git URL once this is pushed somewhere
ddev restart
```

## What you get

- A `prosody` service running alongside your project, reachable from both the host and other DDEV containers (including your `web` container) as `prosody`.
- Raw TCP ports published directly to the host (these bypass `ddev-router`, which only proxies HTTP(S)):
  - `5222` — c2s (client-to-server). This is what a server-side PHP client (e.g. [xmpp-php](../xmpp-php)) or any native XMPP client library will connect to.
  - `5269` — s2s (server federation). Not needed for a single-server dev setup but left open in case you test federation.
- BOSH/WebSocket, routed through `ddev-router` the same way DDEV's other addons (e.g. Solr) expose extra services, so you get a real URL with a trusted cert instead of a raw port:
  - `http://<project>.ddev.site:5280/http-bind` / `ws://<project>.ddev.site:5280/xmpp-websocket`
  - `https://<project>.ddev.site:5281/http-bind` / `wss://<project>.ddev.site:5281/xmpp-websocket` — TLS is terminated by `ddev-router` using DDEV's trusted mkcert wildcard cert, so there's no self-signed-cert warning. Prosody itself only ever serves plain HTTP internally on 5280; it has no cert configured.
- A minimal `prosody.cfg.lua` (in `.ddev/prosody/prosody.cfg.lua` after install) with:
  - `VirtualHost` set to `$DDEV_HOSTNAME` (e.g. `xmpp-dev.ddev.site`) — the JID domain, read from the container's `DDEV_HOSTNAME` env var, falling back to `localhost` if unset. Note the JID domain is independent of the network address/port you connect to; `user@xmpp-dev.ddev.site` will authenticate fine over a raw socket dialed at `127.0.0.1:5222`.
  - c2s/s2s encryption not required, and PLAIN auth allowed unencrypted, since common PHP XMPP libraries (e.g. xmpp-php) don't support STARTTLS. Port 5222 has no TLS available at all. Not something to lock down further unless your client actually negotiates TLS.
  - `mod_bosh` and `mod_websocket` enabled.
  - Registration locked down (`allow_registration = false`) — create accounts explicitly, see below.

## Creating test accounts

```bash
ddev prosody-adduser testuser xmpp-dev.ddev.site secret123
```

(substitute your project's actual DDEV hostname, shown by `ddev describe`). This gives you a JID of `testuser@xmpp-dev.ddev.site` with password `secret123` to connect with from your client code.

## Connecting from PHP (e.g. xmpp-php)

From the `web` container or the host, connect to:

- Host: `prosody` (from inside DDEV containers) or `127.0.0.1` (from the host)
- Port: `5222`
- JID domain: your project's DDEV hostname, e.g. `xmpp-dev.ddev.site`

## Logs

```bash
ddev prosody-logs --follow
```

## Customizing the config

Edit `.ddev/prosody/prosody.cfg.lua` directly, or drop additional `*.cfg.lua` snippets into `.ddev/prosody/conf.d/` (already mounted into the container at `/etc/prosody/conf.d/`). Run `ddev restart` after changes.

## Caveats

This config is intentionally minimal and meant for local development/testing only, not production. Raw c2s/s2s (ports 5222/5269) are unencrypted — deliberately, so PLAIN-auth-only clients like xmpp-php keep working without extra setup — and are published directly to the host rather than through `ddev-router`, so anything on your machine can reach them (no different from any other DDEV service on a direct port). Don't point this config at a real deployment.
