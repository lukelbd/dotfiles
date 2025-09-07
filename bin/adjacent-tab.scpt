# Strangely Debug->Tab Ordering->Position of New Tabs->After Current Tab
# only works when command-clicking links and not with command-T. Use this instead.
# See: https://daringfireball.net/2018/12/safari_new_tab_next_to_current_tab
tell application id "com.apple.Safari"
  tell front window
    set old_tab to current tab
    set new_tab to make new tab at after old_tab
    set current tab to new_tab
  end tell
end tell
