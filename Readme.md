# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

```sql
CREATE DATABASE store;
CREATE USER new_user WITH PASSWORD 'userpass';
\c store
GRANT CONNECT, TEMP ON DATABASE store TO new_user;
GRANT USAGE, CREATE ON SCHEMA public TO new_user;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON ALL TABLES IN SCHEMA public TO new_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO new_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON TABLES TO new_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO new_user;


## Шаг 10 — количество проданных сосисок за каждый день предыдущей недели

```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders AS o
JOIN order_product AS op ON o.id = op.order_id
WHERE o.status = 'shipped'
  AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created;
