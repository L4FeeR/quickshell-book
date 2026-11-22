# ~/.zshrc: a fast, good-looking zsh without a framework.
# Plugins are three git clones; the prompt is starship.

# ── History ──────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_reduce_blanks inc_append_history

# ── Behaviour ────────────────────────────────────────────────────────────
setopt auto_cd                 # type a folder name to cd into it
setopt interactive_comments    # allow # comments on the command line
bindkey -e                     # emacs-style keys (Ctrl+A, Ctrl+E…)

# ── Completion ───────────────────────────────────────────────────────────
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select                       # arrow through matches
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"  # colours like ls

# ── Plugins (cloned once, sourced every start) ─────────────────────────────
ZPLUGINS=${XDG_DATA_HOME:-$HOME/.local/share}/zsh-plugins
plug() {
    local name=${1:t}
    [[ -d $ZPLUGINS/$name ]] || git clone --depth 1 "https://github.com/$1" "$ZPLUGINS/$name"
    source "$ZPLUGINS/$name/$2"
}
plug zsh-users/zsh-autosuggestions     zsh-autosuggestions.zsh
plug zsh-users/zsh-syntax-highlighting zsh-syntax-highlighting.zsh
plug Aloxaf/fzf-tab                     fzf-tab.plugin.zsh

# suggestions in a muted colour that fits the theme
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#545c7e'

# ── Modern replacements (only if installed) ────────────────────────────────
if (( $+commands[eza] )); then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias tree='eza --tree --icons'
fi
(( $+commands[bat] ))    && alias cat='bat --style=plain --paging=never'
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"
(( $+commands[fzf] ))    && source <(fzf --zsh)

# fzf in the theme's colours
export FZF_DEFAULT_OPTS="--height 40% --layout reverse --border rounded \
  --color=bg+:#283457,bg:-1,spinner:#7dcfff,hl:#7aa2f7,fg:#c0caf5,header:#7aa2f7 \
  --color=info:#bb9af7,pointer:#7dcfff,marker:#9ece6a,fg+:#c0caf5,prompt:#7aa2f7,hl+:#7dcfff"

# ── Prompt ───────────────────────────────────────────────────────────────
(( $+commands[starship] )) && eval "$(starship init zsh)"

# ── Greeting: system info once per terminal ────────────────────────────────
[[ -o interactive ]] && (( $+commands[fastfetch] )) && fastfetch
