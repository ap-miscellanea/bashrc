[ -z "$SSH_AUTH_SOCK" -a -x /usr/bin/ssh-agent ] &&
	LANG=C LC_ALL=C exec /usr/bin/ssh-agent /usr/bin/perl -e 'exec { shift } shift' "$SHELL" "$0"

# for BSD-ish systems
[ -x /usr/libexec/path_helper ] && eval `/usr/libexec/path_helper`

[ -r ~/.bashrc ] && source ~/.bashrc
