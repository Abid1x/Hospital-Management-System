-- CS4400: Introduction to Database Systems: Monday, October 13, 2025
-- ER Management System Phase II Create Table Statements Key

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set session SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'er_hospital_management';
drop database if exists er_hospital_management;
create database if not exists er_hospital_management;
use er_hospital_management;

-- Defining the database tables

drop table if exists person;
create table person ( 
	ssn char(11) not null, 
    firstName varchar(100) not null, 
    lastName varchar(100) not null, 
    birthdate date not null, 
    address varchar(200) not null, 
    primary key (ssn)
) engine = innodb;

drop table if exists patient;
create table patient (
	ssn char(11) not null,
    funds integer not null,
    contact char(12) not null, 
    primary key (ssn),
    foreign key (ssn) references person (ssn) on update restrict on delete cascade
) engine = innodb;

drop table if exists staff;
create table staff (
	ssn char(11) not null,
	staffId integer not null,
    hireDate date not null,
    salary integer not null,
    primary key (ssn),
    unique key (staffId),
    foreign key (ssn) references person (ssn) on update restrict on delete cascade
) engine = innodb;

drop table if exists doctor;
create table doctor (
	ssn char(11) not null, 
    licenseNumber integer not null,
    experience integer not null,
    primary key (ssn), 
    unique key (licenseNumber),
    foreign key (ssn) references staff (ssn) on update restrict on delete cascade
) engine = innodb;

drop table if exists nurse;
create table nurse (
	ssn char(11) not null, 
    shiftType varchar(100) not null, 
    regExpiration date not null,
    primary key (ssn),
    foreign key (ssn) references staff (ssn) on update restrict on delete cascade
) engine = innodb;

drop table if exists department;
create table department (
	deptId integer not null, 
    longName varchar(100) not null, 
    manager char(11) not null, 
    primary key (deptId),
    foreign key (manager) references staff (ssn) on update restrict on delete restrict
) engine = innodb;

drop table if exists room;
create table room (
	roomNumber integer not null,
    roomType varchar(100) not null, 
    managingDept integer not null,
    occupiedBy char(11),
    primary key (roomNumber),
    foreign key (managingDept) references department (deptId) on update cascade on delete restrict,
    foreign key (occupiedBy) references patient (ssn) on update restrict on delete set null
) engine = innodb;

drop table if exists med_order;
create table med_order (
	orderNumber integer not null, 
    orderDate date not null, 
    priority integer not null, 
    patientId char(11) not null, 
    doctorId char(11) not null,
    cost integer not null,
    primary key (orderNumber),
    foreign key (patientId) references patient (ssn) on update restrict on delete cascade,
    foreign key (doctorId) references doctor (ssn) on update restrict on delete restrict
) engine = innodb;

drop table if exists prescription;
create table prescription (
	orderNumber integer not null,
    drug varchar(100) not null,
    dosage integer not null,
    primary key (orderNumber),
    foreign key (orderNumber) references med_order (orderNumber) on update cascade on delete cascade
) engine = innodb;

drop table if exists lab_work;
create table lab_work (
	orderNumber integer not null,
    labType varchar(100) not null,
    primary key (orderNumber),
    foreign key (orderNumber) references med_order (orderNumber) on update cascade on delete cascade
) engine = innodb;

drop table if exists appointment;
create table appointment (
	patientId char(11) not null,
    apptDate date not null,
    apptTime time not null,
    cost integer not null,
    primary key (patientId, apptDate, apptTime),
    foreign key (patientId) references patient (ssn) on update restrict on delete cascade
) engine = innodb;

drop table if exists symptom;
create table symptom (
	symptomType varchar(100) not null,
    numDays integer not null,
    patientId char(11) not null,
	apptDate date not null,
    apptTime time not null,
    primary key (symptomType,numDays, patientId, apptDate, apptTime),
    foreign key (patientId, apptDate, apptTime) references appointment (patientId, apptDate, apptTime) on update cascade on delete cascade
) engine = innodb;

drop table if exists room_assignment;
create table room_assignment (
	roomNumber integer not null,
    nurseId char(11) not null,
    primary key (roomNumber, nurseId),
    foreign key (roomNumber) references room (roomNumber) on update cascade on delete cascade,
    foreign key (nurseId) references nurse (ssn) on update cascade on delete cascade
) engine = innodb;

drop table if exists works_in;
create table works_in (
	staffSsn char(11) not null,
    deptId integer not null,
    primary key (staffSsn, deptId),
    foreign key (staffSsn) references staff (ssn) on update restrict on delete cascade,
    foreign key (deptId) references department(deptId) on update cascade on delete cascade
) engine = innodb;

drop table if exists appt_assignment;
create table appt_assignment (
	patientId char(11) not null,
    apptDate date not null,
    apptTime time not null,
    doctorId char(11) not null,
    primary key (patientId, apptDate, apptTime, doctorId),
    foreign key (patientId, apptDate, apptTime) references appointment (patientId, apptDate, apptTime) on update cascade on delete cascade,
    foreign key (doctorId) references doctor (ssn) on update restrict on delete cascade
) engine = innodb;
