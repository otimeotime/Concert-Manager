-- =============================================================================
-- Part 1: Create Database and Tables
-- Source: DB/src/create_database.sql
-- =============================================================================

CREATE DATABASE ConcertManagement;

\c ConcertManagement;

CREATE TABLE Audience (
	audience_id CHAR(6) NOT NULL,
	last_name VARCHAR(100) NOT NULL,
	first_name VARCHAR(100) NOT NULL,
	dob DATE NOT NULL,
	username VARCHAR(1000) NOT NULL UNIQUE,
	pass_word VARCHAR(1000) NOT NULL,
	special_condition VARCHAR(10000),
	CONSTRAINT pk_audience PRIMARY KEY (audience_id)
);

CREATE TABLE Venue(
	venue_id CHAR(6) NOT NULL,
	venue_name VARCHAR(20) NOT NULL, 
	capacity INT DEFAULT 0,
	destination VARCHAR(100) NOT NULL,
	CONSTRAINT pk_venue PRIMARY KEY (venue_id),
	CONSTRAINT check_capacity CHECK(capacity >= 0)
);

CREATE TABLE Technicle(
	technicle_id CHAR(6) NOT NULL,
	team_size INT DEFAULT 0,
	mixing_quantity INT DEFAULT 1,
	microphone_quantity INT DEFAULT 1,
	monitor_quantity INT DEFAULT 1,
	pa_quantity INT DEFAULT 1,
	CONSTRAINT pk_technicle PRIMARY KEY (technicle_id),
	CONSTRAINT check_quantity CHECK(team_size >= 0 AND mixing_quantity >= 1 AND microphone_quantity >= 1 AND monitor_quantity >= 1 AND pa_quantity >= 1)
);

CREATE TABLE Broadcast(
	technicle_id CHAR(6) NOT NULL,
	platform CHAR(3) NOT NULL,
	CONSTRAINT pk_broadcast PRIMARY KEY (technicle_id, platform),
	CONSTRAINT fk_technicle FOREIGN KEY (technicle_id) REFERENCES Technicle(technicle_id)
);

CREATE TABLE Concert (
	concert_id CHAR(6) NOT NULL,
	concert_name VARCHAR(100) NOT NULL,
	event_date date NOT NULL,
	start_time time NOT NULL,
	end_time time NOT NULL,
	age_restriction INT DEFAULT 0,
	venue_id CHAR(6) NOT NULL,
	technicle_id CHAR(6) NOT NULL,
	CONSTRAINT pk_concert PRIMARY KEY (concert_id),
	CONSTRAINT fk_venue FOREIGN KEY (venue_id) REFERENCES Venue(venue_id),
	CONSTRAINT fk_technicle FOREIGN KEY (technicle_id) REFERENCES Technicle(technicle_id),
	CONSTRAINT check_concert CHECK(start_time < end_time AND age_restriction >= 0)
);

CREATE TABLE Ticket (
	ticket_id CHAR(6) NOT NULL,
	ticket_rank VARCHAR(10) NOT NULL,
	lim	INT	NOT NULL DEFAULT 0,
	lim_one_person INT NOT NULL DEFAULT 1,
	price INT NOT NULL DEFAULT 0,
	concert_id CHAR(6) NOT NULL,
	quantity INT NOT NULL,
	CONSTRAINT pk_ticket PRIMARY KEY(ticket_id, concert_id),
	CONSTRAINT fk_concert FOREIGN KEY (concert_id) REFERENCES Concert(concert_id),
	CONSTRAINT check_ticket CHECK ((ticket_rank IN ('Normal', 'Vip', 'Luxury') AND price > 0 AND lim >= 0 AND lim_one_person >= 1))
);

CREATE TABLE Own (
	ticket_id CHAR(6) NOT NULL,
	audience_id CHAR(6) NOT NULL,
	buy_date DATE NOT NULL,
	quantity INT NOT NULL,
	CONSTRAINT pk_own PRIMARY KEY (ticket_id, audience_id, buy_date),
	CONSTRAINT fk_ticket FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id),
	CONSTRAINT fk_audience FOREIGN KEY (audience_id) REFERENCES Audience(audience_id)
);

CREATE TABLE Brand (
	brand_id CHAR(6) NOT NULL,
	brand_name VARCHAR(100) NOT NULL,
	CONSTRAINT pk_brand PRIMARY KEY (brand_id)
);

CREATE TABLE Sponsor (
	concert_id CHAR(6) NOT NULL,
	brand_id CHAR(6) NOT NULL,
	sponsor_rank VARCHAR(10) NOT NULL,
	CONSTRAINT pk_sponsor PRIMARY KEY (concert_id, brand_id),
	CONSTRAINT fk_concert FOREIGN KEY (concert_id) REFERENCES Concert(concert_id),
	CONSTRAINT fk_brand FOREIGN KEY (brand_id) REFERENCES Brand(brand_id),
	CONSTRAINT check_sponsor_rank CHECK (sponsor_rank IN ('Bronze', 'Silver', 'Gold', 'Diamond'))	
);

CREATE TABLE Artist (
	artist_id CHAR(6) NOT NULL,
	stage_name VARCHAR(100),
	last_name VARCHAR(100) NOT NULL,
	first_name VARCHAR(100) NOT NULL,
	dob DATE NOT NULL,
	CONSTRAINT pk_artist PRIMARY KEY (artist_id)
);

CREATE TABLE Performance (
	performance_id CHAR(6) NOT NULL,
	song_name VARCHAR(100) NOT NULL,
	author VARCHAR(100) NOT NULL,
	dance_team VARCHAR(100) NOT NULL,
	duration INTERVAL NOT NULL,
	age_restriction INT DEFAULT 0,
	require_mixing INT DEFAULT 1,
	require_pa INT DEFAULT 1,
	require_monitor INT DEFAULT 1,
	require_microphone INT DEFAULT 1,
	concert_id CHAR(6) NOT NULL,
	CONSTRAINT pk_performance PRIMARY KEY (performance_id),
	CONSTRAINT fk_concert FOREIGN KEY (concert_id) REFERENCES Concert(concert_id),
	CONSTRAINT check_performance CHECK (duration > '0 seconds' AND require_mixing >= 1 AND require_pa >= 1 AND require_monitor >= 1 AND require_microphone >= 1 AND age_restriction >= 0)
);

CREATE TABLE Act (
	artist_id CHAR(6) NOT NULL,
	performance_id CHAR(6) NOT NULL,
	CONSTRAINT pk_act PRIMARY KEY (artist_id, performance_id),
	CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES Artist(artist_id),
	CONSTRAINT fk_performance FOREIGN KEY (performance_id) REFERENCES Performance(performance_id)
);

CREATE TABLE Contract (
	concert_id CHAR(6) NOT NULL,
	artist_id CHAR(6) NOT NULL,
	time_limit INTERVAL NOT NULL,
	fee INT NOT NULL,
	CONSTRAINT pk_contract PRIMARY KEY (concert_id, artist_id),
	CONSTRAINT fk_concert FOREIGN KEY (concert_id) REFERENCES Concert(concert_id),
	CONSTRAINT fk_artist FOREIGN KEY (artist_id) REFERENCES Artist(artist_id)
); 

-- =============================================================================
-- Part 2: Create Functions
-- Source: DB/src/function.sql
-- =============================================================================

CREATE OR REPLACE FUNCTION BuyTicket(IN tid CHAR(6), IN aid CHAR(6), IN amount INT) 
RETURNS VOID AS $$
DECLARE
	concert_date DATE;
	cid CHAR(6);
	concert_age_restriction INT;
	audience_age INT;
BEGIN
	SELECT concert_id INTO cid
	FROM Ticket t
	WHERE t.ticket_id = tid;
	
	SELECT event_date, age_restriction INTO concert_date, concert_age_restriction
	FROM Concert c
	WHERE c.concert_id = cid;

	SELECT EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM dob) INTO audience_age
	FROM Audience
	WHERE audience_id = aid;

	IF (concert_date < CURRENT_DATE) THEN
		RAISE EXCEPTION 'The ticket is unavailable';
	END IF;

	IF (concert_age_restriction > audience_age) THEN
		RAISE EXCEPTION 'Age restriction violated';
	END IF;
	
	INSERT INTO Own (audience_id, ticket_id, buy_date, quantity)
	VALUES (aid, tid, CURRENT_DATE, amount);
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION RemoveTicket(IN tid CHAR(6), IN aid CHAR(6), IN buydate DATE, IN amount INT) 
RETURNS VOID AS $$
DECLARE q INT;
BEGIN 
	SELECT quantity INTO q
	FROM Own
	WHERE tid = ticket_id AND aid = audience_id AND buy_date = buydate;
	
	IF (amount = 0) THEN
		DELETE FROM Own
		WHERE tid = ticket_id AND aid = audience_id AND buy_date = buydate;
	ELSEIF (amount = q) THEN
		RETURN;
	ELSE 
		UPDATE Own
		SET quantity = quantity - amount
		WHERE (tid = ticket_id AND aid = audience_id AND buy_date = buydate); 
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewAudienceArtist(IN aid CHAR(6), IN cid CHAR(6))
RETURNS TABLE(dob DATE) AS $$
DECLARE
    pass CHAR(6);
BEGIN
    -- Verify if the sponsor exists
    SELECT concert_id INTO pass
    FROM Contract
    WHERE artist_id = aid AND concert_id = cid;

    -- If no match is found, raise an exception
    IF (pass IS NULL) THEN
        RAISE EXCEPTION 'Sponsor does not participate in concert %', cid;
    END IF;

    -- Return the audience's date of birth
    RETURN QUERY
    SELECT DISTINCT a.dob
    FROM Own o
    JOIN Ticket t USING(ticket_id)
    JOIN Audience a USING(audience_id)
    WHERE t.concert_id = cid;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION ViewAudienceSponsor(IN bid CHAR(6), IN cid CHAR(6))
RETURNS TABLE(dob DATE) AS $$
DECLARE
    pass CHAR(6);
BEGIN
    -- Verify if the sponsor exists
    SELECT concert_id INTO pass
    FROM Sponsor
    WHERE brand_id = bid AND concert_id = cid;

    -- If no match is found, raise an exception
    IF (pass IS NULL) THEN
        RAISE EXCEPTION 'Sponsor does not participate in concert %', cid;
    END IF;

    -- Return the audience's date of birth
    RETURN QUERY
    SELECT DISTINCT a.dob
    FROM Own o
    JOIN Ticket t USING(ticket_id)
    JOIN Audience a USING(audience_id)
    WHERE t.concert_id = cid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewArtist_Artist(aid CHAR(6), cid CHAR(6))
RETURNS TABLE(
    artist_id CHAR(6),
    stage_name VARCHAR(100),
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    dob DATE
) AS $$
DECLARE
    valid_artist CHAR(6);
BEGIN
    -- Validation: Ensure the artist is contracted for the concert
    SELECT c.artist_id INTO valid_artist
    FROM Contract c
    WHERE c.artist_id = aid AND c.concert_id = cid;

    -- If no valid artist found, raise an exception
    IF valid_artist IS NULL THEN
        RAISE EXCEPTION 'Artist % is not contracted for concert %', aid, cid;
    END IF;

    -- Return list of all artists performing in the concert
    RETURN QUERY
    SELECT a.artist_id, a.stage_name, a.last_name, a.first_name, a.dob
    FROM Contract ac
    JOIN Artist a ON ac.artist_id = a.artist_id
    WHERE ac.concert_id = cid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewArtist_Sponsor(bid CHAR(6), cid CHAR(6))
RETURNS TABLE(artist_id CHAR(6), stage_name VARCHAR(100), last_name VARCHAR(100), first_name VARCHAR(100), dob DATE) AS $$
DECLARE
    valid_brand CHAR(6);
BEGIN
    -- Validation: Ensure the brand is sponsoring the concert
    SELECT brand_id INTO valid_brand
    FROM Sponsor
    WHERE brand_id = bid AND concert_id = cid;

    IF valid_brand IS NULL THEN
        RAISE EXCEPTION 'Brand % is not sponsoring concert %', bid, cid;
    END IF;

    -- Return list of all artists performing in the concert
    RETURN QUERY
    SELECT a.artist_id, a.stage_name, a.last_name, a.first_name, a.dob
    FROM Contract ac
    JOIN Artist a ON ac.artist_id = a.artist_id
    WHERE ac.concert_id = cid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewSponsor_Artist(aid CHAR(6), cid CHAR(6))
RETURNS TABLE(brand_id CHAR(6), brand_name VARCHAR(100), sponsor_rank VARCHAR(10)) AS $$
DECLARE
    valid_artist CHAR(6);
BEGIN
    -- Validation: Ensure the artist is part of the concert
    SELECT artist_id INTO valid_artist
    FROM Contract
    WHERE artist_id = aid AND concert_id = cid;

    IF valid_artist IS NULL THEN
        RAISE EXCEPTION 'Artist % is not contracted for concert %', aid, cid;
    END IF;

    -- Return list of sponsors for the concert
    RETURN QUERY
    SELECT s.brand_id, b.brand_name, s.sponsor_rank
    FROM Sponsor s
    JOIN Brand b ON s.brand_id = b.brand_id
    WHERE s.concert_id = cid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewSponsor_Sponsor(bid CHAR(6), cid CHAR(6))
RETURNS TABLE(brand_id CHAR(6), brand_name VARCHAR(100), sponsor_rank VARCHAR(10)) AS $$
DECLARE
    valid_brand CHAR(6);
BEGIN
    -- Validation: Ensure the sponsor brand is valid
    SELECT s.brand_id INTO valid_brand
    FROM Sponsor s
    WHERE s.brand_id = bid AND s.concert_id = cid;

    IF valid_brand IS NULL THEN
        RAISE EXCEPTION 'Brand % is not sponsoring concert %', bid, cid;
    END IF;

    -- Return list of sponsors for the concert
    RETURN QUERY
    SELECT s.brand_id, b.brand_name, s.sponsor_rank
    FROM Sponsor s
    JOIN Brand b ON s.brand_id = b.brand_id
    WHERE s.concert_id = cid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewInfoAudience(aid CHAR(6))
RETURNS TABLE(
    audience_id CHAR(6), 
    last_name VARCHAR(100), 
    first_name VARCHAR(100), 
    dob DATE, 
    username VARCHAR(1000), 
    special_condition VARCHAR(10000)
) AS $$
DECLARE
    user_match BOOLEAN;
BEGIN


    -- Return audience details
    RETURN QUERY
    SELECT a.audience_id, a.last_name, a.first_name, a.dob, a.username, a.special_condition
    FROM Audience a
    WHERE a.audience_id = aid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION ViewTicket(aid CHAR(6), cid CHAR(6))
RETURNS TABLE(
    ticket_id CHAR(6), 
    ticket_rank VARCHAR(10), 
    price INT, 
    quantity INT, 
    buy_date DATE
) AS $$
DECLARE
    user_match BOOLEAN;
BEGIN
    -- Validate if the CURRENT_USER matches the username for the given audience ID
    SELECT EXISTS (
        SELECT 1 
        FROM Audience a
        WHERE a.audience_id = aid AND LOWER(a.username) = LOWER(CURRENT_USER)
    ) INTO user_match;

    -- If no match, raise an exception
    IF NOT user_match THEN
        RAISE EXCEPTION 'Access Denied: You can only view your own ticket information.';
    END IF;

    -- Return ticket details for the user and concert
    RETURN QUERY
    SELECT t.ticket_id, t.ticket_rank, t.price, o.quantity, o.buy_date
    FROM Own o
    JOIN Ticket t ON o.ticket_id = t.ticket_id
    WHERE o.audience_id = aid AND t.concert_id = cid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION SearchConcertByName(concert_name_input VARCHAR)
RETURNS TABLE(
    concert_id CHAR(6), 
    concert_name VARCHAR(100), 
    event_date DATE, 
    start_time TIME, 
    end_time TIME, 
    age_restriction INT, 
    venue_id CHAR(6), 
    technicle_id CHAR(6)
) AS $$
BEGIN
    -- Return all concerts matching (or partially matching) the given name
    RETURN QUERY
    SELECT 
        c.concert_id, 
        c.concert_name, 
        c.event_date, 
        c.start_time, 
        c.end_time, 
        c.age_restriction, 
        c.venue_id, 
        c.technicle_id
    FROM Concert c
    WHERE LOWER(c.concert_name) LIKE LOWER('%' || concert_name_input || '%');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SearchArtistByNameAndConcert(
    artist_name_input VARCHAR,
    concert_name_input VARCHAR
)
RETURNS TABLE(
    artist_id CHAR(6),
    stage_name VARCHAR(100),
    last_name VARCHAR(100),
    first_name VARCHAR(100),
    dob DATE,
    concert_id CHAR(6),
    concert_name VARCHAR(100)
) AS $$
BEGIN
    -- Return artists matching the given artist and concert names
    RETURN QUERY
    SELECT 
        a.artist_id,
        a.stage_name,
        a.last_name,
        a.first_name,
        a.dob,
        c.concert_id,
        c.concert_name
    FROM Artist a
    JOIN Act ac ON a.artist_id = ac.artist_id
    JOIN Performance p ON ac.performance_id = p.performance_id
    JOIN Concert c ON p.concert_id = c.concert_id
    WHERE LOWER(a.stage_name) LIKE LOWER('%' || artist_name_input || '%')
      AND LOWER(c.concert_name) LIKE LOWER('%' || concert_name_input || '%');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION SearchSponsorByNameAndConcert(
    sponsor_name_input VARCHAR,
    concert_name_input VARCHAR
)
RETURNS TABLE(
    brand_id CHAR(6),
    brand_name VARCHAR(100),
    sponsor_rank VARCHAR(10),
    concert_id CHAR(6),
    concert_name VARCHAR(100)
) AS $$
BEGIN
    -- Return sponsors matching the given sponsor and concert names
    RETURN QUERY
    SELECT 
        b.brand_id,
        b.brand_name,
        s.sponsor_rank,
        c.concert_id,
        c.concert_name
    FROM Brand b
    JOIN Sponsor s ON b.brand_id = s.brand_id
    JOIN Concert c ON s.concert_id = c.concert_id
    WHERE LOWER(b.brand_name) LIKE LOWER('%' || sponsor_name_input || '%')
      AND LOWER(c.concert_name) LIKE LOWER('%' || concert_name_input || '%');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION ViewConcert_Sponsor(IN bid char(6))
RETURNS TABLE (concert_id CHAR(6), event_date DATE, start_time TIME, end_time TIME, age_restriction INT, venue_name VARCHAR(20), technicle_id CHAR(6)) AS $$
BEGIN
	RETURN QUERY
	SELECT c.concert_id, c.event_date, c.start_time, c.end_time, c.age_restriction, v.venue_name, c.technicle_id
	FROM Concert c JOIN Sponsor s USING(concert_id) JOIN venue v USING(venue_id)
	WHERE s.brand_id = bid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Register(IN lastname VARCHAR(100), firstname VARCHAR(100), IN dateobirth DATE, IN uname VARCHAR(1000), IN pw VARCHAR(100))
RETURNS VOID AS $$
DECLARE 
	max_id CHAR(6);
	max_idd INT;
BEGIN
	SELECT MAX(audience_id) INTO max_id
	FROM audience;
	max_idd := CAST(max_id as INT);

	INSERT INTO Audience (audience_id, last_name, first_name, dob, username, pass_word, join_date)
	VALUES (CAST(max_idd+1 as CHAR(6)), lastname, firstname, dateobirth, uname, pw, CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_artist_audience(IN cid VARCHAR(6))
RETURNS TABLE (stage_name VARCHAR(100)) AS $$
BEGIN
	RETURN QUERY
		SELECT a.stage_name
		FROM artist a JOIN contract cc USING(artist_id)
		WHERE cid = cc.concert_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Part 3: Create Triggers
-- Source: DB/src/trigger_function.sql
-- =============================================================================

--CONCERT TRIGGERS
--Update concert age restriction when performance added to a concert
CREATE OR REPLACE FUNCTION Concert_age_restriction_update()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Concert c
    SET age_restriction = (
        SELECT MAX(p.age_restriction)
        FROM Performance p
        WHERE p.concert_id = c.concert_id
    )
    WHERE c.concert_id IN (
        SELECT DISTINCT concert_id
        FROM Performance
        WHERE concert_id = c.concert_id
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Concert_age_restriction
AFTER INSERT OR UPDATE OR DELETE ON Performance
FOR EACH STATEMENT 
EXECUTE FUNCTION Concert_age_restriction_update();
--Check if venue is already planned
CREATE OR REPLACE FUNCTION venue_technicle_check()
RETURNS TRIGGER AS $$
DECLARE
    endtime TIME;
BEGIN
    -- Check Venue Availability
    FOR endtime IN (SELECT c.end_time FROM Concert c WHERE c.venue_id = NEW.venue_id AND c.event_date = NEW.event_date) LOOP
        IF endtime > NEW.start_time THEN
            RAISE EXCEPTION 'Venue is already planned';
        ELSIF (NEW.start_time - endtime) <= interval '5 hours' THEN
            RAISE EXCEPTION 'Venue cannot recover after the previous concert';
        END IF;
    END LOOP;

    -- Check Technicle Team Availability
    FOR endtime IN (SELECT c.end_time FROM Concert c WHERE c.technicle_id = NEW.technicle_id) LOOP
        IF endtime > NEW.start_time THEN
            RAISE EXCEPTION 'Technicle team is already planned';
        ELSIF (NEW.start_time - endtime) <= interval '5 hours' THEN
            RAISE EXCEPTION 'Technicle team cannot recover after the previous concert';
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER concert_check
BEFORE INSERT OR UPDATE ON Concert
FOR EACH ROW
EXECUTE FUNCTION venue_technicle_check();

--AUDIENCE TRIGGERS
--Create new login user whenever new row is added
CREATE OR REPLACE FUNCTION create_login_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Create the login role
    EXECUTE format(
        'CREATE ROLE %I WITH LOGIN PASSWORD %L IN ROLE Audience;',
        NEW.username,
        NEW.pass_word
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

--Delete account 
CREATE OR REPLACE FUNCTION delete_audience_roles()
RETURNS TRIGGER AS $$
DECLARE
    r RECORD;
BEGIN
    -- Loop through all roles in the 'audience' group and drop them
    FOR r IN 
        SELECT member::regrole AS role_name 
        FROM pg_auth_members 
        WHERE roleid = 'audience'::regrole 
          AND member::regrole = OLD.username::regrole
    LOOP
        EXECUTE format('DROP ROLE IF EXISTS %I', r.role_name);
    END LOOP;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;


-- Trigger
CREATE TRIGGER trg_delete_audience_role
AFTER DELETE ON Audience
FOR EACH ROW
EXECUTE FUNCTION delete_audience_role();



CREATE TRIGGER trigger_create_login_role
AFTER INSERT ON Audience
FOR EACH ROW
EXECUTE FUNCTION create_login_role();

--If an andience has special condition that attempt to buy a ticket, 
--he/she need to be approved by the director
CREATE OR REPLACE FUNCTION Audience_special_condition_constraint()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Audience a
        WHERE a.audience_id = NEW.audience_id AND a.special_condition IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Insertion not allowed: Audience has a special condition.';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER Audience_special_condition
BEFORE INSERT ON Own
FOR EACH ROW
EXECUTE FUNCTION Audience_special_condition_constraint();


--OWN TRIGGERS
--If an audience buy the same ticket on the same date, we just update the quantity
CREATE OR REPLACE FUNCTION Own_quantity_update()
RETURNS TRIGGER AS $$
DECLARE
    existing_quantity INT;
BEGIN
    SELECT quantity INTO existing_quantity
    FROM Own
    WHERE buy_date = NEW.buy_date
    LIMIT 1;
    
    IF FOUND THEN
        UPDATE Own
        SET quantity = quantity + NEW.quantity
        WHERE buy_date = NEW.buy_date;
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Own_quantity
BEFORE INSERT ON Own
FOR EACH ROW
EXECUTE FUNCTION Own_quantity_update();

--Update ticket quantity when delete Own entry
CREATE OR REPLACE FUNCTION Own_delete_update_ticket()
RETURNS TRIGGER AS $$
BEGIN
	UPDATE Ticket
	SET quantity = quantity + OLD.quantity
	WHERE OLD.ticket_id = ticket_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Own_delete_update_ticket
AFTER DELETE ON Own
FOR EACH ROW
EXECUTE FUNCTION Own_delete_update_ticket();

--Update the ticket and own quantity when decrease or delete all of ticket
CREATE OR REPLACE FUNCTION Own_decrease_ticket() 
RETURNS TRIGGER AS $$
BEGIN
	IF(NEW.quantity = OLD.quantity) THEN
		DELETE FROM Own
		WHERE (OLD.ticket_id = Own.ticket_id AND OLD.audience_id = Own.audience_id AND OLD.buy_date = Own.buy_date);
	END IF;

	UPDATE Ticket
	SET quantity = quantity + (OLD.quantity - NEW.quantity)
	WHERE ticket_id = NEW.ticket_id;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER Own_decrease_ticket
AFTER UPDATE ON Own
FOR EACH ROW
EXECUTE FUNCTION Own_decrease_ticket();

--PERFORMANCE TRIGGERS
--Check the requirement of the performance if it's fullfiled yet
CREATE OR REPLACE FUNCTION Performance_requirement_fullfil()
RETURNS TRIGGER AS $$
DECLARE
    technicle_mixing INT;
    technicle_pa INT;
    technicle_monitor INT;
    technicle_microphone INT;
    technicle_id_local CHAR(6);
    concert_time INTERVAL;
    total_performance_time INTERVAL;
BEGIN
    -- Get the Technicle ID associated with the Concert
    SELECT c.technicle_id
    INTO technicle_id_local
    FROM Concert c
    WHERE c.concert_id = NEW.concert_id;

    -- Validate if the Concert exists
    IF technicle_id_local IS NULL THEN
        RAISE EXCEPTION 'Invalid concert_id: No associated concert found.';
    END IF;

    -- Get the Technicle equipment capacities
    SELECT t.mixing_quantity, t.pa_quantity, t.monitor_quantity, t.microphone_quantity
    INTO technicle_mixing, technicle_pa, technicle_monitor, technicle_microphone
    FROM Technicle t
    WHERE t.technicle_id = technicle_id_local;

    -- Validate Requirements Against Technicle Capacities
    IF NEW.require_mixing > technicle_mixing THEN
        RAISE EXCEPTION 'Requirement Error: Required mixing exceeds available capacity (% > %).', NEW.require_mixing, technicle_mixing;
    END IF;

    IF NEW.require_pa > technicle_pa THEN
        RAISE EXCEPTION 'Requirement Error: Required PA exceeds available capacity (% > %).', NEW.require_pa, technicle_pa;
    END IF;

    IF NEW.require_monitor > technicle_monitor THEN
        RAISE EXCEPTION 'Requirement Error: Required monitor exceeds available capacity (% > %).', NEW.require_monitor, technicle_monitor;
    END IF;

    IF NEW.require_microphone > technicle_microphone THEN
        RAISE EXCEPTION 'Requirement Error: Required microphone exceeds available capacity (% > %).', NEW.require_microphone, technicle_microphone;
    END IF;

    -- Validate Concert Duration
    SELECT (end_time - start_time)
    INTO concert_time
    FROM Concert
    WHERE concert_id = NEW.concert_id;

    IF concert_time IS NULL THEN
        RAISE EXCEPTION 'Concert Error: Start or end time for concert is not defined.';
    END IF;

    -- Calculate the adjusted total performance time
    SELECT COALESCE(SUM(p.duration), '0 seconds'::interval)
    INTO total_performance_time
    FROM Performance p
    WHERE p.concert_id = NEW.concert_id
      AND p.performance_id != NEW.performance_id; -- Exclude the current performance

    -- Add the new performance duration
    total_performance_time := total_performance_time + NEW.duration;

    -- Validate Total Performance Time
    IF total_performance_time > concert_time THEN
        RAISE EXCEPTION 'Total Duration Error: Combined performance duration (%) exceeds concert duration (%).',
            total_performance_time, concert_time;
    END IF;

    -- If all checks pass, allow the operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER Performance_requirement
BEFORE UPDATE OR INSERT ON Performance
FOR EACH ROW 
EXECUTE FUNCTION Performance_requirement_fullfil();

--CONTRACT TRIGGERS
--Check if the time_limit of an artist exceed the time to hold the concert
CREATE OR REPLACE FUNCTION validate_contract_time_limit()
RETURNS TRIGGER AS $$
DECLARE
    concert_duration INTERVAL;
    total_time_limit INTERVAL;
BEGIN
    -- Fetch concert duration
    SELECT (end_time - start_time) INTO concert_duration
    FROM Concert
    WHERE concert_id = NEW.concert_id;

    -- Check if the concert exists
    IF concert_duration IS NULL THEN
        RAISE EXCEPTION 'Invalid concert_id: No associated concert found.';
    END IF;

    -- Calculate the total time limit of all existing contracts for the concert
    SELECT COALESCE(SUM(time_limit), INTERVAL '0 seconds') INTO total_time_limit
    FROM Contract
    WHERE concert_id = NEW.concert_id AND artist_id != NEW.artist_id;

    -- Add the new artist's time limit
    total_time_limit := total_time_limit + NEW.time_limit;

    -- Validate total time limit against concert duration
    IF total_time_limit > concert_duration THEN
        RAISE EXCEPTION 'Contract Error: Total artist time limit (%) exceeds concert duration (%).',
        total_time_limit, concert_duration;
    END IF;

    -- Allow the operation if validation passes
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER validate_contract_time_limit_trigger
BEFORE INSERT OR UPDATE ON Contract
FOR EACH ROW
EXECUTE FUNCTION validate_contract_time_limit();


--TICKET TRIGGERS
--Make sure the number of ticket to sell doesn't exceed the venue capacity and existed ticket class
CREATE OR REPLACE FUNCTION check_ticket_limit()
RETURNS TRIGGER AS $$
DECLARE
    venue_capacity INT;
    existing_ticket_sum INT;
BEGIN
    -- Skip the check if only the quantity column is being updated
    IF TG_OP = 'UPDATE' AND OLD.lim = NEW.lim THEN
        RETURN NEW;
    END IF;

    -- Get the capacity of the venue for the concert
    SELECT v.capacity
    INTO venue_capacity
    FROM Venue v
    JOIN Concert c ON v.venue_id = c.venue_id
    WHERE c.concert_id = NEW.concert_id;

    -- Calculate the sum of existing ticket limits for the concert
    SELECT COALESCE(SUM(lim), 0)
    INTO existing_ticket_sum
    FROM Ticket
    WHERE concert_id = NEW.concert_id;

    -- Check if the new ticket limit exceeds the remaining venue capacity
    IF (existing_ticket_sum + NEW.lim) > venue_capacity THEN
        RAISE EXCEPTION 'Total ticket limit exceeds venue capacity';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER trg_check_ticket_limit
BEFORE UPDATE OR INSERT ON Ticket
FOR EACH ROW
EXECUTE FUNCTION check_ticket_limit();

--Make sure 1 person can only buy enough amount of ticket 
CREATE OR REPLACE FUNCTION check_audience_purchase_limit()
RETURNS TRIGGER AS $$
DECLARE
    ticket_limit INT;
	ticket_quantity INT;
    total_purchased INT;
BEGIN
    -- Get the lim_one_person for the ticket
    SELECT lim_one_person, quantity
    INTO ticket_limit, ticket_quantity
    FROM Ticket
    WHERE ticket_id = NEW.ticket_id;

	IF(NEW.quantity > ticket_quantity) THEN
		RAISE EXCEPTION 'There are not enough ticket to buy';
	END IF;

    -- Calculate the total purchased tickets by the audience for this ticket
    SELECT COALESCE(SUM(quantity), 0)
    INTO total_purchased
    FROM Own
    WHERE ticket_id = NEW.ticket_id
      AND audience_id = NEW.audience_id;

    -- Check if the new purchase exceeds the per-person ticket limit
    IF (total_purchased + NEW.quantity) > ticket_limit THEN
        RAISE EXCEPTION 'Audience purchase exceeds the limit for this ticket';
    END IF;

	UPDATE Ticket
	SET quantity = quantity - NEW.quantity
	WHERE ticket_id = NEW.ticket_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_audience_purchase_limit
BEFORE INSERT OR UPDATE ON Own
FOR EACH ROW
EXECUTE FUNCTION check_audience_purchase_limit();

--ACT TRIGGER
CREATE OR REPLACE FUNCTION Act_check()
RETURNS TRIGGER AS $$
DECLARE
    artist_total_duration INTERVAL;
    contract_time_limit INTERVAL;
    concert_id_tmp CHAR(6);
	new_duration INTERVAL;
BEGIN
    -- Find the concert_id for the new or updated performance
    SELECT concert_id
    INTO concert_id_tmp
    FROM Performance
    WHERE performance_id = NEW.performance_id;

    -- Validate the artist's total performance time against the contract time limit
    SELECT COALESCE(SUM(p.duration), '0 seconds'::interval)
    INTO artist_total_duration
    FROM Act a
    JOIN Performance p ON a.performance_id = p.performance_id
    WHERE p.concert_id = concert_id_tmp AND a.artist_id = NEW.artist_id
          AND a.performance_id != NEW.performance_id; -- Exclude the current performance

    -- Get the artist's contract time limit
    SELECT c.time_limit
    INTO contract_time_limit
    FROM Contract c
    WHERE c.concert_id = concert_id_tmp AND c.artist_id = NEW.artist_id;

    -- Add the duration of the new performance to the total and validate

	SELECT duration INTO new_duration
	FROM performance p 
	WHERE NEW.performance_id = p.performance_id;
	
	artist_total_duration := artist_total_duration + new_duration;

    IF artist_total_duration > contract_time_limit THEN
        RAISE EXCEPTION 'Time Limit Error: Artist''s total performance time exceeds the contract limit (% > %).',
            artist_total_duration, contract_time_limit;
    END IF;

    -- If all checks pass, allow the operation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE TRIGGER Act_check
BEFORE UPDATE OR INSERT ON Act
FOR EACH ROW
EXECUTE FUNCTION Act_check();

--ARTIST TRIGGERS
--Create account for artist
CREATE OR REPLACE FUNCTION create_login_role_artist()
RETURNS TRIGGER AS $$
BEGIN
    -- Create the login role
    EXECUTE format(
        'CREATE ROLE %I WITH LOGIN PASSWORD %L IN ROLE artist;',
        NEW.artist_id,
        NEW.artist_id
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_create_login_role_artist
AFTER INSERT ON Artist
FOR EACH ROW
EXECUTE FUNCTION create_login_role_artist();

--BRAND TRIGGERS
--Create account for added brand
-- Function to create a login role for a new brand
CREATE OR REPLACE FUNCTION create_brand_login_role()
RETURNS TRIGGER AS $$
DECLARE
    role_exists INT;
BEGIN
    -- Check if the role already exists
    SELECT COUNT(*) INTO role_exists
    FROM pg_roles
    WHERE rolname = NEW.brand_id;

    -- Create role if it doesn't exist
    IF role_exists = 0 THEN
        EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L;', NEW.brand_id, NEW.brand_id);
        EXECUTE format('GRANT Sponsor TO %I;', NEW.brand_id);
        RAISE NOTICE 'Role % created and assigned to Sponsor group.', NEW.brand_id;
    ELSE
        RAISE NOTICE 'Role % already exists.', NEW.brand_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for new brand insertion
CREATE TRIGGER trg_create_brand_login_role
AFTER INSERT ON Brand
FOR EACH ROW
EXECUTE FUNCTION create_brand_login_role();

--Delete artist account
CREATE OR REPLACE FUNCTION delete_artist_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Drop the PostgreSQL role associated with the deleted artist
    EXECUTE format('DROP ROLE IF EXISTS %I', OLD.artist_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_delete_artist_role
AFTER DELETE ON Artist
FOR EACH ROW
EXECUTE FUNCTION delete_artist_role();

--Delete sponsor account
CREATE OR REPLACE FUNCTION delete_brand_role()
RETURNS TRIGGER AS $$
BEGIN
    -- Drop the PostgreSQL role associated with the deleted brand
    EXECUTE format('DROP ROLE IF EXISTS %I', OLD.brand_id);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger
CREATE TRIGGER trg_delete_brand_role
AFTER DELETE ON Brand
FOR EACH ROW
EXECUTE FUNCTION delete_brand_role();


CREATE OR REPLACE FUNCTION check_artist_availability()
RETURNS TRIGGER AS $$
DECLARE
    overlapping_concert RECORD;
BEGIN
    -- Check if the artist is already booked for another concert during the same time period
    SELECT c.concert_id, c.event_date, c.start_time, c.end_time
    INTO overlapping_concert
    FROM Contract ct
    JOIN Concert c ON ct.concert_id = c.concert_id
    WHERE ct.artist_id = NEW.artist_id
      AND c.event_date = (SELECT event_date FROM Concert WHERE concert_id = NEW.concert_id)
      AND (
          (c.start_time < (SELECT end_time FROM Concert WHERE concert_id = NEW.concert_id)
           AND c.end_time > (SELECT start_time FROM Concert WHERE concert_id = NEW.concert_id))
      );

    -- If a conflicting concert is found, raise an exception
    IF FOUND THEN
        RAISE EXCEPTION 'Artist % is already scheduled for concert % during this time.', NEW.artist_id, overlapping_concert.concert_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Attach the trigger to the Contract table
CREATE TRIGGER trg_artist_availability
BEFORE INSERT ON Contract
FOR EACH ROW
EXECUTE FUNCTION check_artist_availability();

-- =============================================================================
-- Part 4: Generate Data
-- Source: DB/src/gen_data.sql
-- =============================================================================

INSERT INTO Artist (artist_id, stage_name, last_name, first_name, dob)
VALUES
	('000001', 'tlinh', 'Nguyen', 'Linh', '2000-10-07'),
	('000002', 'MCK', 'Nguyen', 'Long', '1999-03-02'),
	('000003', 'Low G', 'Nguyen', 'Long', '1997-07-23');

INSERT INTO Venue (venue_id, venue_name, capacity, destination)
VALUES 
	('000001', 'San van dong Phu Tho', 5000, '2 Le Dai Hanh, Phuong 9, Quan 11, TPHCM'),
	('000002', 'Cong vien Yen So', 10000, 'QL1A Cong Vien, Phuong Yen So, Quan Hoang Mai, TPHN');

INSERT INTO Audience (audience_id, last_name, first_name, dob, username, pass_word)
VALUES 
	('000001', 'Trinh', 'Quynh', '2004-07-26', 'otime3', 'mattrang1'),
	('000002', 'Phan', 'Tu', '2004-10-25', 'phantu', 'hehehe');

INSERT INTO Technicle (technicle_id, team_size, mixing_quantity, microphone_quantity, monitor_quantity, pa_quantity)
VALUES ('000001', 100, 100, 100, 100, 100);

INSERT INTO Brand (brand_id, brand_name) 
VALUES 
	('000001', 'Momo'),
	('000002', 'Ticket Box');

INSERT INTO Concert (concert_id, concert_name, event_date, start_time, end_time, age_restriction, venue_id, technicle_id)
VALUES 
	('000001', 'Nhung Thanh Pho Mo Mang', '2024-12-21', '14:00:00', '22:30:00', 0, '000002', '000001');

INSERT INTO Ticket (ticket_id, ticket_rank, lim, lim_one_person, concert_id, price, quantity) 
VALUES 
	('000001', 'Normal', 5000, 1, '000001', '599000', 5000);

INSERT INTO Ticket (ticket_id, ticket_rank, lim, lim_one_person, concert_id, price, quantity) 
VALUES 
	('000002', 'Vip', 5000, 1, '000001', '699000', 5000);

INSERT INTO Broadcast (technicle_id, platform) 
VALUES
	('000001', 'HTV'),
	('000001', 'VTV'),
	('000001', 'YTB'),
	('000001', 'TTK');

INSERT INTO Own (ticket_id, audience_id, buy_date, quantity)
VALUES 
	('000001', '000001', CURRENT_DATE, 1);

INSERT INTO Contract (concert_id, artist_id, time_limit, fee)
VALUES 
	('000001', '000001', '3 hours', '300000000');

INSERT INTO Performance (concert_id, performance_id, song_name, author, dance_team, duration, age_restriction, require_mixing, require_pa, require_monitor, require_microphone)
VALUES 
	('000001','000001','Neu Luc Do', 'TLinh', 'Last Fire Crew', '1 hour', 18, 100, 100, 100, 100);

UPDATE Performance
SET duration = '10 minutes'
WHERE performance_id = '000001' AND concert_id = '000001';

INSERT INTO Act (artist_id, performance_id) 
VALUES 
	('000001', '000001');

-- =============================================================================
-- Part 5: Create Indexes
-- Source: DB/src/index.sql
-- =============================================================================

-- Index for Audience
CREATE INDEX idx_audience_last_name ON Audience (last_name);
CREATE INDEX idx_audience_first_name ON Audience (first_name);

-- Index for Venue
CREATE INDEX idx_venue_name ON Venue (venue_name);

-- Index for Concert
CREATE INDEX idx_concert_name ON Concert (concert_name);

-- Index for Brand
CREATE INDEX idx_brand_name ON Brand (brand_name);

-- Index for Artist
CREATE INDEX idx_artist_stage_name ON Artist (stage_name);
CREATE INDEX idx_artist_last_name ON Artist (last_name);
CREATE INDEX idx_artist_first_name ON Artist (first_name);

-- Index for Performance
CREATE INDEX idx_performance_song_name ON Performance (song_name);

-- Audience table primary key index
CREATE INDEX idx_audience_id ON Audience (audience_id);

-- Venue table primary key index
CREATE INDEX idx_venue_id ON Venue (venue_id);

-- Technicle table primary key index
CREATE INDEX idx_technicle_id ON Technicle (technicle_id);

-- Broadcast table primary key index
CREATE INDEX idx_broadcast_id ON Broadcast (technicle_id, platform);

-- Concert table primary key index
CREATE INDEX idx_concert_id ON Concert (concert_id);

-- Ticket table primary key index
CREATE INDEX idx_ticket_id ON Ticket (ticket_id, concert_id);

-- Own table primary key index
CREATE INDEX idx_own_id ON Own (ticket_id, audience_id, buy_date);

-- Brand table primary key index
CREATE INDEX idx_brand_id ON Brand (brand_id);

-- Sponsor table primary key index
CREATE INDEX idx_sponsor_id ON Sponsor (concert_id, brand_id);

-- Artist table primary key index
CREATE INDEX idx_artist_id ON Artist (artist_id);

-- Performance table primary key index
CREATE INDEX idx_performance_id ON Performance (performance_id);

-- Act table primary key index
CREATE INDEX idx_act_id ON Act (artist_id, performance_id);

-- Contract table primary key index
CREATE INDEX idx_contract_id ON Contract (concert_id, artist_id);