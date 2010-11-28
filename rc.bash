#!/bin/bash

exists() { which "$@" &> /dev/null ; }

case "`uname`" in MINGW32*) RUNNING_ON_CYGWIN=1 ;; *) RUNNING_ON_CYGWIN= ; esac

# GENERIC ENVIRONMENT STUFF
# =========================

[ "$RUNNING_ON_CYGWIN" ] && TERM=cygwin

if [ $TERM != dumb ] ; then
	exists stty      && stty kill undef
	exists setterm   && setterm -blength 0
	exists dircolors && eval $( dircolors | sed -r '
		/:\*.m4a=/!s!:\*\.wav=([^:]*)!&:*.m4a=\1!;
		/:\*.txz=/!s!:\*\.tgz=([^:]*)!&:*.txz=\1!;
		/:\*.xz=/!s!:\*\.gz=([^:]*)!&:*.xz=\1!;
	' )
fi

# clean up: delete all X .serverauth files in home dir except the latest
perl <<''
use File::stat;
chdir or die;
@f = <.serverauth.*>;
@m = map { (stat $_)->mtime } @f;
@f = @f[ sort { $m[$a] <=> $m[$b] } 0..$#f ];
pop @f;
unlink @f;

# remove all empty and current-dir components from $PATH and prepend $HOME/bin
export PATH=`perl -MEnv=@PATH,HOME -e'print join ":", "$HOME/bin", "/sbin", "/usr/sbin", grep !/\A\.?\z/, @PATH'`

if [ $( expr ":$MANPATH:" : ".*:$HOME/man:" ) -eq 0 ] ; then
	export MANPATH="$HOME/man:$MANPATH"
fi

if exists locale && locale -a | grep -cq utf8 ; then
	# looks like Linux
	export LC_ALL=
	export LANG=en_GB.utf8
	export LC_COLLATE=C
	export LC_CTYPE=de_DE.utf8
elif exists locale && locale -a | grep -cq UTF-8 ; then
	# we seem to be on FreeBSD
	export LC_ALL=
	export LANG=en_GB.UTF-8
	export LC_COLLATE=C
	export LC_CTYPE=de_DE.UTF-8
elif [ "$RUNNING_ON_CYGWIN" ] ; then
	: # no comment...
else
	echo 'Could not find UTF-8 locales! No locale configured' 1>&2
fi

export EDITOR=vim
export VISUAL=vim

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

export ZIPOPT="-9"
export GREP_OPTIONS="--directories=skip --binary-files=without-match"
export RSYNC_RSH=ssh
export PERL5LIB="$HOME/lib"

case "`hostname`" in
	klangraum|klangraum.*)
		export CFLAGS='-O2 -march=i686 -mtune=native -pipe -fomit-frame-pointer'
		export CPPFLAGS="$CFLAGS"
		export CXXFLAGS="$CFLAGS"
		export MAKEFLAGS='-j5'
		#export http_proxy="http://localhost:8080"
		export no_proxy="127.0.0.1,192.168.0.96,plasmasturm.org,klangraum.dyndns.org"
		export TEXINPUTS=".:$HOME/share/tex/currvita/:$HOME/share/tex/rechnung310/:"
		export PATH="$HOME/perl/5.10.0/bin:$PATH"
		;;
	plurisight|plurisight.*)
		export PATH=/opt/git/bin:$PATH
		;;
esac


# SHELL CUSTOMISATION
# ===================

for f in /usr/doc/git-*/contrib/completion/git-completion.bash ; do
	if [ -e "$f" ] ; then
		source "$f"
		break
	fi
done

[ -e /etc/bash_completion ] && source /etc/bash_completion

escseq() {
	local ESC
	local fmt
	case $TERM in
		putty*) fmt='\e[%sm'     ;;
		*)      fmt='\[\e[%sm\]' ;;
	esac
	while [ "$*" ] ; do
		case "$1" in
			%*) ESC="$ESC;${1##%}" ;;
			*)
				[ "$ESC" ] && printf $fmt "$ESC"
				printf '%s' "$1"
				unset ESC
				;;
		esac
		shift
	done
	[ "$ESC" ] && printf $fmt "$ESC"
}

termtitle() {
	(($#)) || { echo "usage: $0 title [cmd [arg ...]]"; }
	local TITLE="$1"
	shift
	printf '\e]0;%s\007' "$TITLE"
	"$@"
}

putxy() {
	local X=$1 ; shift
	local Y=$1 ; shift
	local IFS=''
	printf '\e7' # save position
	printf '\e[%d;%dH%s' "$X" "$Y" "$*"
	printf '\e8' # restore position
}

prompt_termtitle() {
	case "$PWD" in
		"$HOME") p=\~         ;;
		/)       p=/          ;;
		*)       p=${PWD##*/} ;;
	esac
	termtitle "$USER@${HOSTNAME%%.*} : $p"
}

PS1=( '[' %36 '\t' %0 '] ' )
case $TERM in
	xterm*|rxvt*|putty*|screen)
		PROMPT_COMMAND=prompt_termtitle ;;
	*)
		PS1=( "${PS1[@]}" %1 '\u@\h' %0 ' : ' ) ;;
esac
PS1=( "${PS1[@]}" %1 %33 '\w' %0 %1 ' ($( ' )
type -t __git_ps1 > /dev/null && PS1=( "${PS1[@]}" 'x=$(__git_ps1 "%s"); [ "$x" ] && echo "$x" || ' )
if exists dirsize ; then PS1=( "${PS1[@]}" 'dirsize -Hb' ) ; else PS1=( "${PS1[@]}" 'printf '\''?'\' ) ; fi
PS1=( "${PS1[@]}" ' )) \$ ' %0 )
PS1=$( escseq "${PS1[@]}" )

# cygwin hack to get initial $PWD reformatted properly
case "`uname`" in MINGW32*) cd "$PWD" ; esac

mcd()  { mkdir -p "$1" ; cd "$1" ; }
ggv()  { git grep -l -E "$@" | xargs ${DISPLAY:+g}vim ; }

unalias -a
alias -- \
	-='popd 2>/dev/null || cd -' \
	..='cd ..' \
	...='cd ../..' \
	....='cd ../../..' \
	.....='cd ../../../..' \
	cp='ionice -c3 cp' \
	cal='cal -m' \
	ddiff='LC_ALL=C TZ=UTC0 command diff -urd --unidirectional-new-file' \
	gg='git grep -E' \
	ll='ls -l' \
	la='ll -A' \
	man='LC_CTYPE=C man' \
	mv='ionice -c3 mv' \
	pod=perldoc \

exists git && alias diff='git diff --no-index'

# GNU ls or BSD?
if ls --version &> /dev/null ; then
	alias ls='/bin/ls -F -b --color=auto -T 0'
else
	alias ls='/bin/ls -F -b -G'
fi

# try to use native GVIM on Windows
for gvim in /c/Programme/Vim/vim*/gvim.exe ; do [ -x $gvim ] && alias gvim="$gvim" ; done

exists perldoc-complete && complete -C perldoc-complete -o nospace -o default pod

bind -x '"\C-l": clear'

HISTCONTROL=erasedups
HISTIGNORE="l[sla]:[bf]g"
HISTSIZE=200000
HISTFILESIZE=${HISTSIZE}

FCEDIT=vim

unset MAIL MAILCHECK MAILPATH

unset CDPATH

if [ ${BASH_VERSION%%.*} -gt 1 ] ; then
	shopt -s \
		checkhash \
		checkwinsize \
		cmdhist \
		extglob \
		histappend \
		histverify \
		no_empty_cmd_completion \
		xpg_echo
fi

if [ ${BASH_VERSION%%.*} -gt 2 ] ; then
	HISTCONTROL=erasedups
fi

if [ ${BASH_VERSION%%.*} -gt 3 ] ; then
	unalias ..
	alias ...=../.. ....=../../.. .....=../../../..
	shopt -s \
		autocd \
		checkjobs \
		globstar
fi

unset RUNNING_ON_CYGWIN
