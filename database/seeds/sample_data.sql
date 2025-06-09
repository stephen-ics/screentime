-- =====================================================
-- SEEDS: sample_data.sql
-- Description: Sample data for development and testing
-- Dependencies: All schema files
-- =====================================================

-- NOTE: This file contains sample data for development/testing only
-- DO NOT run this in production!

-- Check if we're in a development environment
DO $$
BEGIN
    IF current_setting('app.environment', true) = 'production' THEN
        RAISE EXCEPTION 'Sample data should not be loaded in production environment';
    END IF;
END $$;

-- =====================================================
-- SAMPLE APPROVED APPS DATA
-- =====================================================

-- Sample approved apps (common iOS apps)
INSERT INTO approved_apps (name, bundle_identifier, is_enabled, user_id) VALUES
-- Educational apps
('Khan Academy', 'org.khanacademy.Khan-Academy', true, '00000000-0000-0000-0000-000000000001'),
('Duolingo', 'com.duolingo.DuolingoMobile', true, '00000000-0000-0000-0000-000000000001'),
('Photomath', 'com.microblink.PhotoMath', true, '00000000-0000-0000-0000-000000000001'),

-- Creative apps
('GarageBand', 'com.apple.mobilegarageband', true, '00000000-0000-0000-0000-000000000001'),
('Procreate', 'com.savageinteractive.procreate', true, '00000000-0000-0000-0000-000000000001'),

-- Games (time-limited)
('Minecraft', 'com.mojang.minecraftpe', true, '00000000-0000-0000-0000-000000000001'),
('Roblox', 'com.roblox.robloxmobile', true, '00000000-0000-0000-0000-000000000001'),

-- Social/Entertainment (time-limited)
('YouTube', 'com.google.ios.youtube', true, '00000000-0000-0000-0000-000000000001'),
('TikTok', 'com.zhiliaoapp.musically', true, '00000000-0000-0000-0000-000000000001'),
('Instagram', 'com.burbn.instagram', true, '00000000-0000-0000-0000-000000000001')

-- Note: These use placeholder UUIDs. In reality, these would reference actual user IDs
ON CONFLICT (user_id, bundle_identifier) DO NOTHING;

-- =====================================================
-- SAMPLE TASKS DATA
-- =====================================================

-- Sample tasks for earning time
INSERT INTO tasks (title, task_description, reward_seconds, is_recurring, recurring_frequency, assigned_to, created_by) VALUES
-- Daily tasks
('Make your bed', 'Make your bed neatly every morning', 900, true, 'daily', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 15 minutes
('Brush teeth (morning)', 'Brush your teeth thoroughly in the morning', 300, true, 'daily', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 5 minutes
('Brush teeth (evening)', 'Brush your teeth thoroughly before bed', 300, true, 'daily', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 5 minutes

-- Weekly tasks
('Clean your room', 'Vacuum, dust, and organize your room completely', 1800, true, 'weekly', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 30 minutes
('Take out trash', 'Take trash cans to curb and bring them back', 600, true, 'weekly', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 10 minutes

-- Educational tasks
('Read for 30 minutes', 'Read any book of your choice for at least 30 minutes', 1800, true, 'daily', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 30 minutes
('Complete math homework', 'Finish all assigned math homework', 2700, false, null, '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 45 minutes

-- One-time tasks
('Organize closet', 'Sort through clothes and organize your closet', 3600, false, null, '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001'), -- 60 minutes
('Help with grocery shopping', 'Help parent with weekly grocery shopping', 2400, false, null, '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001') -- 40 minutes

-- Note: These use placeholder UUIDs. In reality, these would reference actual user IDs
ON CONFLICT DO NOTHING;

-- =====================================================
-- SAMPLE MIGRATION ENTRIES
-- =====================================================

-- Record sample data migration
INSERT INTO schema_migrations (version, description) 
VALUES ('SEED001', 'Sample data for development and testing')
ON CONFLICT (version) DO NOTHING;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '🌱 Sample data seeded successfully!';
    RAISE NOTICE '📱 % approved apps added', (SELECT count(*) FROM approved_apps WHERE user_id = '00000000-0000-0000-0000-000000000001');
    RAISE NOTICE '📝 % sample tasks added', (SELECT count(*) FROM tasks WHERE created_by = '00000000-0000-0000-0000-000000000001');
    RAISE NOTICE '⚠️  Remember: This is sample data for development only!';
END $$; 