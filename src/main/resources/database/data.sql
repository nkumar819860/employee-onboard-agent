-- Employee Onboarding System Sample Data
-- Insert sample data for testing and demo purposes

-- Sample employees
INSERT INTO employees (employee_id, first_name, last_name, email, department, position, status, start_date, created_date) VALUES
('EMP001', 'John', 'Smith', 'john.smith@company.com', 'Engineering', 'Software Engineer', 'active', '2024-01-15', CURRENT_TIMESTAMP),
('EMP002', 'Sarah', 'Johnson', 'sarah.johnson@company.com', 'HR', 'HR Manager', 'active', '2024-01-10', CURRENT_TIMESTAMP),
('EMP003', 'Mike', 'Davis', 'mike.davis@company.com', 'Finance', 'Financial Analyst', 'onboarding', '2024-02-01', CURRENT_TIMESTAMP),
('EMP004', 'Lisa', 'Wilson', 'lisa.wilson@company.com', 'Marketing', 'Marketing Specialist', 'onboarding', '2024-02-15', CURRENT_TIMESTAMP),
('EMP005', 'David', 'Brown', 'david.brown@company.com', 'Operations', 'Operations Manager', 'active', '2023-12-01', CURRENT_TIMESTAMP);

-- Sample assets inventory
INSERT INTO assets (asset_id, asset_type, brand, model, serial_number, status, specs, created_date) VALUES
-- Laptops
('LAP001', 'laptop', 'Dell', 'Latitude 5520', 'DL001234567', 'AVAILABLE', 'Intel i7, 16GB RAM, 512GB SSD', CURRENT_TIMESTAMP),
('LAP002', 'laptop', 'HP', 'EliteBook 850', 'HP001234567', 'ALLOCATED', 'Intel i7, 16GB RAM, 1TB SSD', CURRENT_TIMESTAMP),
('LAP003', 'laptop', 'Lenovo', 'ThinkPad T14', 'LN001234567', 'AVAILABLE', 'Intel i5, 8GB RAM, 256GB SSD', CURRENT_TIMESTAMP),
('LAP004', 'laptop', 'Apple', 'MacBook Pro 14"', 'AP001234567', 'ALLOCATED', 'M2 Pro, 16GB RAM, 512GB SSD', CURRENT_TIMESTAMP),
('LAP005', 'laptop', 'Dell', 'XPS 13', 'DL002234567', 'AVAILABLE', 'Intel i7, 16GB RAM, 512GB SSD', CURRENT_TIMESTAMP),

-- Monitors
('MON001', 'monitor', 'Samsung', '27" 4K Monitor', 'SM001234567', 'AVAILABLE', '27 inch, 4K UHD, USB-C', CURRENT_TIMESTAMP),
('MON002', 'monitor', 'LG', '24" UltraWide', 'LG001234567', 'ALLOCATED', '24 inch, 1440p, IPS Panel', CURRENT_TIMESTAMP),
('MON003', 'monitor', 'Dell', '32" 4K Monitor', 'DL003234567', 'AVAILABLE', '32 inch, 4K UHD, Type-C Hub', CURRENT_TIMESTAMP),

-- Phones
('PHN001', 'phone', 'Apple', 'iPhone 15', 'AP002234567', 'AVAILABLE', '128GB, Blue', CURRENT_TIMESTAMP),
('PHN002', 'phone', 'Samsung', 'Galaxy S24', 'SM002234567', 'ALLOCATED', '256GB, Black', CURRENT_TIMESTAMP),
('PHN003', 'phone', 'Apple', 'iPhone 15 Pro', 'AP003234567', 'AVAILABLE', '256GB, Space Gray', CURRENT_TIMESTAMP),

-- ID Cards
('IDC001', 'id_card', 'Company', 'Employee ID Card', 'IDC001234567', 'AVAILABLE', 'RFID enabled, Photo ID', CURRENT_TIMESTAMP),
('IDC002', 'id_card', 'Company', 'Employee ID Card', 'IDC002234567', 'ALLOCATED', 'RFID enabled, Photo ID', CURRENT_TIMESTAMP),
('IDC003', 'id_card', 'Company', 'Employee ID Card', 'IDC003234567', 'AVAILABLE', 'RFID enabled, Photo ID', CURRENT_TIMESTAMP),

-- Access Cards
('ACC001', 'access_card', 'Company', 'Building Access Card', 'ACC001234567', 'AVAILABLE', 'Proximity card, All floors access', CURRENT_TIMESTAMP),
('ACC002', 'access_card', 'Company', 'Building Access Card', 'ACC002234567', 'ALLOCATED', 'Proximity card, Engineering floor access', CURRENT_TIMESTAMP),

-- Keyboards and Mouse
('KEY001', 'keyboard', 'Logitech', 'MX Keys', 'LG003234567', 'AVAILABLE', 'Wireless, Backlit, Multi-device', CURRENT_TIMESTAMP),
('KEY002', 'keyboard', 'Apple', 'Magic Keyboard', 'AP004234567', 'ALLOCATED', 'Wireless, Touch ID, Space Gray', CURRENT_TIMESTAMP),
('MOU001', 'mouse', 'Logitech', 'MX Master 3', 'LG004234567', 'AVAILABLE', 'Wireless, Precision scroll, Multi-device', CURRENT_TIMESTAMP),
('MOU002', 'mouse', 'Apple', 'Magic Mouse', 'AP005234567', 'ALLOCATED', 'Wireless, Multi-touch, Space Gray', CURRENT_TIMESTAMP);

-- Update allocated assets with employee assignments
UPDATE assets SET allocated_to = 'EMP001', allocated_date = CURRENT_TIMESTAMP WHERE asset_id IN ('LAP002', 'MON002', 'PHN002', 'IDC002', 'ACC002', 'KEY002', 'MOU002');
UPDATE assets SET allocated_to = 'EMP002', allocated_date = CURRENT_TIMESTAMP WHERE asset_id = 'LAP004';

-- Sample email logs
INSERT INTO email_logs (employee_id, email_type, recipient, subject, sent_date, status) VALUES
('EMP001', 'WELCOME', 'john.smith@company.com', 'Welcome to Engineering Department - John Smith', DATEADD('DAY', -15, CURRENT_TIMESTAMP), 'SENT'),
('EMP001', 'ASSET_ALLOCATION', 'john.smith@company.com', 'Assets Allocated - John Smith', DATEADD('DAY', -14, CURRENT_TIMESTAMP), 'SENT'),
('EMP001', 'COMPLETION', 'john.smith@company.com', 'Onboarding Complete - Welcome to the Team, John!', DATEADD('DAY', -10, CURRENT_TIMESTAMP), 'SENT'),

('EMP002', 'WELCOME', 'sarah.johnson@company.com', 'Welcome to HR Department - Sarah Johnson', DATEADD('DAY', -20, CURRENT_TIMESTAMP), 'SENT'),
('EMP002', 'ASSET_ALLOCATION', 'sarah.johnson@company.com', 'Assets Allocated - Sarah Johnson', DATEADD('DAY', -19, CURRENT_TIMESTAMP), 'SENT'),
('EMP002', 'COMPLETION', 'sarah.johnson@company.com', 'Onboarding Complete - Welcome to the Team, Sarah!', DATEADD('DAY', -15, CURRENT_TIMESTAMP), 'SENT'),

('EMP003', 'WELCOME', 'mike.davis@company.com', 'Welcome to Finance Department - Mike Davis', DATEADD('DAY', -17, CURRENT_TIMESTAMP), 'SENT'),
('EMP003', 'ASSET_ALLOCATION', 'mike.davis@company.com', 'Assets Allocated - Mike Davis', DATEADD('DAY', -16, CURRENT_TIMESTAMP), 'SENT'),

('EMP004', 'WELCOME', 'lisa.wilson@company.com', 'Welcome to Marketing Department - Lisa Wilson', DATEADD('DAY', -3, CURRENT_TIMESTAMP), 'SENT'),

('EMP005', 'WELCOME', 'david.brown@company.com', 'Welcome to Operations Department - David Brown', DATEADD('DAY', -80, CURRENT_TIMESTAMP), 'SENT'),
('EMP005', 'COMPLETION', 'david.brown@company.com', 'Onboarding Complete - Welcome to the Team, David!', DATEADD('DAY', -75, CURRENT_TIMESTAMP), 'SENT');
