#!/bin/bash

set -e

while IFS= read -r -d '' script
do echo "Running shellcheck on $script"
   shellcheck "$script"
done <   <(find . -name '*.sh' -print0)
