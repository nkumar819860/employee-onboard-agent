-- Employee Onboarding System Sample Data
-- Sample data for demonstration and testing

-- Insert sample employees
INSERT INTO employees (employee_id, first_name, last_name, email, department, position, start_date, status) VALUES
('EMP001', 'John', 'Doe', 'john.doe@company.com', 'IT', 'Software Engineer', '2024-01-15', 'active'),
('EMP002', 'Jane', 'Smith', 'jane.smith@company.com', 'HR', 'HR Specialist', '2024-01-20', 'active'),
('EMP003', 'Mike', 'Johnson', 'mike.johnson@company.com', 'Finance', 'Financial Analyst', '2024-02-01', 'active'),
('EMP004', 'Sarah', 'Wilson', 'sarah.wilson@company.com', 'Marketing', 'Marketing Manager', '2024-02-10', 'onboarding');

-- Insert sample assets
INSERT INTO assets (asset_id, asset_type, asset_name, description, status, serial_number, location) VALUES
-- Available laptops
('LAPTOP001', 'laptop', 'Dell Latitude 5520', 'Business laptop with 16GB RAM, 512GB SSD', 'available', 'DL5520001', 'IT Storage Room'),
('LAPTOP002', 'laptop', 'Dell Latitude 5520', 'Business laptop with 16GB RAM, 512GB SSD', 'available', 'DL5520002', 'IT Storage Room'),
('LAPTOP003', 'laptop', 'MacBook Pro 14"', 'Apple MacBook Pro with M2 chip, 16GB RAM, 512GB SSD', 'available', 'MBP14001', 'IT Storage Room'),
('LAPTOP004', 'laptop', 'ThinkPad X1 Carbon', 'Lenovo ThinkPad with 16GB RAM, 1TB SSD', 'available', 'TPX1001', 'IT Storage Room'),
('LAPTOP005', 'laptop', 'Dell XPS 13', 'Ultrabook with 16GB RAM, 512GB SSD', 'available', 'DXPS13001', 'IT Storage Room'),

-- Available phones
('PHONE001', 'phone', 'iPhone 14 Pro', 'Apple iPhone 14 Pro 256GB', 'available', 'IPH14P001', 'IT Storage Room'),
('PHONE002', 'phone', 'iPhone 14 Pro', 'Apple iPhone 14 Pro 256GB', 'available', 'IPH14P002', 'IT Storage Room'),
('PHONE003', 'phone', 'Samsung Galaxy S23', 'Samsung Galaxy S23 256GB', 'available', 'SGS23001', 'IT Storage Room'),
('PHONE004', 'phone', 'Google Pixel 7 Pro', 'Google Pixel 7 Pro 256GB', 'available', 'GPP7001', 'IT Storage Room'),

-- Available security badges
('BADGE001', 'security_badge', 'Employee ID Badge', 'Standard employee identification badge with building access', 'available', 'BDG001', 'Security Office'),
('BADGE002', 'security_badge', 'Employee ID Badge', 'Standard employee identification badge with building access', 'available', 'BDG002', 'Security Office'),
('BADGE003', 'security_badge', 'Employee ID Badge', 'Standard employee identification badge with building access', 'available', 'BDG003', 'Security Office'),
('BADGE004', 'security_badge', 'Employee ID Badge', 'Standard employee identification badge with building access', 'available', 'BDG004', 'Security Office'),
('BADGE005', 'security_badge', 'Employee ID Badge', 'Standard employee identification badge with building access', 'available', 'BDG005', 'Security Office'),

-- Available monitors
('MONITOR001', 'monitor', 'Dell UltraSharp 24"', '24-inch 4K monitor with USB-C connectivity', 'available', 'DU24001', 'IT Storage Room'),
('MONITOR002', 'monitor', 'Dell UltraSharp 27"', '27-inch 4K monitor with USB-C connectivity', 'available', 'DU27001', 'IT Storage Room'),
('MONITOR003', 'monitor', 'LG UltraWide 34"', '34-inch ultrawide monitor for productivity', 'available', 'LGUW34001', 'IT Storage Room'),

-- Available keyboards and mice
('KEYBOARD001', 'keyboard', 'Logitech MX Keys', 'Wireless illuminated keyboard', 'available', 'LMXK001', 'IT Storage Room'),
('KEYBOARD002', 'keyboard', 'Apple Magic Keyboard', 'Wireless keyboard for Mac', 'available', 'AMK001', 'IT Storage Room'),
('MOUSE001', 'mouse', 'Logitech MX Master 3', 'Advanced wireless mouse', 'available', 'LMXM3001', 'IT Storage Room'),
('MOUSE002', 'mouse', 'Apple Magic Mouse', 'Wireless mouse for Mac', 'available', 'AMM001', 'IT Storage Room'),

-- Some assigned assets
('LAPTOP101', 'laptop', 'Dell Latitude 5520', 'Business laptop with 16GB RAM, 512GB SSD', 'assigned', 'DL5520101', 'John Doe Desk'),
('PHONE101', 'phone', 'iPhone 14 Pro', 'Apple iPhone 14 Pro 256GB', 'assigned', 'IPH14P101', 'John Doe'),
('BADGE101', 'security_badge', 'Employee ID Badge', 'Employee identification badge', 'assigned', 'BDG101', 'John Doe');

-- Update assigned assets with employee assignments
UPDATE assets SET assigned_to = 'EMP001', assigned_date = '2024-01-15 10:00:00' WHERE asset_id IN ('LAPTOP101', 'PHONE101', 'BADGE101');

-- Insert sample email logs
INSERT INTO email_logs (employee_id, email_type, recipient_email, subject, message_body, status, sent_date) VALUES
('EMP001', 'welcome', 'john.doe@company.com', 'Welcome to the Company!', 'Welcome John! We are excited to have you join our IT team.', 'sent', '2024-01-15 09:00:00'),
('EMP001', 'asset_allocation', 'john.doe@company.com', 'Your IT Equipment Assignment', 'Your laptop, phone, and security badge have been assigned and are ready for pickup.', 'sent', '2024-01-15 10:30:00'),
('EMP001', 'onboarding_complete', 'john.doe@company.com', 'Onboarding Process Complete', 'Congratulations! Your onboarding process has been completed successfully.', 'sent', '2024-01-15 16:00:00'),

('EMP002', 'welcome', 'jane.smith@company.com', 'Welcome to the Company!', 'Welcome Jane! We are thrilled to have you join our HR team.', 'sent', '2024-01-20 09:00:00'),
('EMP002', 'asset_allocation', 'jane.smith@company.com', 'Your IT Equipment Assignment', 'Your laptop and security badge have been assigned and are ready for pickup.', 'sent', '2024-01-20 10:30:00'),

('EMP003', 'welcome', 'mike.johnson@company.com', 'Welcome to the Company!', 'Welcome Mike! We look forward to having you on our Finance team.', 'sent', '2024-02-01 09:00:00'),

('EMP004', 'welcome', 'sarah.wilson@company.com', 'Welcome to the Company!', 'Welcome Sarah! We are excited to have you join our Marketing team.', 'sent', '2024-02-10 09:00:00'),

-- System notification logs
(NULL, 'system', 'admin@company.com', 'Database Initialized', 'Employee Onboarding System database has been initialized with sample data.', 'sent', CURRENT_TIMESTAMP),
(NULL, 'system', 'it@company.com', 'Asset Inventory Updated', 'Asset inventory has been loaded with available laptops, phones, badges, and accessories.', 'sent', CURRENT_TIMESTAMP);

-- Insert onboarding task updates
UPDATE employees SET onboarding_tasks = '{"tasks":[{"task":"Complete IT setup","status":"completed"},{"task":"Security briefing","status":"completed"},{"task":"Department orientation","status":"completed"}]}' WHERE employee_id = 'EMP001';
UPDATE employees SET onboarding_tasks = '{"tasks":[{"task":"Complete IT setup","status":"completed"},{"task":"HR documentation","status":"completed"},{"task":"Department orientation","status":"in_progress"}]}' WHERE employee_id = 'EMP002';
UPDATE employees SET onboarding_tasks = '{"tasks":[{"task":"Complete IT setup","status":"completed"},{"task":"Financial systems access","status":"in_progress"}]}' WHERE employee_id = 'EMP003';
UPDATE employees SET onboarding_tasks = '{"tasks":[{"task":"Complete IT setup","status":"pending"},{"task":"Marketing tools training","status":"pending"}]}' WHERE employee_id = 'EMP004';
