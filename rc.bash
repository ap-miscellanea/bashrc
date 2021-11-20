exists () { [[ $( type -t "$1" ) == file ]] ; }
running_on_cygwin () { [[ $MSYSTEM = MINGW32 ]] ; }
interactive_shell () { [[ $- == *i* ]] ; }
colorful_terminal () { [[ $TERM == *-256color ]] ; }

#### PATH INIT #########################################################

PATH=:$PATH:
while [[ $PATH == *::* ]]  ; do PATH=${PATH//::/:}  ; done
while [[ $PATH == *:.:* ]] ; do PATH=${PATH//:.:/:} ; done
PATH=${PATH#:}
PATH=${PATH%:}
for p in /sbin /usr/sbin ~/bin ; do
	[[ :$PATH: == *:$p:* ]] || PATH=$p${PATH+:}$PATH
done

#### LOCALE INIT #######################################################

export LANG=C LC_COLLATE=C LC_CTYPE=C LC_ALL=
while read l ; do
	case "$l" in
		en_GB.utf8|en_GB.UTF-8) export LANG=$l ;;
		de_DE.utf8|de_DE.UTF-8) export LC_CTYPE=$l ;;
	esac
done < <( locale -a 2> /dev/null )

#### TERMINAL INIT #####################################################

[ -t 0 ] && stty kill undef
running_on_cygwin && TERM=cygwin
case "$TERM" in con|linux) setterm --blength 0 ;; esac

#### GENERAL ENVIRONMENT ###############################################

exists dircolors && eval "`TERM=vt100 dircolors -p | if colorful_terminal ; then sed 's/^DIR .*/DIR 01;38;5;32/' ; else cat ; fi | dircolors -b -`"

export LSCOLORS=`printf '%s' Ex fx cx dx bx eg ed ab ag ac ad` # BSD ls: default colors but with bolded dirs

export EDITOR=vim
export VISUAL=vim
export MYVIMRC=$HOME/.vim/vimrc VIMINIT='source $MYVIMRC' # help old Vims along

export PAGER=less
export LESS=-QSX
export LESSCHARSET=utf-8
# see termcap(5) for this crud
#export LESS_TERMCAP_mb=
export LESS_TERMCAP_md=$'\E[1;2m'
#export LESS_TERMCAP_so=
export LESS_TERMCAP_us=$'\E[1;3m'
export LESS_TERMCAP_ue=$'\E[22;23m'
#export LESS_TERMCAP_se=
export LESS_TERMCAP_me=$'\E[0m'

export BROWSER=google-chrome
exists open && BROWSER=open

export MOSH_TITLE_NOPREFIX=1

if [ `uname` = Darwin ] ; then
	export COPYFILE_DISABLE=true
	export BASH_SILENCE_DEPRECATION_WARNING=1 # get lost
fi

export LS_BLOCK_SIZE="'"1 # for GNU ls: show sizes in bytes and commify

if colorful_terminal # for GNU ls/du
	then export TIME_STYLE=+$'\e[38;5;246m%d.%b’%y \e[38;5;252m%T\e[0m'
	else export TIME_STYLE=+'%d.%b'\'\\\'\''%y %T'
fi

export ZIPOPT=-9
export RSYNC_RSH=ssh
export CFLAGS='-Os -march=native -pipe -fomit-frame-pointer'
export CXXFLAGS=$CFLAGS
export PERL_CPANM_OPT='--no-man-pages'
export HARNESS_OPTIONS=j9 # FIXME
export TEST_JOBS=9        # FIXME

[ -d ~/.minicpan ] && export PERL_CPANM_OPT="$PERL_CPANM_OPT --mirror-only --mirror $HOME/.minicpan"

#### MACHINE-LOCAL PREFS ###############################################

[ -r ~/.bashrc.local ] && source ~/.bashrc.local

#### SHELL SETTINGS ####################################################

exists dirsize || dirsize () { return 0 ; }
declare -fF __git_ps1 > /dev/null || __git_ps1 () { return 0 ; }

export FILTER_BRANCH_SQUELCH_WARNING=1 # get lost
GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWSTASHSTATE=1
prompt_command () {
	PS1_GIT=`__git_ps1 '(%s)'`
	PS1_DIR=`[[ -z $PS1_GIT ]] && dirsize -Hb`
	PS1_JOBS=`set -- $( jobs -p ) ; (( $# )) && echo $#+`
}
PROMPT_COMMAND=prompt_command

PS1='<38;5;39>\t<0> <1;38;5;226>\h<0> <1>\w<0> $PS1_DIR<38;5;215>$PS1_GIT<0> <1;31>$PS1_JOBS<0;1>\$<0> '
colorful_terminal || { PS1=${PS1/38;5;39/36} ; PS1=${PS1/38;5;226/33} ; PS1=${PS1/38;5;215/33} ; }
PS1=${PS1//</'\[\e['} ; PS1=${PS1//>/'m\]'}
case $TERM in
	xterm*|rxvt*|putty*|screen*) PS1='\[\e]0;\u@\h \W\a\]'$PS1 ;;
esac

# cygwin hack to get initial $PWD reformatted properly
running_on_cygwin && cd "$PWD"

mcd () { mkdir -p "$1" ; cd "$1" ; }

unalias -a
alias -- -='popd 2>/dev/null || cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias grep='grep --directories=skip --binary-files=without-match'
alias ddiff='LC_ALL=C TZ=UTC0 command diff -urd --unidirectional-new-file'
alias ll='ls -l'
alias la='ll -A'
alias scratch='cd `mktemp -d ./scratch-XXXXXXXXXXXXXX`'
alias rmcd..='{ cd .. && rmdir "$OLDPWD" ; } || cd - >/dev/null'
alias man='LC_CTYPE=C man'
alias pod='PERLDOC_PAGER=less\ -R perldoc'
alias m='mv -vi'
alias rmv='rsync --remove-source-files'
alias singlecore='env HARNESS_OPTIONS= TEST_JOBS= MAKEFLAGS='
alias pmver='perl -e '\''system $^X, "-le", join "\n", q[#line 1 pmver], map qq[print "$_ \$$_\::VERSION" if require $_;], @ARGV'\'

exists qlmanage && alias ql='qlmanage -p &>/dev/null'

if exists ionice && ! [[ ${HOSTNAME%%.*} == ksm ]] ; then
	alias cp='ionice -c 3 cp'
	alias mv='ionice -c 3 mv'
	alias rsync='ionice -c 3 rsync'
fi

if exists git ; then
	alias diff='git diff --no-index'
	alias g..='cd "`git rev-parse --show-toplevel || echo /dev/null`" 2>/dev/null'
	alias s='git st'
fi

# GNU ls or BSD?
if ls --version &> /dev/null ; then
	alias ls='/bin/ls -F --quoting-style=escape --color=auto -T0 -v'
	#alias ls='/bin/ls -F --quoting-style=shell --color=auto -T0 -v'
	#if ls --group-directories-first --version &> /dev/null ; then
	#	eval "`alias ls`' --group-directories-first'"
	#fi
else
	alias ls='/bin/ls -F -b -G'
fi

complete -C perldoc-complete -o nospace -o default pod
complete -C     ssh-complete            -o default ssh

if interactive_shell && ! running_on_cygwin ; then
	bind -x '"\C-l": clear'
	bind -x '"\C-\M-l": reset'
fi

HISTIGNORE='l[sla]:[bf]g:  *'
(( BASH_VERSINFO >= 2 )) && HISTCONTROL=erasedups
HISTSIZE=200000
HISTFILESIZE=${HISTSIZE}
HISTTIMEFORMAT="${TIME_STYLE#+}  "

FCEDIT=vim

unset MAIL MAILCHECK MAILPATH

unset CDPATH

shopt -s checkhash checkwinsize cmdhist extglob histappend histverify no_empty_cmd_completion xpg_echo
(( BASH_VERSINFO >= 4 )) && shopt -s autocd checkjobs globstar
