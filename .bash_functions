#!/usr/bin/env bash

# IMPORTANT:
# This script uses indented heredocs which REQUIRE TABS
# Do NOT reformat this script with spaces, e.g.., expandtabs in vim

tmux-session-id () {
	echo $(tmux list-session | grep attached | awk -F: '{print $1}')
}

tmux-window-id () {
	echo $(tmux list-windows | grep active | awk -F: '{print $1}')
}

tmux-pane-id () {
	echo $(tmux list-panes | grep active | awk -F: '{print $1}')
}

tmux-pane () {
	echo "$(tmux-session-id).$(tmux-window-id).$(tmux-pane-id)"
}

gh_repo_transfer () {
	[[ $# -ne 3 ]] && \
		{
			echo "USAGE: $FUNCNAME <FROM_ORG> <TO_ORG> <REPO>" >&2
			return 1
		}
		FROM_ORG=$1
		TO_ORG=$2
		REPO=$3
		cat <<-EOM | gh api repos/$FROM_ORG/$REPO/transfer --input -
	{"new_owner":"$TO_ORG"}
	EOM
}

user-installed-pkgs() {
	local release="$(lsb_release -rs)"
	local manifest="https://cloud-images.ubuntu.com/releases/${release}/release/ubuntu-${release}-server-cloudimg-amd64-wsl.rootfs.manifest"
	comm -13 <(curl -s $manifest | cut -f1 | sort -u) <(apt-mark showmanual | sort -u)
}

st() {
	tmuxp load ~/.tmuxp/$1.yaml
}
