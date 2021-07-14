#!/bin/bash

# version 0.0.3

# prompt <ENV_VAR> <PROMPT_TEXT> [<DEFAULT_VALUE>]
# prompt GREET "Enter greeting"
# prompt GREET "Enter greeting" "Hi"
prompt() {
  if [ "$3" == '' ]
  then
    read -r -p "$2: " $1
  else
    read -r -p "$2 (leave blank for default '$3'): " value
    if [[ -z ${value} ]]
    then
      read -r $1 <<< $3
    else
      read -r $1 <<< "$value"
    fi
  fi
}

# default — NO
confirm() {
    read -r -p "${1:-Are you sure?} [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# default — YES
confirm_default_yes() {
    read -r -p "${1:-Are you sure?} [Y/n] " response
    case "$response" in
        [nN][oO]|[nN])
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# ask for value of ENV variable, accept empty value to set default value and, if value is not default, writes it into .env
ask_env_default() {
  read -r -p "$2 (or leave blank for default '$3'): " value
  [[ -z ${value} ]]  || echo "$1=${value}" >> ./.env
}

# ask for value of ENV variable and writes it into .env
ask_env() {
  read -r -p "$2: " value
  echo "$1=${value}" >> ./.env
}

# ask for value of ENV variable, accept empty value to set default value and writes it into .env
ask_env_default_write() {
  read -r -p "$2 (or leave blank for default '$3'): " value
  [[ -z ${value} ]] && echo "$1=$3" >> ./.env || echo "$1=${value}" >> ./.env
}
