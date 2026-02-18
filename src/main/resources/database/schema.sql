-- Employee Onboarding System Database Schema
-- H2 Database Setup with user 'sa' and empty password
-- Database URL: jdbc:h2:mem:employee_db;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS email_logs;
DROP TABLE IF EXISTS assets;
DROP TABLE IF EXISTS employees;

-- Create employees table
CREATE TABLE employees (
    employee_id VARCHAR(50) PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    department VARCHAR(100) NOT NULL,
    position VARCHAR(100),
    status VARCHAR(50) DEFAULT 'onboarding',
    onboarding_tasks TEXT,
    manager_id VARCHAR(50),
    start_date DATE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create assets table
CREATE TABLE assets (
    asset_id VARCHAR(50) PRIMARY KEY,
    asset_type VARCHAR(50) NOT NULL,
    brand VARCHAR(100),
    model VARCHAR(100),
    serial_number VARCHAR(255) UNIQUE,
    status VARCHAR(50) DEFAULT 'AVAILABLE',
    specs TEXT,
    allocated_to VARCHAR(50),
    allocated_date TIMESTAMP,
    returned_date TIMESTAMP,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (allocated_to) REFERENCES employees(employee_id)
);

-- Create email_logs table
CREATE TABLE email_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(50),
    email_type VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(500),
    sent_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(50) DEFAULT 'SENT',
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Create indexes for better performance
CREATE INDEX idx_employees_department ON employees(department);
CREATE INDEX idx_employees_status ON employees(status);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_assets_type ON assets(asset_type);
CREATE INDEX idx_assets_status ON assets(status);
CREATE INDEX idx_assets_allocated_to ON assets(allocated_to);
CREATE INDEX idx_email_logs_employee ON email_logs(employee_id);
CREATE INDEX idx_email_logs_type ON email_logs(email_type);
CREATE INDEX idx_email_logs_date ON email_logs(sent_date);

-- Add comments to tables
COMMENT ON TABLE employees IS 'Employee information and onboarding status';
COMMENT ON TABLE assets IS 'Company assets inventory and allocation tracking';
COMMENT ON TABLE email_logs IS 'Email notification audit trail';
