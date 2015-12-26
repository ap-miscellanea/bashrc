all:
	/bin/rm -f ~/.profile
	/bin/ln -sf .config/bash/rc.bash      ~/.bashrc
	/bin/ln -sf .config/bash/profile.bash ~/.bash_profile
