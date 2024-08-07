create database cmms;
USE CMMS;

CREATE TABLE administrator (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(50) NOT NULL,
  password VARCHAR(50) NOT NULL
);

CREATE TABLE worker (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(50) NOT NULL,
  password VARCHAR(50) NOT NULL,
  image LONGBLOB,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(50) NOT NULL,
  ssn VARCHAR(20) NOT NULL
);

create table Client (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(50) NOT NULL,
  password VARCHAR(50) NOT NULL,
  image LONGBLOB,
  name VARCHAR(100) NOT NULL,
  role VARCHAR(50) NOT NULL,
  ssn VARCHAR(20) NOT NULL
);

CREATE TABLE asset (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  status ENUM('functional', 'needs checking', 'faulty') NOT NULL,
  image LONGBLOB
);

CREATE TABLE worker_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  worker_id INT NOT NULL,
  asset_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  description TEXT,
  status ENUM('open', 'in progress', 'closed') NOT NULL,
  images JSON,
  FOREIGN KEY (worker_id) REFERENCES worker(id) ON DELETE CASCADE,
  FOREIGN KEY (asset_id) REFERENCES asset(id) ON DELETE CASCADE
);
create table reports(
  id INT AUTO_INCREMENT PRIMARY KEY,
  worker_id INT NOT NULL,
  work_order_id int not null,
  Question1 VARCHAR(50) NOT NULL,
  Question2 VARCHAR(50) NOT NULL,
  Question3 VARCHAR(50) NOT NULL,
  Question4 VARCHAR(50) NOT NULL,
  Question5 VARCHAR(50) NOT NULL,
  Question6 VARCHAR(50) NOT NULL,
  pictures json,
  FOREIGN KEY (worker_id) REFERENCES worker(id) ON DELETE CASCADE,
  FOREIGN KEY (work_order_id) REFERENCES worker_orders(id) ON DELETE CASCADE
);

create table work_request(
id int auto_increment primary key,
client_id int not null,
site varchar(50) not null,
asset_id int not null,
date_of_fault date not null,
description varchar(50) not null,
foreign key (asset_id) references asset(id) on delete cascade,
foreign key (client_id) references client(id) on delete cascade
);

insert into administrator values(1, 'admin@discovery.com', '123');