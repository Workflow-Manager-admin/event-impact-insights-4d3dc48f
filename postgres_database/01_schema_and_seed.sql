-- PostgreSQL Schema for Event Impact Insights Platform
-- Schema includes: venues, users, events, sustainability metrics, reports, plus auxiliary tables

BEGIN;

-- =================== USERS TABLE ===================
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'venue_admin', -- roles: super_admin, venue_admin, staff
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================== VENUES TABLE ===================
CREATE TABLE venues (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address TEXT,
    city VARCHAR(120),
    state VARCHAR(120),
    country VARCHAR(120),
    postal_code VARCHAR(50),
    phone VARCHAR(60),
    website VARCHAR(255),
    venue_contact_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================== USERS_TO_VENUES (many-to-many) ===================
CREATE TABLE users_venues (
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    venue_id INTEGER REFERENCES venues(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'venue_admin', -- redundancy for venue-specific roles
    PRIMARY KEY (user_id, venue_id)
);

-- =================== EVENTS TABLE ===================
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    venue_id INTEGER NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(120), -- e.g. Conference, Wedding, Expo
    start_date DATE,
    end_date DATE,
    expected_attendees INTEGER,
    actual_attendees INTEGER,
    created_by INTEGER REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================== SUSTAINABILITY METRIC TYPES TABLE ===================
CREATE TABLE sustainability_metric_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    category VARCHAR(120) NOT NULL, -- e.g. Energy, Water, Waste, Transportation
    unit VARCHAR(50) NOT NULL, -- e.g. kWh, kg, liters
    description TEXT,
    is_active BOOLEAN DEFAULT true
);

-- =================== EVENT SUSTAINABILITY METRICS TABLE ===================
CREATE TABLE event_sustainability_metrics (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    metric_type_id INTEGER NOT NULL REFERENCES sustainability_metric_types(id),
    value NUMERIC(16,4) NOT NULL,
    collected_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT,
    UNIQUE(event_id, metric_type_id) -- Only one value per type per event
);

-- =================== REPORTS TABLE ===================
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    event_id INTEGER NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    generated_by INTEGER REFERENCES users(id),
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    summary TEXT,
    report_url VARCHAR(255), -- S3/file link for PDF etc.
    status VARCHAR(50) NOT NULL DEFAULT 'complete' -- draft, complete, error
);

-- =================== METRIC GOALS (venue-specific sustainability targets) ===================
CREATE TABLE sustainability_goals (
    id SERIAL PRIMARY KEY,
    venue_id INTEGER NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    metric_type_id INTEGER NOT NULL REFERENCES sustainability_metric_types(id),
    target_value NUMERIC(16,4) NOT NULL,
    period VARCHAR(20) NOT NULL DEFAULT 'year', -- e.g. year, quarter, event
    notes TEXT,
    UNIQUE(venue_id, metric_type_id, period)
);

-- ============== AUDIT/LOG TABLE (for auxiliary auditing, optional) ==============
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(120) NOT NULL,
    target_table VARCHAR(255),
    target_id INTEGER,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =================== SEED DATA (minimal) ===================

-- 1. Insert some sustainability metric types
INSERT INTO sustainability_metric_types (name, category, unit, description)
VALUES
('Electricity Consumption', 'Energy', 'kWh', 'Total electricity used'),
('Water Usage', 'Water', 'Liters', 'Water consumed during event'),
('Waste Generated', 'Waste', 'Kg', 'Total waste produced'),
('Recycled Waste', 'Waste', 'Kg', 'Amount of waste recycled'),
('CO2 Emissions', 'Transportation', 'KgCO2', 'Estimated carbon footprint');

-- 2. Insert a sample user (hashed password is a dummy value)
INSERT INTO users (email, password_hash, full_name, role)
VALUES
('admin@samplevenue.com', '$2b$12$abcdefghijklmnopqrstuv', 'Venue Admin', 'super_admin'),
('staff@samplevenue.com', '$2b$12$abcdefghijklmnopqrstuv', 'Venue Staff', 'venue_admin');

-- 3. Insert a sample venue
INSERT INTO venues (name, address, city, country, phone, website, venue_contact_id)
VALUES
('Green Conference Center', '123 Leafy Rd', 'Greenville', 'USA', '+15551212345', 'https://greenvenue.com', 1);

-- 4. Map users to venue
INSERT INTO users_venues (user_id, venue_id, role)
VALUES
(1, 1, 'super_admin'),
(2, 1, 'venue_admin');

-- 5. Insert a sample event
INSERT INTO events (venue_id, name, description, event_type, start_date, end_date, expected_attendees, created_by)
VALUES
(1, 'Eco Awareness Summit', 'Annual sustainability summit for corporate clients', 'Conference', '2023-09-10', '2023-09-12', 300, 1);

-- 6. Insert event metric data
INSERT INTO event_sustainability_metrics (event_id, metric_type_id, value, notes)
VALUES
(1, 1, 1800, 'Total electricity for summit'),
(1, 2, 20000, 'Liters of water used'),
(1, 3, 800, 'Total waste generated'),
(1, 4, 500, 'Of which, 500kg was recycled'),
(1, 5, 1200, 'Estimated transportation emissions');

-- 7. Insert a sample report
INSERT INTO reports (event_id, generated_by, summary, status)
VALUES
(1, 1, 'Initial sustainability impact report for Eco Awareness Summit.', 'complete');

-- 8. Insert a sustainability goal for the venue
INSERT INTO sustainability_goals (venue_id, metric_type_id, target_value, period, notes)
VALUES
(1, 1, 1500, 'event', 'Target consumption per event kWh'),
(1, 3, 600, 'event', 'Target waste generated per event');

COMMIT;

-- ===================
-- End Schema + Seed
-- ===================
