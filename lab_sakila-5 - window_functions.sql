-- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LAB | Window Functions --

-- Setting the working database
USE sakila;
show tables;
select * from actor;

-- Challenge 1 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- This challenge consists of three exercises that will test your ability to use the SQL RANK() function.
-- You will use it to rank films by their length, their length within the rating category, and by the actor or actress who has acted in the greatest number of films.

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Rank films by their length and create an output table that includes the title, length, and rank columns only.
-- Filter out any rows with null or zero values in the length column.


SELECT title, length, DENSE_RANK() OVER(ORDER BY length DESC) AS 'Rank'
FROM film
where ifnull(length,0) > 0;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only.
-- Filter out any rows with null or zero values in the length column.

select * from film;

SELECT title, length, rating, DENSE_RANK() OVER(partition BY rating order by length desc) AS 'Rank'
FROM film
where ifnull(length,0) > 0;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3. Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films,
-- as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH actor_film_count AS (
    SELECT fa.actor_id, COUNT(fa.film_id) AS total_films
    FROM film_actor fa
    GROUP BY fa.actor_id
),
film_actor_ranked AS (
    SELECT f.film_id, f.title, a.actor_id, a.first_name, a.last_name, afc.total_films
    FROM film f
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    JOIN actor_film_count afc ON a.actor_id = afc.actor_id
),
max_actor_film AS (
    SELECT film_id, MAX(total_films) AS max_films
    FROM film_actor_ranked
    GROUP BY film_id
)
SELECT far.title, far.first_name, far.last_name, far.total_films
FROM film_actor_ranked far
JOIN max_actor_film maf ON far.film_id = maf.film_id AND far.total_films = maf.max_films
ORDER BY far.title;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Challenge 2 -------------------------------------------------------------------------------------------------------------------------------------------------------
-- This challenge involves analyzing customer activity and retention in the Sakila database to gain insight into business performance.
-- By analyzing customer behavior over time, businesses can identify trends and make data-driven decisions to improve customer retention and increase revenue.

-- The goal of this exercise is to perform a comprehensive analysis of customer activity and retention by conducting an analysis on the monthly percentage 
-- change in the number of active customers and the number of retained customers. Use the Sakila database and progressively build queries to achieve the desired outcome.

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id,
        COUNT(rental_id) AS rentals_count
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
)
SELECT rental_year, rental_month, COUNT(DISTINCT customer_id) AS active_customers
FROM monthly_active_customers
GROUP BY rental_year, rental_month
ORDER BY rental_year, rental_month;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Step 2. Retrieve the number of active users in the previous month.

-- Paso 2: Recuperar número de clientes activos en el mes actual y el mes anterior
SELECT 
    curr.rental_year AS current_year,
    curr.rental_month AS current_month,
    COUNT(DISTINCT curr.customer_id) AS active_customers_current,
    COUNT(DISTINCT prev.customer_id) AS active_customers_previous
FROM (
    -- Clientes del mes actual
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS curr
LEFT JOIN (
    -- Clientes del mes anterior
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS prev
ON curr.customer_id = prev.customer_id
AND (prev.rental_year = curr.rental_year AND prev.rental_month = curr.rental_month - 1
OR (prev.rental_year = curr.rental_year - 1 AND prev.rental_month = 12 AND curr.rental_month = 1))
GROUP BY current_year, current_month
ORDER BY current_year, current_month;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.

-- Paso 3: Calcular la variación porcentual
SELECT 
    curr.rental_year AS current_year,
    curr.rental_month AS current_month,
    COUNT(DISTINCT curr.customer_id) AS active_customers_current,
    COUNT(DISTINCT prev.customer_id) AS active_customers_previous,
    ROUND(
        (
            (COUNT(DISTINCT curr.customer_id) - COUNT(DISTINCT prev.customer_id)) 
            / COUNT(DISTINCT prev.customer_id)
        ) * 100, 2
    ) AS percentage_change
FROM (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS curr
LEFT JOIN (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS prev
ON curr.customer_id = prev.customer_id
AND (prev.rental_year = curr.rental_year AND prev.rental_month = curr.rental_month - 1
OR (prev.rental_year = curr.rental_year - 1 AND prev.rental_month = 12 AND curr.rental_month = 1))
GROUP BY current_year, current_month
ORDER BY current_year, current_month;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.
-- Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

-- Paso 4: Calcular clientes retenidos
SELECT 
    curr.rental_year AS current_year,
    curr.rental_month AS current_month,
    COUNT(DISTINCT curr.customer_id) AS retained_customers
FROM (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS curr
JOIN (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS prev
ON curr.customer_id = prev.customer_id
AND (prev.rental_year = curr.rental_year AND prev.rental_month = curr.rental_month - 1
OR (prev.rental_year = curr.rental_year - 1 AND prev.rental_month = 12 AND curr.rental_month = 1))
GROUP BY current_year, current_month
ORDER BY current_year, current_month;

-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
    curr.rental_year AS current_year,
    curr.rental_month AS current_month,
    COUNT(DISTINCT curr.customer_id) AS active_customers_current,
    COUNT(DISTINCT prev.customer_id) AS active_customers_previous,
    ROUND(
        (
            (COUNT(DISTINCT curr.customer_id) - COUNT(DISTINCT prev.customer_id)) 
            / COUNT(DISTINCT prev.customer_id)
        ) * 100, 2
    ) AS percentage_change,
    COUNT(DISTINCT CASE WHEN prev.customer_id IS NOT NULL THEN curr.customer_id END) AS retained_customers
FROM (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS curr
LEFT JOIN (
    SELECT 
        YEAR(rental_date) AS rental_year,
        MONTH(rental_date) AS rental_month,
        customer_id
    FROM rental
    GROUP BY rental_year, rental_month, customer_id
) AS prev
ON curr.customer_id = prev.customer_id
AND (prev.rental_year = curr.rental_year AND prev.rental_month = curr.rental_month - 1
OR (prev.rental_year = curr.rental_year - 1 AND prev.rental_month = 12 AND curr.rental_month = 1))
GROUP BY current_year, current_month
ORDER BY current_year, current_month;


-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------------------------------------------------------------------------------------------------------------