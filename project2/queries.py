queries = ["" for i in range(0, 4)]

queries[0] = """
select 0;
"""

### 1.
queries[1] = ["", ""]
### <answer1>
queries[1][0] = "COUNT(flewon_cust7.customerid)"
### <answer2>
queries[1][1] = "flights NATURAL LEFT OUTER JOIN flewon_cust7"


### 2.
queries[2] = """
SELECT 
    name,
    ROUND((SELECT COUNT(*)::decimal 
     FROM flights f 
     WHERE f.airlineid = 'AA' 
       AND (f.source = airportidunion.airportid OR f.dest = airportidunion.airportid)
    )/COUNT(*), 2)
FROM 
    (SELECT source AS airportid FROM flights UNION ALL SELECT dest AS airportid FROM flights) AS airportidunion
    NATURAL JOIN airports
GROUP BY 
    name, airportidunion.airportid;
"""

### 3.
### Explaination - it keeps data it shouldn't, removing flights and 
### not the airlines, basically erasing our excluding factor
###
queries[3] = """
WITH airlines_with_jfk AS (
    SELECT DISTINCT a.airlineid
    FROM flights_jfk j
    JOIN flights_airports a ON j.flightid = a.flightid
),
airlines_flights_count AS (
    SELECT a.airlineid, COUNT(a.flightid) AS flight_count
    FROM flights_airports a
    GROUP BY a.airlineid
    HAVING COUNT(a.flightid) >= 15
)
SELECT a.airlineid
FROM airlines_flights_count a
WHERE a.airlineid NOT IN (SELECT airlineid FROM airlines_with_jfk);


"""