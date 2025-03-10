/*
    Title: db_init_2025.sql
    Authors: Vaneshiea Bell, DeJanae Faison, Jess Monnier (based loosely on script by Professor Sue Sampson)
    Created: 22 February 2025
	Last Modified: 2 March 2025
    Description: outland database initialization script.
*/

-- create database if it doesn't exist yet
CREATE DATABASE IF NOT EXISTS outland;
USE outland; -- Without this, if you aren't already using outland, script will error out

-- drop database user if exists 
DROP USER IF EXISTS 'adm'@'localhost';

-- create movies_user and grant them all privileges to the movies database 
CREATE USER 'adm'@'localhost' IDENTIFIED WITH mysql_native_password BY 'adventure';

-- grant all privileges to the movies database to user movies_user on localhost 
GRANT ALL PRIVILEGES ON outland.* TO 'adm'@'localhost';

-- drop tables if they are present
-- learned the hard way that order matters; drop tables w foreign keys before tables those keys originate from
DROP TABLE IF EXISTS guide_req_tracker;
DROP TABLE IF EXISTS guide_req;
DROP TABLE IF EXISTS trip_member;
DROP TABLE IF EXISTS trip;
DROP TABLE IF EXISTS rental_history;
DROP TABLE IF EXISTS rental_inventory;
DROP TABLE IF EXISTS rental;
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_inventory;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS staff;

-- similarly, when creating tables, need to create primary table first before any table where it will be referenced for a foreign key

-- create the customer table 
CREATE TABLE customer (
    cust_id   		INT             NOT NULL        AUTO_INCREMENT,
    first_name  	VARCHAR(75)     NOT NULL,
	last_name		VARCHAR(75)		NOT NULL,
	phone_number	CHAR(12)		NOT NULL, -- 12-char for 555-555-5555 format
	addr_street		VARCHAR(75)		NOT NULL,
	addr_city		VARCHAR(30)		NOT NULL,
	addr_state		CHAR(2)			NOT NULL, -- 2-char for NE format
	addr_zip		INT				NOT NULL,
	email			VARCHAR(50)		NOT NULL,
     
    PRIMARY KEY(cust_id)
); 

-- create the staff table 
CREATE TABLE staff (
    staff_id    	INT             NOT NULL        AUTO_INCREMENT,
    first_name  	VARCHAR(75)     NOT NULL,
	last_name		VARCHAR(75)		NOT NULL,
	nick_name		VARCHAR(25),			  -- nick name is optional
    phone_number	CHAR(12)		NOT NULL, -- 12-char for 555-555-5555 format
	addr_street		VARCHAR(75)		NOT NULL,
	addr_city		VARCHAR(30)		NOT NULL,
	addr_state		CHAR(2)			NOT NULL, -- 2-char for NE format
	addr_zip		INT				NOT NULL,
	email			VARCHAR(50)		NOT NULL,
    staff_role		VARCHAR(20)		NOT NULL,
     
    PRIMARY KEY(staff_id)
); 

-- create the trip table and set the foreign keys
CREATE TABLE trip (
    trip_id			INT           	NOT NULL        AUTO_INCREMENT,
    destination 	VARCHAR(75)     NOT NULL, -- Destination should be comma-separated ending in continent/major continent region, e.g. "Victoria Falls, Zimbabwe, Africa"
    trip_start   	DATE     		NOT NULL,
	trip_end		DATE			NOT NULL,
	staff_id		INT				NOT NULL,
	cust_primary	INT				NOT NULL,
	
    PRIMARY KEY(trip_id),

	CONSTRAINT fk_trip_staff_id -- this gives the foreign key a name for easy reference if we want to delete or change it later
    FOREIGN KEY(staff_id)
        REFERENCES staff(staff_id),
	
	CONSTRAINT fk_trip_cust_id
    FOREIGN KEY(cust_primary)
        REFERENCES customer(cust_id)
);
    
-- create the trip_members table and set the foreign keys, add check on cust_id
CREATE TABLE trip_member (
	id					INT 			NOT NULL	AUTO_INCREMENT,
	trip_id				INT				NOT NULL,
	first_name			VARCHAR(75),			  -- name only filled if no cust_id
	last_name			VARCHAR(75),
    date_of_birth		DATE			NOT NULL,
    reservations		VARCHAR(255),			  -- empty until reservations are booked
    waiver				MEDIUMBLOB		NOT NULL,
    email 				VARCHAR(50),			  -- email & phone only filled if no cust_id
    phone_number 		CHAR(12),
    cust_id		 		INT,					  -- only one trip member is required to have a customer account
    passport_status		VARCHAR(255) 	NOT NULL,
    emergency_number	CHAR(12)		NOT NULL,
    emergency_name  	VARCHAR(75)     NOT NULL,
    emergency_relation	VARCHAR(25)		NOT NULL,
    
    PRIMARY KEY(id),
    
	CONSTRAINT fk_trip_members_trip_id
	FOREIGN KEY(trip_id)
		REFERENCES trip(trip_id),
	
	CONSTRAINT fk_trip_members_cust_id
	FOREIGN KEY(cust_id)
		REFERENCES customer(cust_id),
	
	-- ensure there's either a cust_id OR name/contact info
	-- this prevents duplication of info in the customer table
	CONSTRAINT check_cust_id CHECK(
	(cust_id IS NULL AND email IS NOT NULL AND phone_number IS NOT NULL
		AND first_name IS NOT NULL AND last_name IS NOT NULL)
	OR
	(cust_id IS NOT NULL and email IS NULL and phone_number IS NULL
		AND first_name IS NULL AND last_name IS NULL))
);

-- create order_inventory table and composite primary key
CREATE TABLE order_inventory (
	product_code		VARCHAR(75)		NOT NULL,
	product_condition	VARCHAR(9)		NOT NULL,
	name				VARCHAR(75)		NOT NULL,
    unit_price			FLOAT 			NOT NULL,
    stock				INT				NOT NULL,
    weight				INT				NOT NULL,
    dimensions 			VARCHAR(25) 	NOT NULL,
	description			VARCHAR(255)	NOT NULL,
	
	CONSTRAINT pk_product -- because any given product could have a new, used-good, or used-fair condition,
	PRIMARY KEY (product_code, product_condition) -- the pair forms a unique primary key
);

-- create orders table and add foreign key; note orders is plural where other table names aren't to deconflict with sql keyword
CREATE TABLE orders (
	order_id		INT				NOT NULL 	AUTO_INCREMENT,
    order_date 		DATE 			NOT NULL,
    cust_id			INT				NOT NULL,
    ship_street		VARCHAR(75),			  -- shipping address columns not used when pick up in store selected
	ship_city		VARCHAR(30),
	ship_state		CHAR(2),
	ship_zip		INT,
    
    PRIMARY KEY(order_id),
	
	CONSTRAINT fk_orders_cust_id
	FOREIGN KEY(cust_id)
		REFERENCES customer(cust_id)
);

-- create order_item table and add foreign keys
CREATE TABLE order_item (
	id					INT 			NOT NULL 	AUTO_INCREMENT,
	product_code		VARCHAR(75)		NOT NULL,
	product_condition	VARCHAR(9)		NOT NULL,
    quantity			INT 			NOT NULL,
    ship_tracking 		VARCHAR(75),			  -- empty for in-store pickup
	order_id			INT				NOT NULL,
    
    PRIMARY KEY(id),
	
	CONSTRAINT fk_product
	FOREIGN KEY(product_code, product_condition)
		REFERENCES order_inventory(product_code, product_condition),
	
	CONSTRAINT fk_order_item_order_id
	FOREIGN KEY(order_id)
		REFERENCES orders(order_id)
);

-- create rental table and set foreign key
CREATE TABLE rental (
	rental_id	INT		NOT NULL 	AUTO_INCREMENT,
    rental_date	DATE	NOT NULL,
    cust_id		INT		NOT NULL,
    start_date	DATE 	NOT NULL,
    end_date	DATE	NOT NULL,
    
    PRIMARY KEY(rental_id),
    
	CONSTRAINT fk_rental_cust_id
	FOREIGN KEY(cust_id)
		REFERENCES customer(cust_id)
);

-- create rental inventory and set foreign keys
CREATE TABLE rental_inventory (
	item_id 			INT			NOT NULL	AUTO_INCREMENT,
    initial_use			DATE,				  -- this value is not filled until first time item is rented
    rate				FLOAT		NOT NULL,
    product_condition 	VARCHAR(25)	NOT NULL,
    product_code		VARCHAR(75)	NOT NULL,
    rental_id			INT,				  -- this value is only filled when the item is currently rented/reserved
    
    PRIMARY KEY(item_id),
	
	CONSTRAINT fk_rental_inventory_rental_id
	FOREIGN KEY(rental_id)
		REFERENCES rental(rental_id),
	
	CONSTRAINT fk_rental_inventory_product
	FOREIGN KEY(product_code)
		REFERENCES order_inventory(product_code)
);

-- create rental history and set up foreign keys
CREATE TABLE rental_history (
	id					INT				NOT NULL	AUTO_INCREMENT,
	item_id				INT				NOT NULL,
	rental_id			INT				NOT NULL,
	issue_condition		VARCHAR(50)		NOT NULL,
	return_condition	VARCHAR(50),			  -- should be empty until item is returned
	
	PRIMARY KEY(id),
	
	CONSTRAINT fk_rental_history_item_id
	FOREIGN KEY(item_id)
		REFERENCES rental_inventory(item_id),
	
	CONSTRAINT fk_rental_history_rental_id
	FOREIGN KEY(rental_id)
		REFERENCES rental(rental_id)
);

-- create guide_req table
CREATE TABLE guide_req (
	req_id			INT				NOT NULL	AUTO_INCREMENT,
	name			VARCHAR(75)		NOT NULL,
	description		VARCHAR(255)	NOT NULL,
	valid_months	INT,					  -- number of months req is valid once obtained; if empty, never expires
	governing_org	VARCHAR(255)	NOT NULL,
	
	PRIMARY KEY(req_id)
);

-- create guide_req_tracker table and add foreign keys
CREATE TABLE guide_req_tracker (
	id				INT				NOT NULL	AUTO_INCREMENT,
	complete_date	DATE,					  -- can be empty if member has not completed it yet
	status			VARCHAR(255)	NOT NULL,
	req_id			INT				NOT NULL,
	staff_id		INT				NOT NULL,
	
	PRIMARY KEY(id),
	
	CONSTRAINT fk_guid_req_tracker_staff_id
    FOREIGN KEY(staff_id)
        REFERENCES staff(staff_id),
	
	CONSTRAINT fk_guide_req_tracker_req_id
    FOREIGN KEY(req_id)
        REFERENCES guide_req(req_id)
);

-- insert customers; ChatGPT used to generate an extra 9 customers after initial 6
INSERT INTO customer 
(first_name, last_name, phone_number, addr_street, 
	addr_city, addr_state, addr_zip, email)
VALUES 
("John", "Doe", "555-555-1234", "123 West Adventure Terrace", 
	"Denver", "CO", 80014, "john.doe.3535@gmail.com"),
("Sally", "Ride", "555-555-2323", "418 Slip St Apt 3",
	"Palatine", "IL", 60067, "sally.rides.again@gmail.com"),
("Khloe", "Arson", "856-643-1224", "455 West Adventure Terrace", 
	"Denver", "CO", 80014, "sillyLady@gmail.com"),
("Matthew", "Lanes", "122-877-2332", "18 Huntings St", 
	"Denver", "CO", 80015, "marshallMatthews@yahoo.com"),
("Tyson", "Conners", "766-211-9055", "72 Washington Rd", 
	"Denver", "CO", 80014, "knockOut@gmail.com"),
("Sandra", "Griffin", "209-121-9800", "489 Georges Ave", 
	"Denver", "CO", 80015, "quahougSquare@gmail.com"),
("Emma", "Stone", "555-555-3321", "1000 Maple St", 
	"Denver", "CO", 80013, "emma.stone01@gmail.com"),
("James", "Smith", "555-555-4455", "2040 Sunrise Dr", 
	"Denver", "CO", 80202, "jsmith1987@yahoo.com"),
("Olivia", "Martinez", "555-555-5566", "42 Cherry Blossom Ln", 
	"Denver", "CO", 80012, "olive.martinez@gmail.com"),
("Liam", "Johnson", "555-555-6677", "307 Park Ave", 
	"Denver", "CO", 80019, "ljohnson712@gmail.com"),
("Isabella", "Miller", "555-555-7788", "577 Crescent Moon Blvd", 
	"Denver", "CO", 80022, "bella.miller@hotmail.com"),
("Lucas", "Brown", "555-555-8899", "990 Aspen Ridge Rd", 
	"Denver", "CO", 80221, "lucas.brown23@gmail.com"),
("Charlotte", "Davis", "555-555-9000", "150 Oakwood Ave", 
	"Madison", "WI", 53703, "charlotte.davis@gmail.com"),
("Sophia", "Taylor", "555-555-1010", "310 Pinehill St", 
	"Columbus", "OH", 43215, "sophia.taylor77@gmail.com"),
("Ethan", "Walker", "555-555-1122", "801 River Rd", 
	"Des Moines", "IA", 50309, "ethan.walker@aol.com");

-- insert staff, example with all fields and with no nick name/bonus
INSERT INTO staff 
(first_name, nick_name, last_name, phone_number, addr_street,
	addr_city, addr_state, addr_zip, email, staff_role)
VALUES 
("Blythe", NULL, "Timmerson", "555-555-8111", "2380 Chipper Ave",
	"Denver", "CO", 80016, "blythe@outlandadventures.com", "Owner"),
("James", "Jim", "Ford", "578-902-0021", "90 Oliver Dr",
	"Denver", "CO", 80016, "jim@outlandadventures.com", "Owner"),
("John", "Mac", "MacNell", "555-555-4321", "5612 Wandering Rd",
	"Denver", "CO", 80016, "mac@outlandadventures.com", "Guide"),
("D.B.", "Duke", "Marland", "728-351-7920", "143 Douglas St",
	"Denver", "CO", 80016, "duke@outlandadventures.com", "Guide"),
("Anita", NULL, "Gallegos", "555-555-8765", "52108 Blankenship St",
	"Denver", "CO", 80014, "anita@outlandadventures.com", "Marketing"),
("Dimitrios", NULL, "Stravopolous", "555-555-1482", "5412 Saddle Ln",
	"Denver", "CO", 80015, "dimitrios@outlandadventures.com", "Inventory Manager"),
("Mei", NULL, "Wong", "555-555-0147", "823 W Falcon Terr",
	"Denver", "CO", 80013, "mei@outlandadventures.com", "Web Admin"),
("Alexi", "Lexi", "Tysons", "908-545-4001", "404 Dashing Rd",
	"Denver", "CO", 80016, "tysonL@outlandadventures.com", "Apprentence"),
("Karen", NULL, "Allison", "785-008-8765", "5800 Parkings St",
	"Denver", "CO", 80016, "allison@outlandadventures.com", "Accountant");

-- insert trips, select statements needed bc of auto-increment of primary keys
-- ChatGPT used to help generate the basis for an additional 19 rows after initial 6
INSERT INTO trip 
(destination, trip_start, trip_end, 
	staff_id, 
	cust_primary)
VALUES 
("Victoria Falls, Zimbabwe, Africa", "2024-09-15", "2024-09-21", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "John")),
("Mount Everest, Nepal, Asia", "2025-04-01", "2025-04-14", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Sally")),
("Kenting National Park, Taiwan, Asia", "2025-06-01", "2025-06-10", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Khloe")),
("Kilimanjaro, Africa", "2025-07-05", "2025-07-15", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Matthew")),
("Vitosha Nature Park, Bulgaria, Southern Europe", "2025-08-10", "2025-08-20", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Tyson")),
("Sierra Nevada, Southern Europe", "2025-09-10", "2025-09-20", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Sandra")),
("Sahara Desert, Morocco, Africa", "2023-10-05", "2023-10-12", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Emma")),
("Table Mountain, South Africa, Africa", "2023-10-15", "2023-10-22", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "James")),
("Sahara Desert, Morocco, Africa", "2023-11-01", "2023-11-06", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Olivia")),
("Costa Brava, Spain, Southern Europe", "2023-11-07", "2023-11-13", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Liam")),
("Serengeti National Park, Tanzania, Africa", "2024-01-10", "2024-01-17", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Isabella")),
("Mount Everest, Nepal, Asia", "2024-01-25", "2024-02-02", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Lucas")),
("Alps, Switzerland, Southern Europe", "2024-03-15", "2024-03-22", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Charlotte")),
("Azores, Portugal, Southern Europe", "2024-04-01", "2024-04-07", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Sophia")),
("Bromo Tengger Semeru National Park, Indonesia, Asia", "2024-05-10", "2024-05-18", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Ethan")),
("Olympus Mountain, Greece, Southern Europe", "2024-06-01", "2024-06-08", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Sally")),
("Namib Desert, Namibia, Africa", "2024-07-05", "2024-07-12", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Matthew")),
("Mount Kilimanjaro, Tanzania, Africa", "2024-08-01", "2024-08-06", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Tyson")),
("Alps, Switzerland, Southern Europe", "2024-09-01", "2024-09-10", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Sandra")),
("Victoria Falls, Zambia/Zimbabwe, Africa", "2024-10-05", "2024-10-12", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Khloe")),
("Mount Fuji, Japan, Asia", "2024-11-01", "2024-11-08", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Matthew")),
("Pyrenees, France/Spain, Southern Europe", "2025-02-10", "2025-02-17", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Tyson")),
("Kruger National Park, South Africa, Africa", "2025-03-01", "2025-03-09", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Olivia")),
("Mount Kilimanjaro, Tanzania, Africa", "2025-04-01", "2025-04-10", 
	(select staff_id from staff where nick_name = "Duke"),
	(select cust_id from customer where first_name = "Emma")),
("Serengeti National Park, Tanzania, Africa", "2025-04-10", "2025-04-17", 
	(select staff_id from staff where nick_name = "Mac"),
	(select cust_id from customer where first_name = "Isabella"));

-- ChatGPT used to help generate additional trip members after the initial 6

-- Members for the trip to "Victoria Falls, Zimbabwe, Africa"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where trip_start = "2024-09-15" and destination = "Victoria Falls, Zimbabwe, Africa"),
	"1992-04-15", "American Airlines MDABRG", "pretend this is a data blob",
	(select cust_id from customer where first_name = "John"),
	"Complete", NULL, NULL, NULL, NULL, "555-555-8713", "Amanda Smith", "mother"),
((select trip_id from trip where trip_start = "2024-09-15" and destination = "Victoria Falls, Zimbabwe, Africa"),
	"1995-08-23", "American Airlines MDABRG", "pretend this is a data blob",
	NULL, "Complete", "555-555-4376", "melanie.harmon.45@gmail.com", "Melanie", "Harmon", "555-555-1899", "Morgan Harmon", "sister"),
((select trip_id from trip where trip_start = "2024-09-15" and destination = "Victoria Falls, Zimbabwe, Africa"),
	"1985-02-18", "British Airways AB1234", "pretend this is a data blob",
	NULL, "Complete", "555-555-1212", "jennifer.williams@gmail.com", "Jennifer", "Williams", "555-555-2001", "David Williams", "husband"),
((select trip_id from trip where trip_start = "2024-09-15" and destination = "Victoria Falls, Zimbabwe, Africa"),
	"1990-09-09", "United Airlines XY4567", "pretend this is a data blob",
	NULL, "Complete", "555-555-3490", "nathan.smith@hotmail.com", "Nathan", "Smith", "555-555-3100", "Rebecca Smith", "friend");

-- Members for the trip to "Mount Everest, Nepal, Asia"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where destination = "Mount Everest, Nepal, Asia" and trip_start = "2025-04-01"),
	"1988-06-12", "Delta Airlines XYZ1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Sally"),
	"Complete", NULL, NULL, 
	NULL, NULL, "555-555-1122", "Jane Ride", "sister"),
((select trip_id from trip where destination = "Mount Everest, Nepal, Asia" and trip_start = "2025-04-01"),
	"1994-07-22", "United Airlines JK9876", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-7878", "sam.taylor@gmail.com", 
	"Sam", "Taylor", "555-555-7890", "Michelle Taylor", "mother"),
((select trip_id from trip where destination = "Mount Everest, Nepal, Asia" and trip_start = "2025-04-01"),
	"1990-03-10", "American Airlines QQ6578", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-4321", "alex.morris@hotmail.com", 
	"Alex", "Morris", "555-555-9832", "Jordan Morris", "brother");

-- Members for the trip to "Kenting National Park, Taiwan, Asia"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where destination = "Kenting National Park, Taiwan, Asia" and trip_start = "2025-06-01"),
	"1991-09-30", "United Airlines AB1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Khloe"),
	"Complete", NULL, NULL, 
	NULL, NULL, "555-555-2233", "Mark Arson", "father"),
((select trip_id from trip where destination = "Kenting National Park, Taiwan, Asia" and trip_start = "2025-06-01"),
	"1993-11-04", "American Airlines MCX8721", "pretend this is a data blob",
	NULL, 
	"Submitted app 2/25, expected to take 3-4 weeks", "555-555-3333", "marshallMatthews@yahoo.com", 
	"Matthew", "Lanes", "555-555-3344", "Lorna Lanes", "aunt"),
((select trip_id from trip where destination = "Kenting National Park, Taiwan, Asia" and trip_start = "2025-06-01"),
	"1990-03-20", "Southwest Airlines XYX9821", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-4444", "knockOut@gmail.com", 
	"Tyson", "Conners", "555-555-4455", "Holly Conners", "mother");

-- Members for the trip to "Kilimanjaro, Africa"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where destination = "Kilimanjaro, Africa" and trip_start = "2025-07-05"),
	"1988-07-14", "Delta Airlines GH1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Matthew"),
	"Complete", NULL, NULL, 
	NULL, NULL, "555-555-7789", "Oliver Spencer", "friend"),
((select trip_id from trip where destination = "Kilimanjaro, Africa" and trip_start = "2025-07-05"),
	"1995-01-21", "United Airlines AB1234", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-1992", "lisa.jones@gmail.com", 
	"Lisa", "Jones", "555-555-2311", "Paul Jones", "father"),
((select trip_id from trip where destination = "Kilimanjaro, Africa" and trip_start = "2025-07-05"),
	"1990-11-10", "American Airlines WQ4783", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-6547", "lucas.reed@yahoo.com", 
	"Lucas", "Reed", "555-555-4598", "Sarah Reed", "mother");

-- Members for the trip to "Vitosha Nature Park, Bulgaria, Southern Europe"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where destination = "Vitosha Nature Park, Bulgaria, Southern Europe" and trip_start = "2025-08-10"),
	"1992-05-05", "Aeroflot Airlines XY1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Tyson"),
	"Complete", NULL, NULL, 
	NULL, NULL, "555-555-8932", "Ella Harrison", "mother"),
((select trip_id from trip where destination = "Vitosha Nature Park, Bulgaria, Southern Europe" and trip_start = "2025-08-10"),
	"1994-08-13", "British Airways AB4623", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-4921", "susan.king@gmail.com", 
	"Susan", "King", "555-555-1233", "John King", "father");

-- Members for the trip to "Sierra Nevada, Southern Europe"
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where destination = "Sierra Nevada, Southern Europe" and trip_start = "2025-09-10"),
	"1990-11-12", "Turkish Airlines AB7896", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Sandra"),
	"Complete", NULL, NULL, 
	NULL, NULL, "555-555-5876", "Eva Moore", "mother"),
((select trip_id from trip where destination = "Sierra Nevada, Southern Europe" and trip_start = "2025-09-10"),
	"1993-02-02", "Air France AB5678", "pretend this is a data blob",
	NULL, 
	"Complete", "555-555-7932", "george.martin@gmail.com", 
	"George", "Martin", "555-555-3722", "Rachel Martin", "sister");


-- insert order inventory (We looked on REI to find the product codes/info)
-- product_condition can be new, used-fair, or used-good
INSERT INTO order_inventory
(product_code, product_condition, name, unit_price,
	stock, weight, dimensions,
	description)
VALUES
("gregory-amber-65-pack-womens", "new", "Amber 65 Pack - Women's", 239.95,
	10, 4, "29.5 x 13 x 12 in",
	"Providing the gear space needed for mega-treks of all types, the women's Gregory Amber 65 pack offers easy top loading and bottom access, while the breathable VersaFit suspension adjusts your fit."),
("Branzo-48", "used-good", "Branzo Bamboo Walking Stick", 75.65,
	4, 10, "49 x 5 x 12 in",
	"So whether you find your way along demanding hiking trails or the around the city block, these staffs are over-engineered for the task"),
("Ozark-10-Tent", "new", "Ozark Camping Tent- 10 person Cabin", 196.78,
	2, 31, "14 x 10 x 23 in",
	"The Ozark Trail 10-Person Instant Cabin Tent is the perfect tent to take with you on your next outdoor adventure. This tent sets up in under two minutes with the innovative instant frame design for easy and fun camping"),
("RailRoad-Lantern", "new", "RailRoad Rechargeable Camping Lantern", 99.99,
	12, 2, "6 x 5 x 13 in",
	"You'll use this lantern in your home when you are not at camp.  Check out the details of the seeded glass and the fine craftsmanship and quality materials."),
("Corzoi-38", "new", "Corzoi Bamboo Walking Stick", 90.87,
	13, 8, "39 x 5 x 6 in",
	"The traditional handle is the most commonly known in hiking sticks. No-frills, just the straight or natural shape of the sapling or lumber, this is the most popular style when it comes to walking sticks."),
("TrailOrange", "new", "Trail 25 Pack DayPack Orange ", 99.95,
	6, 2, "18 x 13 x 8 in",
	"Keep your day's gear within easy reach in the REI Co-op Trail 25 pack.");

-- insert orders, examples for shipped vs in-store pickup
INSERT INTO orders
(order_date, ship_street,
	cust_id,
	ship_city, ship_state, ship_zip)
VALUES
("2024-11-13", "418 Slip St Apt 3",
	(select cust_id from customer where first_name = "Sally"),
	"Palatine", "IL", 60067),
("2025-01-18", NULL,
	(select cust_id from customer where first_name = "John"),
	NULL, NULL, NULL),
("2025-02-10", "418 Slip St Apt 3",
	(select cust_id from customer where first_name = "Sally"),
	"Palatine", "IL", 60067),
("2025-02-12", "123 Ocean Ave",
	(select cust_id from customer where first_name = "Khloe"),
	"Denver", "CO", 80014),
("2025-02-14", "567 High St",
	(select cust_id from customer where first_name = "Matthew"),
	"Denver", "CO", 80014),
("2025-02-18", "1000 Park Ave",
	(select cust_id from customer where first_name = "Tyson"),
	"Denver", "CO", 80014);

-- insert order items
INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking,
	order_id)
VALUES
("gregory-amber-65-pack-womens", "new", 1, "pretend tracking number",
	(select order_id from orders where order_date = "2024-11-13")),
("gregory-amber-65-pack-womens", "new", 1, "ABC12345",
	(select order_id from orders where order_date = "2025-02-10")),
("Branzo-48", "used-good", 2, "XYZ23456",
	(select order_id from orders where order_date = "2025-02-12")),
("Ozark-10-Tent", "new", 1, "LMN34567",
	(select order_id from orders where order_date = "2025-02-14")),
("RailRoad-Lantern", "new", 1, "OPQ45678",
	(select order_id from orders where order_date = "2025-02-18")),
("TrailOrange", "new", 3, "RST56789",
	(select order_id from orders where order_date = "2025-02-12"));

-- More orders with items for each, generated by ChatGPT

-- Order #1 (James, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-03-15", "789 Pine St", 
	(select cust_id from customer where first_name = "James"),
	"Chicago", "IL", 60601);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("gregory-amber-65-pack-womens", "new", 1, "ABC67890",
	(select order_id from orders where order_date = "2024-03-15")),
("Branzo-48", "used-good", 1, "XYZ11122",
	(select order_id from orders where order_date = "2024-03-15"));

-- Order #2 (Olivia, in-store pickup)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-04-20", NULL, 
	(select cust_id from customer where first_name = "Olivia"),
	NULL, NULL, NULL);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("Ozark-10-Tent", "new", 2, NULL,
	(select order_id from orders where order_date = "2024-04-20")),
("Corzoi-38", "new", 1, NULL,
	(select order_id from orders where order_date = "2024-04-20"));

-- Order #3 (Liam, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-05-05", "456 Oak St", 
	(select cust_id from customer where first_name = "Liam"),
	"Chicago", "IL", 60607);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("RailRoad-Lantern", "new", 1, "LMN67890",
	(select order_id from orders where order_date = "2024-05-05")),
("TrailOrange", "new", 1, "RST23456",
	(select order_id from orders where order_date = "2024-05-05"));

-- Order #4 (Isabella, in-store pickup)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-06-15", NULL, 
	(select cust_id from customer where first_name = "Isabella"),
	NULL, NULL, NULL);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("Branzo-48", "used-good", 1, NULL,
	(select order_id from orders where order_date = "2024-06-15")),
("gregory-amber-65-pack-womens", "new", 1, NULL,
	(select order_id from orders where order_date = "2024-06-15"));

-- Order #5 (Lucas, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-07-01", "123 Elm St", 
	(select cust_id from customer where first_name = "Lucas"),
	"Chicago", "IL", 60615);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("Ozark-10-Tent", "new", 1, "XYZ98765",
	(select order_id from orders where order_date = "2024-07-01")),
("RailRoad-Lantern", "new", 2, "OPQ23456",
	(select order_id from orders where order_date = "2024-07-01"));

-- Order #6 (Charlotte, in-store pickup)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-08-10", NULL, 
	(select cust_id from customer where first_name = "Charlotte"),
	NULL, NULL, NULL);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("TrailOrange", "new", 2, NULL,
	(select order_id from orders where order_date = "2024-08-10")),
("Corzoi-38", "new", 1, NULL,
	(select order_id from orders where order_date = "2024-08-10"));

-- Order #7 (Sophia, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-09-05", "789 Maple St", 
	(select cust_id from customer where first_name = "Sophia"),
	"Chicago", "IL", 60616);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("gregory-amber-65-pack-womens", "new", 1, "DEF56789",
	(select order_id from orders where order_date = "2024-09-05")),
("Ozark-10-Tent", "new", 1, "XYZ34567",
	(select order_id from orders where order_date = "2024-09-05"));

-- Order #8 (Ethan, in-store pickup)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-09-25", NULL, 
	(select cust_id from customer where first_name = "Ethan"),
	NULL, NULL, NULL);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("TrailOrange", "new", 3, NULL,
	(select order_id from orders where order_date = "2024-09-25")),
("Branzo-48", "used-good", 1, NULL,
	(select order_id from orders where order_date = "2024-09-25"));

-- Order #9 (Matthew, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-10-10", "234 Birch St", 
	(select cust_id from customer where first_name = "Matthew"),
	"Chicago", "IL", 60617);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("RailRoad-Lantern", "new", 1, "LMN45678",
	(select order_id from orders where order_date = "2024-10-10")),
("Branzo-48", "used-good", 2, "XYZ78901",
	(select order_id from orders where order_date = "2024-10-10"));

-- Order #10 (Khloe, in-store pickup)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-11-01", NULL, 
	(select cust_id from customer where first_name = "Khloe"),
	NULL, NULL, NULL);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("Corzoi-38", "new", 1, NULL,
	(select order_id from orders where order_date = "2024-11-01"));

-- Order #11 (Tyson, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2024-12-15", "123 Pine St", 
	(select cust_id from customer where first_name = "Tyson"),
	"Chicago", "IL", 60618);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("gregory-amber-65-pack-womens", "new", 1, "LMN56789",
	(select order_id from orders where order_date = "2024-12-15"));

-- Order #12 (Sandra, shipped)
INSERT INTO orders
(order_date, ship_street, cust_id, ship_city, ship_state, ship_zip)
VALUES
("2025-01-05", "789 Oak St", 
	(select cust_id from customer where first_name = "Sandra"),
	"Chicago", "IL", 60619);

INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("Ozark-10-Tent", "new", 2, "ABC12345",
	(select order_id from orders where order_date = "2025-01-05"));

-- Add order items for Order #2 (John) (added after having ChatGPT check if any existing orders had no items)
INSERT INTO order_item
(product_code, product_condition, quantity, ship_tracking, order_id)
VALUES
("gregory-amber-65-pack-womens", "new", 1, NULL,
	(select order_id from orders where order_date = "2025-01-18")),
("Branzo-48", "used-good", 1, NULL,
	(select order_id from orders where order_date = "2025-01-18"));

-- insert rentals
INSERT INTO rental
(rental_date, start_date, end_date,
	cust_id)
VALUES
("2025-02-20", "2025-02-20", "2025-02-24",
	(select cust_id from customer where first_name = "Sally")),
("2025-02-21", "2025-02-21", "2025-02-28",
	(select cust_id from customer where first_name = "Sally")),
("2025-02-22", "2025-02-22", "2025-03-02",
	(select cust_id from customer where first_name = "Khloe")),
("2025-02-23", "2025-02-23", "2025-03-03",
	(select cust_id from customer where first_name = "Matthew")),
("2025-02-24", "2025-02-24", "2025-03-04",
	(select cust_id from customer where first_name = "Tyson")),
("2025-02-25", "2025-02-25", "2025-03-05",
	(select cust_id from customer where first_name = "Sandra")),
("2024-03-02", "2024-03-02", "2024-03-08", 
	(SELECT cust_id FROM customer WHERE first_name = "James")),
("2024-04-10", "2024-04-10", "2024-04-16", 
	(SELECT cust_id FROM customer WHERE first_name = "Olivia")),
("2024-05-15", "2024-05-15", "2024-05-21", 
	(SELECT cust_id FROM customer WHERE first_name = "Liam")),
("2024-06-01", "2024-06-01", "2024-06-07", 
	(SELECT cust_id FROM customer WHERE first_name = "Isabella")),
("2024-06-25", "2024-06-25", "2024-07-01", 
	(SELECT cust_id FROM customer WHERE first_name = "Lucas")),
("2024-07-10", "2024-07-10", "2024-07-16", 
	(SELECT cust_id FROM customer WHERE first_name = "Charlotte")),
("2024-08-05", "2024-08-05", "2024-08-11", 
	(SELECT cust_id FROM customer WHERE first_name = "Sophia")),
("2024-09-12", "2024-09-12", "2024-09-18", 
	(SELECT cust_id FROM customer WHERE first_name = "Ethan")),
("2024-09-30", "2024-09-30", "2024-10-06", 
	(SELECT cust_id FROM customer WHERE first_name = "Matthew")),
("2024-10-21", "2024-10-21", "2024-10-27", 
	(SELECT cust_id FROM customer WHERE first_name = "Khloe")),
("2024-11-07", "2024-11-07", "2024-11-13", 
	(SELECT cust_id FROM customer WHERE first_name = "Sally")),
("2024-11-18", "2024-11-18", "2024-11-24", 
	(SELECT cust_id FROM customer WHERE first_name = "Tyson")),
("2024-12-04", "2024-12-04", "2024-12-10", 
	(SELECT cust_id FROM customer WHERE first_name = "Emma")),
("2025-01-02", "2025-01-02", "2025-01-08", 
	(SELECT cust_id FROM customer WHERE first_name = "Lucas")),
("2025-01-15", "2025-01-15", "2025-01-21", 
	(SELECT cust_id FROM customer WHERE first_name = "Liam")),
("2025-01-22", "2025-01-22", "2025-01-28", 
	(SELECT cust_id FROM customer WHERE first_name = "Olivia")),
("2025-02-07", "2025-02-07", "2025-02-13", 
	(SELECT cust_id FROM customer WHERE first_name = "John")),
("2025-02-14", "2025-02-14", "2025-02-20", 
	(SELECT cust_id FROM customer WHERE first_name = "Sandra")),
("2025-02-16", "2025-02-16", "2025-02-22", 
	(SELECT cust_id FROM customer WHERE first_name = "Sophia")),
("2025-02-19", "2025-02-19", "2025-02-25", 
	(SELECT cust_id FROM customer WHERE first_name = "Charlotte"));

-- insert rental inventory; examples of never-been-rented vs currently rented item
INSERT INTO rental_inventory
(initial_use, rate, product_condition, product_code,
	rental_id)
VALUES
(NULL, 8.75, "new", "gregory-amber-65-pack-womens",
	NULL),
("2019-02-05", 8.75, "good", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-20")),
(NULL, 8.75, "new", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-21")),
("2013-05-10", 8.75, "good", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-22")),
("2023-06-15", 25.50, "fair", "Ozark-10-Tent",
	(select rental_id from rental where rental_date = "2025-02-23")),
("2020-07-25", 10.00, "used-good", "RailRoad-Lantern",
	(select rental_id from rental where rental_date = "2025-02-24")),
("2022-08-01", 8.75, "new", "TrailOrange",
	(select rental_id from rental where rental_date = "2025-02-25")),
("2020-03-12", 8.75, "new", "gregory-amber-65-pack-womens", 
	NULL),
("2021-08-07", 8.75, "used-good", "Branzo-48", 
	NULL),
("2019-06-15", 25.50, "new", "Ozark-10-Tent", 
	NULL),
("2020-11-23", 8.75, "new", "RailRoad-Lantern", 
	NULL),
("2018-09-10", 8.75, "new", "Corzoi-38", 
	NULL),
("2022-01-30", 8.75, "new", "TrailOrange", 
	NULL),
("2023-04-18", 8.75, "used-good", "gregory-amber-65-pack-womens", 
	NULL),
("2021-07-22", 25.50, "used-good", "Ozark-10-Tent", 
	NULL),
(NULL, 10.00, "new", "RailRoad-Lantern", 
	NULL);

-- insert rental history
INSERT INTO rental_history
(item_id,
	rental_id,
	issue_condition, return_condition)
VALUES
((select item_id from rental_inventory where initial_use = "2019-02-05" LIMIT 1),
	(select rental_id from rental where rental_date = "2025-02-20"),
	"good", NULL),
((select item_id from rental_inventory where initial_use = "2013-05-10" LIMIT 1),
	(select rental_id from rental where rental_date = "2025-02-22"),
	"good", NULL),
((select item_id from rental_inventory where initial_use = "2023-06-15" LIMIT 1),
	(select rental_id from rental where rental_date = "2025-02-23"),
	"good", NULL),
((select item_id from rental_inventory where initial_use = "2020-07-25" LIMIT 1),
	(select rental_id from rental where rental_date = "2025-02-24"),
	"good", NULL),
((select item_id from rental_inventory where initial_use = "2022-08-01" LIMIT 1),
	(select rental_id from rental where rental_date = "2025-02-25"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2019-02-05" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-20"), 
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2019-02-05" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-20"), 
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2020-03-12" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-21"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2013-05-10" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-22"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2023-06-15" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-23"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-07-25" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-24"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-08-01" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-25"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2020-03-12" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-03-02"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Branzo-48" AND initial_use >= "2021-08-07" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-04-10"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2021-07-22" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-05-15"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2019-06-15" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-06-01"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-01-30" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-06-25"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-01-30" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-06-25"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Branzo-48" AND initial_use >= "2021-08-07" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-07-10"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-11-23" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-08-05"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-01-30" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-09-12"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2021-07-22" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-09-12"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Branzo-48" AND initial_use >= "2021-08-07" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-09-30"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2019-02-05" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-10-21"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-11-23" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-11-07"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2020-03-12" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-11-07"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-08-01" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-11-18"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2023-06-15" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-12-04"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-07-25" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2024-12-04"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-01-30" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-01-02"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Branzo-48" AND initial_use >= "2021-08-07" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-01-15"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2021-07-22" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-01-15"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "gregory-amber-65-pack-womens" AND initial_use >= "2020-03-12" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-01-22"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-11-23" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-01-22"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2023-04-18" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-07"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Corzoi-38" AND initial_use >= "2018-09-10" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-14"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "RailRoad-Lantern" AND initial_use >= "2020-07-25" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-14"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "TrailOrange" AND initial_use >= "2022-01-30" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-16"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Branzo-48" AND initial_use >= "2021-08-07" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-19"),
	"good", NULL),
((SELECT item_id FROM rental_inventory WHERE product_code = "Ozark-10-Tent" AND initial_use >= "2021-07-22" LIMIT 1),
	(SELECT rental_id FROM rental WHERE rental_date = "2025-02-19"),
	"good", NULL);

-- insert guide reqs
INSERT INTO guide_req
(name, valid_months, governing_org,
	description)
VALUES
("CPR", 24, "https://www.redcross.org",
	"Guides need to be able to perform CPR in the event of an emergency."),
("Wilderness First Aid", 12, "https://www.redcross.org",
	"Guides need to be able to treat anything from scratches to illness."),  
("Leave No Trace Awareness", 24, "https://lnt.org/get-involved/training-courses/",
	"Understanding the importance of protecting nature by leaving no trace"),
("Wilderness Fire Safety", 4, "https://www.fs.usda.gov/managing-land/fire/training",
	"Only you can prevent forest fires.") ,
("WFA Certificate", 24, "Wilderness Guide Association",
	"Guides need a basic understanding of reading maps, field training etc"),
("WGA Training", 48, "Wilderness Guide Association",
	"Physically be able to withstand the job") ;

-- insert guide req tracker entries
INSERT INTO guide_req_tracker
(complete_date, status,
	req_id,
	staff_id)
VALUES
("2023-03-18", "Certified",
	(select req_id from guide_req where name = "CPR"),
	(select staff_id from staff where nick_name = "Mac")),
("2025-01-10", "Certified",
	(select req_id from guide_req where name = "CPR"),
	(select staff_id from staff where nick_name = "Duke")),
("2025-01-15", "Certified",
	(select req_id from guide_req where name = "Wilderness First Aid"),
	(select staff_id from staff where nick_name = "Mac")),
("2025-01-20", "Certified",
	(select req_id from guide_req where name = "Leave No Trace Awareness"),
	(select staff_id from staff where nick_name = "Duke")),
("2025-01-22", "Certified",
	(select req_id from guide_req where name = "Wilderness Fire Safety"),
	(select staff_id from staff where nick_name = "Duke")),
("2022-02-15", "Certified",
	(select req_id from guide_req where name = "WGA Training"),
	(select staff_id from staff where nick_name = "Mac"));