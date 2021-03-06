#
# Defines helper functions.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Checks a boolean variable for "true".
# Case insensitive: "1", "y", "yes", "t", "true", "o", and "on".
function is-true {
  [[ -n "$1" && "$1" == (1|[Yy]([Ee][Ss]|)|[Tt]([Rr][Uu][Ee]|)|[Oo]([Nn]|)) ]]
}

# Checks a name if it is a command, function, or alias.
function is-callable {
  (( $+commands[$1] )) || (( $+functions[$1] )) || (( $+aliases[$1] ))
}

# Prints the first non-empty string in the arguments array.
function coalesce {
  for arg in $argv; do
    print "$arg"
    return 0
  done
  return 1
}

# Checks if a file can be autoloaded by trying to load it in a subshell.
function autoloadable {
  ( unfunction $1 ; autoload -U +X $1 ) &> /dev/null
}

# Loads Oh My Zsh modules.
function omodload {
  local -a omodules
  local omodule
  local ofunction_glob='^([_.]*|prompt_*_setup|README*)(.N:t)'

  # $argv is overridden in the anonymous function.
  omodules=("$argv[@]")

  # Add functions to $fpath.
  fpath=(${omodules:+${OMZ}/modules/${^omodules}/functions(/FN)} $fpath)

  function {
    local ofunction

    # Extended globbing is needed for listing autoloadable function directories.
    setopt LOCAL_OPTIONS EXTENDED_GLOB

    # Load Oh My Zsh functions.
    for ofunction in $OMZ/modules/${^omodules}/functions/$~ofunction_glob; do
      autoload -Uz "$ofunction"
    done
  }

  # Load Oh My Zsh modules.
  for omodule in "$omodules[@]"; do
    if zstyle -t ":omz:module:$omodule" loaded; then
      continue
    elif [[ ! -d "$OMZ/modules/$omodule" ]]; then
      print "$0: no such module: $omodule" >&2
      continue
    else
      if [[ -s "$OMZ/modules/$omodule/init.zsh" ]]; then
        source "$OMZ/modules/$omodule/init.zsh"
      fi

      if (( $? == 0 )); then
        zstyle ":omz:module:$omodule" loaded 'yes'
      else
        # Remove the $fpath entry.
        fpath[(r)$OMZ/modules/${omodule}/functions]=()

        function {
          local ofunction

          # Extended globbing is needed for listing autoloadable function
          # directories.
          setopt LOCAL_OPTIONS EXTENDED_GLOB

          # Unload Oh My Zsh functions.
          for ofunction in $OMZ/modules/$omodule/functions/$~ofunction_glob; do
            unfunction "$ofunction"
          done
        }

        zstyle ":omz:module:$omodule" loaded 'no'
      fi
    fi
  done
}

