// controllers/employeeController.js
import sql from "../config/db.js";

// 📌 Add new employee
export const addEmployee = async (req, res) => {
  try {
    const { first_name, last_name, email, position, id_number, contact_number, civil_status, department, status, date_hired, gender } = req.body;

    const [employee] = await sql`
      INSERT INTO employee_list (
        first_name, 
        last_name, 
        email, 
        position, 
        id_number, 
        contact_number, 
        civil_status, 
        department, 
        status, 
        date_hired,
        gender
      ) VALUES (
        ${first_name}, 
        ${last_name}, 
        ${email}, 
        ${position}, 
        ${id_number}, 
        ${contact_number}, 
        ${civil_status}, 
        ${department}, 
        ${status}, 
        ${date_hired},
        ${gender}
      )
      RETURNING *
    `;

    res.status(201).json(employee);
  } catch (error) {
    console.error("Error adding employee:", error);
    res.status(500).json({ error: "Failed to add employee" });
  }
};

// 📌 Get all employees
export const getEmployees = async (req, res) => {
  try {
    const result = await sql`
      SELECT 
        id,
        first_name,
        last_name,
        (first_name || ' ' || last_name) AS full_name,
        email,
        position,
        department,
        employment_status,
        gender,
        civil_status,
        status,
        date_hired,
        id_number,
        contact_number,
        created_at,
        updated_at
      FROM employee_list
      ORDER BY id DESC;
    `;
    res.json(result);
  } catch (error) {
    console.error("Error fetching employees:", error);
    res.status(500).json({ error: "Failed to fetch employees" });
  }
};

// 📌 Get single employee by ID
export const getEmployeeById = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await sql`
      SELECT 
        id,
        first_name,
        last_name,
        (first_name || ' ' || last_name) AS full_name,
        email,
        position,
        department,
        employment_status,
        gender,
        civil_status,
        status,
        date_hired,
        id_number,
        contact_number,
        created_at,
        updated_at
      FROM employee_list
      WHERE id = ${id};
    `;
    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }
    res.json(result[0]);
  } catch (error) {
    console.error("Error fetching employee:", error);
    res.status(500).json({ error: "Failed to fetch employee" });
  }
};

// 📌 Update employee
export const updateEmployee = async (req, res) => {
  const { id } = req.params;
  const {
    first_name,
    last_name,
    email,
    position,
    department,   // ✅ plain text
    employment_status,
    gender,
    civil_status,
    status,
    date_hired,
    id_number,
    contact_number,
  } = req.body;

  try {
    const result = await sql`
      UPDATE employee_list
      SET
        first_name = ${first_name},
        last_name = ${last_name},
        email = ${email},
        position = ${position},
        department = ${department},
        employment_status = ${employment_status},
        gender = ${gender},
        civil_status = ${civil_status},
        status = ${status},
        date_hired = ${date_hired},
        id_number = ${id_number},
        contact_number = ${contact_number},
        updated_at = NOW()
      WHERE id = ${id}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json(result[0]);
  } catch (error) {
    console.error("Error updating employee:", error);
    res.status(500).json({ error: "Failed to update employee" });
  }
};

// 📌 Delete employee
export const deleteEmployee = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await sql`
      DELETE FROM employee_list
      WHERE id = ${id}
      RETURNING *;
    `;

    if (result.length === 0) {
      return res.status(404).json({ error: "Employee not found" });
    }

    res.json({ message: "Employee deleted successfully" });
  } catch (error) {
    console.error("Error deleting employee:", error);
    res.status(500).json({ error: "Failed to delete employee" });
  }
};

// Count employees
export async function getEmployeeCount(req, res) {
  try {
    const [result] = await sql`
      SELECT COUNT(*)::int AS total FROM employee_list
    `;
    res.status(200).json({ total: result.total });
  } catch (error) {
    console.error("Error fetching employee count:", error);
    res.status(500).json({ message: "Internal server error" });
  }
}


