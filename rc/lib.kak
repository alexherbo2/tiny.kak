declare-option str cursor_character_unicode

define-command -override add-cursor-character-unicode-expansion -docstring 'add %opt{cursor_character_unicode} expansion' %{
  remove-hooks global update-cursor-character-unicode-expansion
  hook -group update-cursor-character-unicode-expansion global NormalIdle '' %{
    set-option window cursor_character_unicode %sh{printf '%04x' "$kak_cursor_char_value"}
  }
}

define-command -override delete-scratch-message -docstring 'delete scratch message' %{
  remove-hooks global delete-scratch-message
  hook -group delete-scratch-message global BufCreate '\*scratch\*' %{
    execute-keys '%d'
  }
}

declare-option -docstring 'find command' str find_command 'fd --type file'

define-command -override find -menu -params 1 -shell-script-candidates %opt{find_command} -docstring 'open file' %{
  edit %arg{1}
}

alias global f find

define-command -override open-kakrc -docstring 'open kakrc' %{
  edit "%val{config}/kakrc"
}

define-command -override source-kakrc -docstring 'source kakrc' %{
  source "%val{config}/kakrc"
}

define-command -override source-runtime -menu -params 1 -shell-script-candidates 'cd "$kak_runtime" && find -L . -type f -name "*.kak" | sort -u' -docstring 'source from %val{runtime}' %{
  source "%val{runtime}/%arg{1}"
}

define-command -override source-config -menu -params 1 -shell-script-candidates 'cd "$kak_config" && find -L . -type f -name "*.kak" | sort -u' -docstring 'source from %val{config}' %{
  source "%val{config}/%arg{1}"
}

define-command -override evaluate-selections -docstring 'evaluate selections' %{
  evaluate-commands -itersel %{
    evaluate-commands %val{selection}
  }
}

alias global = evaluate-selections

# Registers: https://github.com/mawww/kakoune/blob/master/doc/pages/registers.asciidoc
# Source code: https://github.com/mawww/kakoune/blob/master/src/register_manager.cc
define-command -override evaluate-commands-pure -params .. -docstring 'evaluate-commands -pure [switches] <commands>' %{
  evaluate-commands -no-hooks -save-regs '"#%./0123456789:@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_abcdefghijklmnopqrstuvwxyz|' %arg{@}
}

define-command -override append-text -params .. -docstring 'append-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys '<a-p>'
  }
}

define-command -override insert-text -params .. -docstring 'insert-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys '<a-P>'
  }
}

define-command -override replace-text -params .. -docstring 'replace-text [values]' %{
  evaluate-commands -save-regs '"' %{
    set-register dquote %arg{@}
    execute-keys 'R'
  }
}

define-command -override indent-selections -docstring 'indent selections' %{
  # Replace leading tabs with the appropriate indent.
  try %[ execute-keys -draft "<a-s>s\A\t+<ret>s.<ret>%opt{indentwidth}@" ]
  # Align everything with the current line.
  try %[ execute-keys -draft -itersel '<a-s>Z)<space><a-x>s^\h+<ret>yz)<a-space>_P' ]
}

# Reference:
# https://github.com/mawww/kakoune/blob/master/src/normal.cc#:~:text=enter_insert_mode
define-command -override enter-insert-mode-with-main-selection -docstring 'enter insert mode with main selection and iterate selections with Alt+N and Alt+P' %{
  execute-keys -save-regs '' '<a-:><a-;>Z<space>i'

  # Internal mappings
  map -docstring 'iterate next selection' window insert <a-n> '<a-;>z<a-;>)<a-;>Z<a-;><space>'
  map -docstring 'iterate previous selection' window insert <a-p> '<a-;>z<a-;>(<a-;>Z<a-;><space>'

  hook -always -once window ModeChange 'pop:insert:normal' %{
    execute-keys z
    unmap window insert
  }
}

define-command -override add-selections-to-register -params 1 -docstring 'add selections to register (default: ^)' %{
  try %{
    execute-keys -draft """%arg{1}<a-z>a"
    execute-keys -with-hooks -save-regs '' """%arg{1}<a-Z>a"
  } catch %{
    execute-keys -with-hooks -save-regs '' """%arg{1}Z"
  }
}

declare-option -hidden str register_name

define-command -override clear-register -params 1 -docstring 'clear register (default: ^)' %{
  set-option global register_name %sh{printf '%s' "${kak_register:-^}"}
  set-register %opt{register_name}
  echo -markup "{Information}cleared register '%opt{register_name}'{Default}"
}

define-command -override select-next-word -docstring 'select next word' %{
  evaluate-commands -itersel %{
    hook -group select-next-word -always -once window User "%val{selection_desc}" %{
      search-next-word
    }
    try %{
      execute-keys '<a-i>w'
      trigger-user-hook "%val{selection_desc}"
    } catch %{
      search-next-word
    }
    remove-hooks window select-next-word
  }
}

define-command -override -hidden search-next-word -docstring 'search next word' %{
  execute-keys 'h/\W\w<ret><a-i>w'
}

# Reference: https://code.visualstudio.com/docs/getstarted/keybindings#_basic-editing
define-command -override move-lines-down -docstring 'move line down' %{
  execute-keys -draft '<a-x><a-_><a-:>Z;ezj<a-x>dzP'
}

define-command -override move-lines-up -docstring 'move line up' %{
  execute-keys -draft '<a-x><a-_><a-:><a-;>Z;bzk<a-x>dzp'
}

define-command -override select-highlights -docstring 'select all occurrences of current selection' %{
  execute-keys '"aZ*%s<ret>"bZ"az"b<a-z>a'
}

define-command -override sort-selections -docstring 'sort selections' %{
  connect run kcr pipe jq sort
}

define-command -override reverse-selections -docstring 'reverse selections' %{
  connect run kcr pipe jq reverse
}

define-command -override math -docstring 'math' %{
  prompt math: %{
    evaluate-commands-pure %{
      set-register t %val{text}
      execute-keys 'a<c-r>t<esc>|bc<ret>'
    }
  }
}

set-face global SelectedText 'default,bright-black'

define-command -override show-selected-text -docstring 'show selected text' %{
  remove-hooks global show-selected-text
  hook -group show-selected-text global NormalIdle '' update-selected-text-highlighter
  hook -group show-selected-text global InsertIdle '' update-selected-text-highlighter
}

define-command -override hide-selected-text -docstring 'hide selected text' %{
  remove-hooks global show-selected-text
  remove-highlighter global/selected-text
}

define-command -override -hidden update-selected-text-highlighter -docstring 'update selected text highlighter' %{
  evaluate-commands -draft -save-regs '/' %{
    try %{
      execute-keys '<a-k>..<ret>'
      execute-keys -save-regs '' '*'
      add-highlighter -override global/selected-text regex "%reg{/}" 0:SelectedText
    } catch %{
      remove-highlighter global/selected-text
    }
  }
}

set-face global Search 'black,bright-yellow'

define-command -override show-search -docstring 'show search' %{
  remove-hooks global show-search
  hook -group show-search global RegisterModified '/' %{
    try %{
      add-highlighter -override global/search regex "%reg{/}" 0:Search
    } catch %{
      remove-highlighter global/search
    }
  }
}

define-command -override hide-search -docstring 'hide search' %{
  remove-hooks global show-search
  remove-highlighter global/search
}

declare-option -hidden range-specs mark_ranges

set-face global Mark 'black,bright-green+F'

define-command -override -hidden update-mark-ranges -docstring 'update mark ranges' %{
  evaluate-commands -buffer '*' unset-option buffer mark_ranges
  try %{
    evaluate-commands -draft %{
      execute-keys 'z'
      set-option buffer mark_ranges %val{timestamp}
      evaluate-commands -itersel %{
        set-option -add buffer mark_ranges "%val{selection_desc}|Mark"
      }
    }
  }
}

define-command -override show-marks -docstring 'show marks' %{
  remove-hooks global show-marks
  add-highlighter -override global/marks ranges mark_ranges
  hook -group show-marks global RegisterModified '\^' update-mark-ranges
}

define-command -override hide-marks -docstring 'hide marks' %{
  remove-hooks global show-marks
  remove-highlighter global/marks
}

# Indent guides
# Show indentation guides.
# Reference: https://code.visualstudio.com/docs/getstarted/userinterface#_indent-guides

# Faces
set-face global IndentGuidesOdd 'blue,blue+f'
set-face global IndentGuidesEven 'bright-blue,bright-blue+f'
set-face global IndentGuidesIncomplete 'red,red+f'

# Highlighters
add-highlighter -override shared/indent-guides regions
add-highlighter -override shared/indent-guides/region region '^' '(?=\H)' group
add-highlighter -override shared/indent-guides/region/incomplete fill IndentGuidesIncomplete
add-highlighter -override shared/indent-guides/region/odd dynregex '\h{%opt{indentwidth}}' '0:IndentGuidesOdd'
add-highlighter -override shared/indent-guides/region/even dynregex '\h{%opt{indentwidth}}\K\h{%opt{indentwidth}}' '0:IndentGuidesEven'

# Commands
define-command -override show-indent-guides -docstring 'show indent guides' %{
  add-highlighter -override global/indent-guides ref indent-guides
}

define-command -override hide-indent-guides -docstring 'hide indent guides' %{
  remove-highlighter global/indent-guides
}

declare-option -hidden str-list palette

define-command -override show-palette -docstring 'show palette' %{
  evaluate-commands -draft %{
    # Select the viewport
    execute-keys 'gtGb'
    # Select colors
    execute-keys '2s(#|rgb:)([0-9A-Fa-f]{6})<ret>'
    set-option window palette %reg{.}
  }
  info -anchor "%val{cursor_line}.%val{cursor_column}" -markup %sh{
    printf '{rgb:%s}██████{default}\n' $kak_opt_palette
  }
}

define-command -override set-indent -params 2 -docstring 'set-indent <scope> <width>: set indent in <scope> to <width>' %{
  set-option %arg{1} tabstop %arg{2}
  set-option %arg{1} indentwidth %arg{2}
}

define-command -override enable-detect-indent -docstring 'enable detect indent' %{
  remove-hooks global detect-indent
  hook -group detect-indent global BufOpenFile '.*' detect-indent
  hook -group detect-indent global BufWritePost '.*' detect-indent
}

define-command -override disable-detect-indent -docstring 'disable detect indent' %{
  remove-hooks global detect-indent
  evaluate-commands -buffer '*' %{
    unset-option buffer tabstop
    unset-option buffer indentwidth
  }
}

define-command -override detect-indent -docstring 'detect indent' %{
  try %{
    evaluate-commands -draft %{
      # Search the first indent level
      execute-keys 'gg/^\h+<ret>'

      # Tabs vs. Spaces
      # https://youtu.be/V7PLxL8jIl8
      try %{
        execute-keys '<a-k>\t<ret>'
        set-option buffer tabstop 8
        set-option buffer indentwidth 0
      } catch %{
        set-option buffer tabstop %val{selection_length}
        set-option buffer indentwidth %val{selection_length}
      }
    }
  }
}

define-command -override enable-auto-indent -docstring 'enable auto-indent' %{
  remove-hooks global auto-indent
  hook -group auto-indent global InsertChar '\n' %{
    # Copy previous line indent
    try %{ execute-keys -draft 'K<a-&>' }
    # Clean previous line indent
    try %{ execute-keys -draft 'k<a-x>s^\h+$<ret>d' }
  }
}

define-command -override disable-auto-indent -docstring 'disable auto-indent' %{
  remove-hooks global auto-indent
}

define-command -override make-directory-on-save -docstring 'make directory on save' %{
  remove-hooks global make-directory-on-save
  hook -group make-directory-on-save global BufWritePre '.*' %{
    nop %sh{
      # The full path of the file does not work with scratch buffers,
      # hence using `dirname`.
      # buffer_directory_path=${kak_buffile%/*}
      buffer_directory_path=$(dirname "$kak_buffile")
      if [ ! -d "$buffer_directory_path" ]; then
        mkdir -p "$buffer_directory_path"
      fi
    }
  }
}

# Documentation: https://xfree86.org/current/ctlseqs.html#:~:text=clipboard
define-command -override synchronize-clipboard -docstring 'synchronize clipboard' %{
  remove-hooks global synchronize-clipboard
  hook -group synchronize-clipboard global RegisterModified '"' %{
    nop %sh{
      encoded_selection_data=$(printf '%s' "$kak_main_reg_dquote" | base64)
      printf '\033]52;c;%s\a' "$encoded_selection_data" > /dev/tty
    }
  }
}

define-command -override synchronize-buffer-directory-name-with-register -params 1 -docstring 'synchronize buffer directory name with register' %{
  remove-hooks global "synchronize-buffer-directory-name-with-register-%arg{1}"
  hook -group "synchronize-buffer-directory-name-with-register-%arg{1}" global WinDisplay '.*' "
    save-directory-name-to-register %%val{hook_param} %arg{1}
  "
}

define-command -override -hidden save-directory-name-to-register -params 2 -docstring 'save-directory-name-to-register <path> <register>: save directory name to register' %{
  set-register %arg{2} %sh{printf '%s/' "${1%/*}"}
}

define-command -override link-window -params 1 -client-completion -docstring 'link-window <client>: link window to client' %{
  execute-keys '"sZ'
  execute-keys -client %arg{1} '"sz'
}

define-command -override move-window -params 1 -client-completion -docstring 'move-window <client>: move window to client' %{
  execute-keys '"sZ'
  execute-keys -client %arg{1} '"sz'
  buffer-next
}

define-command -override swap-window -params 1 -client-completion -docstring 'swap-window <client>: swap window with client' %{
  execute-keys '"sZ'
  execute-keys -client %arg{1} '"tZ'
  execute-keys '"tz'
  execute-keys -client %arg{1} '"sz'
}
