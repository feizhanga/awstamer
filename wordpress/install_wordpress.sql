-- [ec2-user ~]$ mysql -u root -p

CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'what?';
CREATE DATABASE `wordpressdb`;
GRANT ALL PRIVILEGES ON `wordpressdb`.* TO "wordpressuser"@"localhost";
FLUSH PRIVILEGES;
