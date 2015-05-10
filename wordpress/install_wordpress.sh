Step1: Install and configure LAMP

Step2: install wordpress
    [ec2-user ~]$ wget https://wordpress.org/latest.tar.gz
    [ec2-user ~]$ tar -xzf latest.tar.gz
    [ec2-user ~]$ sudo service mysqld start
    [ec2-user ~]$ mysql -u root -p

Step3 configure 
    [ec2-user ~]$ cd wordpress/
    [ec2-user wordpress]$ cp wp-config-sample.php wp-config.php
    [ec2-user wordpress]$ nano wp-config.php
    [ec2-user wordpress]$ mv * /var/www/html/
    [ec2-user wordpress]$ mkdir /var/www/html/blog
    [ec2-user wordpress]$ mv * /var/www/html/blog
    [ec2-user wordpress]$ sudo usermod -a -G www apache
    [ec2-user wordpress]$ sudo chown -R apache /var/www
    [ec2-user wordpress]$ sudo chgrp -R www /var/www
    [ec2-user wordpress]$ sudo chmod 2775 /var/www
    [ec2-user wordpress]$ find /var/www -type d -exec sudo chmod 2775 {} +
    [ec2-user wordpress]$ find /var/www -type f -exec sudo chmod 0664 {} +
    [ec2-user wordpress]$ sudo service httpd restart
    [ec2-user wordpress]$ sudo chkconfig httpd on
    [ec2-user wordpress]$ sudo chkconfig mysqld on
    [ec2-user wordpress]$ sudo service mysqld status
    [ec2-user wordpress]$ sudo service mysqld start
    [ec2-user wordpress]$ sudo service httpd status
    [ec2-user wordpress]$ sudo service httpd start
