-- Minimal Prosody config for local DDEV development/testing.
-- Not hardened for production use.

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
-- DIGEST-MD5 auth over an unencrypted channel. Since TLS isn't usable in
-- this image (see https_ports below) and common PHP XMPP libraries (e.g.
-- xmpp-php) only implement PLAIN/DIGEST-MD5, allow it here for local dev.
allow_unencrypted_plain_auth = true

authentication = "internal_plain"
storage = "internal"

allow_registration = false -- create accounts with `ddev prosody-adduser` instead

log = {
    info = "*console";
}

http_ports = { 5280 }
https_ports = { } -- the bundled sample cert isn't readable by the prosody
                  -- user in this image, so https/wss is disabled for local
                  -- dev; use ws://.../xmpp-websocket and http://.../http-bind

-- The JID domain your clients will authenticate against. This is
-- independent of the host/port they connect to (localhost:5222) --
-- XMPP lets you specify them separately, so "localhost" works fine
-- even though DDEV project URLs use a different hostname.
VirtualHost "localhost"

Include "conf.d/*.cfg.lua"
