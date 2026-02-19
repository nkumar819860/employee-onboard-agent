-- Employee Onboarding System Database Schema
-- H2 Database Schema for CloudHub Deployment

-- Drop existing tables if they exist
DROP TABLE IF EXISTS email_logs;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS employees;

-- Create employees table
CREATE TABLE employees (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    department VARCHAR(100),
    position VARCHAR(100),
    manager_id VARCHAR(50),
    start_date DATE,
    status VARCHAR(50) DEFAULT 'onboarding',
    onboarding_tasks TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Create assets table
CREATE TABLE assets (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    asset_id VARCHAR(50) UNIQUE NOT NULL,
    asset_type VARCHAR(100) NOT NULL,
    asset_name VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'available',
    assigned_to VARCHAR(50),
    assigned_date TIMESTAMP,
    serial_number VARCHAR(100),
    location VARCHAR(200),
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_to) REFERENCES employees(employee_id) ON DELETE SET NULL
);

-- Create email_logs table
CREATE TABLE email_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(50),
    email_type VARCHAR(100) NOT NULL,
    recipient_email VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    message_body TEXT,
    status VARCHAR(50) DEFAULT 'sent',
    sent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    error_message TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE SET NULL
);

-- Create indexes for better performance
CREATE INDEX idx_employees_employee_id ON employees(employee_id);
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_assets_asset_id ON assets(asset_id);
CREATE INDEX idx_assets_assigned_to ON assets(assigned_to);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_email_logs_employee_id ON email_logs(employee_id);
CREATE INDEX idx_email_logs_email_type ON email_logs(email_type);

-- Log schema creation
INSERT INTO email_logs (employee_id, email_type, recipient_email, subject, message_body, status) 
VALUES (NULL, 'system', 'system@company.com', 'Database Schema Created', 
        'Employee Onboarding System database schema has been successfully created with tables: employees, assets, email_logs', 
        'sent');
