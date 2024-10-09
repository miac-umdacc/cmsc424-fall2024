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
WITH airlines_jfk AS (
    SELECT DISTINCT a.airlineid
    FROM flights_airports a
    JOIN flights_jfk j 
        ON a.flightid = j.flightid
)
SELECT a.airlineid
FROM flights_airports a 
LEFT JOIN airlines_jfk aj 
	ON a.airlineid = aj.airlineid
WHERE aj.airlineid IS NULL 
GROUP BY a.airlineid
HAVING COUNT(*) >= 15; 


"""