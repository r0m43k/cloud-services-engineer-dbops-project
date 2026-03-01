INSERT INTO product (name, picture_url, price) VALUES
('Булочная', 'https://res.cloudinary.com/sugrobov/image/upload/v1623323635/repos/sausages/6.jpg', 320);

INSERT INTO orders (status, date_created) VALUES
('new', CURRENT_DATE);

INSERT INTO order_product (quantity, order_id, product_id) VALUES
(1, 1, 1);
