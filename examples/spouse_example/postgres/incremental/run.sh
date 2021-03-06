#!/usr/bin/env bash
# A lower-level script for compiling DDlog program and running it with DeepDive
# Usage: run.sh DDLOG_FILE DDLOG_MODE PIPELINE [DEEPDIVE_ARG...]
#
# DDLOG_MODE is one of: --materialization or --incremental or --merge
#
# Not intended to be used directly by users.  Please use the higher-level scripts.
set -eux

DDlog=$1; shift
Mode=$1; shift
Pipeline=$1; shift
Out=$1; shift

# sanitize Mode and default to original
case $Mode in
    --materialization|--incremental|--merge) ;;
    *) Mode=
esac

appConf="${DDlog%.ddlog}${Mode:+.${Mode#--}}.deepdive.conf"
userConf="$(dirname "$DDlog")"/deepdive.conf

# compile deepdive.conf from DDlog if necessary
[[ "$appConf" -nt "$DDlog" && "$appConf" -nt "$userConf" ]] || {
    ddlog compile $Mode "$DDlog"
    cat "$userConf"
} >"$appConf"

# XXX `readlink -f` isn't portable, hence these nasty workarounds
appConf="$(cd "$(dirname "$appConf")" && pwd)/$(basename "$appConf")"
Out=$(mkdir -p "$Out" && cd "$Out" && pwd)
BASEDIR=${BASEDIR:+$(mkdir -p "$BASEDIR" && cd "$BASEDIR" && pwd)}

# ddlog-generated deepdive.conf contains a PIPELINE, so we must set it here
export PIPELINE=$Pipeline

# XXX workaround to play nice with the new deepdive-compile and initdb
case $PIPELINE in
    initdb)
        case $Mode in
            --incremental) ;;
            *)
                ln -sfnv "$DDlog" app.ddlog
                deepdive compile
                exec deepdive initdb
        esac
        ;;
esac

# run DeepDive, passing the rest of the arguments
# TODO use deepdive run instead
deepdive run -c "$appConf" -o "$Out"  "$Pipeline" "$@"
