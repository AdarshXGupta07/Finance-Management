# Finance Management System

A simplified and cleaner Personal Finance Management System built with **Flask + MySQL**.

## What was improved

- Simplified and polished login/register pages.
- Better HTML structure and cleaner CSS for authentication screens.
- Added smooth animations for a modern, minimal UI experience.
- Kept all core project functionality unchanged.
- Added SQL documentation for constraints, set operations, joins, views, triggers, cursors, and aggregation.

## Project Structure

```text
Finance-Management/
├── backend/
├── database/
├── frontend/
└── README.md
```

## Run Locally

1. Create DB schema and seed sample data:
   ```bash
   mysql -u root -p < database/schema.sql
   mysql -u root -p < database/sample_data.sql
   ```
2. Install backend requirements:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
3. Start server:
   ```bash
   python app.py
   ```
4. Open:
   - `http://127.0.0.1:5000/login`
   - `http://127.0.0.1:5000/register`

## Database Concepts Included

The project includes examples of:

- Constraints
- Sets / Set logic
- Joins
- Views
- Triggers
- Cursors (stored procedure cursors)
- Aggregation

Detailed SQL examples are documented in:

- `DATABASE_ENHANCEMENTS.md`
- `database/SQL_QUERIES_USED.md`
- `database/CHAPTER_3_COMPLEX_QUERIES.md`
