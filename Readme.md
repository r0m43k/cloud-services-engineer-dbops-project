# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

## Шаг 3
```
\c store_default
CREATE DATABASE store;
CREATE USER new_user WITH PASSWORD 'userpass';
\c store
GRANT CONNECT, TEMP ON DATABASE store TO new_user;
GRANT USAGE, CREATE ON SCHEMA public TO new_user;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO new_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO new_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO new_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO new_user;
```
## Шаг 10
```
store=# \timing
Timing is on.
store=# SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
 date_created | sum 
--------------+-----
(0 rows)

Time: 1.979 ms
```


## Шаг 11
### Запрос (Выполнение БЕЗ индексов)
```
store=# SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
 date_created | sum 
--------------+-----
(0 rows)

Time: 72.431 ms
```


```
EXPLAIN ANALYZE:

store=# EXPLAIN (ANALYZE)
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
                                                     QUERY PLAN                                                      
---------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2.05..2.07 rows=1 width=12) (actual time=0.014..0.015 rows=0 loops=1)
   Group Key: o.date_created
   ->  Sort  (cost=2.05..2.06 rows=1 width=8) (actual time=0.013..0.014 rows=0 loops=1)
         Sort Key: o.date_created
         Sort Method: quicksort  Memory: 25kB
         ->  Nested Loop  (cost=0.00..2.04 rows=1 width=8) (actual time=0.010..0.011 rows=0 loops=1)
               Join Filter: (o.id = op.order_id)
               ->  Seq Scan on orders o  (cost=0.00..1.02 rows=1 width=12) (actual time=0.010..0.010 rows=0 loops=1)
                     Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                     Rows Removed by Filter: 1
               ->  Seq Scan on order_product op  (cost=0.00..1.01 rows=1 width=12) (never executed)
 Planning Time: 0.116 ms
 Execution Time: 0.044 ms
(13 rows)

Time: 24.756 ms
```


### создание индексов
```
store=# CREATE INDEX order_product_order_id_idx ON order_product(order_id);
CREATE INDEX
Time: 8.257 ms
store=# CREATE INDEX orders_status_date_idx ON orders(status, date_created);
CREATE INDEX
Time: 4.272 ms
```

### Выполнение с индексами

```
store=# SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
 date_created | sum 
--------------+-----
(0 rows)

Time: 0.781 ms
```


```
store=# EXPLAIN (ANALYZE)
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
                                                     QUERY PLAN                                                      
---------------------------------------------------------------------------------------------------------------------
 GroupAggregate  (cost=2.05..2.07 rows=1 width=12) (actual time=0.016..0.017 rows=0 loops=1)
   Group Key: o.date_created
   ->  Sort  (cost=2.05..2.06 rows=1 width=8) (actual time=0.015..0.016 rows=0 loops=1)
         Sort Key: o.date_created
         Sort Method: quicksort  Memory: 25kB
         ->  Nested Loop  (cost=0.00..2.04 rows=1 width=8) (actual time=0.010..0.010 rows=0 loops=1)
               Join Filter: (o.id = op.order_id)
               ->  Seq Scan on orders o  (cost=0.00..1.02 rows=1 width=12) (actual time=0.009..0.010 rows=0 loops=1)
                     Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                     Rows Removed by Filter: 1
               ->  Seq Scan on order_product op  (cost=0.00..1.01 rows=1 width=12) (never executed)
 Planning Time: 0.142 ms
 Execution Time: 0.038 ms
(13 rows)

Time: 0.611 ms
```

## Вывод
После создания индексов время выполнения запроса уменьшилось примерно с 72 ms до 0.78 ms. Однако таблицы содержат очень небольшое количество данных. На больших объёмах данных индексы позволят значительно ускорить JOIN и фильтрацию.
