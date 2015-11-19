#!/bin/sh
# \
exec wish "$0" ${1+"$@"}

proc add_user_modal { } {
  # Modal Setup
  set w .add_user_modal
  toplevel $w
  tkwait visibility $w
  grab $w

  # UI
  wm title $w "Add User"
  frame $w.frame -padx 2 -pady 2
  pack $w.frame -fill x -expand yes

  label $w.account_label -text "Username:"
  pack $w.account_label -in $w.frame -side top -anchor nw
  entry $w.account_text -text "" -textvariable _username
  pack $w.account_text -in $w.frame -side top
  focus $w.account_text

  label $w.directory_label -text "Directory:"
  pack $w.directory_label -in $w.frame -side top -anchor nw
  ttk::combobox $w.directory_text -state readonly -values {"/home/uploads/" "/home/production/"} -textvariable _directory
  pack $w.directory_text -in $w.frame -side top
  set ::_directory "/home/uploads/"

  label $w.password_label -text "Password:"
  pack $w.password_label -in $w.frame -side top -anchor nw
  entry $w.password_text -text "" -textvariable _password
  pack $w.password_text -in $w.frame -side top

  button $w.ok -text Create -command {set _complete true}
  button $w.cancel -text Cancel -command {set _complete false}
  pack $w.cancel $w.ok -side right

  # Action
  vwait _complete

  if { $::_complete } {
    exec adduser --system --ingroup ftpuser --home $::_directory$::_username $::_username 2> /dev/null
    exec echo "$::_username:$::_password" | chpasswd
    tk_messageBox -message "The user `$::_username` was added successfully." -type ok
    refresh_user_table
  }

  # Cleanup
  wm withdraw $w
  destroy $w

  unset ::_complete ::_username ::_directory ::_password
}

proc update_user_modal { } {
  # User Selected Check
  set selection [.user_table selection]
  set selected_user [.user_table item $selection -text]

  if {$selected_user == ""} {
    tk_messageBox -message "No user was selected." -type ok -icon error
    return
  }

  # Modal Setup
  set w .add_user_modal
  toplevel $w
  tkwait visibility $w
  grab $w

  # UI
  wm title $w "Update User"
  frame $w.frame -padx 2 -pady 2
  pack $w.frame -fill x -expand yes

  label $w.account_label -justify left -text "Username:\n$selected_user"
  pack $w.account_label -in $w.frame -side top -anchor nw
  
  label $w.password_label -text "Password:"
  pack $w.password_label -in $w.frame -side top -anchor nw
  entry $w.password_text -text "" -textvariable _password
  pack $w.password_text -in $w.frame -side top
  focus $w.password_text

  button $w.ok -text Update -command {set _complete true}
  button $w.cancel -text Cancel -command {set _complete false}
  pack $w.cancel $w.ok -side right

  # Action
  vwait _complete

  if { $::_complete } {
    exec echo "$selected_user:$::_password" | chpasswd
    tk_messageBox -message "The user `$selected_user` was updated successfully." -type ok
  }

  # Cleanup
  wm withdraw $w
  destroy $w

  unset ::_complete ::_password
}

proc remove_user_modal { } {
  # User Selected Check
  set selection [.user_table selection]
  set selected_user [.user_table item $selection -text]

  if {$selected_user == ""} {
    tk_messageBox -message "No user was selected." -type ok -icon error
    return
  }

  # Remove user on confirm
  set answer [tk_messageBox -message "Delete user `$selected_user`?" -icon question -type yesno]
  switch -- $answer {
    yes {
      .user_table delete $selection
      tk_messageBox -message "The user `$selected_user` was removed." -type ok
      exec userdel $selected_user
    }
  }
}

proc refresh_user_table { } {
   # Clear User Table
  .user_table delete [.user_table children {}]

  # Grep For Users or None
  #
  # [bash] awk -F: '{ system("id -gn " $1); print " " $1 " " $6 " " }' /etc/passwd | xargs -n3 | grep ftpuser
  # > root nick /home/nick/
  #
  if {[catch {exec awk {-F:} {{ system("id -gn " $1); print $1 " " $6 }} /etc/passwd | xargs -n3 | grep ftpuser} users]} {
    set users {}
  }

  # Fill in User Table
  if {[llength $users] != 0} {
    foreach {group user dir} $users {
      .user_table insert {} end -text $user -values [list $dir]
    }
  }
}

# Main Window
wm title . "Manage FTP"
wm resizable . 0 0
wm geometry . +800+500
. configure -padx 4 -pady 4
wm attributes . -topmost 0

# Main Window UI
# User Table
ttk::treeview .user_table -selectmode browse -columns "Directory" -displaycolumns "Directory" -yscroll [list .scrollbar set]
ttk::scrollbar .scrollbar -command [list .user_table yview]
.user_table heading \#0 -text "User"
.user_table heading Directory -text "Directory"
pack .user_table .scrollbar -side left -expand yes -fill y

# Populate User Table
refresh_user_table

# Right Side Actions
frame .actions -padx 2
pack .actions -side right -expand yes -fill both
grid [button .add_button -text "Add User" -command add_user_modal] -in .actions -row 0 -column 0 -sticky news
grid [button .update_button -text "Update User" -command update_user_modal] -in .actions -row 1 -column 0 -sticky news
grid [button .remove_button -text "Remove User" -command remove_user_modal] -in .actions -row 2 -column 0 -sticky news
