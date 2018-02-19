-- Anonymizing emails.
UPDATE contact        SET email_address = 'random.email.' || floor(random() * (10000000 - 1000000) + 1000000) || '@bitmedia.com' WHERE email_address IS NOT NULL;
UPDATE password_reset SET email         = 'random.email.' || floor(random() * (10000000 - 1000000) + 1000000) || '@bitmedia.com' WHERE email         IS NOT NULL;
UPDATE registration   SET email         = 'random.email.' || floor(random() * (10000000 - 1000000) + 1000000) || '@bitmedia.com' WHERE email         IS NOT NULL;
UPDATE teacher_signup SET email         = 'random.email.' || floor(random() * (10000000 - 1000000) + 1000000) || '@bitmedia.com' WHERE email         IS NOT NULL;
-- Anonymizing phones.
UPDATE contact        SET phone_number  = '+' || floor(random() * (99999 - 10000) + 10000000000) WHERE phone_number  IS NOT NULL;
UPDATE password_reset SET phone         = '+' || floor(random() * (99999 - 10000) + 10000000000) WHERE phone         IS NOT NULL;
UPDATE registration   SET phone         = '+' || floor(random() * (99999 - 10000) + 10000000000) WHERE phone         IS NOT NULL;
UPDATE teacher_signup SET phone         = '+' || floor(random() * (99999 - 10000) + 10000000000) WHERE phone         IS NOT NULL;
-- Anonymizing full names.
UPDATE person SET firstname  = left(md5(firstname), 7)  WHERE firstname  IS NOT NULL;
UPDATE person SET middlename = left(md5(middlename), 7) WHERE middlename IS NOT NULL;
UPDATE person SET lastname   = left(md5(lastname), 7)   WHERE lastname   IS NOT NULL;
