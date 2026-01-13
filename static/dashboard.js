const sections = {
    appointments: `
        <div class="section-card">
            <h2>Appointments</h2>
            <p class="section-desc">
                Schedule, assign, and complete patient appointments.
            </p>

            <div class="card-grid">
                <a class="card" href="/book_appointment/form">
                    <h3>Book Appointment</h3>
                    <p>Create a new appointment for a patient.</p>
                </a>

                <a class="card" href="/assign_doctor_to_appointment/form">
                    <h3>Assign Doctor</h3>
                    <p>Link a doctor to an existing appointment.</p>
                </a>

                <a class="card" href="/complete_appointment/form">
                    <h3>Complete Appointment</h3>
                    <p>Mark appointments as completed.</p>
                </a>
            </div>
        </div>
    `,

    patients: `
        <div class="section-card">
            <h2>Patients</h2>
            <p class="section-desc">
                Manage patient records and balances.
            </p>

            <div class="card-grid">
                <a class="card" href="/add_patient/form">
                    <h3>Add Patient</h3>
                    <p>Register a new patient in the system.</p>
                </a>

                <a class="card" href="/add_funds/form">
                    <h3>Add Funds</h3>
                    <p>Add funds to a patient account.</p>
                </a>

                <a class="card" href="/remove_patient/form">
                    <h3>Remove Patient</h3>
                    <p>Delete patient records.</p>
                </a>
            </div>
        </div>
    `,

    departments: `
        <div class="section-card">
            <h2>Departments</h2>
            <p class="section-desc">
                Assign and manage staff across departments.
            </p>

            <div class="card-grid">
                <a class="card" href="/manage_department/form">
                    <h3>Manage Department</h3>
                    <p>Move patients between departments.</p>
                </a>

                <a class="card" href="/add_staff_to_dept/form">
                    <h3>Add Staff</h3>
                    <p>Assign staff members to departments.</p>
                </a>

                <a class="card" href="/remove_staff_from_dept/form">
                    <h3>Remove Staff</h3>
                    <p>Remove staff from departments.</p>
                </a>
            </div>
        </div>
    `,

    rooms: `
        <div class="section-card">
            <h2>Rooms</h2>
            <p class="section-desc">
                Control room assignments and availability.
            </p>

            <div class="card-grid">
                <a class="card" href="/assign_room_to_patient/form">
                    <h3>Assign Room</h3>
                    <p>Assign a room to a patient.</p>
                </a>

                <a class="card" href="/assign_nurse_to_room/form">
                    <h3>Assign Nurse</h3>
                    <p>Assign a nurse to a room.</p>
                </a>

                <a class="card" href="/release_room/form">
                    <h3>Release Room</h3>
                    <p>Free up occupied rooms.</p>
                </a>
            </div>
        </div>
    `,

    views: `
        <div class="section-card">
            <h2>System Views</h2>
            <p class="section-desc">
                Read-only system insights and summaries.
            </p>

            <div class="card-grid">
                <a class="card" href="/medical_staff_view">
                    <h3>Medical Staff</h3>
                    <p>View all medical staff details.</p>
                </a>

                <a class="card" href="/department_view">
                    <h3>Departments</h3>
                    <p>Overview of hospital departments.</p>
                </a>

                <a class="card" href="/room_wise_view">
                    <h3>Room Usage</h3>
                    <p>Current room assignments.</p>
                </a>

                <a class="card" href="/symptoms_overview_view">
                    <h3>Symptoms</h3>
                    <p>Patient symptoms overview.</p>
                </a>

                <a class="card" href="/outstanding_charges_view">
                    <h3>Outstanding Charges</h3>
                    <p>Pending patient balances.</p>
                </a>
            </div>
        </div>
    `
};

const content = document.getElementById("content");
const navItems = document.querySelectorAll(".nav-links li");

function loadSection(sectionKey) {
    content.classList.remove("show");

    setTimeout(() => {
        content.innerHTML = sections[sectionKey];
        content.classList.add("show");
    }, 150);
}

navItems.forEach(item => {
    item.addEventListener("click", () => {
        navItems.forEach(li => li.classList.remove("active"));
        item.classList.add("active");
        loadSection(item.dataset.section);
    });
});

navItems[0].classList.add("active");
loadSection("appointments");
