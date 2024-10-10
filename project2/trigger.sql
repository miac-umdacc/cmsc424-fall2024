-- trigger 1 customers->newcustomers/ffairlines
CREATE FUNCTION forwardcompat() RETURNS trigger AS $$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            INSERT INTO newcustomers VALUES (NEW.customerid, NEW.name, NEW.birthdate);
            IF (NEW.frequentflieron IS NOT NULL) THEN
                INSERT INTO ffairlines VALUES (NEW.customerid, NEW.frequentflieron, 0);
            END IF;
        ELSIF (TG_OP = 'UPDATE') THEN 
            UPDATE newcustomers
            SET birthdate=NEW.birthdate, name=NEW.name
            WHERE NEW.customerid = customerid;
            IF ((OLD.frequentflieron IS NULL AND NEW.frequentflieron IS NOT NULL) OR OLD.frequentflieron <> NEW.frequentflieron) THEN
                IF (NEW.frequentflieron IS NULL) THEN
                    DELETE FROM ffairlines WHERE customerid = NEW.customerid;
                ELSE 
                    INSERT INTO ffairlines VALUES (NEW.customerid, NEW.frequentflieron, (SELECT COALESCE(SUM(EXTRACT(EPOCH FROM (f.local_arrival_time - f.local_departing_time)) / 60), 0)
    FROM flights f
    WHERE f.airlineid = NEW.frequentflieron));
                END IF;
            END IF;
        ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM newcustomers WHERE customerid = OLD.customerid;
            DELETE FROM  ffairlines WHERE customerid = OLD.customerid;
        END IF;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER forwardtrigger 
AFTER INSERT OR DELETE OR UPDATE 
ON customers
FOR EACH ROW 
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE forwardcompat();

-- Trigger 2 newcustomers->customers
CREATE FUNCTION backwardscompat() RETURNS trigger AS $$
    BEGIN
        IF (TG_OP = 'INSERT') THEN
            INSERT INTO customers VALUES (NEW.customerid, NEW.name, NEW.birthdate, NULL);
        ELSIF (TG_OP = 'UPDATE') THEN 
            UPDATE customers
            SET birthdate=NEW.birthdate, name=NEW.name
            WHERE NEW.customerid = customerid;
        ELSIF (TG_OP = 'DELETE') THEN
            DELETE FROM customers WHERE customerid = OLD.customerid;
            DELETE FROM  ffairlines WHERE customerid = OLD.customerid;
        END IF;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER backtrigger 
AFTER INSERT OR DELETE OR UPDATE 
ON newcustomers
FOR EACH ROW 
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE backwardscompat();

--trigger 3 ffairlines-> customers.frequentflieron
CREATE FUNCTION ffcascade() RETURNS trigger AS $$
    BEGIN
            UPDATE customers
            SET frequentflieron = (SELECT f.airlineid FROM flights f
                                JOIN flewon fw ON f.flightid = fw.flightid
                                WHERE fw.customerid = NEW.customerid
                                ORDER BY fw.flightdate DESC, f.airlineid ASC
                                LIMIT 1)
            WHERE NEW.customerid = customerid;
            RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ffcascadetrigger 
AFTER INSERT OR DELETE OR UPDATE 
ON ffairlines
FOR EACH ROW 
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE ffcascade();


-- trigger 4 flewon -> customers

CREATE FUNCTION newflightshift() RETURNS trigger AS $$
    BEGIN
            UPDATE customers
            SET frequentflieron = (SELECT f.airlineid FROM flights f
                                JOIN flewon fw ON f.flightid = fw.flightid
                                WHERE fw.customerid = NEW.customerid
                                ORDER BY fw.flightdate DESC, f.airlineid ASC
                                LIMIT 1)

            WHERE NEW.customerid = customerid;
            RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER newflighttrigger 
AFTER INSERT OR DELETE OR UPDATE 
ON flewon
FOR EACH ROW 
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE newflightshift();