#!/bin/bash

set -e

cd "$(dirname -- "${BASH_SOURCE[0]}")"

docker build --tag rust-devel:latest .
