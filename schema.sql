require("dotenv").config();

const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const pool = require("./db");

const app = express();

app.use(helmet());
app.use(cors({
origin: process.env.FRONTEND_ORIGIN || false
}));
app.use(express.json({ limit: "20kb" }));

// Check whether the API is running.
app.get("/api/health", (req, res) => {
res.json({
success: true,
message: "Rosslyn Foundation API is running."
});
});

// Submit a support request.
app.post("/api/support-requests", async (req, res) => {
try {
const {
fullName,
relationship,
dateOfBirth,
email,
phone,
location,
service,
details,
contactMethod,
consent
} = req.body;

// Check required fields.
const requiredFields = {
  fullName,
  relationship,
  dateOfBirth,
  email,
  phone,
  location,
  service,
  details
};

for (const [field, value] of Object.entries(requiredFields)) {
  if (typeof value !== "string" || !value.trim()) {
    return res.status(400).json({
      success: false,
      message: `Please provide a valid ${field}.`
    });
  }
}

// Validate field lengths.
if (fullName.trim().length > 200 ||
    email.trim().length > 255 ||
    phone.trim().length > 30 ||
    location.trim().length > 150 ||
    details.trim().length < 20 ||
    details.trim().length > 2500) {
  return res.status(400).json({
    success: false,
    message: "One or more fields have invalid lengths."
  });
}

// Validate the email format.
const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

if (!emailPattern.test(email.trim())) {
  return res.status(400).json({
    success: false,
    message: "Please enter a valid email address."
  });
}

// Validate the relationship selection.
const validRelationships = [
  "myself",
  "family",
  "person-in-care",
  "other"
];

if (!validRelationships.includes(relationship)) {
  return res.status(400).json({
    success: false,
    message: "Please select a valid relationship."
  });
}

// Validate the preferred contact method.
const selectedContactMethod = contactMethod || "phone";
const validContactMethods = ["phone", "email", "either"];

if (!validContactMethods.includes(selectedContactMethod)) {
  return res.status(400).json({
    success: false,
    message: "Please select a valid contact method."
  });
}

// Consent must be explicitly confirmed.
if (consent !== true) {
  return res.status(400).json({
    success: false,
    message: "Consent is required to submit this request."
  });
}

// Validate the support category.
const validServices = [
  "Care and well-being",
  "Food and essential supplies",
  "Health-related needs",
  "Companionship and community",
  "Financial hardship",
  "General guidance / not sure",
  "Other"
];

if (!validServices.includes(service)) {
  return res.status(400).json({
    success: false,
    message: "Please select a valid support type."
  });
}

// Validate the date and minimum age of 40.
if (!/^\d{4}-\d{2}-\d{2}$/.test(dateOfBirth)) {
  return res.status(400).json({
    success: false,
    message: "Please provide a valid date of birth."
  });
}

const dob = new Date(`${dateOfBirth}T00:00:00.000Z`);
const today = new Date();
today.setUTCHours(0, 0, 0, 0);

if (Number.isNaN(dob.getTime()) ||
    dob.toISOString().slice(0, 10) !== dateOfBirth ||
    dob > today) {
  return res.status(400).json({
    success: false,
    message: "Please provide a valid date of birth."
  });
}

const cutoff = new Date(today);
cutoff.setUTCFullYear(cutoff.getUTCFullYear() - 40);

if (dob > cutoff) {
  return res.status(400).json({
    success: false,
    message: "The person needing support must be at least 40 years old."
  });
}

// Save the request using a parameterized SQL query.
const result = await pool.query(
  `INSERT INTO support_requests (
    full_name,
    relationship,
    date_of_birth,
    email,
    phone,
    location,
    service,
    details,
    contact_method,
    consent
  ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  RETURNING id, status, created_at`,
  [
    fullName.trim(),
    relationship,
    dateOfBirth,
    email.trim().toLowerCase(),
    phone.trim(),
    location.trim(),
    service,
    details.trim(),
    selectedContactMethod,
    true
  ]
);

return res.status(201).json({
  success: true,
  message: "Your support request has been submitted successfully.",
  request: result.rows[0]
});

} catch (error) {
console.error("Support request submission failed:", error.message);

return res.status(500).json({
  success: false,
  message: "We could not submit your request. Please try again later."
});

}
});

// Handle invalid JSON and unexpected errors.
app.use((err, req, res, next) => {
if (err instanceof SyntaxError && err.status === 400 && "body" in err) {
return res.status(400).json({
success: false,
message: "The submitted data is not valid JSON."
});
}

console.error("API error:", err.message);

return res.status(500).json({
success: false,
message: "An unexpected error occurred."
});
});

const PORT = process.env.PORT || 3000;

if (require.main === module) {
app.listen(PORT, () => {
console.log("Rosslyn Foundation API listening on port ${PORT}");
});
}

module.exports = app;
