-- Minimal Prosody config for local DDEV development/testing.
-- Not hardened for production use.

-- Without this, Prosody detaches to the background and the container's
-- PID 1 exits immediately.
daemonize = false;

admins = { }

modules_enabled = {
    "roster"; "saslauth"; "tls"; "dialback"; "disco";
    "carbons"; "pep"; "private"; "blocklist"; "vcard4"; "vcard_legacy";
    "version"; "uptime"; "time"; "ping";
    "register"; -- lets prosodyctl create accounts, and optional in-band registration
    "mam"; "csi_simple";
    "bosh"; "websocket"; -- HTTP transports for browser-based clients
    "admin_adhoc";
}

-- No TLS certs are provisioned by default, so connections are unencrypted.
-- Fine for local dev; do not point this config at a real deployment.
c2s_require_encryption = false
s2s_require_encryption = false
s2s_secure_auth = false

-- Without this, Prosody only advertises SCRAM-SHA-1 and refuses PLAIN/
-- DIGEST-MD5 auth over an unencrypted channel. Common PHP XMPP libraries
-- (e.g. xmpp-php) only implement PLAIN/DIGEST-MD5, so allow it here for
-- local dev.
allow_unencrypted_plain_auth = true

authentication = "internal_plain"
storage = "internal"

allow_registration = false -- create accounts with `ddev prosody-adduser` instead

log = {
    info = "*console";
}

-- BOSH/WebSocket are served here as plain HTTP; ddev-router terminates
-- TLS in front of this using DDEV's trusted mkcert wildcard cert (see
-- HTTPS_EXPOSE in docker-compose.prosody.yaml), so no cert is configured
-- here and https_ports is left empty.
http_ports = { 5280 }
https_ports = { }

-- The JID domain your clients will authenticate against, e.g.
-- user@xmpp-dev.ddev.site. Set from the DDEV_HOSTNAME env var (see
-- docker-compose.prosody.yaml) so it matches this project's actual
-- hostname; falls back to "localhost" if that's unset. Note the domain
-- is independent of the network address/port a client dials (5222,
-- 5281, etc.) -- XMPP lets you specify them separately.
VirtualHost(os.getenv("DDEV_HOSTNAME") or "localhost")

Include "conf.d/*.cfg.lua"
