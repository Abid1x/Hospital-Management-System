-- CS4400: Introduction to Database Systems: Monday, October 13, 2025
-- ER Management System Stored Procedures & Views Template [1]

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set session SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'er_hospital_management';
use er_hospital_management;

-- -------------------
-- Views
-- -------------------

-- [1] room_wise_view()
-- -----------------------------------------------------------------------------
/* This view provides an overview of patient room assignments, including the patients' 
first and last names, room numbers, managing department names, assigned doctors' first and 
last names (through appointments), and nurses' first and last names (through room). 
It displays key relationships between patients, their assigned medical staff, and 
the departments overseeing their care. Note that there will be a row for each combination 
of assigned doctor and assigned nurse.*/
-- -----------------------------------------------------------------------------
create or replace view room_wise_view as
select 
	-- needed to have some aggregate function otherwise errors up the wazoo
    p.firstName AS patient_fname,
    p.lastName AS patient_lname,
    r.roomNumber AS room_num,
    d.longName AS department_name,
    dp.firstname as doctor_fname,
    dp.lastname as doctor_lname,
    np.firstname as nurse_fname,
    np.lastname as nurse_lname
from room r left join patient pat on
	pat.ssn=r.occupiedBy
left join person p on
	p.ssn=pat.ssn
left join department d on
	d.deptId=r.managingDept
left join appointment a on
	a.patientId=pat.ssn
left join appt_assignment aa on
	aa.patientId=a.patientId
    and aa.apptDate=a.apptDate
    and aa.apptTime=a.apptTime
left join doctor doc on
	doc.ssn=aa.doctorId
left join person dp on
	dp.ssn=doc.ssn
left join room_assignment ra on
	ra.roomNumber=r.roomNumber
left join nurse n on
	n.ssn=ra.nurseId
left join person np on
	np.ssn=n.ssn
where r.occupiedBy is not null;


-- [2] symptoms_overview_view()
-- -----------------------------------------------------------------------------
/* This view provides a comprehensive overview of patient appointments
along with recorded symptoms. Each row displays the patient's SSN, their full name 
(HINT: the CONCAT function can be useful here), the appointment time, appointment date, 
and a list of symptoms recorded during the appointment with each symptom separated by a 
comma and a space (HINT: the GROUP_CONCAT function can be useful here). */
-- -----------------------------------------------------------------------------
create or replace view symptoms_overview_view as
select 
	p.ssn as "Patient SSN",
	concat(p.firstName,' ' ,p.lastName) as "Patient Name",
    appt.apptDate as "Appointment Date",
    appt.apptTime as "Appointment Time",
	group_concat(s.symptomtype separator ', ') as Symptoms
from person p join patient pat
	on pat.ssn = p.ssn
join appointment appt
	on appt.patientId = pat.ssn 
join symptom s 
	on (appt.patientId = s.patientId and appt.apptTime = s.apptTime and appt.apptDate = s.apptDate) 
group by
	p.ssn,
    "Patient Name",
    appt.apptTime,
    appt.apptDate;

-- [3] medical_staff_view()
-- -----------------------------------------------------------------------------
/* This view displays information about medical staff. For every nurse and doctor, it displays
their ssn, their "staffType" being either "nurse" or "doctor", their "licenseInfo" being either
their licenseNumber or regExpiration, their "jobInfo" being either their shiftType or 
experience, a list of all departments they work in in alphabetical order separated by a
comma and a space (HINT: the GROUP_CONCAT function can be useful here), and their "numAssignments" 
being either the number of rooms they're assigned to or the number of appointments they're assigned to. */
-- -----------------------------------------------------------------------------
create or replace view medical_staff_view as
with
	q1 as (
		select s.ssn from staff s
        where s.ssn in (select ssn from doctor)
        or s.ssn in (select ssn from nurse)
	),
    q2 as (
        select q1.ssn, group_concat(distinct department.longName order by department.longName separator ', ') as depts
        from q1 join works_in wi on
        q1.ssn = wi.staffSsn join department on
        wi.deptId = department.deptId group by q1.ssn
    ),
    q3 as (
		-- nurse
		select n.ssn,
        'nurse' as staffType,
        n.regExpiration as licenseInfo,
        n.shiftType as jobInfo,
        q2.depts
        from nurse n join q2
        on q2.ssn=n.ssn
        
        union all
        
        -- doctor
        select d.ssn,
        'doctor' as staffType,
        d.licenseNumber as licenseInfo,
        d.experience as jobInfo,
        q2.depts from doctor d join q2
        on q2.ssn=d.ssn
    )
    
    select ssn as staffSsn, staffType, licenseInfo, jobInfo, depts as deptNames,
    case
		when staffType='nurse' then (
			select count(*) from
            room_assignment ra where
            ra.nurseId=q3.ssn
		) else (
			select count(*) from
            appt_assignment aa where
            aa.doctorId=q3.ssn
		) end as numAssignments
	from q3;
    


-- [4] department_view()
-- -----------------------------------------------------------------------------
/* This view displays information about every department in the hospital. The information
displayed should be the department's long name, number of total staff members, the number of 
doctors in the department, and the number of nurses in the department. If a department does not 
have any doctors/nurses/staff members, ensure the output for those columns is zero, not null */
-- -----------------------------------------------------------------------------
create or replace view department_view as
select
	longName,
	count(distinct staffSsn) as total_staff_members,
	count(case
		when wk.staffSsn in (select ssn from doctor) then 1
	end) as count_doc,
	count(case
		when wk.staffSsn in (select ssn from nurse) then 1
	end) as count_nurse
from department d join works_in wk
	on wk.deptId = d.deptId
group by longName;


-- [5] outstanding_charges_view()
-- -----------------------------------------------------------------------------
/* This view displays the outstanding charges for the patients in the hospital. 
"Outstanding charges" is the sum of appointment costs and order costs. It also 
displays a patient's first name, last name, SSN, funds, number of appointments, 
and number of orders. Ensure there are no null values if there are no charges, 
appointments, orders for a patient (HINT: the IFNULL or COALESCE functions can be 
useful here).  */
-- -----------------------------------------------------------------------------
create or replace view outstanding_charges_view as
select
	per.firstName,
    per.lastName,
    p.ssn,
    p.funds,
	(case
		when a.totalApptCost is null then 0 else a.totalApptCost
	end + 
	case
		when m.totalOrderCost is null then 0 else m.totalOrderCost
	end) as outstandingCharges,
	case
		when a.numAppointments is null then 0 else a.numAppointments
	end as numAppointments,
	case
		when m.numOrders is null then 0 else m.numOrders
	end as numOrders
from patient p
join person per
	on p.ssn = per.ssn
left join (
        select patientId, 
        count(*) as numAppointments, 
        sum(cost) as totalApptCost
        from appointment
        group by patientId
) a
	on p.ssn = a.patientId
left join (
        select patientId, 
        count(*) as numOrders, 
        sum(cost) as totalOrderCost
        from med_order
        group by patientId
) m
	on p.ssn = m.patientId;


-- -------------------
-- Stored Procedures
-- -------------------

-- [6] add_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new patient. If the new patient does 
not exist in the person table, then add them prior to adding the patient. 
Ensure that all input parameters are non-null, and that a patient with the given 
SSN does not already exist. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_patient;
delimiter //
create procedure add_patient (
	in ip_ssn varchar(40),
    in ip_first_name varchar(100),
    in ip_last_name varchar(100),
    in ip_birthdate date,
    in ip_address varchar(200), 
    in ip_funds integer,
    in ip_contact char(12)
)
sp_main: begin
	-- checks
	if ip_ssn is null or
		ip_first_name is null or
        ip_last_name is null or
        ip_birthdate is null or
        ip_birthdate>curdate() or	-- unborn babies dont need patient records yet
        ip_address is null or
        ip_funds is null or
        ip_funds<0 or				-- negative funds is a nono i would think? need to check
        ip_contact is null then
		leave sp_main;
	end if;

	-- check that this ssn doesn't already exist
    if ip_ssn in
		(select ssn from patient) then
		leave sp_main;
    end if;

	-- if not already in the person table then add record
    if ip_ssn not in
		(select ssn from person) then
		insert into person (firstName, lastName, address, birthdate, ssn)
        values (ip_first_name, ip_last_name, ip_address, ip_birthdate, ip_ssn);
    end if;

	-- add to patient table
    insert into patient (ssn, contact, funds)
    values (ip_ssn, ip_contact, ip_funds);

end //
delimiter ;

-- [7] record_symptom()
-- -----------------------------------------------------------------------------
/* This stored procedure records a new symptom for a patient. Ensure that all input 
parameters are non-null, and that the referenced appointment exists for the given 
patient, date, and time. Ensure that the same symptom is not already recorded for 
that exact appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists record_symptom;
delimiter //
create procedure record_symptom (
	in ip_patientId varchar(40),
    in ip_numDays int,
    in ip_apptDate date,
    in ip_apptTime time,
    in ip_symptomType varchar(100)
)
sp_main: begin
	-- checks
	if ip_patientId is null or
		ip_numDays is null or
        ip_apptDate is null or
        ip_apptDate>curdate() or	-- how would we have symptoms before the patient is seen
        ip_apptTime is null or
        ip_symptomType is null then
        leave sp_main;
    end if;
	
    -- ensured referenced appointment exists
	if not exists (
        select 1 from appointment where 
        (patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime)) then
        leave sp_main;
    end if;

	-- ensure this symptom for this appointment doesn't already exist
	if exists (
        select 1 from symptom where 
        (symptomType = ip_symptomType and
        patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime)) then
        leave sp_main;
    end if;

    insert into symptom (symptomType, numDays, patientId, apptDate, apptTime)
    values (ip_symptomType, ip_numDays, ip_patientId, ip_apptDate, ip_apptTime);

end //
delimiter ;

-- [8] book_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure books a new appointment for a patient at a specific time and date.
The appointment date/time must be in the future (the CURDATE() and CURTIME() functions will
be helpful). The patient must not have any conflicting appointments and must have the funds
to book it on top of any outstanding costs. Each call to this stored procedure must add the 
relevant data to the appointment table if conditions are met. Ensure that all input parameters 
are non-null and reference an existing patient, and that the cost provided is non-negative. 
Do not charge the patient, but ensure that they have enough funds to cover their current outstanding 
charges and the cost of this appointment.
HINT: You should complete outstanding_charges_view before this procedure! */
-- -----------------------------------------------------------------------------
drop procedure if exists book_appointment;
delimiter //
create procedure book_appointment (
	in ip_patientId char(11),
	in ip_apptDate date,
    in ip_apptTime time,
	in ip_apptCost integer
)
sp_main: begin
	declare patient_funds int;
    declare ost_charges int;
    
    -- checks
	if ip_patientId is null or
		ip_apptDate is null or
        ip_apptTime is null or
        ip_apptDate<curdate() or		-- v
        (ip_apptDate=curdate() and	-- cant book an appointment in the past
		ip_apptTime<=curtime()) or	-- ^
        ip_apptCost is null or
        ip_apptCost<0 then
        leave sp_main;
    end if;
    
    -- not referencing an existing patient
    if ip_patientId not in
		(select ssn from patient) then
		leave sp_main;
	end if;
    
    -- no conflicting appointments
    if ip_patientId in 
		(select patientId from appointment where
		apptDate = ip_apptDate and
        apptTime = ip_apptTime) then
		leave sp_main;
	end if;
    
    select funds into patient_funds from patient where ssn = ip_patientId;
    
    select outstandingCharges into ost_charges
    from outstanding_charges_view where ssn = ip_patientId;
    
    -- healthcare should be free
    if (ost_charges + ip_apptCost) > patient_funds then
        leave sp_main; 
	end if;
    
    -- add record for the new appointment
    insert into appointment(patientId, apptDate, apptTime, cost)
    values (ip_patientId, ip_apptDate, ip_apptTime, ip_apptCost);

end //
delimiter ;

-- [9] place_order()
-- -----------------------------------------------------------------------------
/* This stored procedures places a new order for a patient as ordered by their
doctor. The patient must also have enough funds to cover the cost of the order on 
top of any outstanding costs. Each call to this stored procedure will represent 
either a prescription or a lab report, and the relevant data should be added to the 
corresponding table. Ensure that the order-specific, patient-specific, and doctor-specific 
input parameters are non-null, and that either all the labwork specific input parameters are 
non-null OR all the prescription-specific input parameters are non-null (i.e. if ip_labType 
is non-null, ip_drug and ip_dosage should both be null).
Ensure the inputs reference an existing patient and doctor. 
Ensure that the order number is unique for all orders and positive. Ensure that a cost 
is provided and non-negative. Do not charge the patient, but ensure that they have 
enough funds to cover their current outstanding charges and the cost of this appointment. 
Ensure that the priority is within the valid range. If the order is a prescription, ensure 
the dosage is positive. Ensure that the order is never recorded as both a lab work and a prescription.
The order date inserted should be the current date, and the previous procedure lists a function that
will be required to use in this procedure as well.
HINT: You should complete outstanding_charges_view before this procedure! */
-- -----------------------------------------------------------------------------
drop procedure if exists place_order;
delimiter //
create procedure place_order (
	in ip_orderNumber int, 
	in ip_priority int,
    in ip_patientId char(11), 
	in ip_doctorId char(11),
    in ip_cost integer,
    in ip_labType varchar(100),
    in ip_drug varchar(100),
    in ip_dosage int
)
sp_main: begin
	declare patient_funds int;
    declare ost_charges int;
    
    if ip_orderNumber is null or
		ip_priority is null or
        ip_patientId is null or
        ip_doctorId is null or
        ip_cost is null or
        ip_cost<0 then
		leave sp_main;
    end if;
    
    select funds into patient_funds from patient where ssn = ip_patientid;
    
    select outstandingCharges into ost_charges from outstanding_charges_view where ssn = ip_patientId;
    
    if ost_charges is null then
		set ost_charges = 0;
	end if;
    
    if ip_labType is not null and
		(ip_drug is not null or
        ip_dosage is not null) then
		leave sp_main;
	end if;
    
    if ip_labType is null and
		(ip_drug is null or
        ip_dosage is null) then
		leave sp_main;
	end if;
    
    if ip_patientId not in (select ssn from patient) or
        ip_doctorId not in (select ssn from doctor) then
        leave sp_main;
    end if;
    
    if ip_orderNumber <= 0 or
		ip_orderNumber in (select orderNumber from med_order) then
		leave sp_main;
	end if;
    if patient_funds < (ost_charges + ip_cost) then
		leave sp_main;
    end if;
    if ip_priority < 1 or ip_priority > 5 then
        leave sp_main;
    end if;
    
    if ip_dosage is not null and
		ip_dosage <= 0 then
		leave sp_main;
    end if;
    
    insert into med_order(orderNumber, orderDate, priority, patientId, doctorId, cost)
    values (ip_orderNumber, curdate(), ip_priority, ip_patientId, ip_doctorId, ip_cost);
    
    if ip_labType is not null then
        insert into lab_work(orderNumber, labType)
        values (ip_orderNumber, ip_labType);
    else
        insert into prescription(orderNumber, drug, dosage)
        values (ip_orderNumber, ip_drug, ip_dosage);
    end if;

end //
delimiter ;

-- [10] add_staff_to_dept()
-- -----------------------------------------------------------------------------
/* This stored procedure adds a staff member to a department. If they are already
a staff member and not a manager for a different department, they can be assigned
to this new department. If they are not yet a staff member or person, they can be 
assigned to this new department and all other necessary information should be 
added to the database. Ensure that all input parameters are non-null and that the 
Department ID references an existing department. Ensure that the staff member is 
not already assigned to the department. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_staff_to_dept;
delimiter //
create procedure add_staff_to_dept (
	in ip_deptId integer,
    in ip_ssn char(11),
    in ip_firstName varchar(100),
	in ip_lastName varchar(100),
    in ip_birthdate date,
    in ip_startdate date,
    in ip_address varchar(200),
    in ip_staffId integer,
    in ip_salary integer
)
sp_main: begin
	-- checks
	if ip_deptId is null 
        or ip_ssn is null 
        or ip_firstName is null 
        or ip_lastName is null
        or ip_birthdate is null
        or ip_birthdate>curdate()	-- unborn babies dont need records
        or ip_startdate is null
        or ip_startdate>curdate()	-- future staff dont need to be in the db me thinks but idk
        or ip_address is null
        or ip_staffId is null
        or ip_staffId<=0
        or ip_salary is null 
        or ip_salary<0 then
        leave sp_main;
    end if;
    
    -- make sure this is a real department
    if ip_deptId not in
		(select deptId from department) then
        leave sp_main;
	end if;
    
    -- check if staff is already in the department
    if ip_ssn in
		(select staffSsn from works_in where deptId=ip_deptId) then
        leave sp_main;
	end if;
    
    -- if already a staff member then make sure they're not a manager for a diff department
    if ip_ssn in
		(select manager from department) then
        leave sp_main;
	end if;
    
    -- if not already staff then add records for them
    if ip_ssn not in
		(select ssn from staff) then
        -- if not already person then add records
        if ip_ssn not in
			(select ssn from person) then
			insert into person(ssn, firstName, lastName, birthdate, address) values (ip_ssn, ip_firstName, ip_lastName, ip_birthdate, ip_address);
		end if;
        
        insert into staff(ssn, staffId, hireDate, salary) values (ip_ssn, ip_staffId, ip_startdate, ip_salary);
	else
		if ip_ssn in
			(select staffSsn from works_in) then
			delete from works_in where staffSsn=ip_ssn;
		end if;
	end if;
    
    insert into works_in(staffSsn, deptId) values (ip_ssn, ip_deptId);
end //
delimiter ;

-- [11] add_funds()
-- -----------------------------------------------------------------------------
/* This stored procedure adds funds to an existing patient. The amount of funds
added must be positive. Ensure that all input parameters are non-null and reference 
an existing patient. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_funds;
delimiter //
create procedure add_funds (
	in ip_ssn char(11),
    in ip_funds integer
)
sp_main: begin
if ip_ssn is null or ip_funds is null
then 
leave sp_main;
end if;

 if ip_ssn not in (select ssn from patient) then
        leave sp_main;
    end if;

if ip_funds < 1 then 
leave sp_main;
end if;

update patient set funds = ip_funds + funds where ssn = ip_ssn;


end //
delimiter ;


-- [12] assign_nurse_to_room()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a nurse to a room. In order to ensure they
are not over-booked, a nurse cannot be assigned to more than 4 rooms. Ensure that 
all input parameters are non-null and reference an existing nurse and room. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_nurse_to_room;
delimiter //
create procedure assign_nurse_to_room (
	in ip_nurseId char(11),
    in ip_roomNumber integer
)
sp_main: begin
	if ip_nurseId is null or ip_roomNumber is null or
    ip_nurseId<=0 or ip_roomNumber<=0
then 
leave sp_main;
end if;

if ip_nurseId not in (select ssn from nurse) then 
leave sp_main;
end if;

if ip_roomNumber not in (select roomNumber from room) then 
leave sp_main;
end if; 

if 
(select count(roomNumber) from room_assignment where ip_nurseId = nurseId group by nurseId) > 3 then
leave sp_main;
end if;

insert into room_assignment (roomNumber, nurseId) values (ip_roomNumber, ip_nurseId);

end //
delimiter ;

-- [13] assign_room_to_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a room to a patient. The room must currently be
unoccupied. If the patient is currently assigned to a different room, they should 
be removed from that room. To ensure that the patient is placed in the correct type 
of room, we must also confirm that the provided room type matches that of the 
provided room number. Ensure that all input parameters are non-null and reference 
an existing patient and room. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_room_to_patient;
delimiter //
create procedure assign_room_to_patient (
    in ip_ssn char(11),
    in ip_roomNumber int,
    in ip_roomType varchar(100)
)
sp_main: begin
    -- code here
    if ip_ssn is null or ip_roomNumber is null or ip_roomType is null or ip_roomNumber<=0
    then
    leave sp_main;
    end if;
    
    
    if ip_ssn not in (select ssn from patient) then
        leave sp_main;
    end if;
    
    if ip_roomNumber not in (select roomNumber from room) then
        leave sp_main;
		end if;
        
	if ip_roomType != (select roomType from room where roomNumber = ip_roomNumber) then
    leave sp_main;
	end if;
    
    if (select occupiedBy from room where roomNumber = ip_roomNumber) is not null then
        leave sp_main;
    end if;
    
    if ip_ssn in (select occupiedBy from room) then
    update room set occupiedBy = null where occupiedBy = ip_ssn;
    end if;
    
    update room set occupiedBy = ip_ssn where roomNumber = ip_roomNumber;

end //
delimiter ;

-- [14] assign_doctor_to_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a doctor to an existing appointment. Ensure that no
more than 3 doctors are assigned to an appointment, and that the doctor does not
have commitments to other patients at the exact appointment time. Ensure that all input 
parameters are non-null and reference an existing doctor and appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_doctor_to_appointment;
delimiter //
create procedure assign_doctor_to_appointment (
	in ip_patientId char(11),
    in ip_apptDate date,
    in ip_apptTime time,
    in ip_doctorId char(11)
)
sp_main: begin
	-- null checks
	if ip_patientId is null or
		ip_apptDate is null or
        ip_apptTime is null or
        ip_doctorId is null then
        leave sp_main;
    end if;
    
    -- check for existing doctors
    if not exists
		(select 1 from doctor where
        ssn = ip_doctorId) then
        leave sp_main;
    end if;
    
    -- check for pre-existing appointment
    if not exists
		(select 1 from appointment where
        patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime) then
        leave sp_main;
    end if;
    
    -- make sure doc isn't already occupied at this time
    if exists (
        select 1 from appt_assignment aa
        join appointment a on
        aa.patientId = a.patientId and
        aa.apptDate = a.apptDate and
        aa.apptTime = a.apptTime where
        aa.doctorId = ip_doctorId and
        a.apptDate = ip_apptDate and
        a.apptTime = ip_apptTime) then
        leave sp_main;
    end if;
    
    -- make sure there aren't already 3 docs
    if (
        select count(*) from appt_assignment where
        patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime) >= 3 then
        leave sp_main;
    end if;
    
    -- make sure doc already isn't on this appointment
    if exists (
        select 1 from appt_assignment where
        patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime and
        doctorId = ip_doctorId) then
        leave sp_main;
    end if;
    
    insert into appt_assignment (patientId, apptDate, apptTime, doctorId)
    values (ip_patientId, ip_apptDate, ip_apptTime, ip_doctorId);
end //
delimiter ;

-- [15] manage_department()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a staff member as the manager of a department.
The staff member cannot currently be the manager for any departments. They
should be removed from working in any departments except the given
department (make sure the staff member is not the sole employee for any of these 
other departments, as they cannot leave and be a manager for another department otherwise),
for which they should be set as its manager. Ensure that all input parameters are non-null 
and reference an existing staff member and department.
*/
-- -----------------------------------------------------------------------------
drop procedure if exists manage_department;
delimiter //
create procedure manage_department (
	in ip_ssn char(11),
    in ip_deptId int
)
sp_main: begin
	declare employee_count int; -- how many employees in the staff members old department

	-- null checks
	if ip_ssn is null 
        or ip_deptId is null then
        leave sp_main;
    end if;
    
    -- check if this is an existing staff
    if ip_ssn not in
		(select ssn from staff) then
        leave sp_main;
	end if;
    
    -- check if this is an existing dept
    if ip_deptId not in
		(select deptId from department) then
        leave sp_main;
	end if;
    
    -- cant be manager for any department
    if ip_ssn in
		(select manager from department) then
        leave sp_main;
	end if;
    
    -- provided they are not the sole employee of a dept, they should be removed
    if ip_ssn in 
		(select staffSsn from works_in where deptId in 
        (select deptId from works_in group by deptId having COUNT(*) = 1)) then 
        leave sp_main;
    else
		delete from works_in where staffSsn = ip_ssn;
        insert into works_in (staffSsn,deptId) values (ip_ssn,ip_deptId);
        update department set manager = ip_ssn where deptId = ip_deptId;
	end if;
end //
delimiter ;

-- [16] release_room()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a patient from a given room. Ensure that 
the input room number is non-null and references an existing room.  */
-- -----------------------------------------------------------------------------
drop procedure if exists release_room;
delimiter //
create procedure release_room (
    in ip_roomNumber int
)
sp_main: begin
	if ip_roomNumber is null then
    leave sp_main;
    end if;
    
    if not exists ( select 1 from room
	where roomNumber = ip_roomNumber) then
	leave sp_main;
    end if;
    
    update room set occupiedBy = null where ip_roomNumber = roomNumber;

end //
delimiter ;

-- [17] remove_patient()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a given patient. If the patient has any pending
orders or remaining appointments (regardless of time), they cannot be removed.
If the patient is not a staff member, they then must be completely removed from 
the database. Ensure all data relevant to this patient is removed. Ensure that the 
input SSN is non-null and references an existing patient. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_patient;
delimiter //
create procedure remove_patient (
	in ip_ssn char(11)
)
sp_main: begin
	-- null checks
	if ip_ssn is null then
		leave sp_main;
	end if;

    if not exists (select ssn from patient where ssn=ip_ssn) then
		leave sp_main;
	end if;
    
    if exists (select patientId from med_order where patientId=ip_ssn) or exists (select patientId from appointment where patientId=ip_ssn) then
		leave sp_main;
	end if;
    delete from patient where ssn=ip_ssn;
	if not exists (select ssn from staff where ssn=ip_ssn) then
		delete from person where ssn=ip_ssn;
	end if;
    
end //
delimiter ;

-- remove_staff()
-- Lucky you, we provided this stored procedure to you because it was more complex
-- than we would expect you to implement. You will need to call this procedure
-- in the next procedure!
-- -----------------------------------------------------------------------------
/* This stored procedure removes a given staff member. If the staff member is a 
manager, they are not removed. If the staff member is a nurse, all rooms
they are assigned to have a remaining nurse if they are to be removed. 
If the staff member is a doctor, all appointments they are assigned to have
a remaining doctor and they have no pending orders if they are to be removed.
If the staff member is not a patient, then they are completely removed from 
the database. All data relevant to this staff member is removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_staff;
delimiter //
create procedure remove_staff (
	in ip_ssn char(11)
)
sp_main: begin
	-- ensure parameters are not null
    if ip_ssn is null then
		leave sp_main;
	end if;
    
	-- ensure staff member exists
	if not exists (select ssn from staff where ssn = ip_ssn) then
		leave sp_main;
	end if;
	
    -- if staff member is a nurse
    if exists (select ssn from nurse where ssn = ip_ssn) then
	if exists (
		select 1
		from (
			 -- Get all rooms assigned to the nurse
			 select roomNumber
			 from room_assignment
			 where nurseId = ip_ssn
		) as my_rooms
		where not exists (
			 -- Check if there is any other nurse assigned to that room
			 select 1
			 from room_assignment 
			 where roomNumber = my_rooms.roomNumber
			   and nurseId <> ip_ssn
		)
	)
	then
		leave sp_main;
	end if;
		
        -- remove this nurse from room_assignment and nurse tables
		delete from room_assignment where nurseId = ip_ssn;
		delete from nurse where ssn = ip_ssn;
	end if;
	
    -- if staff member is a doctor
	if exists (select ssn from doctor where ssn = ip_ssn) then
		-- ensure the doctor does not have any pending orders
		if exists (select * from med_order where doctorId = ip_ssn) then 
			leave sp_main;
		end if;
		
		-- ensure all appointments assigned to this doctor have remaining doctors assigned
		if exists (
		select 1
		from (
			 -- Get all appointments assigned to ip_ssn
			 select patientId, apptDate, apptTime
			 from appt_assignment
			 where doctorId = ip_ssn
		) as ip_appointments
		where not exists (
			 -- For the same appointment, check if there is any other doctor assigned
			 select 1
			 from appt_assignment 
			 where patientId = ip_appointments.patientId
			   and apptDate = ip_appointments.apptDate
			   and apptTime = ip_appointments.apptTime
			   and doctorId <> ip_ssn
		)
	)
	then
		leave sp_main;
	end if;
        
		-- remove this doctor from appt_assignment and doctor tables
		delete from appt_assignment where doctorId = ip_ssn;
		delete from doctor where ssn = ip_ssn;
	end if;
    
    -- remove staff member from works_in and staff tables
    delete from works_in where staffSsn = ip_ssn;
    delete from staff where ssn = ip_ssn;

	-- ensure staff member is not a patient
	if exists (select * from patient where ssn = ip_ssn) then 
		leave sp_main;
	end if;
    
    -- remove staff member from person table
	delete from person where ssn = ip_ssn;
end //
delimiter ;

-- [18] remove_staff_from_dept()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a staff member from a department. If the staff
member is the manager of that department, they cannot be removed. If the staff
member, after removal, is no longer working for any departments, they should then 
also be removed as a staff member, following all logic in the remove_staff procedure. 
Ensure that all input parameters are non-null and that the given person works for
the given department. Ensure that the department will have at least one staff member 
remaining after this staff member is removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists remove_staff_from_dept;
delimiter //
create procedure remove_staff_from_dept (
	in ip_ssn char(11),
    in ip_deptId integer
)
sp_main: begin
	if ip_ssn is null or ip_deptId is null then
		leave sp_main;
    end if;
    
    if (select count(*) from department where manager = ip_ssn and deptId = ip_deptId)=1 then
		leave sp_main;
    end if;
    
    delete from works_in where staffSsn = ip_ssn and deptId = ip_deptId;
    
    if (select count(*) from works_in where ip_ssn = staffSsn) = 1 then
		call remove_staff(ip_ssn);
    end if;

end //
delimiter ;

-- [19] complete_appointment()
-- -----------------------------------------------------------------------------
/* This stored procedure completes an appointment given its date, time, and patient SSN.
The completed appointment and any related information should be removed 
from the system, and the patient should be charged accordingly. Ensure that all 
input parameters are non-null and that they reference an existing appointment. */
-- -----------------------------------------------------------------------------
drop procedure if exists complete_appointment;
delimiter //
create procedure complete_appointment (
	in ip_patientId char(11),
    in ip_apptDate DATE, 
    in ip_apptTime TIME
)
sp_main: begin
	declare apptCost int;

	-- null checks
	if ip_patientId is null or
		ip_apptDate is null or
        ip_apptTime is null then
        leave sp_main;
	end if;
    
    -- do parameters reference an existing appointment
    if (select count(*)	from appointment where
		patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime) = 0 then
		leave sp_main;
	end if;
    
    -- charge patient appointment cost
    select cost into apptCost from appointment where
		patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime;
	
    update patient set funds = funds-apptCost where ssn=ip_patientId;
    
    -- remove related data
    delete from symptom where
		patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime;
	delete from appointment where
		patientId = ip_patientId and
        apptDate = ip_apptDate and
        apptTime = ip_apptTime;
    
end //
delimiter ;

-- [20] complete_orders()
-- -----------------------------------------------------------------------------
/* This stored procedure attempts to complete a certain number of orders based on the 
passed in value. Orders should be completed in order of their priority, from highest to
lowest. If multiple orders have the same priority, the older dated one should be 
completed first. Any completed orders should be removed from the system, and patients 
should be charged accordingly. Ensure that there is a non-null number of orders
passed in, and complete as many as possible up to that limit. */
-- -----------------------------------------------------------------------------
drop procedure if exists complete_orders;
delimiter //
create procedure complete_orders (
	in ip_num_orders integer
)
sp_main: begin
	declare counter int;
    declare order_num int;
    declare patient_num char(11);
	
	if ip_num_orders is null then
		leave sp_main;
    end if;
    
    if (select count(*) from med_order) > ip_num_orders then
		set counter = ip_num_orders;
	else
		select count(*) into counter from med_order;
	end if;
    
    while counter != 0 do
		select orderNumber, patientId into order_num, patient_num from med_order order by priority desc, orderDate asc limit 1;
        
        update patient set funds = funds - (select cost from med_order where orderNumber = order_num) where ssn = patient_num;
        
        delete from med_order where orderNumber = order_num;
		set counter = counter - 1;
	end while;
end //
delimiter ;
