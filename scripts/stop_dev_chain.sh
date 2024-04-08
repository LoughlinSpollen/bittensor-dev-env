#! /usr/bin/env zsh
set -e -u

PORTS=(9943 9944)
for PORT in $PORTS
do
    lsof -ti:$PORT | xargs kill
done
echo "Local chain nodes stopped"
