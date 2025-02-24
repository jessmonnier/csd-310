/*
    Title: db_init_2025.sql
    Author: Professor Sampson
	Modified by: Vaneshiea Bell, DeJanae Faison, Jess Monnier
    Date: 22 February 2025
    Description: outland database initialization script.
*/

-- create database if it doesn't exist yet
CREATE DATABASE IF NOT EXISTS outland;

-- drop database user if exists 
DROP USER IF EXISTS 'adm'@'localhost';

-- create movies_user and grant them all privileges to the movies database 
CREATE USER 'adm'@'localhost' IDENTIFIED WITH mysql_native_password BY 'adventure';

-- grant all privileges to the movies database to user movies_user on localhost 
GRANT ALL PRIVILEGES ON outland.* TO 'adm'@'localhost';

-- drop tables if they are present
DROP TABLE IF EXISTS guide_req_tracker;
DROP TABLE IF EXISTS guide_req;
DROP TABLE IF EXISTS trip_member;
DROP TABLE IF EXISTS trip;
DROP TABLE IF EXISTS rental_inventory;
DROP TABLE IF EXISTS rental;
DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS order_inventory;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS staff;

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
    salary			INT				NOT NULL,
    bonus			INT,					  -- not all employees get a bonus (mastly it's for the guides)
    staff_role		VARCHAR(20)		NOT NULL,
     
    PRIMARY KEY(staff_id)
); 

-- create the trip table and set the foreign keys
CREATE TABLE trip (
    trip_id			INT           	NOT NULL        AUTO_INCREMENT,
    destination 	VARCHAR(75)     NOT NULL,
    trip_start   	DATE     		NOT NULL,
	trip_end		DATE			NOT NULL,
	staff_id		INT				NOT NULL,
	unit_fee		INT 			NOT NULL,
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
    cost				FLOAT 			NOT NULL,
    
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

-- insert customers
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
	"Denver", "CO", 80015, "quahougSquare@gmail.com");

-- insert staff, example with all fields and with no nick name/bonus
INSERT INTO staff 
(first_name, nick_name, last_name, phone_number, addr_street,
	addr_city, addr_state, addr_zip, email,
	salary, bonus, staff_role)
VALUES 
("Blythe", NULL, "Timmerson", "555-555-8111", "2380 Chipper Ave",
	"Denver", "CO", 80016, "blythe@outlandadventures.com",
	75000, NULL, "Owner"),
("James", "Jim", "Ford", "578-902-0021", "90 Oliver Dr",
	"Denver", "CO", 80016, "jim@outlandadventures.com",
	75000, NULL, "Owner"),
("John", "Mac", "MacNell", "555-555-4321", "5612 Wandering Rd",
	"Denver", "CO", 80016, "mac@outlandadventures.com",
	48000, 50, "Guide"),
("D.B.", "Duke", "Marland", "728-351-7920", "143 Douglas St",
	"Denver", "CO", 80016, "duke@outlandadventures.com",
	49000, 50, "Guide"),
("Anita", NULL, "Gallegos", "555-555-8765", "52108 Blankenship St",
	"Denver", "CO", 80014, "anita@outlandadventures.com",
	51000, NULL, "Marketing"),
("Dimitrios", NULL, "Stravopolous", "555-555-1482", "5412 Saddle Ln",
	"Denver", "CO", 80015, "dimitrios@outlandadventures.com",
	50000, NULL, "Inventory Manager"),
("Mei", NULL, "Wong", "555-555-0147", "823 W Falcon Terr",
	"Denver", "CO", 80013, "mei@outlandadventures.com",
	50000, NULL, "Web Admin"),
("Alexi", "Lexi", "Tysons", "908-545-4001", "404 Dashing Rd",
	"Denver", "CO", 80016, "tysonL@outlandadventures.com",
	32000, 25, "Apprentence"),
("Karen", NULL, "Allison", "785-008-8765", "5800 Parkings St",
	"Denver", "CO", 80016, "allison@outlandadventures.com",
	51000, NULL, "Accountant");

-- insert trips, select statements needed bc of auto-increment of primary keys
INSERT INTO trip 
(destination, trip_start, trip_end, 
	staff_id, 
	unit_fee, 
	cust_primary)
VALUES 
("Zimbabwe, Africa", "2024-09-15", "2024-09-21", 
	(select staff_id from staff where nick_name = "Mac"),
	200,
	(select cust_id from customer where first_name = "John")),
("Mount Everest, Nepal, Asia", "2025-04-01", "2025-04-14", 
	(select staff_id from staff where nick_name = "Mac"),
	200,
	(select cust_id from customer where first_name = "Sally")),
("Taiwan, Asia", "2025-06-01", "2025-06-10", 
	(select staff_id from staff where nick_name = "Duke"),
	200,
	(select cust_id from customer where first_name = "Khloe")),
("Kilimanjaro, Africa", "2025-07-05", "2025-07-15", 
	(select staff_id from staff where nick_name = "Mac"),
	200,
	(select cust_id from customer where first_name = "Matthew")),
("Vitosha Nature Park, Bulgaria, Southern Europe", "2025-08-10", "2025-08-20", 
	(select staff_id from staff where nick_name = "Duke"),
	250,
	(select cust_id from customer where first_name = "Tyson")),
("Sierra Nevada, Southern Europe", "2025-09-10", "2025-09-20", 
	(select staff_id from staff where nick_name = "Mac"),
	250,
	(select cust_id from customer where first_name = "Sandra"));

-- insert trip members, example with/without customer account
INSERT INTO trip_member 
(trip_id, 
	date_of_birth, reservations, waiver,
	cust_id,
	passport_status, cost, phone_number, email, 
	first_name, last_name, emergency_number, emergency_name, emergency_relation)
VALUES
((select trip_id from trip where trip_start = "2024-09-15"),
	"1992-04-15", "American Airlines MDABRG", "pretend this is a data blob",
	(select cust_id from customer where first_name = "John"),
	"Complete", 653.12, NULL, NULL,
	NULL, NULL, "555-555-8713", "Amanda Smith", "mother"),
((select trip_id from trip where trip_start = "2024-09-15"),
	"1995-08-23", "American Airlines MDABRG", "pretend this is a data blob",
	NULL,
	"Complete", 624.73, "555-555-4376", "melanie.harmon.45@gmail.com",
	"Melanie", "Harmon", "555-555-1899", "Morgan Harmon", "sister"),
((select trip_id from trip where destination = "Mount Everest, Nepal, Asia"),
	"1988-06-12", "Delta Airlines XYZ1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Sally"),
	"Complete", 1200.00, NULL, NULL,
	NULL, NULL, "555-555-1122", "Jane Ride", "sister"),
((select trip_id from trip where destination = "Taiwan, Asia"),
	"1991-09-30", "United Airlines AB1234", "pretend this is a data blob",
	(select cust_id from customer where first_name = "Khloe"),
	"Complete", 1100.00, NULL, NULL,
	NULL, NULL, "555-555-2233", "Mark Arson", "father"),
((select trip_id from trip where destination = "Taiwan, Asia"),
	"1993-11-04", "American Airlines MCX8721", "pretend this is a data blob",
	NULL,
	"Submitted app 2/25, expected to take 3-4 weeks", 1500.00, "555-555-3333", "marshallMatthews@yahoo.com",
	"Matthew", "Lanes", "555-555-3344", "Lorna Lanes", "aunt"),
((select trip_id from trip where destination = "Taiwan, Asia"),
	"1990-03-20", "Southwest Airlines XYX9821", "pretend this is a data blob",
	NULL,
	"Complete", 1300.00, "555-555-4444", "knockOut@gmail.com",
	"Tyson", "Conners", "555-555-4455", "Holly Conners", "mother");

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
	"Keep your day's gear within easy reach in the REI Co-op Trail 25 pack.")  ;

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
	(select order_id from orders where order_date = "2025-02-12"))
;

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
	(select cust_id from customer where first_name = "Sandra"));

-- insert rental inventory; examples of never-been-rented vs currently rented item
INSERT INTO rental_inventory
(initial_use, rate, product_condition, product_code,
	rental_id)
VALUES
(NULL, 8.75, "new", "gregory-amber-65-pack-womens",
	NULL),
("2023-02-05", 8.75, "good", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-20")),
(NULL, 8.75, "new", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-21")),
("2023-05-10", 8.75, "good", "gregory-amber-65-pack-womens",
	(select rental_id from rental where rental_date = "2025-02-22")),
("2023-06-15", 25.50, "fair", "Ozark-10-Tent",
	(select rental_id from rental where rental_date = "2025-02-23")),
("2023-07-25", 10.00, "used-good", "RailRoad-Lantern",
	(select rental_id from rental where rental_date = "2025-02-24")),
("2023-08-01", 8.75, "new", "TrailOrange",
	(select rental_id from rental where rental_date = "2025-02-25"));

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