#!/bin/bash
C_RESET='\033[0m'; C_GREEN='\033[38;5;48m'; C_RED='\033[38;5;196m'
log()  { echo -e "${C_GREEN}[*]${C_RESET} $*"; }
warn() { echo -e "${C_RED}[!]${C_RESET} $*" >&2; }
die()  { warn "$*"; exit 1; }
