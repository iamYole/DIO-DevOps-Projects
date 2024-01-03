# Deploying a WordPress website integrated with Logical Volume Management (LVM) storage.

We've seen how to install and configure both Apache and Nginx web servers. We've also seen how to setup a web application using the LAMP and LEMP Stack. In this project, we will be using the LAMP Stack to deploy a WordPress application. However, the focus will be on using LVM for storing application data rather than the conventional hard disk. Some of the benefits of using LVM includes:

- **Dynamic Volume Resizing**: LVM allows for easy resizing of logical volumes, providing flexibility to adjust storage allocation without disrupting data or services.
- **Ease of Management**: LVM simplifies storage management tasks, such as adding or removing storage devices, reallocating space, and managing logical volumes.
- **Snapshot Support**: LVM supports the creation of snapshots, which are point-in-time copies of logical volumes. This is useful for backups or testing without affecting the original data.

The setup for this project includes a Laptop of PC to serve as a client, two (2) AWS EC2 instances, one to serve as the WebServer, and the Other, the Database server. We will also need to attach three (3) additional logical volumes to our sever to configure the LVM storage. Let's get right into it.

### Part 1a - Configuring LVM on the Web Server using AWS

1.  To begin we need to first provision two(2) EC2 Instances. One for our Web Server, and the other for the Database Server.
    ![Alt text](Images/Img_01.png)
    I'll be using the `Red Hat` Linux distribution in this project.

2.  The next step will be the creation of the volumes. In the left corner of your AWS console, click on the volumes menu under Elastic Block Store. Click on create volume and provide the information below:

    - `Volume type`: Select - General Purpose SSD (gp3)
    - `Size`: Select - 1Gib
    - `Availabilty Zone` - Select the AZ your Web Server was provisioned in. Mine is `eu-west-2c`.
    - `Tags` - Click on add tag ang give it a label. I will be labelling my `dio-webserver-lvm1`

    Click create, and repeat the same steps to create two(2) other volumnes.

        For the other options not specified above, feel free to use the default value.

    ![Alt text](Images/Img_02.png)
    Our volumes have been created, and they are currently in an available state. Meaning they are available, but not in use.

3.  Next, we will be attaching these volumes to our Web Server to configure LVM. To do this, click on the checkbok before the Name of the volumne to select it, then click on the Action dropdown menu above and select attach volume.
    ![Alt text](Images/Img_03.png)
    In the attach volume page, click on the Instance dropdown menu and select the `ID` of your Web Server instance and the attach. Repeat this step to add all the volumnes to the Web Server.
    ![Alt text](Images/Img_04.png)
    Note that if the Web Server was created in a different availablity zone from the volume, it won't be listed in the drop down list. So it is important the volumnes are created in the same AZ as the Instance.

        Once all volumes have been attached, the volumes state should change from available to In-use.

    ![Alt text](Images/Img_05.png)

    At this point, we've sucessfully created and attached three (3) volumes to our EC2 Instance.

4.  Having attached the volumes to our Web Server, we need to configure the Linux OS to use the newly attached volumes as they aren't automatically ready for use. There are several disk utitlity tools in Linux. We will be exploring few of them that would be needed for this project.

    Let's connect to our Web Server and explore these commands as well as confirgure the LVM.

    - `lsblk`: This tool is used to list block devices. A `Block device` in Linux is a type of device that stores or supports data in fixed-size blocks or sectors. Example, HDDs, SDDs, USB etc.
      ![Alt text](Images/Img_06.png)
      From the image above, we can see the newly attached volumes. The can be easly recognised based on the sizes.
    - `df -h`: This is used to display information about the disk usage and available space.
    - `gdisk`: A command-line utility for disk partitioning. It allows you to create, delete, and manage partitions on a disk. To use this tool, run `sudo gdisk /dev/xvdf`. The command will display some information and a prompt `Command (? for help)`. You can type ? and enter to see the available options.

      - Type `n`: This will instruct the tool to create a new partition. Hit the `enter` key to start from 1. Keep hitting the `enter` key to accept the default configurations until you see the `Command (? for help)` prompt again.
      - This time, type `w`: This will write the entries into the partition table.

        ![Alt text](Images/Img_07.png)

        `xvdf` is the name of our first volume as seen from the lsblk command. The other two (2) are `xvdg` and `xvdh`.

      Repeat the steps above for the other two (2) volumes. Run the `lsblk` command again and see the changes. New partitions have been created from the disk.

      ![Alt text](Images/Img_09.png)

    - `lvmdiskscan`: This command is used in Linux to scan for all available block devices and display information about them. It isn't installed by default in most Linux distributions so we have to first intall it before using it. To install in, run the command `sudo yum update && sudo yum install lvm2`.

      To use this tool, run `sudo lvmdiskcan`

      ![Alt text](Images/Img_08.png)

    - `pvcreate`: This command is used to initialize a physical volume for use with Logical Volume Management (LVM). LVM allows for dynamic volume management, such as creating logical volumes, resizing them, and managing storage resources efficiently. Let's use this tool by running the command below:

      `sudo pvcreate /dev/xvdf1`
      ![Alt text](Images/Img_10.png)
      Run this for the other two partitions, and then `sudo pvs` to verify the lvm partitions have been created successfully.
      ![Alt text](Images/Img_11.png)

    - `vgcreate`: This command is used to create or group volumes together. Run the code below to create a group called webdata-vg, and `sudo vgs` to verify it's been created.  
       `sudo vgcreate webdata-vg /dev/xvdg1 /dev/xvdh1 /dev/xvdf1`
      ![Alt text](Images/Img_12.png)
      From the image above, we can see the three (3) volumes have been grouped together and this also reflects the size.
    - `lvcreate`: This command is used to create logical volumes within a volume group managed by LVM. We will be creating two (2) logical volumes: `apps-lv` and `logs-lv`. The `apps-lv` would be used to store data for the WordPress site while the `logs-lv` would be used to store application log data. Run the commands below individually to create the lvs.  
       `sudo lvcreate -n apps-lv -L 1.4G webdata-vg`  
       `sudo lvcreate -n logs-lv -L 1.4G webdata-vg`

            - `-n` is used to indicate a new lv
            - `-L` is used to specify the size of the volume. Our `webdata-vg` has just 2.9GB so the lvs above were created with 1.4GB each.

      To verify, run `sudo lvs`. You can also run `sudo vgdisplay - v` to view all the information on the Logical and Physical volumes.
      ![Alt text](Images/Img_13.png)

      Run the `lsblk` command again to see how far we've gone in configuring our volumes.
      ![Alt text](Images/Img_14.png)

    - `mkfs`: The "make file system" command as the name suggests is used to create a file system on a specific block device. The commands below would format the logical volumes, and then create the `ext4` file system on the formated volumes.  
      `sudo mkfs -t ext4 /dev/webdata-vg/apps-lv`  
      `sudo mkfs -t ext4 /dev/webdata-vg/logss-lv`

5.  Now, lets create a directory and then mount the created directory to the file system. This directory would be where our WordPress site stores it's data.

    - Create the `/var/www/html` directory to store website files.  
      `sudo mkdir -p /var/www/html`

    - Create the `/home/recovery/logs` directory to store backup of log data  
      `sudo mkdir -p /home/recovery/logs`

    - Now, lets mount the `/var/www/html` directory to the `apps-lv`.  
      `sudo mount /dev/webdata-vg/apps-lv /var/www/html`
    - We will do the same for the `/home/recovery/logs` directory to `logs-lv`. However, we need to create a backup of the exiting files before mounting the directory. That's because all exiting data in the directory would be deleted before mounting. We will use the `rsync` to create the backup.  
      `sudo rsync -av /var/log/ /home/recovery/logs/`.
    - Now, we can safely mount the `/var/log` directory to the `logs-lv` volume as we have our files backedup.  
      `sudo mount /dev/webdata-vg/logs-lv /var/log`
    - Restore the log files from the backup by running the `rsync` again. This time, we are restoring from the back up location the the original location.  
      `sudo rsync -av /home/recovery/logs/ /var/log/`

6.  The next step will be to update the `/etc/fstab`. This file contains information about the disk drives and partitions on the system. It is used by the operating system to automatically mount these file systems at startup. We will be using the `UUID` of block devices to update this file. Run the `sudo blkid`command get the `UUID`. Copy and save the `UUID` for both the `webdata-vg/apps-lv` and `webdata-vg/logs-lv` to notepad or something as we will be referencing them in the `fstab` file.

    > ```bash
    > #Mounts for the WordPress Site
    >
    > UUID=c11927fc-9f64-432a-9f3d-913957e8ae3d /var/www/html ext4 defaults 0 0
    > UUID=e37111ba-8e5a-4285-a474-b25858eacb9b /var/log ext4 defaults 0 0
    >
    > ```

    Test the configuration by running `sudo mount -a` and `sudo systemctl daemon-reload`. if all goes well, the command will mount all the files system in the `fstab`, and instructs the system to mount all file systems in the file at every startup. If all was done correctly, you should see a similar file structure to the image below when you run the command `df -h`.
    ![Alt text](Images/Img_15.png)

### Part 1b - Installing Apache and WordPress. Confirguring the Web Server to utilise the LVM.

We've configured the storage for the Web Server, lets now install the Web Server and WordPress Site.

- We start by updating the repositories and installing Apache and it's dependencies by running the following commands:  
  `sudo yum update`  
  `sudo yum install wget httpd php php-mysqlnd php-fpm php-json`
- Start the Apapche server and enable the service to start automatically when the system reboots.  
   `sudo systemctl enable httpd`  
   `sudo systemctl start httpd`
  Note: In RedHat Linux distribution, the Apache Service is called httpd and not apache2 as we've seen in ubuntu
  ![Alt text](Images/Img_16.png)
- Now, let's install PhP and all the dependencies required for our our site.

  > ```bash
  > sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  > sudo yum install yum-utils http://rpms.remirepo.net/enterprise/remi-release-8.rpm
  > sudo yum module list php
  > sudo yum module reset php
  > sudo yum module enable php:remi-7.4
  > sudo yum install php php-opcache php-gd php-curl php-mysqlnd
  > sudo systemctl start php-fpm
  > sudo systemctl enable php-fpm
  > sudo setsebool -P httpd_execmem 1
  >
  > ```

  The `setsebool -P httpd_execmem 1` command allows the Apache HTTP Server (httpd) to execute memory, which might be necessary for certain web applications or configurations. Restart the `httpd` server for the newly installed package to be loaded by Apache.  
  `sudo systemctl restart httpd`.

- Next we download and intall WordPress. The WordPress would be installed in our mounted LVM storage location `/var/www/html`. Run the following commands.

  > ```bash
  > mkdir wordpress
  > cd   wordpress
  > sudo wget http://wordpress.org/latest.tar.gz
  > sudo tar xzvf latest.tar.gz
  > sudo rm -rf latest.tar.gz
  > sudo cp wordpress/wp-config-sample.php wordpress/wp-config.php
  > sudo cp -R wordpress /var/www/html/
  > ```
  >
  > From the image below, we can see our wordpress site in now saved in the mounted lvm drive. We can confirm also be comparing the Used and Avail space of the `webdata---vg-apps-lv`.

  ![Alt text](Images/Img_17.png)

- Configure the SELinux Polices  
  Security-Enhanced Linux (SELinux), distributions such as Red Hat, Fedora and CentOS are designed to enhance the overall security posture of the operating system by providing a powerful and flexible access control framework. The SELinux policies are defined security rules for how processes and users can interact with different system resources.  
   Run the commands below to configure the SELinux policies that will enable our site run without issues.
  > ```bash
  > # Change the owner of the /var/www/html/word directory to the user Apache and other users in the Apache group.
  > sudo chown -R apache:apache /var/www/html/wordpress
  >
  > # Modify the SELinux permission allowing our WebSite to read and write to cetain directories
  > sudo chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
  >
  > # Allowing the http server to make network connections
  > sudo setsebool -P httpd_can_network_connect=1
  > ```

### Part 2a - Configuring LVM on the Database Server using AWS

The steps here would be very similar to what we did in Part 1a of this project. I'll run the commands again without the explanation.

1.  Let's start by creating two volumes of size 3G each, and attach them to our DataBase Server EC2 Instance. Remember, the volumes must be created in the same AZ as the Database Server EC2 Instance.
    ![Alt text](Images/Img_18.png)
2.  Next, we attach the volumes to our Database Server, then ssh into the server to configure the LVM.
3.  In our Database Server, we can see the attached volumes by running the `lsblk` command.
    ![Alt text](Images/Img_19.png)
4.  Using `gdisk`, lets create our partitions.
5.  Install and use `lvmdiskscan` to see all block devices connected to the OS.
    ![Alt text](Images/Img_20.png)
    The partitions are showing just as we expected.
6.  Now, using `pvcreate`, initialise the partitions for LVM.  
     `sudo pvcreate /dev/xvdf1` and repeate the same for the second partition.
    ![Alt text](Images/Img_21.png)
7.  Using `vgcreate`, we will create a logical group from these volumes called `dbdata-vg`.  
     `sudo vgcreate dbdata-vg /dev/xvdf1 /dev/xvdg1`
    ![Alt text](Images/Img_22.png)
8.  Using `lgcreate`, we will be createing two (2) logical volumes from `dbdata-vg` just as we did in the Web Server. One to hold the database data, and the other ti hold the log files.  
     `sudo lvcreate -n data-lv -L 2.9G dbdata-vg`  
     `sudo lvcreate -n logs-lv -L 2.9G dbdata-vg`
    ![Alt text](Images/Img_23.png)
    Our LVM has been setup sucessfully and we have to logical drives, one for holding the database data, and the other for holding the log files.
9.  Now, lets format the drive using the `ext4` file system so we can mount our application directories to the drives.  
    For the data files, we will create a directory `/db` to store the data files, the the log files is still in the same location as used earlier. Remember to first backup the log files before mounting them to the drive.
10. Let's edit the `fstab` file using the `UUIDs` for our drivers. Remember, run the `sudo blkid` command to retreive the`UUIDs`. Add the entires below to your `/etc/fstab` file.

    > ```bash
    > #Mounts for the Database Server
    > UUID=8bd5f929-0b71-4e28-a63e-74f8db3c1fef       /home/db        ext4    defaults        0       0
    > UUID=cd0161e4-0311-4b3e-acf2-8df079a34e04       /var/log        ext4    defaults        0       0
    >
    > ```

        Save the file then run the command `sudo mount -a` and then `sudo systemctl deamon-reload`. Once done, run the `df -h` command to verify the setup.

    ![Alt text](Images/img_24.png)

### Part 2b - Installing the MySQL Server and confirgure the database to work with WordPress

1. We start with updating the repository and installing MySQL server.
   `sudo yum update && sudo yum install mysql-server`
2. Next, we start and enable the `msqld` service to start automatically when the system reboots.  
    `sudo systemctl enable mysqld`
   `sudo systemctl start mysqld`
   ![Alt text](Images/Img_25.png)
3. Next, we log into the database and create a new user granting the user create permissions. The newly created user would create the wordpress database.
   We first need to secure our databse by running the `msql_secure_instalation` script. I created the password `PassWord.1` for the root user. Now let's log in as the root user and the the execute the command. In the mysql console run the command below:

   > ```sql
   > CREATE USER 'wpuser'@'%' IDENTIFIED WITH mysql_native_password BY 'PassWord.1';
   > ```

   Next, we grant the newly created user `CREATE` rights.

   > ```sql
   > GRANT CREATE ON *.* TO 'wpuser'@'%';
   > ```

   Log out of the `mysql` console and relog back in using the newly created user's credentials. Create the database.

   > ```sql
   > CREATE DATABASE wordpress;
   > ```

Now, the database has been created sucessfully

### Connecting the WordPress Site to connect remotely to the Database Server

- First, we log into the the Web Server, install a mysql client sotware and then connect remotely to the database server.
- Connect remotely from the Web Server to the database server
  `mysql -u wpuser -p -h [Your-Public or Private ip for the DB Server]`

  ![Alt text](Images/Img_26.png)

  The screen shot above shows we've successfuly connected from the Web server to the mysql running on the Database Server. The `show databases;` command also lists the wordpress database created.  
   `Note. Ensure the port 3306 is enbaled in the security grouos for the DB Server.
`

- Now, let's configure the WordPress site. Open your browser and access the link `http://<Your-Web-Server-Public_IP/wordpress>.` You should get an error saying Unable to establish a database connection.
- To fix the error above, let's provide the database connection details to the wordpress configuration file.
  `sudo vim /var/www/html/wordpress/wp-config.php`  
   In the file, locate the settings below and provide the correct information for your database.

  > ```php
  > define('DB_NAME', 'wordpress');
  > define('DB_USER', 'wpuser');
  > define('DB_PASSWORD', 'PassWord.1');
  > define('DB_HOST', '172.31.3.145');
  > ```

  Save and reload the webpage for wordpress and you should be connected.
  ![Alt text](Images/Img_27.png)
