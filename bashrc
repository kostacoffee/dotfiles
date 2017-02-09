# run fish if it's in a tmux shell
if [ -n "$TMUX" ];
then
	exec fish
else
	exec tmux
fi
