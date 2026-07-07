-- =====================================================
-- SUPABASE SQL MIGRATION SCRIPT
-- Courts and Court Assignments Tables
-- Run this script in your Supabase SQL Editor
-- =====================================================

-- =====================================================
-- 1. CREATE COURTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.courts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    image_url TEXT,
    surface_type VARCHAR(100), -- e.g., 'Clay', 'Hard Court', 'Grass', 'Synthetic'
    is_indoor BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    contact_phone VARCHAR(50),
    contact_email VARCHAR(255),
    hourly_rate DECIMAL(10, 2),
    opening_time VARCHAR(10), -- e.g., '08:00'
    closing_time VARCHAR(10), -- e.g., '22:00'
    amenities JSONB, -- Array of amenities like ['Parking', 'Restrooms', 'Pro Shop']
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_courts_is_active ON public.courts(is_active);
CREATE INDEX IF NOT EXISTS idx_courts_location ON public.courts(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_courts_name ON public.courts(name);

-- Add comments for documentation
COMMENT ON TABLE public.courts IS 'Sports courts available for matches and referee assignments';
COMMENT ON COLUMN public.courts.latitude IS 'Geographic latitude for map display';
COMMENT ON COLUMN public.courts.longitude IS 'Geographic longitude for map display';
COMMENT ON COLUMN public.courts.amenities IS 'JSON array of available amenities';


-- =====================================================
-- 2. CREATE SPORTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.sports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_sports_name ON public.sports(name);
CREATE INDEX IF NOT EXISTS idx_sports_is_active ON public.sports(is_active);

-- Add comments for documentation
COMMENT ON TABLE public.sports IS 'Available sports that can be played at courts';
COMMENT ON COLUMN public.sports.name IS 'Name of the sport (e.g., Tennis, Basketball, Soccer)';


-- =====================================================
-- 3. CREATE COURT_SPORTS TABLE (Junction Table)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.court_sports (
    court_id UUID NOT NULL REFERENCES public.courts(id) ON DELETE CASCADE,
    sport_id UUID NOT NULL REFERENCES public.sports(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Composite primary key to ensure unique court-sport combinations
    PRIMARY KEY (court_id, sport_id)
);

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_court_sports_court ON public.court_sports(court_id);
CREATE INDEX IF NOT EXISTS idx_court_sports_sport ON public.court_sports(sport_id);

-- Add comments for documentation
COMMENT ON TABLE public.court_sports IS 'Many-to-many relationship between courts and sports';


-- =====================================================
-- 4. CREATE COURT ASSIGNMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.court_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    court_id UUID NOT NULL REFERENCES public.courts(id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Admin who made the assignment
    assigned_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    start_date DATE, -- Optional: when assignment becomes effective
    end_date DATE, -- Optional: when assignment expires
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT, -- Additional notes about the assignment
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure a referee can't be assigned to the same court twice (when active)
    CONSTRAINT unique_active_assignment UNIQUE (court_id, referee_id, is_active) 
);

-- Add indexes for common queries
CREATE INDEX IF NOT EXISTS idx_court_assignments_referee ON public.court_assignments(referee_id);
CREATE INDEX IF NOT EXISTS idx_court_assignments_court ON public.court_assignments(court_id);
CREATE INDEX IF NOT EXISTS idx_court_assignments_is_active ON public.court_assignments(is_active);
CREATE INDEX IF NOT EXISTS idx_court_assignments_assigned_by ON public.court_assignments(assigned_by);

-- Add comments for documentation
COMMENT ON TABLE public.court_assignments IS 'Assignments of referees to courts by admin';
COMMENT ON COLUMN public.court_assignments.assigned_by IS 'ID of admin user who created this assignment';


-- =====================================================
-- 5. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on courts table
ALTER TABLE public.courts ENABLE ROW LEVEL SECURITY;

-- Enable RLS on sports table
ALTER TABLE public.sports ENABLE ROW LEVEL SECURITY;

-- Enable RLS on court_sports table
ALTER TABLE public.court_sports ENABLE ROW LEVEL SECURITY;

-- Enable RLS on court_assignments table
ALTER TABLE public.court_assignments ENABLE ROW LEVEL SECURITY;


-- =====================================================
-- 6. CREATE RLS POLICIES FOR COURTS TABLE
-- =====================================================

-- Policy: Anyone can read active courts
CREATE POLICY "Anyone can view active courts"
ON public.courts
FOR SELECT
USING (is_active = TRUE);

-- Policy: Admins can read all courts (including inactive)
CREATE POLICY "Admins can view all courts"
ON public.courts
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can insert courts
CREATE POLICY "Admins can create courts"
ON public.courts
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can update courts
CREATE POLICY "Admins can update courts"
ON public.courts
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can delete courts
CREATE POLICY "Admins can delete courts"
ON public.courts
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);


-- =====================================================
-- 7. CREATE RLS POLICIES FOR SPORTS TABLE
-- =====================================================

-- Policy: Anyone can view active sports
CREATE POLICY "Anyone can view active sports"
ON public.sports
FOR SELECT
USING (is_active = TRUE);

-- Policy: Admins can view all sports (including inactive)
CREATE POLICY "Admins can view all sports"
ON public.sports
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can create sports
CREATE POLICY "Admins can create sports"
ON public.sports
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can update sports
CREATE POLICY "Admins can update sports"
ON public.sports
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can delete sports
CREATE POLICY "Admins can delete sports"
ON public.sports
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);


-- =====================================================
-- 8. CREATE RLS POLICIES FOR COURT_SPORTS TABLE
-- =====================================================

-- Policy: Anyone can view court-sport relationships
CREATE POLICY "Anyone can view court sports"
ON public.court_sports
FOR SELECT
USING (TRUE);

-- Policy: Admins can create court-sport relationships
CREATE POLICY "Admins can assign sports to courts"
ON public.court_sports
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can delete court-sport relationships
CREATE POLICY "Admins can remove sports from courts"
ON public.court_sports
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);


-- =====================================================
-- 9. CREATE RLS POLICIES FOR COURT ASSIGNMENTS TABLE
-- =====================================================

-- Policy: Referees can see their own assignments
CREATE POLICY "Referees can view their own assignments"
ON public.court_assignments
FOR SELECT
TO authenticated
USING (referee_id = auth.uid());

-- Policy: Admins can view all assignments
CREATE POLICY "Admins can view all assignments"
ON public.court_assignments
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can create assignments
CREATE POLICY "Admins can create assignments"
ON public.court_assignments
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can update assignments
CREATE POLICY "Admins can update assignments"
ON public.court_assignments
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);

-- Policy: Admins can delete assignments
CREATE POLICY "Admins can delete assignments"
ON public.court_assignments
FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = auth.uid() 
        AND role = 'admin'
    )
);


-- =====================================================
-- 10. CREATE TRIGGERS FOR updated_at
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for courts table
DROP TRIGGER IF EXISTS update_courts_updated_at ON public.courts;
CREATE TRIGGER update_courts_updated_at
    BEFORE UPDATE ON public.courts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for sports table
DROP TRIGGER IF EXISTS update_sports_updated_at ON public.sports;
CREATE TRIGGER update_sports_updated_at
    BEFORE UPDATE ON public.sports
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for court_assignments table
DROP TRIGGER IF EXISTS update_court_assignments_updated_at ON public.court_assignments;
CREATE TRIGGER update_court_assignments_updated_at
    BEFORE UPDATE ON public.court_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();


-- =====================================================
-- 11. SAMPLE DATA (OPTIONAL - FOR TESTING)
-- Remove or comment out in production
-- =====================================================

-- Insert sample sports
INSERT INTO public.sports (id, name, description, icon_url, is_active)
VALUES 
    ('10000000-0000-0000-0000-000000000001', 'Tennis', 'Racquet sport played on a rectangular court with a net. Popular for singles and doubles matches.', 'sports_tennis', TRUE),
    ('10000000-0000-0000-0000-000000000002', 'Basketball', 'Fast-paced team sport played with a ball and hoops. 5 players per team.', 'sports_basketball', TRUE),
    ('10000000-0000-0000-0000-000000000003', 'Soccer', 'The world''s most popular team sport played with a ball and goals. 11 players per team.', 'sports_soccer', TRUE),
    ('10000000-0000-0000-0000-000000000004', 'Volleyball', 'Team sport played over a net with a ball. 6 players per team.', 'sports_volleyball', TRUE),
    ('10000000-0000-0000-0000-000000000005', 'Badminton', 'Racquet sport played with a shuttlecock over a net. Popular for singles and doubles.', 'sports_badminton', TRUE),
    ('10000000-0000-0000-0000-000000000006', 'Pickleball', 'Paddle sport combining elements of tennis, badminton, and table tennis. Great for all ages.', 'sports_pickleball', TRUE),
    ('10000000-0000-0000-0000-000000000007', 'Padel', 'Racquet sport played in doubles on an enclosed court. Combines tennis and squash elements.', 'sports_padel', TRUE),
    ('10000000-0000-0000-0000-000000000008', 'Futsal', 'Indoor variant of soccer played on a hard court. 5 players per team.', 'sports_futsal', TRUE),
    ('10000000-0000-0000-0000-000000000009', 'Table Tennis', 'Fast-paced racquet sport played on a table with a net. Singles or doubles.', 'sports_table_tennis', TRUE),
    ('10000000-0000-0000-0000-000000000010', 'Squash', 'Racquet sport played in an enclosed court. High intensity workout.', 'sports_squash', TRUE),
    ('10000000-0000-0000-0000-000000000011', 'Handball', 'Team sport where players pass and throw a ball to score goals. 7 players per team.', 'sports_handball', TRUE),
    ('10000000-0000-0000-0000-000000000012', 'Racquetball', 'Racquet sport played in an indoor court. Fast-paced and dynamic.', 'sports_racquetball', TRUE)
ON CONFLICT (name) DO NOTHING;

-- Insert sample courts
INSERT INTO public.courts (id, name, description, address, latitude, longitude, surface_type, is_indoor, is_active, contact_phone, contact_email, hourly_rate, opening_time, closing_time, amenities)
VALUES 
    (
        'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'Mario Court',
        'Premium tennis court with professional-grade surface. Perfect for competitive matches.',
        '123 Sports Ave, Orlando, FL 32801',
        28.5383,
        -81.3792,
        'Hard Court',
        FALSE,
        TRUE,
        '+1 (407) 555-0100',
        'mario@sportsconnect.com',
        35.00,
        '06:00',
        '22:00',
        '["Parking", "Restrooms", "Pro Shop", "Water Fountain", "Lighting"]'
    ),
    (
        'b2c3d4e5-f6a7-8901-bcde-f23456789012',
        'Luigi Indoor Arena',
        'State-of-the-art indoor facility with climate control.',
        '456 Championship Blvd, Orlando, FL 32802',
        28.5500,
        -81.3600,
        'Synthetic',
        TRUE,
        TRUE,
        '+1 (407) 555-0200',
        'luigi@sportsconnect.com',
        50.00,
        '08:00',
        '23:00',
        '["Parking", "Locker Rooms", "Showers", "Cafe", "Equipment Rental"]'
    ),
    (
        'c3d4e5f6-a7b8-9012-cdef-345678901234',
        'Peach Garden Courts',
        'Beautiful outdoor courts surrounded by landscaped gardens.',
        '789 Garden Way, Orlando, FL 32803',
        28.5200,
        -81.4000,
        'Clay',
        FALSE,
        TRUE,
        '+1 (407) 555-0300',
        'peach@sportsconnect.com',
        40.00,
        '07:00',
        '21:00',
        '["Parking", "Restrooms", "Seating Area", "Lighting"]'
    );

-- Assign sports to courts (comprehensive assignment)
INSERT INTO public.court_sports (court_id, sport_id)
VALUES 
    -- Mario Court: Tennis, Pickleball, Badminton (multi-purpose hard court)
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '10000000-0000-0000-0000-000000000001'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '10000000-0000-0000-0000-000000000006'),
    ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', '10000000-0000-0000-0000-000000000005'),
    
    -- Luigi Indoor Arena: Basketball, Volleyball, Badminton, Futsal, Handball (full indoor facility)
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', '10000000-0000-0000-0000-000000000002'),
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', '10000000-0000-0000-0000-000000000004'),
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', '10000000-0000-0000-0000-000000000005'),
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', '10000000-0000-0000-0000-000000000008'),
    ('b2c3d4e5-f6a7-8901-bcde-f23456789012', '10000000-0000-0000-0000-000000000011'),
    
    -- Peach Garden Courts: Tennis, Soccer, Volleyball, Padel (outdoor multi-sport)
    ('c3d4e5f6-a7b8-9012-cdef-345678901234', '10000000-0000-0000-0000-000000000001'),
    ('c3d4e5f6-a7b8-9012-cdef-345678901234', '10000000-0000-0000-0000-000000000003'),
    ('c3d4e5f6-a7b8-9012-cdef-345678901234', '10000000-0000-0000-0000-000000000004'),
    ('c3d4e5f6-a7b8-9012-cdef-345678901234', '10000000-0000-0000-0000-000000000007')
ON CONFLICT (court_id, sport_id) DO NOTHING;

-- Note: To assign courts to referees, you'll need actual referee user IDs
-- Example (replace with actual referee ID):
-- INSERT INTO public.court_assignments (court_id, referee_id, assigned_by)
-- VALUES ('a1b2c3d4-e5f6-7890-abcd-ef1234567890', 'your-referee-user-id', 'your-admin-user-id');


-- =====================================================
-- 12. USEFUL QUERIES FOR ADMIN PANEL (REFERENCE)
-- =====================================================

-- Get all courts with their sports:
-- SELECT c.id, c.name, c.address, 
--        ARRAY_AGG(s.name) as sports
-- FROM courts c
-- LEFT JOIN court_sports cs ON c.id = cs.court_id
-- LEFT JOIN sports s ON cs.sport_id = s.id
-- WHERE c.is_active = TRUE AND (s.is_active = TRUE OR s.id IS NULL)
-- GROUP BY c.id, c.name, c.address;

-- Get all sports available at a specific court:
-- SELECT s.*
-- FROM sports s
-- JOIN court_sports cs ON s.id = cs.sport_id
-- WHERE cs.court_id = 'court-id-here' AND s.is_active = TRUE;

-- Get all courts where a specific sport can be played:
-- SELECT c.*
-- FROM courts c
-- JOIN court_sports cs ON c.id = cs.court_id
-- WHERE cs.sport_id = 'sport-id-here' AND c.is_active = TRUE;

-- Get courts with assignment count and sports:
-- SELECT c.*, 
--        COUNT(DISTINCT ca.id) as assignment_count,
--        ARRAY_AGG(DISTINCT s.name) as sports
-- FROM courts c
-- LEFT JOIN court_assignments ca ON c.id = ca.court_id AND ca.is_active = TRUE
-- LEFT JOIN court_sports cs ON c.id = cs.court_id
-- LEFT JOIN sports s ON cs.sport_id = s.id AND s.is_active = TRUE
-- GROUP BY c.id;

-- Get all courts with assignment count:
-- SELECT c.*, COUNT(ca.id) as assignment_count
-- FROM courts c
-- LEFT JOIN court_assignments ca ON c.id = ca.court_id AND ca.is_active = TRUE
-- GROUP BY c.id;

-- Get referee's assigned courts with court details:
-- SELECT ca.*, c.*
-- FROM court_assignments ca
-- JOIN courts c ON ca.court_id = c.id
-- WHERE ca.referee_id = 'referee-id-here' AND ca.is_active = TRUE;

-- Get all referees assigned to a court:
-- SELECT ca.*, u.name, u.email
-- FROM court_assignments ca
-- JOIN users u ON ca.referee_id = u.id
-- WHERE ca.court_id = 'court-id-here' AND ca.is_active = TRUE;


-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
