#!/bin/sh
#ddev-generated
set -e

# The image's bundled cert key (/etc/prosody/certs/localhost.key) is mode
# 600 root:root, unreadable once the real entrypoint drops from root to the
# unprivileged prosody user via setpriv. We run as root here (before that
# happens), so fix the permissions and hand off to the original entrypoint.
chmod 644 /etc/prosody/certs/*.key 2>/dev/null || true

exec /entrypoint.sh "$@"
