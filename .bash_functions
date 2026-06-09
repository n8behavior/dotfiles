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

# Make `gh` aware of the GitHub location matching the current directory,
# laid out as ~/src/<owner>/<repo>/...:
#   * <owner> (1st segment) is the default owner for `gh repo` subcommands
#     (list/create/clone/view/fork) when none was given explicitly.
#   * <owner>/<repo> (1st+2nd segments) becomes the default repo for any
#     repo-scoped command, via GH_REPO, unless GH_REPO or -R/--repo is set.
# Anything outside ~/src, or with an explicit owner/repo, is passed through
# to the real gh untouched.
gh() {
	local rel="${PWD#"$HOME"/src/}" org="" repo=""
	if [[ "$PWD" == "$HOME"/src/* && "$rel" != "$PWD" ]]; then
		org="${rel%%/*}"
		local rest="${rel#*/}"
		[[ "$rest" != "$rel" ]] && repo="${rest%%/*}"
	fi

	# Directory-derived default repo (OWNER/REPO) for repo-scoped commands,
	# unless the caller already set GH_REPO or passed -R/--repo.
	local ghrepo=""
	if [[ -n "$repo" && -z "$GH_REPO" ]]; then
		case " $* " in
			*" -R "*|*" --repo "*|*" -R="*|*" --repo="*) ;;
			*) ghrepo="$org/$repo" ;;
		esac
	fi

	# `gh repo` owner/name defaulting from the directory.
	if [[ -n "$org" && "$1" == repo ]]; then
		local sub="$2"
		shift 2
		case "$sub" in
			list)
				# Owner is the first positional; inject org if absent.
				[[ -z "$1" || "$1" == -* ]] && set -- "$org" "$@"
				;;
			create)
				# Bare name -> org/name; no name in a repo dir -> org/repo.
				if [[ -n "$1" && "$1" != -* && "$1" != */* ]]; then
					set -- "$org/$1" "${@:2}"
				elif [[ -n "$repo" && ( -z "$1" || "$1" == -* ) ]]; then
					set -- "$org/$repo" "$@"
				fi
				;;
			clone|view|fork)
				# Prefix a bare repo name with the org owner.
				[[ -n "$1" && "$1" != -* && "$1" != */* ]] && set -- "$org/$1" "${@:2}"
				;;
		esac
		set -- repo "$sub" "$@"
	fi

	if [[ -n "$ghrepo" ]]; then
		GH_REPO="$ghrepo" command gh "$@"
	else
		command gh "$@"
	fi
}
