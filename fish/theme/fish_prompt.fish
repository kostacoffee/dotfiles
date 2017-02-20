# name: bobthefish
#
# bobthefish is a Powerline-style, Git-aware fish theme optimized for awesome.
#
# You will need a Powerline-patched font for this to work:
#
#     https://powerline.readthedocs.org/en/master/installation.html#patched-fonts
#
# I recommend picking one of these:
#
#     https://github.com/Lokaltog/powerline-fonts
#
# For more advanced awesome, install a nerd fonts patched font (and be sure to
# enable nerd fonts support with `set -g theme_nerd_fonts yes`):
#
#     https://github.com/ryanoasis/nerd-fonts
#
# You can override some default prompt options in your config.fish:
#
#     set -g theme_display_git no
#     set -g theme_display_git_untracked no
#     set -g theme_display_git_ahead_verbose yes
#     set -g theme_git_worktree_support yes
#     set -g theme_display_vagrant yes
#     set -g theme_display_docker_machine no
#     set -g theme_display_hg yes
#     set -g theme_display_virtualenv no
#     set -g theme_display_ruby no
#     set -g theme_display_user yes
#     set -g theme_display_vi no
#     set -g theme_avoid_ambiguous_glyphs yes
#     set -g theme_powerline_fonts no
#     set -g theme_nerd_fonts yes
#     set -g theme_show_exit_status yes
#     set -g default_user your_normal_user
#     set -g theme_color_scheme dark
#     set -g fish_prompt_pwd_dir_length 0
#     set -g theme_project_dir_length 1

# ===========================
# Helper methods
# ===========================

# function __bobthefish_in_git -S -d 'Check whether pwd is inside a git repo'
#   command which git > /dev/null ^&1
#     and command git rev-parse --is-inside-work-tree >/dev/null ^&1
# end

# function __bobthefish_in_hg -S -d 'Check whether pwd is inside a hg repo'
#   command which hg > /dev/null ^&1
#     and command hg stat > /dev/null ^&1
# end

function __bobthefish_git_branch -S -d 'Get the current git branch (or commitish)'
  set -l ref (command git symbolic-ref HEAD ^/dev/null)
    and string replace 'refs/heads/' "$__bobthefish_branch_glyph " $ref
    and return

  set -l tag (command git describe --tags --exact-match ^/dev/null)
    and echo "$__bobthefish_tag_glyph $tag"
    and return

  set -l branch (command git show-ref --head -s --abbrev | head -n1 ^/dev/null)
  echo "$__bobthefish_detached_glyph $branch"
end

function __bobthefish_hg_branch -S -d 'Get the current hg branch'
  set -l branch (command hg branch ^/dev/null)
  set -l book (command hg book | command grep \* | cut -d\  -f3)
  echo "$__bobthefish_branch_glyph $branch @ $book"
end

function __bobthefish_pretty_parent -S -a current_dir -d 'Print a parent directory, shortened to fit the prompt'
  set -q fish_prompt_pwd_dir_length
    or set -l fish_prompt_pwd_dir_length 1

  # Replace $HOME with ~
  set -l real_home ~
  set -l parent_dir (string replace -r '^'"$real_home"'($|/)' '~$1' (dirname $current_dir))

  if [ $parent_dir = "/" ]
    echo -n /
    return
  end

  if [ $fish_prompt_pwd_dir_length -eq 0 ]
    echo -n "$parent_dir/"
    return
  end

  string replace -ar '(\.?[^/]{'"$fish_prompt_pwd_dir_length"'})[^/]*/' '$1/' "$parent_dir/"
end

function __bobthefish_git_project_dir -S -d 'Print the current git project base directory'
  [ "$theme_display_git" = 'no' ]; and return
  if [ "$theme_git_worktree_support" != 'yes' ]
    command git rev-parse --show-toplevel ^/dev/null
    return
  end

  set -l git_dir (command git rev-parse --git-dir ^/dev/null); or return

  pushd $git_dir
  set git_dir $PWD
  popd

  switch $PWD/
    case $git_dir/\*
      # Nothing works quite right if we're inside the git dir
      # TODO: fix the underlying issues then re-enable the stuff below

      # # if we're inside the git dir, sweet. just return that.
      # set -l toplevel (command git rev-parse --show-toplevel ^/dev/null)
      # if [ "$toplevel" ]
      #   switch $git_dir/
      #     case $toplevel/\*
      #       echo $git_dir
      #   end
      # end
      return
  end

  set -l project_dir (dirname $git_dir)

  switch $PWD/
    case $project_dir/\*
      echo $project_dir
      return
  end

  set project_dir (command git rev-parse --show-toplevel ^/dev/null)
  switch $PWD/
    case $project_dir/\*
      echo $project_dir
  end
end

function __bobthefish_hg_project_dir -S -d 'Print the current hg project base directory'
  [ "$theme_display_hg" = 'yes' ]; or return
  set -l d $PWD
  while not [ $d = / ]
    if [ -e $d/.hg ]
      command hg root --cwd "$d" ^/dev/null
      return
    end
    set d (dirname $d)
  end
end

function __bobthefish_project_pwd -S -a current_dir -d 'Print the working directory relative to project root'
  set -q theme_project_dir_length
    or set -l theme_project_dir_length 0

  set -l project_dir (string replace -r '^'"$current_dir"'($|/)' '' $PWD)

  if [ $theme_project_dir_length -eq 0 ]
    echo -n $project_dir
    return
  end

  string replace -ar '(\.?[^/]{'"$theme_project_dir_length"'})[^/]*/' '$1/' $project_dir
end

function __bobthefish_git_ahead -S -d 'Print the ahead/behind state for the current branch'
  if [ "$theme_display_git_ahead_verbose" = 'yes' ]
    __bobthefish_git_ahead_verbose
    return
  end

  set -l ahead 0
  set -l behind 0
  for line in (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
    switch "$line"
      case '>*'
        if [ $behind -eq 1 ]
          echo '±'
          return
        end
        set ahead 1
      case '<*'
        if [ $ahead -eq 1 ]
          echo '±'
          return
        end
        set behind 1
    end
  end

  if [ $ahead -eq 1 ]
    echo '+'
  else if [ $behind -eq 1 ]
    echo '-'
  end
end

function __bobthefish_git_ahead_verbose -S -d 'Print a more verbose ahead/behind state for the current branch'
  set -l commits (command git rev-list --left-right '@{upstream}...HEAD' ^/dev/null)
  [ $status != 0 ]; and return

  set -l behind (count (for arg in $commits; echo $arg; end | command grep '^<'))
  set -l ahead (count (for arg in $commits; echo $arg; end | command grep -v '^<'))

  switch "$ahead $behind"
    case '' # no upstream
    case '0 0' # equal to upstream
      return
    case '* 0' # ahead of upstream
      echo "↑$ahead"
    case '0 *' # behind upstream
      echo "↓$behind"
    case '*' # diverged from upstream
      echo "↑$ahead↓$behind"
  end
end

# ===========================
# Segment functions
# ===========================

function __bobthefish_start_segment -S -d 'Start a prompt segment'
  set -l bg $argv[1]
  set -e argv[1]
  set -l fg $argv[1]
  set -e argv[1]

  set_color normal # clear out anything bold or underline...
  set_color -b $bg $fg $argv

  switch "$__bobthefish_current_bg"
    case ''
      # If there's no background, just start one
      echo -n ' '
    case "$bg"
      # If the background is already the same color, draw a separator
      echo -ns $__bobthefish_right_arrow_glyph ' '
    case '*'
      # otherwise, draw the end of the previous segment and the start of the next
      set_color $__bobthefish_current_bg
      echo -ns $__bobthefish_right_black_arrow_glyph ' '
      set_color $fg $argv
  end

  set __bobthefish_current_bg $bg
end

function __bobthefish_path_segment -S -a current_dir -d 'Display a shortened form of a directory'
  set -l segment_color $__color_path
  set -l segment_basename_color $__color_path_basename

  if not [ -w "$current_dir" ]
    set segment_color $__color_path_nowrite
    set segment_basename_color $__color_path_nowrite_basename
  end

  __bobthefish_start_segment $segment_color

  set -l directory
  set -l parent

  switch "$current_dir"
    case /
      set directory '/'
    case "$HOME"
      set directory '~'
    case '*'
      set parent    (__bobthefish_pretty_parent "$current_dir")
      set directory (basename "$current_dir")
  end

  echo -n $parent
  set_color -b $segment_basename_color
  echo -ns $directory ' '
end

function __bobthefish_finish_segments -S -d 'Close open prompt segments'
  if [ "$__bobthefish_current_bg" != '' ]
    set_color normal
    set_color $__bobthefish_current_bg
    echo -ns $__bobthefish_right_black_arrow_glyph ' '
  end

  set_color normal
  set __bobthefish_current_bg
end


# ===========================
# Theme components
# ===========================

function __bobthefish_prompt_vagrant -S -d 'Display Vagrant status'
  [ "$theme_display_vagrant" = 'yes' -a -f Vagrantfile ]; or return

  # .vagrant/machines/$machine/$provider/id
  for file in .vagrant/machines/*/*/id
    read -l id <$file

    if [ ! -z "$id" ]
      switch "$file"
        case '*/virtualbox/id'
          __bobthefish_prompt_vagrant_vbox $id
        case '*/vmware_fusion/id'
          __bobthefish_prompt_vagrant_vmware $id
        case '*/parallels/id'
          __bobthefish_prompt_vagrant_parallels $id
      end
    end
  end
end

function __bobthefish_prompt_vagrant_vbox -S -a id -d 'Display VirtualBox Vagrant status'
  set -l vagrant_status
  set -l vm_status (VBoxManage showvminfo --machinereadable $id ^/dev/null | command grep 'VMState=' | tr -d '"' | cut -d '=' -f 2)
  switch "$vm_status"
    case 'running'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_running_glyph"
    case 'poweroff'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_poweroff_glyph"
    case 'aborted'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_aborted_glyph"
    case 'saved'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_saved_glyph"
    case 'stopping'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_stopping_glyph"
    case ''
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_unknown_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __bobthefish_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __bobthefish_prompt_vagrant_vmware -S -a id -d 'Display VMWare Vagrant status'
  set -l vagrant_status
  if [ (pgrep -f "$id") ]
    set vagrant_status "$vagrant_status$__bobthefish_vagrant_running_glyph"
  else
    set vagrant_status "$vagrant_status$__bobthefish_vagrant_poweroff_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __bobthefish_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __bobthefish_prompt_vagrant_parallels -S -d 'Display Parallels Vagrant status'
  set -l vagrant_status
  set -l vm_status (prlctl list $id -o status ^/dev/null | command tail -1)
  switch "$vm_status"
    case 'running'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_running_glyph"
    case 'stopped'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_poweroff_glyph"
    case 'paused'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_saved_glyph"
    case 'suspended'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_saved_glyph"
    case 'stopping'
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_stopping_glyph"
    case ''
      set vagrant_status "$vagrant_status$__bobthefish_vagrant_unknown_glyph"
  end
  [ -z "$vagrant_status" ]; and return

  __bobthefish_start_segment $__color_vagrant
  echo -ns $vagrant_status ' '
end

function __bobthefish_prompt_docker -S -d 'Show docker machine name'
    [ "$theme_display_docker_machine" = 'no' -o -z "$DOCKER_MACHINE_NAME" ]; and return
    __bobthefish_start_segment $__color_vagrant
    echo -ns $DOCKER_MACHINE_NAME ' '
end

function __bobthefish_prompt_status -S -a last_status -d 'Display symbols for a non zero exit status, root and background jobs'
  set -l nonzero
  set -l superuser
  set -l bg_jobs

  # Last exit was nonzero
  [ $last_status -ne 0 ]
    and set nonzero $__bobthefish_nonzero_exit_glyph

  # if superuser (uid == 0)
  [ (id -u $USER) -eq 0 ]
    and set superuser $__bobthefish_superuser_glyph

  # Jobs display
  [ (jobs -l | wc -l) -gt 0 ]
    and set bg_jobs $__bobthefish_bg_job_glyph

  if [ "$nonzero" -o "$superuser" -o "$bg_jobs" ]
    __bobthefish_start_segment $__color_initial_segment_exit
    if [ "$nonzero" ]
      set_color normal
      set_color -b $__color_initial_segment_exit
      if [ "$theme_show_exit_status" = 'yes' ]
      	echo -ns $last_status ' '
      else
      	echo -n $__bobthefish_nonzero_exit_glyph
      end
    end

    if [ "$superuser" ]
      set_color normal
      set_color -b $__color_initial_segment_su
      echo -n $__bobthefish_superuser_glyph
    end

    if [ "$bg_jobs" ]
      set_color normal
      set_color -b $__color_initial_segment_jobs
      echo -n $__bobthefish_bg_job_glyph
    end
  end
end

function __bobthefish_prompt_user -S -d 'Display actual user if different from $default_user in a prompt segment'
  if [ "$theme_display_user" = 'yes' ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      __bobthefish_start_segment $__color_username
      set -l IFS .
      hostname | read -l hostname __
      echo -ns (whoami) '@' $hostname ' '
    end
  end
end

function __bobthefish_prompt_hg -S -a current_dir -d 'Display the actual hg state'
  set -l dirty (command hg stat; or echo -n '*')

  set -l flags "$dirty"
  [ "$flags" ]
    and set flags ""

  set -l flag_colors $__color_repo
  if [ "$dirty" ]
    set flag_colors $__color_repo_dirty
  end

  __bobthefish_path_segment $current_dir

  __bobthefish_start_segment $flag_colors
  echo -ns $__bobthefish_hg_glyph ' '

  __bobthefish_start_segment $flag_colors
  echo -ns (__bobthefish_hg_branch) $flags ' '
  set_color normal

  set -l project_pwd  (__bobthefish_project_pwd $current_dir)
  if [ "$project_pwd" ]
    if [ -w "$PWD" ]
      __bobthefish_start_segment $__color_path
    else
      __bobthefish_start_segment $__color_path_nowrite
    end

    echo -ns $project_pwd ' '
  end
end

function __bobthefish_prompt_git -S -a current_dir -d 'Display the actual git state'
  set -l dirty   (command git diff --no-ext-diff --quiet --exit-code; or echo -n '*')
  set -l staged  (command git diff --cached --no-ext-diff --quiet --exit-code; or echo -n '~')
  set -l stashed (command git rev-parse --verify --quiet refs/stash >/dev/null; and echo -n '$')
  set -l ahead   (__bobthefish_git_ahead)

  set -l new ''
  set -l show_untracked (command git config --bool bash.showUntrackedFiles)
  if [ "$theme_display_git_untracked" != 'no' -a "$show_untracked" != 'false' ]
    set new (command git ls-files --other --exclude-standard --directory --no-empty-directory)
    if [ "$new" ]
      if [ "$theme_avoid_ambiguous_glyphs" = 'yes' ]
        set new '...'
      else
        set new '…'
      end
    end
  end

  set -l flags "$dirty$staged$stashed$ahead$new"
  [ "$flags" ]
    and set flags " $flags"

  set -l flag_colors $__color_repo
  if [ "$dirty" ]
    set flag_colors $__color_repo_dirty
  else if [ "$staged" ]
    set flag_colors $__color_repo_staged
  end

  __bobthefish_path_segment $current_dir

  __bobthefish_start_segment $flag_colors
  echo -ns (__bobthefish_git_branch) $flags ' '
  set_color normal

  if [ "$theme_git_worktree_support" != 'yes' ]
    set -l project_pwd (__bobthefish_project_pwd $current_dir)
    if [ "$project_pwd" ]
      if [ -w "$PWD" ]
        __bobthefish_start_segment $__color_path
      else
        __bobthefish_start_segment $__color_path_nowrite
      end

      echo -ns $project_pwd ' '
    end
    return
  end

  set -l project_pwd (command git rev-parse --show-prefix ^/dev/null | string replace -r '/$' '')
  set -l work_dir (command git rev-parse --show-toplevel ^/dev/null)

  # only show work dir if it's a parent…
  if [ "$work_dir" ]
    switch $PWD/
      case $work_dir/\*
        string match "$current_dir*" $work_dir
          and set work_dir (string sub -s (string length $current_dir) $work_dir)
      case \*
        set -e work_dir
    end
  end

  if [ "$project_pwd" -o "$work_dir" ]
    set -l colors $__color_path
    if not [ -w "$PWD" ]
      set colors $__color_path_nowrite
    end

    __bobthefish_start_segment $colors

    # handle work_dir != project dir
    if [ "$work_dir" ]
      set -l work_parent (dirname $work_dir | string replace -r '^/' '')
      if [ "$work_parent" ]
        echo -n "$work_parent/"
      end
      set_color normal
      set_color -b $__color_repo_work_tree
      echo -n (basename $work_dir)
      set_color normal
      set_color -b $colors
      [ "$project_pwd" ]
        and echo -n '/'
    end

    echo -ns $project_pwd ' '
  else
    set project_pwd $PWD
    string match "$current_dir*" $project_pwd
      and set project_pwd (string sub -s (string length $current_dir) $current_dir)
    set project_pwd (string replace -r '^/' '' $project_pwd)

    if [ "$project_pwd" ]
      set -l colors $color_path
      if not [ -w "$PWD" ]
        set colors $color_path_nowrite
      end

      __bobthefish_start_segment $colors

      echo -ns $project_pwd ' '
    end
  end
end

function __bobthefish_prompt_dir -S -d 'Display a shortened form of the current directory'
  __bobthefish_path_segment "$PWD"
end

function __bobthefish_prompt_vi -S -d 'Display vi mode'
  [ "$theme_display_vi" != 'no' -a "$fish_key_bindings" = 'fish_vi_key_bindings' ]; or return
  switch $fish_bind_mode
    case default
      __bobthefish_start_segment $__color_vi_mode_default
      echo -n 'N '
    case insert
      __bobthefish_start_segment $__color_vi_mode_insert
      echo -n 'I '
    case replace-one
      __bobthefish_start_segment $__color_vi_mode_insert
      echo -n 'R '
    case visual
      __bobthefish_start_segment $__color_vi_mode_visual
      echo -n 'V '
  end
end

function __bobthefish_virtualenv_python_version -S -d 'Get current python version'
  switch (python --version ^| tr '\n' ' ')
    case 'Python 2*PyPy*'
      echo $__bobthefish_pypy_glyph
    case 'Python 3*PyPy*'
      echo -s $__bobthefish_pypy_glyph $__bobthefish_superscript_glyph[3]
    case 'Python 2*'
      echo $__bobthefish_superscript_glyph[2]
    case 'Python 3*'
      echo $__bobthefish_superscript_glyph[3]
  end
end

function __bobthefish_prompt_virtualfish -S -d "Display activated virtual environment (only for virtualfish, virtualenv's activate.fish changes prompt by itself)"
  [ "$theme_display_virtualenv" = 'no' -o -z "$VIRTUAL_ENV" ]; and return
  set -l version_glyph (__bobthefish_virtualenv_python_version)
  if [ "$version_glyph" ]
    __bobthefish_start_segment $__color_virtualfish
    echo -ns $__bobthefish_virtualenv_glyph $version_glyph ' '
  end
  echo -ns (basename "$VIRTUAL_ENV") ' '
end

function __bobthefish_rvm_parse_ruby -S -a ruby_string scope -d 'Parse RVM Ruby string'
  # Function arguments:
  # - 'ruby-2.2.3@rails', 'jruby-1.7.19'...
  # - 'default' or 'current'
  set -l IFS @
  echo "$ruby_string" | read __ruby __rvm_{$scope}_ruby_gemset __
  set IFS -
  echo "$__ruby" | read __rvm_{$scope}_ruby_interpreter __rvm_{$scope}_ruby_version __
  set -e __ruby
  set -e __
end

function __bobthefish_rvm_info -S -d 'Current Ruby information from RVM'
  # More `sed`/`grep`/`cut` magic...
  set -l __rvm_default_ruby (grep GEM_HOME ~/.rvm/environments/default | sed -e"s/'//g" | sed -e's/.*\///')
  set -l __rvm_current_ruby (rvm-prompt i v g)
  [ "$__rvm_default_ruby" = "$__rvm_current_ruby" ]; and return

  set -l __rvm_default_ruby_gemset
  set -l __rvm_default_ruby_interpreter
  set -l __rvm_default_ruby_version
  set -l __rvm_current_ruby_gemset
  set -l __rvm_current_ruby_interpreter
  set -l __rvm_current_ruby_version

  # Parse default and current Rubies to global variables
  __bobthefish_rvm_parse_ruby $__rvm_default_ruby default
  __bobthefish_rvm_parse_ruby $__rvm_current_ruby current
  # Show unobtrusive RVM prompt

  # If interpreter differs form default interpreter, show everything:
  if [ "$__rvm_default_ruby_interpreter" != "$__rvm_current_ruby_interpreter" ]
    if [ "$__rvm_current_ruby_gemset" = 'global' ]
      rvm-prompt i v
    else
      rvm-prompt i v g
    end
  # If version differs form default version
  else if [ "$__rvm_default_ruby_version" != "$__rvm_current_ruby_version" ]
    if [ "$__rvm_current_ruby_gemset" = 'global' ]
      rvm-prompt v
    else
      rvm-prompt v g
    end
  # If gemset differs form default or 'global' gemset, just show it
  else if [ "$__rvm_default_ruby_gemset" != "$__rvm_current_ruby_gemset" ]
    rvm-prompt g
  end
end

function __bobthefish_show_ruby -S -d 'Current Ruby (rvm/rbenv)'
  set -l ruby_version
  if type -q rvm-prompt
    set ruby_version (__bobthefish_rvm_info)
  else if type -q rbenv
    set ruby_version (rbenv version-name)
    # Don't show global ruby version...
    set -q RBENV_ROOT
      or set -l RBENV_ROOT $HOME/.rbenv

    read -l global_ruby_version <$RBENV_ROOT/version

    [ "$global_ruby_version" ]
      or set global_ruby_version system

    [ "$ruby_version" = "$global_ruby_version" ]; and return
  else if type -q chruby
    set ruby_version $RUBY_VERSION
  end
  [ -z "$ruby_version" ]; and return
  __bobthefish_start_segment $__color_rvm
  echo -ns $__bobthefish_ruby_glyph $ruby_version ' '
end

function __bobthefish_prompt_rubies -S -d 'Display current Ruby information'
  [ "$theme_display_ruby" = 'no' ]; and return
  __bobthefish_show_ruby
end

# ===========================
# Debugging functions
# ===========================

function __bobthefish_display_colors -d 'Print example prompts using the current color scheme'
  set -g __bobthefish_display_colors
end

function __bobthefish_maybe_display_colors -S
  if not set -q __bobthefish_display_colors
    return
  end

  set -e __bobthefish_display_colors

  echo
  set_color normal

  __bobthefish_start_segment $__color_initial_segment_exit
  echo -n exit '! '
  set_color -b $__color_initial_segment_su
  echo -n su '$ '
  set_color -b $__color_initial_segment_jobs
  echo -n jobs '% '
  __bobthefish_finish_segments
  set_color normal
  echo -n "(<- color_initial_segment)"
  echo

  __bobthefish_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_path_nowrite
  echo -n /color/path/nowrite/
  set_color -b $__color_path_nowrite_basename
  echo -ns basename ' '
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __bobthefish_start_segment $__color_repo
  echo -ns $__bobthefish_branch_glyph ' '
  echo -n "color-repo "
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __bobthefish_start_segment $__color_repo_dirty
  echo -ns $__bobthefish_branch_glyph ' '
  echo -n "color-repo-dirty "
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_path
  echo -n /color/path/
  set_color -b $__color_path_basename
  echo -ns basename ' '
  __bobthefish_start_segment $__color_repo_staged
  echo -ns $__bobthefish_branch_glyph ' '
  echo -n "color-repo-staged "
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_vi_mode_default
  echo -ns vi_mode_default ' '
  __bobthefish_finish_segments
  __bobthefish_start_segment $__color_vi_mode_insert
  echo -ns vi_mode_insert ' '
  __bobthefish_finish_segments
  __bobthefish_start_segment $__color_vi_mode_visual
  echo -ns vi_mode_visual ' '
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_vagrant
  echo -n color_vagrant ' '
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_username
  echo -n color_username ' '
  __bobthefish_finish_segments
  echo

  __bobthefish_start_segment $__color_rvm
  echo -n color_rvm ' '
  __bobthefish_finish_segments
  __bobthefish_start_segment $__color_virtualfish
  echo -ns color_virtualfish ' '
  __bobthefish_finish_segments
  echo -e "\n"

end

# ===========================
# Apply theme
# ===========================

function fish_prompt -d 'bobthefish, a fish theme optimized for awesome'
  # Save the last status for later (do this before the `set` calls below)
  set -l last_status $status

  # Powerline glyphs
  set -l __bobthefish_branch_glyph     \uF418
  set -l __bobthefish_detached_glyph   \uF417
  set -l __bobthefish_tag_glyph        \uF412

  set -l __bobthefish_right_black_arrow_glyph \uE0B0
  set -l __bobthefish_right_arrow_glyph       \uE0B1
  set -l __bobthefish_left_black_arrow_glyph  \uE0B2
  set -l __bobthefish_left_arrow_glyph        \uE0B3

  # Additional glyphs
  set -l __bobthefish_nonzero_exit_glyph      \uf00d ' '
  set -l __bobthefish_superuser_glyph         \uf0e7 ' '
  set -l __bobthefish_bg_job_glyph            \uf013 ' '
  set -l __bobthefish_hg_glyph                \u263F

  # Python glyphs
  set -l __bobthefish_superscript_glyph       \u00B9 \u00B2 \u00B3
  set -l __bobthefish_virtualenv_glyph \uE73C ' '
  set -l __bobthefish_pypy_glyph              \u1D56

  set -l __bobthefish_ruby_glyph       \uE791 ' '

  # Vagrant glyphs
  set -l __bobthefish_vagrant_running_glyph  \uF431 # ↑ 'running'
  set -l __bobthefish_vagrant_poweroff_glyph \uF433 # ↓ 'poweroff'
  set -l __bobthefish_vagrant_aborted_glyph  \uF468 # ✕ 'aborted'
  set -l __bobthefish_vagrant_saved_glyph     \u21E1 # ⇡ 'saved'
  set -l __bobthefish_vagrant_stopping_glyph  \u21E3 # ⇣ 'stopping'
  set -l __bobthefish_vagrant_unknown_glyph  \uF421 # strange cases

  # Colors

  #               light  medium dark
  #               ------ ------ ------
  set -l red      cc9999 ce000f 660000
  set -l green    addc10 189303 0c4801
  set -l blue     48b4fb 005faf 255e87
  set -l orange   f6b117 unused 3a2a03
  set -l brown    bf5e00 803f00 4d2600
  set -l grey     cccccc 999999 333333
  set -l white    ffffff
  set -l black    000000
  set -l ruby_red af0000

  set __color_initial_segment_exit     $white $red[2] --bold
  set __color_initial_segment_su       $white $green[2] --bold
  set __color_initial_segment_jobs     $white $blue[3] --bold

  set __color_path                     $grey[3] $grey[2]
  set __color_path_basename            $grey[3] $white --bold
  set __color_path_nowrite             $red[3] $red[1]
  set __color_path_nowrite_basename    $red[3] $red[1] --bold

  set __color_repo                     $green[1] $green[3]
  set __color_repo_work_tree           $green[1] $white --bold
  set __color_repo_dirty               $red[2] $white
  set __color_repo_staged              $orange[1] $orange[3]

  set __color_vi_mode_default          $grey[2] $grey[3] --bold
  set __color_vi_mode_insert           $green[2] $grey[3] --bold
  set __color_vi_mode_visual           $orange[1] $orange[3] --bold

  set __color_vagrant                  $blue[1] $white --bold
  set __color_username                 $grey[1] $blue[3]
  set __color_rvm                      $ruby_red $grey[1] --bold
  set __color_virtualfish              $blue[2] $grey[1] --bold

  # Start each line with a blank slate
  set -l __bobthefish_current_bg

  __bobthefish_maybe_display_colors

  __bobthefish_prompt_status $last_status
  __bobthefish_prompt_vi
  __bobthefish_prompt_vagrant
  __bobthefish_prompt_docker
  __bobthefish_prompt_user
  __bobthefish_prompt_rubies
  __bobthefish_prompt_virtualfish

  set -l git_root (__bobthefish_git_project_dir)
  set -l hg_root  (__bobthefish_hg_project_dir)

  if [ "$git_root" -a "$hg_root" ]
    # only show the closest parent
    switch $git_root
      case $hg_root\*
        __bobthefish_prompt_git $git_root
      case \*
        __bobthefish_prompt_hg $hg_root
    end
  else if [ "$git_root" ]
    __bobthefish_prompt_git $git_root
  else if [ "$hg_root" ]
    __bobthefish_prompt_hg $hg_root
  else
    __bobthefish_prompt_dir
  end

  __bobthefish_finish_segments
end
