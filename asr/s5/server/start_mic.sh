#!/usr/bin/env bash
rec -r 16k -e signed-integer -c 1 -b 16 -t raw -q - | nc -N localhost 5050
