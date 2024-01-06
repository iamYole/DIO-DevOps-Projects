# Basic Linux commands

### Part 1 - File Manipulation

- `sudo`  
   This command is used by non root users to run tasks/commands that reqiure root or administrative privelidge.
  ![Alt text](Images/img_01.png)
- `pwd`  
   This command is used to print the current or present working directory .
  ![Alt text](Images/img_02.png)
- `cd`  
   This command is used to change the current directory. It is usully used with the name of the directory that needs to be changed to.
  ![Alt text](Images/img_03.png)
- `ls`  
  The list command is used to list the content of a directory. This command can be used with several flags for example:

  - ls -a : lists hidden files in a directory.
  - ls -lh : lists the files in a directory and their size.
  - ls - R list the files in a directory as well as the files in all sub directorys.

  ![Alt text](Images/img_04.png)

- `cat`  
   The `cat` command is used to read the content of a file. It can also be used to merge the contents of multiple files.
  ![Alt text](Images/img_05.png)
- `cp`  
   The `cp` command is used to copy contents of a file, a file itself or even a directory. When used with the `-R` flag, it can copy the content of an entire directory from one location to another.
  ![Alt text](Images/img_06.png)
- `mv`  
   This command is used to move files from one location to another. It can also be used to rename a file.
  ![Alt text](Images/img_07.png)
- `mkdir`  
   The `mkdir` command is used to create a new directory.
  ![Alt text](Images/img_08.png)
- `rmdir`  
   This command is used to remove or delete an empty directory.
  ![Alt text](Images/img_09.png)
- `rm`  
   The is command is used to remove or delete a file from a directory.
  ![Alt text](Images/img_10.png)
- `touch`  
   This command is used to create an empty file on Linux. Alternatively, we can use vi/vim (a text editor) to create a file and then add some conntents  
  ![Alt text](Images/img_11.png)
- `locate`  
   The `locate` command is used to search for a file in the file directory. Using this command with the flag `-i` makes the search string not case sensitive, and it can also be used with wildcards such as `*` to make the search more dynamic. For example `sudo locate *.txt`  
  ![Alt text](Images/img_12.png)
- `find`
  This is very similar to the `locate` command. The `find` command is also used to search for a file in directory using different attributes such as -name, -d directory etc.
  ![Alt text](Images/img_13.png)
- `grep`  
   The `grep` command or global regular expression command also helps in searching for files or contents of a directory. It can be used it several other commands such as `cat`, `ls` etc. It can be used to limit or streamline the output of our search to something more specific. It comes in very handy when going through large texts.  
   For example, running the command `cat /etc/passwd` would list a lot of contents about users of the system. But with the `grep` command, it can be limited to a particular user with the following command `cat /etc/passwd | grep ubuntu`
  ![Alt text](Images/img_14.png)
- `df`  
   This command is used to print useful information about the disk on the linux machine.
  ![Alt text](Images/img_15.png)
- `du`  
   The `du` or disk usgae commnd is used to check how much space a file or directory takes in the system
  ![Alt text](Images/img_16.png)
- `head`  
   This commands prints the first 10 lines in a textfle. When used with `-n` it can print a specific number of lines.
  ![Alt text](Images/img_17.png)
- `tail`  
   This is the exact oppostie of the `head` command. It is used the print the last 10 lines in a text file, or when used with `-n`, print a specific number of lines.
  ![Alt text](Images/img_18.png)
  When used together, the `head` and `tail` can be used to print any Nth line or number of lines
  ![Alt text](Images/img_18b.png)
- `diff`  
  This command is used to print the different between the content of two files
  ![Alt text](Images/img_19.png)
- `tar`  
   The `tar` command is used to compress multiple files into a single tar file, just like zipping a file in windows. This command has several flags such as `-t`,`-c`,`-x`,`-v` to list, create, extract, provides more information etc.
  ![Alt text](Images/img_20.png)

#### Part 2 - File Permission and Ownership

- `chmod`  
   This commond is used to modify a file or directory's read, write or execute permission.
  ![Alt text](Images/img_21a.png)
  Using `chmod -rw file2.txt` we removed the read and write permissing on file2.
  ![Alt text](Images/img_21b.png)
  A combination of numbers can also be used to archieve this where:

  - 4 Represents Read,
  - 2 Represents Write, and
  - 1 Represents Execute.

  By this, `7` reresents full access, `6` represents read+write, `5` represents read+execute ....

- `chown`  
   Just like `chmod`, `chown` is used to modify the ownership of a file. In the example below, the ownership of the `.tar` file was changed to th root user.
  ![Alt text](Images/img_22.png)

- `jobs`
  The `jobs` command is used to list all active or stopped jobs in the system
- `kill`  
   The `kill` command is used to stop an unresponsive application or process in the system. In order to use the command, you must know the process id in which the unresponsive program is running on.
  ![Alt text](Images/img_23.png)
  The code in the example above list all process running the bash shell. To kill the oricess running bash in root, we issue the `kill 1599` command. This should however be done with care.
- `ping`  
   This is commonly used to check if a network or server is reachable.
  ![Alt text](Images/img_24.png)
- `wget`  
   This command is used to download files from the internet.
  ![Alt text](Images/img_25.png)
- `uname`  
   The UNIX name command is used to print information about the operating system, hardware platform, and kernel version.
  ![Alt text](Images/img_26.png)
- `top`  
   This command is used to display the top running process in the linux machine. The display is dynamic as the state or processes change frequently.
  ![Alt text](Images/img_27.png)
- `history`  
   Just as the name suggests, the `history` command is just to print the recently executed commands in the system. This command can list up to the last 500 commands executed.
  ![Alt text](Images/img_28.png)
- `man`  
  Short for manual, the `man` command is used to provide a user manual or help page to commands. For example `man tar` will provide a detailed explanation on how to use the `tar` command include all it's available options
- `echo`  
   This command is used to print out a text or variable. It can also be used to write contents to a file.
  ![Alt text](Images/img_30.png)
- `zip and unzip`  
  These commands are used to compress and uncompress files or directories. Just like the zip and unzip commands in windows.
- `hostname`  
   This command is used to display the hostname of a system.
  ![Alt text](Images/img_31.png)
- `userdadd, userdel`  
   Just as the name suggests, these commands are used to add or delete a user from the system.
  ![Alt text](Images/img_32.png)
  Alternatively, we can use the `adduser` command to create both the user and other information including their home directory
  ![Alt text](Images/img_33.png)
- `apt-get`  
  This command is used by _debian_ and _ubuntu based_ linux machines to install, update or remove packages or applications.
- `nano, vi/vim, jed`  
   Just like notepad in windows, these are text editors for editng basic files. In `vim` for example, loading a file requires `vim filename`, pressing `i` will place the file on insert mode and the `:w` saves the file
  ![Alt text](Images/img_34.png)
- `alias, unalias`
  These commands are used to create or delete alias for an exiting linux command. For instance if you don't like using the `cat` command to print the content of a fiile, you can replace that by using the code below.
  ![Alt text](Images/img_35.png)
- `su`
  The switch user command is used to switch from one user. It is particularly helpful when working from a remote shell, and one requires adminstrative access. One can easily switch to the root user to perform specific task as against loggin in as the root user. Unlike the `sudo` command, the `su` command can be used to switch to a non root account.
  ![Alt text](Images/img_36.png)
- `htop`  
   This command is an interactive tool used to monitor processess in linux. This is very similar to the `top` command, but the `htop` is more interactive, and allows more control for session/process management.
  ![Alt text](Images/img_37.png)
- `ps`  
   The process status is used to list all the running processes in the system. It can be used with different flags such as `-u` to list all process associated with a user. We can even filter more using the `grep` command.
  ![Alt text](Images/img_38.png)
