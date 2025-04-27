#!/usr/bin/env bash

# TODO: this is pretty invasive and will replace other peoples PS1 configuration.
# I should check if I can use PROMPT_COMMAND instead since that will just extend the original PS1 config.
# https://wiki.archlinux.org/title/Bash/Prompt_customization#PROMPT_COMMAND
# Alternatvely there is this project, which introduces preexec and precmd similar to zsh:
# https://github.com/rcaloras/bash-preexec
# The problem is that it will become incredibly convoluted to install this functionality.
# To avoid having to install a lot of dependencies consider using starship instead:
# https://github.com/starship/starship
SHORT_PS1='${debian_chroot:+($debian_chroot)}[\[\033[01;34m\]\W\[\033[00m\]]\[\e[91m\]\[\e[00m\] \$ '
LONG_PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\] \$ '

# Define our map using associative array
declare -A features
features=([short]="no" [git]="yes" [aws]="no" [kubernetes]="no")

parse_git_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""
}

git_open_parantheses() {
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        echo "("
    else
        echo ""
    fi
}

git_close_parantheses() {
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        echo ")"
    else
        echo ""
    fi
}

# TODO: implement this properly. This should show which account the terminal is logged into.
get_aws_prompt() {
    echo $AWS_ACCOUNT_NAME
}

get_kubernetes_namespace() {
    echo $(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
}

get_kubernetes_context() {
    echo $(kubectl config current-context 2>/dev/null | cut -d ":" -f 4-)
}

get_kubernetes_prompt() {
    local kubernetes_context=$(get_kubernetes_context)
    local kubernetes_namespace=$(get_kubernetes_namespace)
    if [[ -n "$kubernetes_context" && -n "$kubernetes_namespace" ]]; then
        echo "$kubernetes_context:$kubernetes_namespace"
    elif [[ -n "$kubernetes_context" ]]; then
        echo "$kubernetes_context"
    else
        echo ""
    fi
}

check_is_production_account() {
    local kubernetes_context=$(get_kubernetes_context)
    local output=""
    
    if [ -z $TOGGLE_PROMPT_PRODUCTION_ACCOUNT ]; then
        return
    fi

    if [[ -n "$kubernetes_context" && "$kubernetes_context" == *"$TOGGLE_PROMPT_PRODUCTION_ACCOUNT"* ]]; then
        output=" !!! You are in production !!!"
    fi
    
    echo "$output"
}

update_prompt() {
    # Base prompt according to short/long setting
    if [ "${features["short"]}" = "yes" ]; then
        PS1=$SHORT_PS1
    else
        PS1=$LONG_PS1
    fi
    
    # Build dynamic components
    local extras=""
    
    for feature in git aws kubernetes; do
        if [ "${features[$feature]}" = "yes" ]; then
            case $feature in
                "git")
                    extras+='$(git_open_parantheses)\[\e[91m\]$(parse_git_branch)\[\e[00m\]$(git_close_parantheses)'
                    ;;
                "aws")
                    extras+='[\[\033[01;33m\]$(get_aws_prompt)\[\033[00m\]]'
                    ;;
                "kubernetes")
                    extras+='[\[\033[01;36m\]$(get_kubernetes_prompt)\[\033[00m\]]\[\e[91m\]$(check_is_production_account)\[\e[00m\]\n'
                    ;;
            esac
        fi
    done
    
    # Insert extras before the final $ in PS1
    if [[ -n "$extras" ]]; then
        PS1="${PS1/ \\$ /$extras \$ }"
    fi
}

toggle_prompt() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            "--short")
                features["short"]=$([ "${features["short"]}" = "yes" ] && echo "no" || echo "yes")
                shift
                ;;
            "--git")
                features["git"]=$([ "${features["git"]}" = "yes" ] && echo "no" || echo "yes")
                shift
                ;;
            "--aws")
                features["aws"]=$([ "${features["aws"]}" = "yes" ] && echo "no" || echo "yes")
                shift
                ;;
            "--kubernetes")
                features["kubernetes"]=$([ "${features["kubernetes"]}" = "yes" ] && echo "no" || echo "yes")
                shift
                ;;
            "--reset")
                features["git"]=yes
                features["aws"]=no
                features["kubernetes"]=no
                features["short"]=no
                shift
                ;;
            "--help"|"-h")
                _toggle_prompt_help
                return 0
                ;;
            *)
                echo "Error: Unknown option '$1'"
                _toggle_prompt_help
                return 1
                ;;
        esac
    done
    
    # Update the prompt
    update_prompt
    
    _toggle_prompt_status
}

toggle_prompt_production_account() {
    if [ $# -ne 1 ]; then
        echo "error: production account needs a value"
        return 1
    fi

    TOGGLE_PROMPT_PRODUCTION_ACCOUNT=$1
}

# Helper function to display current status
_toggle_prompt_status() {
    echo "Current settings:"
    echo "  Short mode:   $([ ${features["short"]} = "yes" ] && echo "enabled" || echo "disabled")"
    echo "  Git:          $([ ${features["git"]} = "yes" ] && echo "enabled" || echo "disabled")"
    echo "  AWS:          $([ ${features["aws"]} = "yes" ] && echo "enabled" || echo "disabled")"
    echo "  Kubernetes:   $([ ${features["kubernetes"]} = "yes" ] && echo "enabled" || echo "disabled")"
}

# Helper function to show help
_toggle_prompt_help() {
    echo "Usage: toggle_prompt [OPTIONS]"
    echo "To install this you can source it in your bashrc:"
    echo "source /path/to/toggle_prompt.sh"
    echo "Toggle shell prompt display options."
    echo ""
    echo "Options:"
    echo "  --short       Toggle short mode (current path only)"
    echo "  --git         Toggle git information in prompt"
    echo "  --aws         Toggle AWS information in prompt"
    echo "  --kubernetes  Toggle Kubernetes information in prompt"
    echo "  --reset       Resets to default flag configuration"
    echo "  --help, -h    Display this help message"
}

# Initialize the prompt with default settings
toggle_prompt --reset
