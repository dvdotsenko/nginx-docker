#!/bin/bash
set -e

echo "Command: $@"

perl -w -- /usr/local/bin/resolve_env_vars.pl /etc/nginx /etc/nginx/conf.d

exec "$@"
