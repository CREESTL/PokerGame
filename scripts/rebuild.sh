#!/usr/bin/env bash

rm -rf ./build && tronbox compile --compile-all && tronbox migrate

