#!/bin/sh

set -e

# This script ensures the user and group passed in as first and second argument by id exist. If not it creates them.
# It also ensures a home directory owned by the user/group and returns the user config from /etc/passwd
UserID=${1:-0}
GroupID=$2
HomeDir=$3

[[ "$UserID" -eq  "0" ]] && exit 0

# Create user and group unless they already exist
group=$(awk -F: -v id=${GroupID} '$3 == id { print $1 }' /etc/group)
user=$(awk -F: -v id=${UserID} '$3 == id { print $1 }' /etc/passwd)

# Set up group/user if either are absent
[[ -z "$group" ]] && group=api && addgroup -g ${GroupID} -S ${group} || true
[[ -z "$user" ]] && user=api && adduser -S -D -u ${UserID} -G ${group} ${user} || true

# Ensure home directory exists and is owned by user/group
mkdir -p ${HomeDir}
usermod -d ${HomeDir} -aG ${group} ${user}
chown -R ${user}:${group} ${HomeDir}

# Return user group names that may have been created
awk -F: -v id=${UserID} '$3 == id { print }' /etc/passwd
