[ -z "$SSH_AUTH_SOCK" -a -x /usr/bin/ssh-agent ] &&
	LANG=C LC_ALL=C exec /usr/bin/ssh-agent /usr/bin/perl -e 'exec { $ENV{SHELL} } @ARGV' -- "$0" ${1+"$@"}

# on BSD-ish systems, we want the default MANPATH to be made explicit, for later modifications
[ -x /usr/libexec/path_helper ] &&
	# The MANPATH environment variable will not be modified unless it is already set in the environment.
	# -- path_helper(1)
	eval `MANPATH=: /usr/libexec/path_helper`

[ -r ~/.bashrc ] && source ~/.bashrc
