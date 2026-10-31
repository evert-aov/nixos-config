#!/usr/bin/env bash
export QS_CACHE_DIR="$HOME/.cache/quickshell"
export QS_STATE_DIR="$HOME/.local/state/quickshell"
export QS_RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell"
export QS_LOG_DIR="$QS_RUN_DIR/logs"

if [[ ! -d "$QS_CACHE_DIR" || ! -d "$QS_STATE_DIR" || ! -d "$QS_RUN_DIR" || ! -d "$QS_LOG_DIR" ]]; then
    mkdir -p "$QS_CACHE_DIR" "$QS_STATE_DIR" "$QS_RUN_DIR" "$QS_LOG_DIR"
fi

# Function to dynamically create and export cache directories for ANY module by request
qs_ensure_cache() {
    local WIDGET_NAME="$1"
    local WIDGET_UPPER="${WIDGET_NAME^^}"
    
    local WIDGET_CACHE="$QS_CACHE_DIR/$WIDGET_NAME"
    local WIDGET_STATE="$QS_STATE_DIR/$WIDGET_NAME"
    local WIDGET_RUN="$QS_RUN_DIR/$WIDGET_NAME"
    
    if [[ ! -d "$WIDGET_CACHE" || ! -d "$WIDGET_STATE" || ! -d "$WIDGET_RUN" ]]; then
        mkdir -p "$WIDGET_CACHE" "$WIDGET_STATE" "$WIDGET_RUN"
    fi
    
    export "QS_CACHE_${WIDGET_UPPER}=$WIDGET_CACHE"
    export "QS_STATE_${WIDGET_UPPER}=$WIDGET_STATE"
    export "QS_RUN_${WIDGET_UPPER}=$WIDGET_RUN"
}

# Each caller initializes only the modules it uses with qs_ensure_cache.
# Event listeners need only the root runtime directory for their FIFO.
