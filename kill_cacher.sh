#!/bin/bash

kill "$(cat "$(pwd)/apt-cache/pid")"
