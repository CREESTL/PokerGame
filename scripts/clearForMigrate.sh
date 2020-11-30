#!/usr/bin/env bash

rm -rf ./build/contracts && tronbox compile --compile-all && tronbox migrate

