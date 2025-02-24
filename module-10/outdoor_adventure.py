# BLUE TEAM: Vaneshiea Bell, Jess Monnier, DeJanae Faison
# Professor Sue Sampson
# Assignment 10 Milestone 2, 2/23/25
# Connect to SQL file and print contents of database tables
import mysql.connector
from mysql.connector import errorcode
import os

# Connect to .env file
from dotenv import dotenv_values

# Get the directory of the script so we don't have to execute 
# the script from that directory for the .env file to work
working_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(working_dir)

# Using ENV file
secrets = dotenv_values(".env")

config = {
    "user": secrets["USER"],
    "password": secrets["PASSWORD"],
    "host": secrets["HOST"],
    "database": secrets["DATABASE"],
    "raise_on_warnings": True # not in .env file
}

# open connection with error checking
try:
    """ try/catch block for handling potential MySQL database errors """ 

    db = mysql.connector.connect(**config) # connect to the database 
    
    # output the connection status 
    print("\n  Database user {} connected to MySQL on host {} with database {}".format(config["user"], config["host"], config["database"]))

    input("\n\n  Press Enter to view the contents of the customer table...")

    # Get a database "cursor" to execute queries in our database
    cursor = db.cursor()

    # Get all information from the customer table
    cursor.execute("SELECT * FROM customer")
    customers = cursor.fetchall()
    
    # Display customer info
    print("\n\n--Customers--")
    for customer in customers:
        # Use a multi-line string and its .format method to get a nice output
        print("""
ID: {}
Name: {} {}
Phone: {}
Address:
    {}
    {}, {} {}""".format(*customer))

    input("\n\n  Press Enter to view the contents of the staff table...")
    
    # Get the contents of the staff table
    cursor.execute("SELECT * FROM staff")
    employees = cursor.fetchall()
    
    # Display staff info
    print("\n\n--Staff--")
    for staff in employees:
        print("""
ID: {}
Name: {} {}
Nickname: {}
Phone: {}
Address:
    {}
    {}, {} {}
Email: {}
Salary: ${}
Bonus: {}
Role: {}""".format(*staff))

    input("\n\n  Press Enter to view the contents of the trip table...")
    
    # Get the contents of the trip table
    cursor.execute("SELECT * FROM trip")
    trips = cursor.fetchall()
    
    # Display trip info
    print("\n\n--Trip--")
    for trip in trips:
        print("""
ID: {}
Destination: {}
Dates: {} - {}
Staff ID of Guide: {}
Unit Fee: ${} (This is the charge per guest on top of the cost of their tickets etc.)
Primary Customer's ID: {}""".format(*trip))
    
    input("\n\n  Press Enter to view the contents of the trip_member table...")
    
    # Get the contents of the trip_member table
    cursor.execute("SELECT * FROM trip_member")
    trip_members = cursor.fetchall()
    
    # Display trip_member info
    print("\n\n--Trip Member--")
    for trip_member in trip_members:
        print("""
ID: {}
Trip ID: {}
Name: {} {} (Result of None None means this info is in the customer table)
Date of Birth: {}
Reservations: {}
Waiver: ${}
Email: {} (Result of None means this info is in the customer table)
Phone Number: {} (Ditto)
Customer ID: {} (Result of None means this trip member has no customer account)
Passport Status: {}
Emergency Contact Number: {}
Emergency Contact Name: {}
Emergency Contact Relationship: {}
Cost: ${} (This is the total cost of the customer's travel, lodging, etc.)""".format(*trip_member))
    
    input("\n\n  Press Enter to view the contents of the guide requirements table...")
    
    # Get the contents of the guide_req table
    cursor.execute("SELECT * FROM guide_req")
    guide_reqs = cursor.fetchall()
    
    # Display guide_req info
    print("\n\n--Guide Requirements--")
    for guide_req in guide_reqs:
        print("""
Requirement ID: {}
Name: {}
Description: 
    {}
Months Valid: {} (A result of None means it doesn't expire)
Governing Organization:
    {}""".format(*guide_req))
    
    input("\n\n  Press Enter to view the contents of the guide requirements tracking table...")
    
    # Get the contents of the guide_req_tracker table
    cursor.execute("SELECT * FROM guide_req_tracker")
    entries = cursor.fetchall()
    
    # Display guide_req_tracker info
    print("\n\n--Guide Requirement Tracker--")
    for entry in entries:
        print("""
ID: {}
Last Date of Completion: {}
Status: {}
Requirement ID: {}
Staff ID of Guide: {}""".format(*entry))
    
    input("\n\n  Press Enter to view the contents of the order inventory table...")
    
    # Get the contents of the order_inventory table
    cursor.execute("SELECT * FROM order_inventory")
    eqps = cursor.fetchall()
    
    # Display order_inventory info
    print("\n\n--Order Inventory--")
    for eqp in eqps:
        print("""
Product Code: {}
Product Condition: {}
Name: {}
Unit Price: ${}
Stock: {}
Weight: {} lbs (Approximate, for shipping)
Dimensions: {} (Also for shipping)
Description:
    {}""".format(*eqp))
    
    input("\n\n  Press Enter to view the contents of the orders table...")
    
    # Get the contents of the orders table
    cursor.execute("SELECT * FROM orders")
    orders = cursor.fetchall()
    
    # Display order info
    print("\n\n--Orders--")
    for order in orders:
        print("""
Order ID: {}
Date of Order: {}
Customer ID: {}
Shipping Info: (Will show "None" for all entries if picking up in store)
    {}
    {}, {} {}""".format(*order))
    
    input("\n\n  Press Enter to view the contents of the order item table...")
    
    # Get the contents of the order_item table
    cursor.execute("SELECT * FROM order_item")
    order_items = cursor.fetchall()
    
    # Display order_item info
    print("\n\n--Order Items--")
    for order_item in order_items:
        print("""
ID: {}
Product Code: {}
Product Condition: {}
Quantity: {}
Shipping Tracking Info: ("None" for in-store pickup)
    {}
Order ID: {}""".format(*order_item))
    
    input("\n\n  Press Enter to view the contents of the rental table...")
    
    # Get the contents of the rental table
    cursor.execute("SELECT * FROM rental")
    rentals = cursor.fetchall()
    
    # Display rental info
    print("\n\n--Rentals--")
    for rental in rentals:
        print("""
Rental ID: {}
Date of Rental Transaction: {}
Customer ID: {}
Rental Period: {} - {}""".format(*rental))
    
    input("\n\n  Press Enter to view the contents of the rental inventory table...")
    
    # Get the contents of the rental_inventory table
    cursor.execute("SELECT * FROM rental_inventory")
    eqps = cursor.fetchall()
    
    # Display rental_inventory info
    print("\n\n--Rental Inventory--")
    for eqp in eqps:
        print("""
Item ID: {}
Date of Initial Use: {} ("None" means it hasn't been rented yet)
Rate: ${} (per day)
Product Condition: {}
Product Code: {}
Rental ID: {} ("None" if not rented/reserved currently)""".format(*eqp))
    
    input("\n\n  Phew, we made it! Press Enter to exit...")

except mysql.connector.Error as err:
    """ on error code """

    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        print("  The supplied username or password are invalid")

    elif err.errno == errorcode.ER_BAD_DB_ERROR:
        print("  The specified database does not exist")

    else:
        print(err)


# Close the database
finally:
    """ close the connection to MySQL """

    db.close()