#!/usr/bin/env bash

# Source and initialize quickshell dynamic caching
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"
qs_ensure_cache "lock"

exec quickshell --no-duplicate -p ~/.config/hypr/scripts/quickshell/Lock.qml
