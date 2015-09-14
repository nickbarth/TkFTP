#!/bin/sh
# \
exec wish "$0" ${1+"$@"}

package require Expect

# Main Window
wm title . "Manage FTP"
wm resizable . 0 0
wm geometry . +800+500
. configure -padx 4 -pady 4
wm attributes . -topmost 0

# Add User Window
proc AddUserWindow { } {
  global ftp_env

  destroy .addWin
  toplevel .addWin -padx 2 -pady 2
  wm title .addWin "Create User"
  wm resizable .addWin 0 0
  regexp {\+([0-9]+)\+([0-9]+)} [winfo geometry .] match x y
  set x [expr "$x + 100"]
  set y [expr "$y + 50"]
  wm geometry .addWin +$x+$y
  wm attributes .addWin -topmost 1

  # UI
  frame .addWin.frame -padx 2 -pady 2
  label .addWin.account_label -text "$ftp_env Alpha ID:"
  entry .addWin.account_text -text "" -textvariable account
  label .addWin.password_label -text "Password:"
  entry .addWin.password_text -text "" -textvariable password
  button .addWin.ok -text Create -command {AddWinOk $account $password}
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
set ftp_env Production

# Functions
proc AddWinCancel {} {
  .addWin.account_text delete 0 end
  .addWin.password_text delete 0 end
  destroy .addWin
}

proc AddWinOk {user password} {
  global ftp_env

  spawn "/cli/ftp_manager/AddFTPUser$ftp_env.sh"
  expect {
    -re "What is the Alpha ID.*" {
      exp_send "$user\r"
      exp_continue
    }
    password: {
      exp_send "$password\r"
      exp_continue
    }
    -re "Success:.*" {
      .addWin.account_text delete 0 end
      .addWin.password_text delete 0 end
      destroy .addWin
      ToggleFTPEnv
      tk_messageBox -title Error -message [string trim $expect_out(buffer)] -type ok -icon error
    }
    -re "Error:.*" {
      wm attributes .addWin -topmost 0
      tk_messageBox -title Error -message [string trim $expect_out(buffer)] -type ok -icon error
      wm attributes .addWin -topmost 1
    }
  }
}

proc RemoveUser { } {
  global ftp_env
  set selection [.user_table selection]
  set selected_user [.user_table item $selection -text]

  if {$selected_user == ""} {
    tk_messageBox -message "No user was selected." -type ok -icon error
    return
  }

  set answer [tk_messageBox -message "Delete $ftp_env User `$selected_user`?" -icon question -type yesno]
  switch -- $answer {
    yes {
      .user_table delete $selection
      tk_messageBox -message "$ftp_env User `$selected_user` removed." -type ok
    }
  }
}

proc ToggleFTPEnv {} {
  global ftp_env
  set ftp_env_lower [string tolower $ftp_env]

  # Clear User Table
  .user_table delete [.user_table children {}]

  # Grep For Users or None
  if {[catch {exec awk {-F:} {{ print $1 " " $6 }} /etc/passwd | grep $ftp_env_lower} users]} {
    set users {}
  }

  # Fill in User Table
  if {[llength $users] != 0} {
    foreach {user dir} $users {
      .user_table insert {} end -text $user -values [list $dir]
    }
  }
}

# Main Window UI
ttk::treeview .user_table -selectmode browse -columns "Directory" -displaycolumns "Directory" -yscroll [list .scrollbar set]
ttk::scrollbar .scrollbar -command [list .user_table yview]
.user_table heading \#0 -text "User"
.user_table heading Directory -text "Directory"

frame .actions -padx 2
pack .user_table .scrollbar -side left -expand yes -fill y
pack .actions -side right -expand yes -fill both

grid [labelframe .select -text Environment] -in .actions -row 0 -column 0 -sticky news
pack [radiobutton .select.am -text Production -variable ftp_env -value Production -command ToggleFTPEnv] -anchor w
pack [radiobutton .select.fm -text Uploads -variable ftp_env -value Uploads -command ToggleFTPEnv] -anchor w

grid [button .addbtn -text "Create User" -command AddUserWindow] -in .actions -row 1 -column 0 -sticky news
# grid [button .rmbtn -text "Remove User" -command RemoveUser] -in .actions -row 2 -column 0 -sticky news

# Init
ToggleFTPEnv
