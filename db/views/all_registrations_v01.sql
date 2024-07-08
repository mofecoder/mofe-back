SELECT id, contest_id, open_registration, created_at, updated_at, deleted_at, 'individual' as type
FROM registrations

UNION

SELECT id, contest_id, open_registration, created_at, updated_at, deleted_at, 'team' as type
FROM team_registrations
