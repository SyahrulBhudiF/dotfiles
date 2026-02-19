export HOME="$HOME"
export ZSH="$HOME/.oh-my-zsh"

plugins=(git)

source $ZSH/oh-my-zsh.sh

eval "$(starship init zsh)"



eval "$(zoxide init zsh)"

export PATH="$HOME/Packages/flutter/bin:$PATH"
export CHROME_EXECUTABLE="/var/lib/flatpak/app/com.google.Chrome/x86_64/stable/active/export/bin/com.google.Chrome"

. "$HOME/.deno/env"

# remove any bun paths injected elsewhere
export PATH="${PATH//:$HOME/.bun/bin/}"
export PATH="${PATH//:$HOME/.bun/install/global/node_modules/@beads/bd/bin/}"

# Php Laravel alias command
alias p="php artisan"
alias pms="php artisan migrate:fresh --seed"
alias pm="php artisan migrate:fresh"
alias prs="php artisan route:list"

make_resource() {
  if [ -z "$1" ]; then
    echo "Usage: make_resource <Name>"
    return 1
  fi

  NAME=$1
  CAMEL=$(echo "$NAME" | sed -E 's/(^|_)([a-z])/\U\2/g') # LibraryManagement -> LibraryManagement
  CONTROLLER_PATH="Shared/${CAMEL}Controller"
  STORE_REQUEST_PATH="Shared/${CAMEL}/Store${CAMEL}Request"
  UPDATE_REQUEST_PATH="Shared/${CAMEL}/Update${CAMEL}Request"
  POLICY_PATH="${CAMEL}Policy"
  SERVICE_PATH="Shared/${CAMEL}Service"

  echo "Generating resources for: $CAMEL"

  p make:controller $CONTROLLER_PATH -r
  p make:request $STORE_REQUEST_PATH
  p make:request $UPDATE_REQUEST_PATH
  p make:policy $POLICY_PATH --model=${CAMEL}
  p make:service $SERVICE_PATH
}
alias pmake="make_resource"

export COMPOSER_HOME="$HOME/.config/composer"
export PATH="$PATH:$COMPOSER_HOME/vendor/bin"
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'

. "$HOME/.local/bin/env"
alias zen-update="$HOME/.local/bin/zen-update"
