ShadowsocksR
============

This repository is trimmed for the current server deployment path:

```bash
./scripts/shadowsocks.sh start -l
```

The startup chain is:

```text
scripts/shadowsocks.sh
scripts/lib/common.sh
python3 shadowsocks/server.py -c shadowsocks.json
```

## Requirements

Install Python 3 and the crypto dependency used by the configured method:

```bash
sudo apt-get install python3-dev libsodium-dev
```

## Configuration

The default config file is `shadowsocks.json` in the repository root.

Use another config file with:

```bash
./scripts/shadowsocks.sh start -l -c /path/to/config.json
```

## Operations

```bash
./scripts/shadowsocks.sh start -l
./scripts/shadowsocks.sh stop
./scripts/shadowsocks.sh restart -l
./scripts/shadowsocks.sh status
./scripts/shadowsocks.sh log
```

The `-m` flag only changes the pid and log file names used by the script. The
Python entrypoint stays `shadowsocks/server.py`.

## Repository Layout

- `shadowsocks/`: core server, relay, DNS, crypto, and protocol code
- `scripts/`: service control scripts
- `shadowsocks.json`: active default server config
- `config.json`: sample config
- `tests/`: retained test fixtures and scripts

## License

Licensed under the Apache License, Version 2.0. See `LICENSE`.
