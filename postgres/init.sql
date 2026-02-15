-- HR Tables
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    department VARCHAR(100),
    role VARCHAR(100),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE it_provisioning (
    id SERIAL PRIMARY KEY,
    employee_id VARCHAR(50) REFERENCES employees(employee_id),
    okta_user_id VARCHAR(100),
    laptop_assigned BOOLEAN DEFAULT FALSE,
    office365_setup BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- MCP Functions
CREATE OR REPLACE FUNCTION onboard_employee(
    p_employee_id VARCHAR, 
    p_first_name VARCHAR, 
    p_last_name VARCHAR, 
    p_email VARCHAR, 
    p_dept VARCHAR, 
    p_role VARCHAR
) RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    INSERT INTO employees (employee_id, first_name, last_name, email, department, role)
    VALUES (p_employee_id, p_first_name, p_last_name, p_email, p_dept, p_role);
    
    INSERT INTO it_provisioning (employee_id) VALUES (p_employee_id);
    
    SELECT json_build_object(
        'status', 'success',
        'employee_id', p_employee_id,
        'message', 'Employee onboarded successfully',
        'email', p_email,
        'department', p_dept
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_employee(p_employee_id VARCHAR) RETURNS JSON AS $$
BEGIN
    RETURN (
        SELECT json_build_object(
            'employee_id', e.employee_id,
            'name', e.first_name || ' ' || e.last_name,
            'email', e.email,
            'department', e.department,
            'it_provisioned', CASE WHEN i.id IS NOT NULL THEN true ELSE false END
        )
        FROM employees e
        LEFT JOIN it_provisioning i ON e.employee_id = i.employee_id
        WHERE e.employee_id = p_employee_id
    );
END;
$$ LANGUAGE plpgsql;
