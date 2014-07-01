#!/bin/bash

exists() { which "$@" &> /dev/null ; }
running_on_cygwin () { [ "$MSYSTEM" = MINGW32 ] ; }
interactive_shell () { case "$-" in *i*) return 0 ;; *) return 1 ;; esac ; }

# GENERIC ENVIRONMENT STUFF
# =========================

export LANG=C
export LC_ALL=
export LC_COLLATE=C
export LC_CTYPE=C

running_on_cygwin && TERM=cygwin

case ":$PATH:" in *:$HOME/bin:*) ;; *) PATH=$HOME/bin:$PATH ;; esac

[ -d ~/perl5/perlbrew ] && source ~/perl5/perlbrew/etc/bashrc

if [ -t 0 ] ; then
	exists stty      && stty kill undef
	exists setterm   && setterm -blength 0
	exists dircolors && eval $( TERM=vt100 dircolors -b )
fi

# clean up all X .serverauth files in home dir except the latest
( shopt -s nullglob ; f=(~/.serverauth.*) ; [ "$f" ] && ls -1t "${f[@]}" | tail +2 | { xargs -r rm 2>/dev/null || xargs rm ; } )

eval $( perl -x ~/.bashrc )

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
exists open && BROWSER=open

export MOSH_TITLE_NOPREFIX=1

[ `uname` = Darwin ] && export COPYFILE_DISABLE=true

export ZIPOPT=-9
export GREP_OPTIONS='--directories=skip --binary-files=without-match'
export RSYNC_RSH=ssh
export CFLAGS='-Os -march=native -pipe -fomit-frame-pointer'
export CPPFLAGS=$CFLAGS
export CXXFLAGS=$CFLAGS
export PERL_CPANM_OPT=--no-man-pages
export HARNESS_OPTIONS=j9 # FIXME
export TEST_JOBS=9        # FIXME

[ -d ~/.minicpan ] && export PERL_CPANM_OPT="$PERL_CPANM_OPT --mirror-only --mirror `printf '%q' ~/.minicpan`"


# SHELL CUSTOMISATION
# ===================

for f in \
	~/.bashrc.local \
	~/perl5/perlbrew/etc/perlbrew-completion.bash \
	/usr/local/Library/Contributions/brew_bash_completion.sh \
	~/.git-completion \
	~/.git-prompt \
; do
	[ -r "$f" ] && source "$f"
done

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
alias -- -='popd 2>/dev/null || cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ddiff='LC_ALL=C TZ=UTC0 command diff -urd --unidirectional-new-file'
alias ll='ls -l'
alias la='ll -A'
alias mcdtmp='cd `mktemp -d "$PWD"/x.XXXXXX`'
alias rmcd..='rmdir "$PWD" && cd ..'
alias man='LC_CTYPE=C man'
alias m='mv -vi'
alias pod=perldoc
alias ssh4='ssh -c arcfour'
alias scp4='scp -c arcfour'
alias rmv='rsync --remove-source-files'
alias singlecore='env HARNESS_OPTIONS= TEST_JOBS= MAKEFLAGS='

exists qlmanage && alias ql='qlmanage -p &>/dev/null'

if exists ionice ; then
	case ${HOSTNAME%%.*} in
		ksm) ;;
		*)
			alias cp='ionice -c 3 cp'
			alias mv='ionice -c 3 mv'
			alias rsync='ionice -c 3 rsync'
			;;
	esac
fi

if exists git ; then
	alias s='git st'
	gg() {
		[ "`git rev-parse --is-inside-work-tree 2>&-`" = true ] || set -- --no-index ${1+"$@"}
		git grep -E ${1+"$@"}
	}
	alias ggv='gg -O${DISPLAY:+g}vim' ; exists mvim && alias ggv='gg -Omvim'
	alias diff='git diff --no-index'
	alias ..g='cd `git rev-parse --show-cdup`'
fi

case $TERM in
	*-256color)
		strftime_format=$'\e[38;5;246m%d.%b’%y \e[38;5;252m%T\e[0m' ;;
	*)
		strftime_format='%d.%b'\'\\\'\''%y %T' ;;
esac

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
	if [ "$strftime_format" ] && ls --time-style=iso --version &> /dev/null ; then
		ls_alias="$ls_alias --time-style=+'$strftime_format'"
	fi
	alias ls="$ls_alias"
	unset ls_alias
else
	alias ls='/bin/ls -F -b -G'
fi

exists perldoc-complete && complete -C perldoc-complete -o nospace -o default pod
exists     ssh-complete && complete -C     ssh-complete            -o default ssh

if ! running_on_cygwin ; then
	if interactive_shell ; then
		bind -x '"\C-l": clear'
		bind -x '"\C-\M-l": reset'
	fi
fi

HISTIGNORE='l[sla]:[bf]g'
HISTSIZE=200000
HISTFILESIZE=${HISTSIZE}
if [ "$strftime_format" ] ; then
	HISTTIMEFORMAT="$strftime_format  "
fi

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
sub export { my $vn = shift; printf "export %s=%s\n", $vn, shquo join ':', @_ }

## drop empty, dupe and current-dir components from $PATH and prepend $HOME/bin et al
my @p = grep !/\A\.?\z/, env 'PATH';
export PATH => uniq "$ENV{HOME}/bin", qw( /sbin /usr/sbin ), @p;

## fix up some dircolors
if ( my @c = env 'LS_COLORS' ) {
	my %c = map { split /=/, $_, 2 } @c;
	$c{'di'} = '01;38;5;32' if $ENV{'TERM'} =~ /-256color\z/;
	$c{'*.m4a'} ||= $c{'*.wav'};
	$c{'*.txz'} ||= $c{'*.tgz'};
	$c{ '*.xz'} ||= $c{ '*.gz'};
	export LS_COLORS => map { join '=', $_, $c{$_} } sort keys %c;
}

export MANPATH => uniq env 'MANPATH';

if ( eval 'require Pod::Perldoc::ToTerm' ) {
	export PERLDOC       => '-o term';
	export PERLDOC_PAGER => 'less -R';
}

__END__
