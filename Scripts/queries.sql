-- A. BASIC QUERIES
--1
UPDATE request
SET title = title || ' (' || TO_CHAR(start_date, 'DD/MM/YYYY') || ' to ' || TO_CHAR(end_date, 'DD/MM/YYYY') || ')';

--2
WITH SkillMatches AS (
    SELECT
        VA.request_id,
        VA.volunteer_id,
        COUNT(SA.skill_name) AS matching_skills
    FROM
        Volunteer_application VA
    JOIN
        Request_skill RS ON VA.request_id = RS.request_id -- match volunteer application with request skill
    LEFT JOIN
        Skill_assignment SA ON VA.volunteer_id = SA.volunteer_id AND RS.skill_name = SA.skill_name -- match volunteer application with volunteer skill & request skill with volunteer skill
    WHERE
        VA.is_valid = TRUE
    GROUP BY
        VA.request_id, VA.volunteer_id
),
AllVolunteers AS (
    SELECT
        VA.request_id,
        VA.volunteer_id,
        COALESCE(SM.matching_skills, 0) AS matching_skills
    FROM
        Volunteer_application VA
    LEFT JOIN
        SkillMatches SM ON VA.request_id = SM.request_id AND VA.volunteer_id = SM.volunteer_id -- left join to include volunteer with 0 matched skill
    WHERE
        VA.is_valid = TRUE
)
SELECT
    R.id AS request_id,
    V.id AS volunteer_id,
    V.name AS volunteer_name,
    AV.matching_skills
FROM
    Request R
JOIN
    AllVolunteers AV ON R.id = AV.request_id
JOIN
    Volunteer V ON AV.volunteer_id = V.id
ORDER BY
    R.id, AV.matching_skills DESC, V.name;

--3
 WITH SkillCoverage AS (
    SELECT
        RS.request_id,
        RS.skill_name,
        RS.min_need,
        COUNT(DISTINCT VA.volunteer_id) AS covered_volunteers
    FROM
        Request_skill RS
    LEFT JOIN
        Skill_assignment SA ON RS.skill_name = SA.skill_name
    LEFT JOIN
        Volunteer_application VA ON SA.volunteer_id = VA.volunteer_id AND VA.request_id = RS.request_id AND VA.is_valid = TRUE
    GROUP BY
        RS.request_id, RS.skill_name, RS.min_need
),
MissingVolunteers AS (
    SELECT
        SC.request_id,
        SC.skill_name,
        SC.min_need,
        SC.min_need - COALESCE(SC.covered_volunteers, 0) AS missing_volunteers
    FROM
        SkillCoverage SC
    WHERE
        SC.min_need - COALESCE(SC.covered_volunteers, 0) > 0
)
SELECT
    R.id AS request_id,
    M.skill_name,
    M.min_need,
    M.missing_volunteers
FROM
    Request R
JOIN
    MissingVolunteers M ON R.id = M.request_id
ORDER BY
    R.id, M.skill_name;

--4
SELECT
    r.id AS request_id,
    b.id AS beneficiary_id,
    b.name,
    r.priority_value,
    r.register_by_date
FROM
    request r
JOIN
    beneficiary b ON r.beneficiary_id = b.id
ORDER BY
    r.priority_value DESC,
    r.register_by_date DESC;

 --5
SELECT v.id AS volunteer_id, r.id AS request_id, r.beneficiary_id, r.number_of_volunteers, r.priority_value,
       r.start_date, r.end_date, r.register_by_date
FROM Volunteer v
JOIN Volunteer_range vr ON v.city_id = vr.city_id
JOIN Request_location rl ON v.city_id = rl.city_id
JOIN Request r ON rl.request_id = r.id
LEFT JOIN Request_skill rs ON r.id = rs.request_id
LEFT JOIN Skill_assignment sa ON v.id = sa.volunteer_id
WHERE (sa.skill_name IS NULL OR rs.skill_name = sa.skill_name)
GROUP BY v.id, r.id
HAVING COUNT(DISTINCT sa.skill_name) >= 2 OR COUNT(DISTINCT rs.skill_name) = 0;

--6
SELECT
    v.id AS volunteer_id,
    r.id AS request_id,
    r.beneficiary_id,
    r.number_of_volunteers,
    r.priority_value,
    r.start_date,
    r.end_date,
    r.register_by_date
FROM
    Volunteer v
JOIN
    Interest_assignment ia ON v.id = ia.volunteer_id
JOIN
    Request r ON r.title LIKE CONCAT('%', LOWER(REGEXP_REPLACE(ia.interest_name, '([a-z])([A-Z])', '\1 \2', 'g')), '%')
WHERE
    r.register_by_date >= CURRENT_DATE;

--7
SELECT R.id AS request_id, V.name, V.email
FROM Request R
JOIN Volunteer_Application VA ON R.id = VA.request_id
JOIN Volunteer V ON VA.volunteer_id = V.id
LEFT JOIN Request_Location RL ON R.id = RL.request_id AND V.city_id = RL.city_id
WHERE RL.request_id IS NULL
ORDER BY V.travel_readiness DESC;

--8
SELECT RS.skill_name, AVG(R.priority_value) AS avg_priority
FROM Request_skill RS
JOIN Request R ON RS.request_id = R.id
GROUP BY RS.skill_name
ORDER BY avg_priority DESC;

--9 Query to Identify Popular Skills Among Volunteers
SELECT SA.skill_name, COUNT(*) AS volunteer_count
FROM Skill_assignment SA
GROUP BY SA.skill_name
ORDER BY volunteer_count DESC;
-- 	This query provides insights into which skills are in high demand among volunteers.
--This information can inform beneficiaries to better align with volunteer interests and expertise.

--10 Query to Determine Volunteer Availability by Age Group:
SELECT
    CASE
        WHEN EXTRACT(YEAR FROM age(V.birthdate)) BETWEEN 18 AND 30 THEN '18-30'
        WHEN EXTRACT(YEAR FROM age(V.birthdate)) BETWEEN 31 AND 45 THEN '31-45'
        WHEN EXTRACT(YEAR FROM age(V.birthdate)) BETWEEN 46 AND 60 THEN '46-60'
        ELSE 'Above 60'
    END AS age_group,
    COUNT(*) AS volunteer_count
FROM Volunteer V
GROUP BY age_group
ORDER BY age_group;
-- This query provides insights into the distribution of volunteer age demographics.
--This information can be useful for beneficiaries to tailor their program to specific age groups.

--11 Query to Identify Requests Requiring Urgent Attention :
SELECT R.id AS request_id, R.register_by_date, B.name AS beneficiary_name
FROM Request R
JOIN Beneficiary B ON R.beneficiary_id = B.id
WHERE R.register_by_date <= CURRENT_DATE + INTERVAL '7 days'
AND R.register_by_date >= CURRENT_DATE
ORDER BY R.register_by_date;
-- This query helps prioritize requests that require immediate attention and action from volunteers and organizations involved in the matching process.

--12
SELECT V.id AS volunteer_id, V.name AS volunteer_name,
       COUNT(DISTINCT SA.skill_name) AS unique_skills_count
FROM Volunteer V
JOIN Skill_assignment SA ON V.id = SA.volunteer_id
GROUP BY V.id, V.name
ORDER BY unique_skills_count DESC;
--This information can be valuable for matching volunteers to requests that require a wide range of expertise.


--B. ADVANCED
--a. Views
--1.
CREATE VIEW BeneficiaryStats AS
SELECT
    b.id AS beneficiary_id,
    b.name AS beneficiary_name,
    AVG(va.volunteer_count) AS avg_volunteers_applied,
    AVG(EXTRACT(YEAR FROM AGE(v.birthdate))) AS avg_age_applied,
    AVG(r.number_of_volunteers) AS avg_volunteers_needed
FROM
    Beneficiary b
JOIN
    Request r ON b.id = r.beneficiary_id
LEFT JOIN
    (SELECT
         request_id,
         COUNT(*) AS volunteer_count
     FROM
         Volunteer_application
     GROUP BY
         request_id) va ON r.id = va.request_id
LEFT JOIN
    Volunteer_application va2 ON r.id = va2.request_id
LEFT JOIN
    Volunteer v ON va2.volunteer_id = v.id
GROUP BY b.id;


--2.
CREATE VIEW CityStats AS
SELECT
    c.id AS city_id,
    c.name AS city_name,
    COUNT(DISTINCT r.request_id) AS num_requests,
    COUNT(DISTINCT vr.volunteer_id) AS num_volunteers,
    CAST(COUNT(DISTINCT vr.volunteer_id) as float) / COUNT(DISTINCT r.request_id) as VtoRratio
FROM
    City c
LEFT JOIN
    Request_location r ON c.id = r.city_id
LEFT JOIN
    Volunteer_range vr ON c.id = vr.city_id
GROUP BY c.id;


--b. Triggers & Functions
--1.
CREATE OR REPLACE FUNCTION validate_volunteer_id(volunteer_id TEXT) RETURNS BOOLEAN AS $$
DECLARE
    date_of_birth TEXT;
    separator_char TEXT;
    individualized_string TEXT;
    control_char TEXT;
   	control_char_got text;
    remainder INT;
BEGIN

    IF LENGTH(volunteer_id) <> 11 THEN
        RETURN FALSE;
    END IF;

    date_of_birth := SUBSTRING(volunteer_id FROM 1 FOR 6);
    separator_char := SUBSTRING(volunteer_id FROM 7 FOR 1);
    individualized_string := SUBSTRING(volunteer_id FROM 8 FOR 3);
    control_char := SUBSTRING(volunteer_id FROM 11 FOR 1);

    IF separator_char NOT IN ('+', '-', 'A', 'B', 'C', 'D', 'E', 'F', 'X', 'Y', 'W', 'V', 'U') THEN
        RETURN FALSE;
    END IF;


    remainder := (CAST(date_of_birth || individualized_string AS BIGINT) % 31);


    control_char_got := CASE
                        WHEN remainder < 10 THEN CAST(remainder AS TEXT)
                        when remainder >= 10 and remainder < 16 then CHR(remainder + 55)
                        when remainder = 16 then 'H'
                        when remainder > 16 and remainder < 22 then CHR(remainder + 57)
                        when remainder = 22 then 'P'
                        ELSE CHR(remainder + 59) -- ASCII value of A = 65, so 10 + 55 = 65 (ASCII value of A)
                      end;

    if control_char_got <> control_char then
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE volunteer
ADD CONSTRAINT valid_volunteer_id CHECK (validate_volunteer_id(id));

--2.

--DROP FUNCTION IF EXISTS update_number_of_volunteers() cascade;
CREATE OR REPLACE FUNCTION update_number_of_volunteers()
RETURNS trigger AS $$
DECLARE
    new_old INT;
BEGIN
    new_old := NEW.min_need - OLD.min_need;
    UPDATE Request
    SET number_of_volunteers = number_of_volunteers + new_old
    WHERE id = NEW.request_id;
   return new;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER update_nof_volunteers
AFTER UPDATE OF min_need ON Request_skill
FOR EACH row
	EXECUTE FUNCTION update_number_of_volunteers();

--c.transaction
START TRANSACTION;

    UPDATE Volunteer_application
    SET modified = CURRENT_TIMESTAMP
    WHERE id = 1;

	UPDATE Volunteer_application
	SET is_valid =
	  CASE
	    WHEN Volunteer_application.modified <= (SELECT register_by_date FROM Request WHERE id = Volunteer_application.request_id) THEN TRUE
	    ELSE FALSE
	  END
	WHERE Volunteer_application.id = 1;

COMMIT;
