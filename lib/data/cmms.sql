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

CREATE TABLE worker_orders (
  id INT AUTO_INCREMENT PRIMARY KEY,
  worker_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  description TEXT,
  status ENUM('open', 'in progress', 'closed') NOT NULL,
  FOREIGN KEY (worker_id) REFERENCES worker(id)
);