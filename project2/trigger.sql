
-- Trigger 1: customers -> newcustomers/ffairlines
CREATE FUNCTION forwardcompat() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO newcustomers VALUES (NEW.customerid, NEW.name, NEW.birthdate);
        IF (NEW.frequentflieron IS NOT NULL) THEN
            INSERT INTO ffairlines VALUES (NEW.customerid, NEW.frequentflieron, 0);
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN 
        UPDATE newcustomers
        SET birthdate = NEW.birthdate, name = NEW.name
        WHERE customerid = NEW.customerid;
        
        IF (NEW.frequentflieron IS NULL) THEN
            DELETE FROM ffairlines WHERE customerid = NEW.customerid;
        ELSE
            IF (OLD.frequentflieron IS DISTINCT FROM NEW.frequentflieron) THEN
                INSERT INTO ffairlines VALUES (NEW.customerid, NEW.frequentflieron, 0);
                UPDATE customers
        SET frequentflieron = (
            SELECT airlineid
            FROM ffairlines
            WHERE customerid = NEW.customerid
            ORDER BY points DESC, airlineid ASC
            LIMIT 1
        )
        WHERE customerid = NEW.customerid;
            END IF;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM newcustomers WHERE customerid = OLD.customerid;
        DELETE FROM ffairlines WHERE customerid = OLD.customerid;
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

-- Trigger 2: newcustomers -> customers
CREATE FUNCTION backwardscompat() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO customers VALUES (NEW.customerid, NEW.name, NEW.birthdate, NULL);
    ELSIF (TG_OP = 'UPDATE') THEN 
        UPDATE customers
        SET birthdate = NEW.birthdate, name = NEW.name
        WHERE customerid = NEW.customerid;
    ELSIF (TG_OP = 'DELETE') THEN
        DELETE FROM customers WHERE customerid = OLD.customerid;
        DELETE FROM ffairlines WHERE customerid = OLD.customerid;
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

CREATE FUNCTION update_customers_from_ffairlines() RETURNS trigger AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE customers
        SET frequentflieron = (
            SELECT airlineid
            FROM ffairlines
            WHERE customerid = NEW.customerid
            ORDER BY points DESC, airlineid ASC
            LIMIT 1
        )
        WHERE customerid = NEW.customerid;
    ELSIF (TG_OP = 'UPDATE') THEN
        UPDATE customers
        SET frequentflieron = (
            SELECT airlineid
            FROM ffairlines
            WHERE customerid = NEW.customerid
            ORDER BY points DESC, airlineid ASC
            LIMIT 1
        )
        WHERE customerid = NEW.customerid;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE customers
        SET frequentflieron = (
            SELECT airlineid
            FROM ffairlines
            WHERE customerid = OLD.customerid
            ORDER BY points DESC, airlineid ASC
            LIMIT 1
        )
        WHERE customerid = OLD.customerid;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ffairlines_trigger
AFTER INSERT OR UPDATE OR DELETE
ON ffairlines
FOR EACH ROW
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE update_customers_from_ffairlines();

CREATE FUNCTION update_customers_from_flewon() RETURNS trigger AS $$
BEGIN
    UPDATE customers
    SET frequentflieron = (
        SELECT airlineid
        FROM ffairlines
        WHERE customerid = NEW.customerid
        ORDER BY points DESC, airlineid ASC
        LIMIT 1
    )
    WHERE customerid = NEW.customerid;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER flewon_trigger
AFTER INSERT OR UPDATE OR DELETE
ON flewon
FOR EACH ROW
WHEN (pg_trigger_depth() = 0) 
EXECUTE PROCEDURE update_customers_from_flewon();