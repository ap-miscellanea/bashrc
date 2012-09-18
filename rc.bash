#!/bin/bash

exists() { which "$@" &> /dev/null ; }
running_on_cygwin () { [ "$MSYSTEM" = MINGW32 ] ; }
interactive_shell () { case "$-" in *i*) return 0 ;; *) return 1 ;; esac ; }

# GENERIC ENVIRONMENT STUFF
# =========================

running_on_cygwin && TERM=cygwin

case ":$PATH:" in *:$HOME/bin:*) ;; *) PATH=$HOME/bin:$PATH ;; esac

[ -d ~/perl5/perlbrew ] && source ~/perl5/perlbrew/etc/bashrc

if [ $TERM != dumb ] ; then
	exists stty      && stty kill undef
	exists setterm   && setterm -blength 0
	exists dircolors && eval $( TERM=vt100 dircolors -b )
fi

# clean up all X .serverauth files in home dir except the latest
( shopt -s nullglob ; f=(~/.serverauth.*) ; [ "$f" ] && ls -1t "${f[@]}" | tail +2 | { xargs -r rm 2>/dev/null || xargs rm ; } )

eval $( perl -x ~/.bashrc )

export LANG=C
export LC_ALL=
export LC_COLLATE=C
export LC_CTYPE=C

if interactive_shell && exists locale ; then
	L=( $( locale -a ) )
	for l in "${L[@]}" ; do
		case "$l" in
			en_GB.utf8|en_GB.UTF-8) export LANG=$l ;;
			de_DE.utf8|de_DE.UTF-8) export LC_CTYPE=$l ;;
		esac
	done
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

export ZIPOPT=-9
export GREP_OPTIONS='--directories=skip --binary-files=without-match'
export RSYNC_RSH=ssh
export PERL_CPANM_OPT=--no-man-pages
export HARNESS_OPTIONS=j9 # FIXME
export TEST_JOBS=9 # FIXME

case ${HOSTNAME%%.*} in
	klangraum)
		export CFLAGS='-O2 -march=native -mtune=native -pipe -fomit-frame-pointer'
		export CPPFLAGS=$CFLAGS
		export CXXFLAGS=$CFLAGS
		export MAKEFLAGS=-j12
		#export http_proxy=http://localhost:8080
		export no_proxy=127.0.0.1,192.168.0.96,plasmasturm.org,klangraum.dyndns.org
		export TEXINPUTS=".:$HOME/share/tex/currvita/:$HOME/share/tex/rechnung310/:"
		export PERL_CPANM_OPT="$PERL_CPANM_OPT --mirror-only --mirror /home/www/cpan"
		;;
	fernweh)
		export CFLAGS='-O2 -march=native -mtune=native -pipe -fomit-frame-pointer'
		export CPPFLAGS=$CFLAGS
		export CXXFLAGS=$CFLAGS
		export MAKEFLAGS=-j5
		export PERL_CPANM_OPT="$PERL_CPANM_OPT --mirror-only --mirror /home/www/cpan"
		;;
	plurisight)
		export PATH=/opt/git/bin:$PATH
		;;
	brixton)
		export MODULEBUILDRC="/home/ap/perl5/.modulebuildrc"
		export PERL_MM_OPT="INSTALL_BASE=/home/ap/perl5"
		export PERL5LIB="/home/ap/perl5/lib/perl5:/home/ap/perl5/lib/perl5/i486-linux-gnu-thread-multi"
		export PATH="/home/ap/perl5/bin:$PATH"
		;;
esac


# SHELL CUSTOMISATION
# ===================

try_source () {
	[ -f "$1" ] || return 1
	source "$@"
	return 0
}

try_source ~/perl5/perlbrew/etc/perlbrew-completion.bash

try_source /usr/local/Library/Contributions/brew_bash_completion.sh

if exists git ; then
	for f in /usr/{doc,local}/git{,-*}/contrib/completion/git-completion.bash ; do
		try_source "$f" && break
	done
fi

unset -f try_source

escseq() {
	local ESC
	local fmt
	case $TERM in
		putty*) fmt='\e[%sm'     ;;
		*)      fmt='\[\e[%sm\]' ;;
	esac
	while [ "$*" ] ; do
		case "$1" in
			%*) ESC="$ESC;${1#%}" ;;
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

if type -t __git_ps1 > /dev/null ; then
	GIT_PS1_SHOWDIRTYSTATE=1
	#GIT_PS1_SHOWSTASHSTATE=1
	#GIT_PS1_SHOWUNTRACKEDFILES=1
	dirbranch() {
		x=$(__git_ps1 "%s")
		[ "$x" ] || return 1
		echo "$x"
	}
else
	dirbranch() { return 1 ; }
fi

exists dirsize || dirsize() { echo '?' ; }

case $TERM in
	xterm*|rxvt*|putty*|screen*)
		prompt_termtitle() {
			case "$PWD" in
				"$HOME") p=\~         ;;
				/)       p=/          ;;
				*)       p=${PWD##*/} ;;
			esac
			printf '\e]0;%s\007' "$USER@${HOSTNAME%%.*} : $p"
		} ;;
	*) prompt_termtitle() { return ; } ;;
esac

prompt_command() {
	prompt_termtitle

	JOBS_INDICATOR=
	local n=$( jobs | wc -l )
	(( n > 0 )) && JOBS_INDICATOR="$n+"

	DIRINFO=$( dirbranch || dirsize -Hb )
}
PROMPT_COMMAND=prompt_command
PS1=$( escseq '[' %36 '\t' %0 '] ' %1 '\h ' %1 %33 '\w' %1 ' ($DIRINFO) ' %1 %31 '$JOBS_INDICATOR' %1 '\$ ' %0 )

# cygwin hack to get initial $PWD reformatted properly
running_on_cygwin &&  cd "$PWD"

mcd()  { mkdir -p "$1" ; cd "$1" ; }

unalias -a
alias -- \
	-='popd 2>/dev/null || cd -' \
	..='cd ..' \
	...='cd ../..' \
	....='cd ../../..' \
	.....='cd ../../../..' \
	cal='cal -m' \
	ddiff='LC_ALL=C TZ=UTC0 command diff -urd --unidirectional-new-file' \
	ll='ls -l' \
	la='ll -A' \
	mcdtmp='cd `mktemp -d $PWD/x.XXXXXX`' \
	rmcd..='rmdir $PWD && cd ..' \
	man='LC_CTYPE=C man' \
	mvi='mv -i' \
	pod=perldoc \
	ssh4='ssh -c arcfour' \
	scp4='scp -c arcfour' \

case ${HOSTNAME%%.*} in heliopause|klangraum) alias f='ssh fernweh' ;; esac
case ${HOSTNAME%%.*} in heliopause|fernweh) alias k='ssh klangraum' ;; esac

if exists ionice ; then
	case ${HOSTNAME%%.*} in
		ksm) ;;
		*) alias -- \
			cp='ionice -c 3 cp' \
			mv='ionice -c 3 mv' \
			rsync='ionice -c 3 rsync' \
			;;
	esac
fi

if exists git ; then
	gg() {
		[ "`git rev-parse --is-inside-work-tree 2>&-`" = true ] || set -- --no-index ${1+"$@"}
		git grep -E ${1+"$@"}
	}
	alias ggv='gg -O${DISPLAY:+g}vim' ; exists mvim && alias ggv='gg -Omvim'
	alias diff='git diff --no-index'
fi

strftime_format=$'\e[38;5;246m%d.%b’%y \e[38;5;252m%T\e[0m'

# GNU ls or BSD?
if ls --version &> /dev/null ; then
	ls_alias='/bin/ls -F --quoting-style=escape --color=auto -T0 -v'
	#ls_alias='/bin/ls -F --quoting-style=shell --color=auto -T0 -v'
	# if ls --group-directories-first --version &> /dev/null ; then
	# 	ls_alias="$ls_alias"' --group-directories-first'
	# fi
	if ls --block-size=\'1 --version &> /dev/null ; then
		ls_alias="$ls_alias --block-size="\\\''1'
	fi
	if ls --time-style=iso --version &> /dev/null ; then
		ls_alias="$ls_alias --time-style=+'$strftime_format'"
	fi
	alias ls="$ls_alias"
	unset ls_alias
else
	alias ls='/bin/ls -F -b -G'
fi

exists perldoc-complete && complete -C perldoc-complete -o nospace -o default pod

if ! running_on_cygwin ; then
	if interactive_shell ; then
		bind -x '"\C-l": clear'
		bind -x '"\C-\M-l": reset'
	fi
fi

HISTIGNORE='l[sla]:[bf]g'
HISTSIZE=200000
HISTFILESIZE=${HISTSIZE}
HISTTIMEFORMAT="$strftime_format  "

FCEDIT=vim

unset MAIL MAILCHECK MAILPATH

unset CDPATH

i=0
while (( ++i <= ${BASH_VERSION%%.*} )) ; do
	case $i in
		1) shopt -s \
			checkhash \
			checkwinsize \
			cmdhist \
			extglob \
			histappend \
			histverify \
			no_empty_cmd_completion \
			xpg_echo
			;;
		2) HISTCONTROL=erasedups ;;
		4) shopt -s autocd checkjobs globstar ;;
	esac
done
unset i

return <<'__END__'

#!perl
use strict;
sub env   { grep length, split /:/, $ENV{$_[0]} }
sub shquo { map { s/'/'\''/g; "'$_'" } my @c = @_ }
sub uniq  { my %seen; grep { !$seen{$_}++ } @_ }

## drop empty, dupe and current-dir components from $PATH and prepend $HOME/bin et al
my @p = grep !/\A\.?\z/, env 'PATH';
printf "PATH=%s\n", shquo join ':', uniq "$ENV{HOME}/bin", qw( /sbin /usr/sbin ), @p;

## fix up some dircolors
if ( my @c = env 'LS_COLORS' ) {
	my %c = map { split /=/, $_, 2 } @c;
	$c{'di'} = '01;38;5;32';
	$c{'*.m4a'} ||= $c{'*.wav'};
	$c{'*.txz'} ||= $c{'*.tgz'};
	$c{ '*.xz'} ||= $c{ '*.gz'};
	printf "LS_COLORS=%s\n", shquo join ':', map { join '=', $_, $c{$_} } sort keys %c;
}

printf "MANPATH=%s\n", shquo join ':', uniq env 'MANPATH';

__END__
