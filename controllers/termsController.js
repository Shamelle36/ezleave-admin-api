import sql from "../config/db.js"; // PostgreSQL connection

// ================================
// GET active Terms (public)
// ================================
export const getActiveTerms = async (req, res) => {
  try {
    const result = await sql`
      SELECT *
      FROM terms_conditions
      WHERE is_active = true
      ORDER BY created_at DESC
      LIMIT 1
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "No active terms found." });
    }

    res.json(result[0]);
  } catch (error) {
    console.error("Error fetching active terms:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// ================================
// GET all Terms versions (Admin)
// ================================
export const getAllTerms = async (req, res) => {
  try {
    const result = await sql`
      SELECT *
      FROM terms_conditions
      ORDER BY created_at DESC
    `;
    res.json(result);
  } catch (error) {
    console.error("Error fetching all terms:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// ================================
// CREATE new Terms & Conditions
// ================================
export const createTerms = async (req, res) => {
  const { version, content } = req.body;

  if (!version || !content) {
    return res.status(400).json({ message: "Version and content are required." });
  }

  try {
    // Deactivate all previous versions
    await sql`
      UPDATE terms_conditions
      SET is_active = false
    `;

    const result = await sql`
      INSERT INTO terms_conditions (version, content, is_active)
      VALUES (${version}, ${content}, true)
      RETURNING *
    `;

    res.status(201).json({
      message: "New Terms & Conditions created and activated.",
      data: result[0],
    });
  } catch (error) {
    console.error("Error creating terms:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// ================================
// UPDATE Terms version
// ================================
export const updateTerms = async (req, res) => {
  const { id } = req.params;
  const { version, content, is_active } = req.body;

  try {
    // If new version is activated, deactivate others
    if (is_active === true) {
      await sql`
        UPDATE terms_conditions
        SET is_active = false
      `;
    }

    const result = await sql`
      UPDATE terms_conditions
      SET 
        version = COALESCE(${version}, version),
        content = COALESCE(${content}, content),
        is_active = COALESCE(${is_active}, is_active),
        updated_at = NOW()
      WHERE id = ${id}
      RETURNING *
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "Terms record not found." });
    }

    res.json({
      message: "Terms & Conditions updated successfully.",
      data: result[0],
    });
  } catch (error) {
    console.error("Error updating terms:", error);
    res.status(500).json({ message: "Server error" });
  }
};

// ================================
// DELETE Terms version
// ================================
export const deleteTerms = async (req, res) => {
  const { id } = req.params;

  try {
    const result = await sql`
      DELETE FROM terms_conditions
      WHERE id = ${id}
      RETURNING *
    `;

    if (result.length === 0) {
      return res.status(404).json({ message: "Terms record not found." });
    }

    res.json({ message: "Terms & Conditions version deleted." });
  } catch (error) {
    console.error("Error deleting terms:", error);
    res.status(500).json({ message: "Server error" });
  }
};
