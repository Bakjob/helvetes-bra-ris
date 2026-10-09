#!/bin/bash
# Alla ljudutgångar (sinks) som JSON-array för volymmenyns enhetsval.
# Standardenheten markeras med "default": true. Byte görs i eww.yuck med
# `pactl set-default-sink <name>` - PipeWire flyttar då med pågående ljud.

default=$(pactl get-default-sink 2>/dev/null)
pactl -f json list sinks 2>/dev/null | python3 -c "
import sys, json
default = sys.argv[1]
try:
    sinks = json.load(sys.stdin)
except Exception:
    sinks = []
out = [{'name': s['name'], 'desc': s.get('description') or s['name'],
        'default': s['name'] == default} for s in sinks]
out.sort(key=lambda s: not s['default'])
print(json.dumps(out))
" "$default"
