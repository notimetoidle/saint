#!/bin/bash
set -e
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )" # https://stackoverflow.com/a/246128
(cd "$SCRIPT_DIR/terraform" && terraform validate)
terraform fmt -recursive "$SCRIPT_DIR/terraform"
