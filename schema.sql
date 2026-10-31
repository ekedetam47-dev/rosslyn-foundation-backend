CREATE TABLE IF NOT EXISTS support_requests (
id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

full_name VARCHAR(200) NOT NULL,
relationship VARCHAR(30) NOT NULL
    CHECK (
        relationship IN (
            'myself',
            'family',
            'person-in-care',
            'other'
        )
    ),

date_of_birth DATE NOT NULL,

email VARCHAR(255) NOT NULL,
phone VARCHAR(30) NOT NULL,
location VARCHAR(150) NOT NULL,

service VARCHAR(100) NOT NULL,
details VARCHAR(2500) NOT NULL,

contact_method VARCHAR(20) NOT NULL DEFAULT 'phone'
    CHECK (
        contact_method IN ('phone', 'email', 'either')
    ),

consent BOOLEAN NOT NULL
    CHECK (consent = TRUE),

status VARCHAR(30) NOT NULL DEFAULT 'pending'
    CHECK (
        status IN (
            'pending',
            'reviewing',
            'approved',
            'rejected',
            'closed'
        )
    ),

created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

CONSTRAINT support_details_min_length
    CHECK (char_length(trim(details)) >= 20),

CONSTRAINT support_full_name_not_empty
    CHECK (char_length(trim(full_name)) > 0),

CONSTRAINT support_location_not_empty
    CHECK (char_length(trim(location)) > 0)

);

CREATE INDEX IF NOT EXISTS idx_support_requests_created_at
ON support_requests (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_support_requests_status
ON support_requests (status);
