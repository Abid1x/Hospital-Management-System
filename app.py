
from flask import Flask, request, render_template
import pymysql
from config import CONFIG 

app = Flask(__name__)




def get_db():
    return pymysql.connect(
        host=CONFIG["host"],
        user=CONFIG["user"],
        password=CONFIG["password"],
        database=CONFIG["database"],
        cursorclass=pymysql.cursors.DictCursor
    )
@app.route("/dashboard")
def buttons():
    return render_template("dashboard.html")





@app.route("/add_funds/form")
def add_funds_form():
    return render_template("add_funds.html")


@app.route("/add_funds/submit", methods=["POST"])
def add_funds_place():
    patient_id = request.form.get("patient_id")
    amount = request.form.get("amount")


    return add_funds(patient_id, amount)


def add_funds(patient_id, amount):

    amount = None if amount == "null" else float(amount)


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("add_funds", [patient_id, amount])
    
    db.commit() 
    db.close()  
    return {"status": "Funds Added Successfully"}  



@app.route("/manage_department/form")
def manage_department_form():
    return render_template("manage_department.html")


@app.route("/manage_department/submit", methods=["POST"])
def manage_department():

    patient_ssn = request.form.get("patient_ssn")
    dept_id = request.form.get("dept_id")

    print(f"Received patient_ssn: {patient_ssn}, dept_id: {dept_id}")

    # Validate inputs
    if not patient_ssn or not dept_id:
        return {"status": "Error", "message": "Both SSN and Department ID are required."}


    db = get_db()
    with db.cursor() as cur:
        
     
        cur.callproc("manage_department", [patient_ssn, dept_id])
        db.commit() 
        return {"status": "Success", "message": "Department management updated successfully!"}
        
       
    db.close()
            
            


@app.route("/place_order/form")
def form_name_form():
    return render_template("place_order.html")


@app.route("/place_order/submit", methods=["POST"])
def form_name_submit():
   
    order_num = request.form.get("ordernum")
    priority = request.form.get("priority")
    patient_id= request.form.get("pid")
    doc_id = request.form.get("docid")
    cost = request.form.get("cost")
    lab = request.form.get("lab")
    drug = request.form.get("drug")
    dosage = request.form.get("dosage")
    
   
    
   
    if not order_num or not priority or not patient_id or not doc_id or not cost or not lab or not drug or not dosage:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
   
        cur.callproc("place_order", [order_num, priority, patient_id, doc_id, cost, lab, drug, dosage])  
        db.commit()  
        db.close() 
        
    return {"message": "Operation Executed Successfully."}



@app.route("/add_patient/form")
def add_patient_form():
    return render_template("add_patient.html")


@app.route("/add_patient/submit", methods=["POST"])
def add_patient_submit():
   
    ssn = request.form.get("ssn")
    first_name = request.form.get("first_name")
    last_name = request.form.get("last_name")
    birthdate = request.form.get("birthdate")
    address = request.form.get("address")
    funds = request.form.get("funds")
    contact = request.form.get("contact")

    
   
    
   
    if not ssn or not first_name or not last_name or not birthdate or not address or not funds or not contact:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
   
        cur.callproc("add_patient", [ssn, first_name, last_name, birthdate, address, funds, contact])  
        db.commit()  
        db.close() 
        
    return {"message": "Operation Executed Successfully."}


@app.route("/add_staff_to_dept/form")
def staff_to_dept_form():
    return render_template("add_staff_to_dept.html")


@app.route("/add_staff_to_dept/submit", methods=["POST"])
def add_staff_to_dept_submit():
   
    dept_id = request.form.get("dept_id")
    ssn = request.form.get("ssn")
    first_name = request.form.get("first_name")
    last_name = request.form.get("last_name")
    birthdate = request.form.get("birthdate")
    start_date = request.form.get("start_date")
    address = request.form.get("address")
    staff_id = request.form.get("staff_id")
    salary = request.form.get("salary")

    
   
    
   
    if not dept_id or not ssn or not first_name or not last_name or not birthdate or not address or not staff_id or not salary:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
   
        cur.callproc("add_staff_to_dept", [dept_id, ssn, first_name, last_name, birthdate, start_date, address, staff_id, salary])  
        db.commit()  
        db.close() 
        
    return {"message": "Operation Executed Successfully."}

@app.route("/book_appointment/form")
def book_appointment_form():
    return render_template("book_appointment.html")


@app.route("/book_appointment/submit", methods=["POST"])
def book_appointment_submit():
   
    patient_id = request.form.get("patient_id")
    appt_date = request.form.get("appt_date")
    appt_time = request.form.get("appt_time")
    appt_cost = request.form.get("appt_cost")

    
   
    
   
    if not patient_id or not appt_date or not appt_time or not appt_cost:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
   
        cur.callproc("book_appointment", [patient_id, appt_date, appt_time, appt_cost])  
        db.commit()  
        db.close() 
        
    return {"message": "Operation Executed Successfully."}


@app.route("/assign_doctor_to_appointment/form")
def assign_doctor_to_appointment_form():
    return render_template("assign_doctor_to_appointment.html")

###this works if patient already exists and has an appointment already, also inputs need to match exactly

@app.route("/assign_doctor_to_appointment/submit", methods=["POST"])
def assign_doctor_to_appointment_submit():
   
    patient_id = request.form.get("patient_id")
    appt_date = request.form.get("appt_date")
    appt_time = request.form.get("appt_time")
    doctor_id = request.form.get("doctor_id")

    
   
    
    
   
    if not patient_id or not appt_date or not appt_time or not doctor_id:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("assign_doctor_to_appointment", [patient_id, appt_date, appt_time, doctor_id])  
        db.commit()  
        return {"status": "Success", "message": "Doctor assigned to appointment successfully!"}
        
    db.close() 


@app.route("/release_room/form")
def release_room_form():
    return render_template("release_room.html")


@app.route("/release_room/submit", methods=["POST"])
def release_room_submit():
   
    room_number = request.form.get("room_number")

    
   
    
    
   
    if not room_number:
        return {"message": "Room number is required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("release_room", [int(room_number)])  
        db.commit()  
        return {"status": "Success", "message": "Room released successfully!"}
        
        db.close() 


@app.route("/remove_patient/form")
def remove_patient_form():
    return render_template("remove_patient.html")

### only if patient exists, does not have any appointments, or orders

@app.route("/remove_patient/submit", methods=["POST"])
def remove_patient_submit():
   
    ssn = request.form.get("ssn")


    
    
   
    if not ssn:
        return {"message": "SSN is required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("remove_patient", [ssn])  
        db.commit()  
        return {"status": "Success", "message": "Patient removed successfully!"}
        
    db.close() 


@app.route("/assign_room_to_patient/form")
def assign_room_to_patient_form():
    return render_template("assign_room_to_patient.html")

##make sure room type macthes to what it already is in the db


@app.route("/assign_room_to_patient/submit", methods=["POST"])
def assign_room_to_patient_submit():
   
    ssn = request.form.get("ssn")
    room_number = request.form.get("room_number")
    room_type = request.form.get("room_type")

    
   
    
    
   
    if not ssn or not room_number or not room_type:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("assign_room_to_patient", [ssn, int(room_number), room_type])  
        db.commit()  
        return {"status": "Success", "message": "Room assigned to patient successfully!"}
        
    db.close() 


@app.route("/assign_nurse_to_room/form")
def assign_nurse_to_room_form():
    return render_template("assign_nurse_to_room.html")

### make sure nurse and room both exist


@app.route("/assign_nurse_to_room/submit", methods=["POST"])
def assign_nurse_to_room_submit():
   
    nurse_id = request.form.get("nurse_id")
    room_number = request.form.get("room_number")

    
   
    
    
   
    if not nurse_id or not room_number:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("assign_nurse_to_room", [nurse_id, int(room_number)])  
        db.commit()  
        return {"status": "Success", "message": "Nurse assigned to room successfully!"}
        
    db.close() 


@app.route("/remove_staff_from_dept/form")
def remove_staff_from_dept_form():
    return render_template("remove_staff_from_dept.html")

## removes from works_on not the actual staff



@app.route("/remove_staff_from_dept/submit", methods=["POST"])
def remove_staff_from_dept_submit():
   
    ssn = request.form.get("ssn")
    dept_id = request.form.get("dept_id")

    
   
    
    
   
    if not ssn or not dept_id:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:

        cur.callproc("remove_staff_from_dept", [ssn, int(dept_id)])  
        db.commit()  
        return {"status": "Success", "message": "Staff removed from department successfully!"}
       
    db.close() 


@app.route("/complete_appointment/form")
def complete_appointment_form():
    return render_template("complete_appointment.html")

## works 


@app.route("/complete_appointment/submit", methods=["POST"])
def complete_appointment_submit():
   
    patient_id = request.form.get("patient_id")
    appt_date = request.form.get("appt_date")
    appt_time = request.form.get("appt_time")

    
   
    
    
   
    if not patient_id or not appt_date or not appt_time:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
        
        cur.callproc("complete_appointment", [patient_id, appt_date, appt_time])  
        db.commit()  
        return {"status": "Success", "message": "Appointment completed successfully!"}
        
    db.close() 

# complete orders is (2.67/3) on autograder
@app.route("/complete_orders/form")
def complete_orders_form():
    return render_template("complete_orders.html")

#


@app.route("/complete_orders/submit", methods=["POST"])
def complete_orders_submit():
   
    num_orders = request.form.get("num_orders")

    
   
    
    
   
    if not num_orders:
        return {"message": "Number of orders is required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
        
        cur.callproc("complete_orders", [int(num_orders)])  
        db.commit()  
        return {"status": "Success", "message": "Orders completed successfully!"}
        

    db.close() 


@app.route("/record_symptom/form")
def record_symptom_form():
    return render_template("record_symptom.html")


@app.route("/record_symptom/submit", methods=["POST"])
def record_symptom_submit():
   
    patient_id = request.form.get("patient_id")
    num_days = request.form.get("num_days")
    appt_date = request.form.get("appt_date")
    appt_time = request.form.get("appt_time")
    symptom_type = request.form.get("symptom_type")

    
   
    
    
   
    if not patient_id or not num_days or not appt_date or not appt_time or not symptom_type:
        return {"message": "All fields are required."}  #maybe do some more fixes on this


    db = get_db()
    with db.cursor() as cur:
        cur.callproc("record_symptom", [patient_id, int(num_days), appt_date, appt_time, symptom_type])  
        db.commit()  
        return {"status": "Success", "message": "Symptom recorded successfully!"}
        

    db.close() 











#################################################################################################################
                                #VIEWS
                                
@app.route("/room_wise_view")
def room_wise_view():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("select * from room_wise_view")
        result = cur.fetchall() 
    db.close()
    return render_template("roomwise_view.html", data=result)

@app.route("/symptoms_overview_view")
def symptoms_overview_view():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("select *from symptoms_overview_view")
        result = cur.fetchall()  
    db.close()
    return render_template("symptoms_overview_view.html", data=result)


@app.route("/medical_staff_view")
def medical_staff_view():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("select * from medical_staff_view")
        result = cur.fetchall()  
    db.close()
    return render_template("medical_staff_view.html", data=result)

@app.route("/department_view")
def department_view():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("select * from department_view")  
        result = cur.fetchall()
    db.close()
    return render_template("department_view.html", data=result)

@app.route("/outstanding_charges_view")
def outstanding_charges_view():
    db = get_db()
    with db.cursor() as cur:
        cur.execute("select * from outstanding_charges_view")
        result = cur.fetchall()
    db.close()
    return render_template("outstanding_charges_view.html", data=result)





if __name__ == "__main__":
    app.run(debug=True)
