SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(r.rental_id) AS total_rentals
FROM customer AS c
JOIN rental AS r 
    ON c.customer_id = r.customer_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
HAVING COUNT(r.rental_id) > (
    SELECT AVG(rental_count)
    FROM (
        SELECT COUNT(rental_id) AS rental_count
        FROM rental
        GROUP BY customer_id
    ) AS customer_rentals
);


SELECT 
    film_id,
    title,
    rental_rate,
    RANK() OVER (ORDER BY rental_rate DESC) AS rate_rank
FROM film;


CREATE OR REPLACE VIEW vw_customer_status AS
SELECT 
    customer_id,
    CONCAT(first_name, ' ', last_name) AS customer_name,
    email,
    active
FROM customer;


SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(p.amount) AS total_payment_amount
FROM customer AS c
JOIN payment AS p 
    ON c.customer_id = p.customer_id
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name
ORDER BY total_payment_amount DESC
LIMIT 10;


WITH CustomerSpending AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(p.amount) AS total_spent,
        NTILE(5) OVER (ORDER BY SUM(p.amount) DESC) AS spending_bucket
    FROM customer AS c
    JOIN payment AS p 
        ON c.customer_id = p.customer_id
    GROUP BY 
        c.customer_id, 
        c.first_name, 
        c.last_name
)
SELECT 
    customer_id,
    first_name,
    last_name,
    total_spent
FROM CustomerSpending
WHERE spending_bucket = 1;


SELECT 
    a.actor_id,
    a.first_name,
    a.last_name,
    COUNT(fa.film_id) AS movie_count,
    DENSE_RANK() OVER (ORDER BY COUNT(fa.film_id) DESC) AS actor_dense_rank
FROM actor AS a
JOIN film_actor AS fa 
    ON a.actor_id = fa.actor_id
GROUP BY 
    a.actor_id, 
    a.first_name, 
    a.last_name;
    
    
    CREATE OR REPLACE VIEW vw_film_details AS
SELECT 
    f.film_id,
    f.title,
    c.name AS category_name,
    f.rental_rate,
    f.replacement_cost
FROM film AS f
JOIN film_category AS fc 
    ON f.film_id = fc.film_id
JOIN category AS c 
    ON fc.category_id = c.category_id;
    
    
    DELIMITER //

CREATE PROCEDURE GetTop20RentedMovies()
BEGIN
    SELECT 
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM film AS f
    JOIN inventory AS i 
        ON f.film_id = i.film_id
    JOIN rental AS r 
        ON i.inventory_id = r.inventory_id
    GROUP BY 
        f.film_id, 
        f.title
    ORDER BY rental_count DESC
    LIMIT 20;
END //

DELIMITER ;


DELIMITER //

CREATE PROCEDURE GetFilmsByRating(IN p_rating VARCHAR(10))
BEGIN
    SELECT 
        film_id,
        title,
        description,
        release_year,
        rental_rate,
        rating
    FROM film
    WHERE rating = p_rating;
END //

DELIMITER ;


WITH FilmRentalCounts AS (
    SELECT 
        c.name AS category_name,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count,
        DENSE_RANK() OVER (
            PARTITION BY c.name 
            ORDER BY COUNT(r.rental_id) DESC
        ) AS rank_in_category
    FROM category AS c
    JOIN film_category AS fc 
        ON c.category_id = fc.category_id
    JOIN film AS f 
        ON fc.film_id = f.film_id
    JOIN inventory AS i 
        ON f.film_id = i.film_id
    JOIN rental AS r 
        ON i.inventory_id = r.inventory_id
    GROUP BY 
        c.name, 
        f.film_id, 
        f.title
)
SELECT 
    category_name,
    title,
    rental_count,
    rank_in_category
FROM FilmRentalCounts
WHERE rank_in_category <= 3
ORDER BY category_name, rank_in_category;


WITH CategoryRentals AS (
    SELECT 
        c.name AS category_name,
        COUNT(r.rental_id) AS rental_count
    FROM category AS c
    JOIN film_category AS fc 
        ON c.category_id = fc.category_id
    JOIN inventory AS i 
        ON fc.film_id = i.film_id
    JOIN rental AS r 
        ON i.inventory_id = r.inventory_id
    GROUP BY c.name
)
SELECT 
    category_name,
    rental_count,
    SUM(rental_count) OVER (
        ORDER BY rental_count ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_rentals
FROM CategoryRentals;


WITH ActorPairs AS (
    SELECT 
        fa1.film_id,
        fa1.actor_id AS actor_1_id,
        fa2.actor_id AS actor_2_id
    FROM film_actor AS fa1
    JOIN film_actor AS fa2 
        ON fa1.film_id = fa2.film_id 
       AND fa1.actor_id < fa2.actor_id
)
SELECT 
    ap.film_id,
    f.title AS film_title,
    CONCAT(a1.first_name, ' ', a1.last_name) AS actor_1_name,
    CONCAT(a2.first_name, ' ', a2.last_name) AS actor_2_name
FROM ActorPairs AS ap
JOIN film AS f 
    ON ap.film_id = f.film_id
JOIN actor AS a1 
    ON ap.actor_1_id = a1.actor_id
JOIN actor AS a2 
    ON ap.actor_2_id = a2.actor_id
ORDER BY ap.film_id, actor_1_name;




DELIMITER //

CREATE PROCEDURE GetCustomerTotalPayment(
    IN  p_customer_id INT,
    OUT p_total_payment DECIMAL(10,2)
)
BEGIN
    SELECT IFNULL(SUM(amount), 0.00)
    INTO p_total_payment
    FROM payment
    WHERE customer_id = p_customer_id;
END //

DELIMITER ;