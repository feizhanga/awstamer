-- [ec2-user ~]$ mysql -u root -p

CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY '3fb021214e6dcabcb6c104ba634aa1bc';
CREATE DATABASE `wordpressdb`;
GRANT ALL PRIVILEGES ON `wordpressdb`.* TO "wordpressuser"@"localhost";
FLUSH PRIVILEGES;
