CREATE TABLE drivers (
    driver_id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    phone VARCHAR(15) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    alternate_phone VARCHAR(15),
    referral_code VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    verification_status VARCHAR(20) DEFAULT 'pending',  -- pending, approved, rejected
	  vehicle_id INT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT FALSE
);


CREATE TABLE driver_documents (
    driver_id INT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    license_url TEXT,
    license_expiry DATE,
    rc_book_url TEXT,
    fc_certificate_url TEXT,
	fc_expiry DATE,
    insurance_url TEXT,
    insurance_expiry DATE,
    aadhar_url TEXT,
    pan_number VARCHAR(20),
    eb_bill_url TEXT
);

CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    vehicle_number VARCHAR(20) NOT NULL,
    vehicle_type VARCHAR(20) CHECK (vehicle_type IN ('3-wheeler', '4-wheeler')),
    vehicle_body_length DECIMAL(3,1), -- e.g., 7.0 or 8.0 feet
    vehicle_body_type VARCHAR(10) CHECK (vehicle_body_type IN ('open', 'closed')),
    fuel_type VARCHAR(10) CHECK (fuel_type IN ('diesel', 'petrol', 'ev', 'cng')),
    vehicle_image_url TEXT,

);

CREATE TABLE vehicle_owners (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	vehicle_id INT NOT NULL REFERENCES vehicles(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    aadhar_number VARCHAR(20) NOT NULL,
    contact_number VARCHAR(15) NOT NULL,
    address_line1 TEXT,
    landmark TEXT,
    pincode VARCHAR(10),
    city VARCHAR(50),
    district VARCHAR(50),
    state VARCHAR(50),
);


CREATE TABLE driver_status_log (
    id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    status VARCHAR(20) CHECK (status IN ('online', 'offline', 'on_ride')),
    status_changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE driver_reviews (
    id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL REFERENCES drivers(id),
    booking_id INT NOT NULL,
    rating INT CHECK ,
    review TEXT,
    reviewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE driver_notifications (
    id SERIAL PRIMARY KEY,
    driver_id INT NOT NULL REFERENCES drivers(id),
    type VARCHAR(50), -- e.g., 'license_expiry', 'insurance_expiry', 'ride_offer'
    message TEXT,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE
);


CREATE TABLE driver_referrals (
    referred_by_id INT REFERENCES drivers(id),
    referred_driver_id INT REFERENCES drivers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    referral_code_used VARCHAR(20),
    referral_status VARCHAR(20) DEFAULT 'pending',
    reward_amount NUMERIC(10,2)
    PRIMARY KEY (referred_by_id, referred_driver_id)
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    phone VARCHAR(15) NOT NULL UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    is_business BOOLEAN DEFAULT FALSE,
    referral_code VARCHAR(20),
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE customer_addresses (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    address_line1 TEXT NOT NULL,
    landmark TEXT,
    pincode VARCHAR(10) NOT NULL,
    city VARCHAR(50) NOT NULL,
    district VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    phone_number VARCHAR(15),
    is_default BOOLEAN DEFAULT FALSE
);

CREATE TABLE customer_gst_details (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    gst_number VARCHAR(20) NOT NULL,
    business_name VARCHAR(255),
    business_address TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE customer_referrals (
    referred_by_id INT REFERENCES customers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    referred_customer_id INT REFERENCES customers(id),
    referral_code_used VARCHAR(20),
    referral_status VARCHAR(20) DEFAULT 'pending',
    reward_amount NUMERIC(10,2),
    PRIMARY KEY (referred_by_id, referred_customer_id)
);


--Optional

CREATE TABLE customer_login_sessions (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    device_info TEXT,
    ip_address VARCHAR(50),
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    logout_time TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);


CREATE TABLE bookings (
    id SERIAL PRIMARY KEY
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    pickup_address_id INT REFERENCES customer_addresses(id),
    drop_address_id INT,
    product_type VARCHAR(20) CHECK (product_type IN ('agriculture', 'non-agriculture')),
    booking_type VARCHAR(20) CHECK (booking_type IN ('personal', 'commercial')),
    package_weight DECIMAL(10,2),
    package_dimensions TEXT,             -- store JSON or string like: "LxWxH"
    number_of_packages INT,
    package_description TEXT,
    package_image_url TEXT,
    gst_bill_url TEXT,
    transport_docs_url TEXT, ---list of docs
    estimated_cost NUMERIC(10,2),
    distance_km DECIMAL(10,2),
    disclaimers_acknowledged BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, cancelled, completed,
	Payment_type TEXT -- Cash, Card, UPI

);

CREATE TABLE booking_assignments (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    driver_id INT NOT NULL REFERENCES drivers(id),
    status VARCHAR(20) CHECK (status IN ('offered', 'accepted', 'rejected', 'auto_rejected')),
    response_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE booking_lifecycle_events (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id),
    event_type VARCHAR(50), -- pickup_otp_verified, loading_done, unloading_done
    actor_type VARCHAR(20), -- driver, customer, system
    actor_id INT,           -- nullable for system actions
    photo_url TEXT,
    notes TEXT,
    event_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE booking_tracking (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES bookings(id),
    driver_id INT NOT NULL REFERENCES drivers(id),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE payments (
    id SERIAL PRIMARY KEY,

    booking_id INT NOT NULL REFERENCES bookings(id),
    driver_id INT NOT NULL REFERENCES drivers(id),
    customer_id INT NOT NULL REFERENCES customers(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10,2) NOT NULL,             -- Total paid by customer (incl. tax)
    base_fare NUMERIC(10,2) NOT NULL,
    distance_charge NUMERIC(10,2),
    waiting_charge NUMERIC(10,2),
    extra_charge NUMERIC(10,2),
    discount_applied NUMERIC(10,2) DEFAULT 0,
    tax_amount NUMERIC(10,2) DEFAULT 0,              -- GST or other applicable tax
    commission NUMERIC(10,2) DEFAULT 0,              -- Platform fee
    driver_earnings NUMERIC(10,2),                   -- total - commission - tax (if applicable)
    payout_status VARCHAR(20) DEFAULT 'pending',     -- pending, paid, failed
    payout_mode VARCHAR(20),                         -- upi, bank_transfer, cash
    payout_reference VARCHAR(100),
    payout_date TIMESTAMP,
    paid_by_customer BOOLEAN DEFAULT TRUE,
    customer_payment_mode VARCHAR(20),               -- upi, card, cash
    payment_gateway_response TEXT
);

CREATE TABLE pending_driver_payments (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    driver_id INT NOT NULL REFERENCES drivers(id),
    booking_id INT REFERENCES bookings(id),  -- optional: null if not booking-related
    amount NUMERIC(10,2) NOT NULL,           -- always positive
    direction VARCHAR(10) NOT NULL CHECK (direction IN ('to_driver', 'from_driver')),
    reason VARCHAR(50),                      -- e.g., 'ride_earning', 'penalty', 'bonus', 'commission_adjustment'
	payout_mode VARCHAR(20),                 -- upi, bank_transfer
    payout_reference VARCHAR(100),
    payout_status VARCHAR(20) DEFAULT 'pending'  -- pending, processed, failed
);
