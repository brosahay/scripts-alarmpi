# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt extendedglob
unsetopt beep
bindkey -e

####CUSTOM####

##ALIAS
alias ls='ls --color=auto -lrt'
alias gedit='pluma'
alias nautilus='caja'
alias py2venv='source ~/venv/bin/activate'
alias gccbuf='gcc -fno-stack-protector -m32 -Wall -O0 -mpreferred-stack-boundary=2 -z execstack'
alias buf_overflow='echo 0 | sudo tee /proc/sys/kernel/randomize_va_space'

##AUTO_COMPLETION
autoload -Uz compinit promptinit
compinit
promptinit

##prompt -p to preview themes
prompt redhat

##FUNCTIONS
orphans() {
  if [[ ! -n $(pacman -Qdt) ]]; then
    echo "No orphans to remove."
  else
    sudo pacman -Rns $(pacman -Qdtq)
  fi
}