SELECT * FROM sys.messages WHERE language_id = 1033 AND message_id IN (32044, 32043, 32042, 32040);
EXEC sp_altermessage 32040, 'WITH_LOG', TRUE
EXEC sp_altermessage 32042, 'WITH_LOG', TRUE
EXEC sp_altermessage 32043, 'WITH_LOG', TRUE
EXEC sp_altermessage 32044, 'WITH_LOG', TRUE
SELECT * FROM sys.messages WHERE language_id = 1033 AND message_id IN (32044, 32043, 32042, 32040)