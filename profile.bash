# for BSD-ish systems
[ -x /usr/libexec/path_helper ] && eval `/usr/libexec/path_helper`

if [ -x /usr/bin/ssh-agent -a -z "$SSH_AUTH_SOCK" ] ; then
	export LANG=C
	export LC_ALL=C
	exec /usr/bin/ssh-agent /usr/bin/perl -e 'exec { shift @ARGV } @ARGV' "$SHELL" "$0" "$@"
fi

if [ -x /usr/bin/ssh-add ] && ! /usr/bin/ssh-add -l &> /dev/null ; then
	/usr/bin/ssh-add
fi

[ -r ~/.bashrc ] && source ~/.bashrc
