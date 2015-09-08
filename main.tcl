#!/bin/sh
# \
exec wish "$0" ${1+"$@"}

# Main Window
wm title . "Manage FTP"
wm resizable . 0 0
wm geometry . +800+500
. configure -padx 4 -pady 4
wm attributes . -topmost 0

proc AddUserWindow { } {
  destroy .addWin
  toplevel .addWin -padx 2 -pady 2
  wm title .addWin "Create User"
  wm resizable .addWin 0 0
  regexp {\+([0-9]+)\+([0-9]+)} [winfo geometry .] match x y
  set x [expr "$x + 100"]
  set y [expr "$y + 50"]
  wm geometry .addWin +$x+$y

  # UI
  frame .addWin.frame -padx 2 -pady 2
  label .addWin.account_label -text "Alpha ID:"
  entry .addWin.account_text -text "" -textvariable account
  label .addWin.password_label -text "Password:"
  entry .addWin.password_text -text "" -textvariable password
  button .addWin.ok -text Create -command {AddWinOk $account}
  button .addWin.cancel -text Cancel -command AddWinCancel
  focus .addWin.account_text

  pack .addWin.frame -fill x -expand yes
  pack .addWin.account_label -in .addWin.frame -side top -anchor nw
  pack .addWin.account_text -in .addWin.frame -side top
  pack .addWin.password_label -in .addWin.frame -side top -anchor nw
  pack .addWin.password_text -in .addWin.frame -side top
  pack .addWin.cancel .addWin.ok -side right
}

# Vars
set users [exec awk {-F:} {{ print $1 " " $6 }} /etc/passwd]

# Functions
proc AddWinCancel {} {
  .addWin.account_text delete 0 end
  .addWin.password_text delete 0 end
  destroy .addWin
}

proc AddWinOk {user} {
  .addWin.account_text delete 0 end
  .addWin.password_text delete 0 end
  destroy .addWin
  .tree insert {} 0 -text $user -values [list "/var/www/$user/"]
  tk_messageBox -message "User $user added." -type ok
}

proc RemoveUser { } {
  set selection [.tree selection]
  set selected_user [.tree item $selection -text]

  if {$selected_user == ""} {
    tk_messageBox -message "No user was selected." -type ok -icon error
    return
  }

  set answer [tk_messageBox -message "Delete `$selected_user` user?" -icon question -type yesno]
  switch -- $answer {
    yes {
      .tree delete $selection
      tk_messageBox -message "User `$selected_user` removed." -type ok
    }
  }
}

# UI
ttk::treeview .tree -selectmode browse -columns "Directory" -displaycolumns "Directory" -yscroll [list .sb set]
ttk::scrollbar .sb -command [list .tree yview]
.tree heading \#0 -text "User"
.tree heading Directory -text "Directory"
button .addbtn -text "Create User" -command AddUserWindow
button .rmbtn -text "Remove User" -command RemoveUser

grid .tree -row 0 -rowspan 4 -column 0 -sticky news
grid .sb -row 0 -rowspan 4 -column 1 -sticky news
grid .addbtn -row 0 -column 2 -sticky news
grid .rmbtn -row 1 -column 2 -sticky news

# Init
foreach {user dir} $users {
  .tree insert {} end -text $user -values [list $dir]
}
