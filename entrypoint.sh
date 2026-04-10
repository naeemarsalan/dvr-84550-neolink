#!/bin/sh
envsubst < /etc/neolink/neolink.toml.tmpl > /etc/neolink/neolink.toml
exec neolink rtsp --config /etc/neolink/neolink.toml
