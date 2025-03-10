"""
BLUE TEAM: Vaneshiea Bell, Jess Monnier, DeJanae Faison
Professor Sue Sampson
Assignment 12 Milestone 5, 3/9/2025
"""

# Import needed modules
import mysql.connector
from mysql.connector import errorcode
import os # Used to control python's working directory
import sys # Used if matplotlib is not installed
import tkinter as tk
from datetime import date
from tkinter import font # was being stubborn when not separately imported
from copy import deepcopy # Used for ease of having a template variable
import numpy as np # for the bar graph
# Print error and exit if matplotlib is not installed
try:
    from matplotlib import pyplot as plt
except ImportError:
    print('\nThis program requires the matplotlib module.')
    print('Please install it and try again.\n')
    sys.exit()

# Connect to .env file
from dotenv import dotenv_values

# Get the directory of the script so we don't have to execute 
# the script from that directory for the .env file to work
working_dir = os.path.dirname(os.path.realpath(__file__))
os.chdir(working_dir)

# Using ENV file; note we renamed ours .env_outland and moved
# to parent folder so it doesn't need to be duplicated each module
secrets = dotenv_values("..\\.env_outland")

# Set up config dictionary to match named variables expected by mysql.connector
config = {
    "user": secrets["USER"],
    "password": secrets["PASSWORD"],
    "host": secrets["HOST"],
    "database": secrets["DATABASE"],
    "raise_on_warnings": True # not in .env file
}

# Initial text variable values
welcome = "Welcome to Outland Adventures' Report Generator! "
welcome += "Please click on the button matching the report you would like to generate."
help_text = "Please click one of the report buttons to generate a report here. "
help_text += "Note that the Trip Destination Trends and Equipment Sales Trends reports "
help_text += "will also open a new window."
query = ""

# open connection with error checking
try:
    db = mysql.connector.connect(**config) # connect to the database 

    # Get a database "cursor" to execute queries in our database
    cursor = db.cursor()

    """ FUNCTIONS CALLED BY TKINTER APP BUTTONS """

    # Function to clear the contents of the report container frame
    def clear_frame(frame):
        for widget in frame.winfo_children():
            widget.destroy()
    
    # Function to build a template based on relevant quarters
    def generate_quarter_template(min_date, max_date):
        
        # Extract year/month from the dates
        earliest_year = int(min_date.year)
        earliest_month = int(min_date.month)
        latest_year = int(max_date.year)
        latest_month = int(max_date.month)
        
        # Determine starting quarter and make array to match
        # We'll be rotating through the array continuously, so
        # it's important to start at the right quarter.
        # For our purposes, Q1 is Jan-Mar, Q2 Apr-Jun, etc.
        if 1 <= earliest_month < 4:
            quarters = [1, 2, 3, 4]
        elif 4 <= earliest_month < 7:
            quarters = [2, 3, 4, 1]
        elif 7 <= earliest_month < 10:
            quarters = [3, 4, 1, 2]
        else:
            quarters = [4, 1, 2, 3]

        # Variables to be populated by following while loop; quarter end
        # dates will only be used in query, where template dictionary will
        # be used both in query and to generate report
        quarter_end_dates = []
        template = {'quarter': [], 'number': []}

        # While loop to generate the relevant quarter end-dates 
        # & quarter/# of order/rental template dictionary. We will be mutating
        # the earliest_year & earliest_month variables to control the loop.
        while earliest_year <= latest_year:
            
            # Get the appropriate end date for the quarter of the current
            # value of earliest_month and earliest_year, then append to list
            for quarter in quarters:
                if 1 <= earliest_month < 4:
                    date_string = str(earliest_year) + "-03-31"
                elif 4 <= earliest_month < 7:
                    date_string = str(earliest_year) + "-06-30"
                elif 7 <= earliest_month < 10:
                    date_string = str(earliest_year) + "-09-30"
                else:
                    date_string = str(earliest_year) + "-12-31"
                quarter_end_dates.append(date_string)
                
                # Append the current quarter to quarter key of template, append 0
                # as the number of orders/rentals to the number key of template; this is to
                # ensure that if query returns 0 items for a quarter, it is not skipped.
                template['quarter'].append(str(earliest_year) + "Q" + str(quarter)) # e.g. 2025Q1
                template['number'].append(0)

                # Add three months to get to the next quarter
                earliest_month += 3

                # If we go beyond 12, change it to the beginning of the next year instead
                if earliest_month > 12:
                    earliest_month -= 12
                    earliest_year += 1
                
                # Check to see if we've reached/surpassed the latest trip date & if so, break
                if earliest_year == latest_year and earliest_month >= latest_month:
                    break
            
            # Need to do a second check outside the for loop to break the while loop
            # Without this we might get 1-3 extra empty quarters, depending on latest 
            # vs earliest quarter number.
            if earliest_year == latest_year and earliest_month >= latest_month:
                break
        
        return quarter_end_dates, template
    
    # Function to make a table out of a dictionary of dictionaries
    def generate_table(template, labels, data_dict):

        # Create a "table" out of tkinter Entry widgets to show the data in a neat format.
        # I learned this technique from a GeeksforGeeks tutorial bc str.center(width) was being stubborn ._.
        for n in range(-1, len(template['quarter'])):
            for i, label in enumerate(labels):
                
                # Create the Entry widget, assign its position within report_container frame
                # n starts at -1 for ease of identifying the label row, so the actual row value
                # for each entry is n+1 (to start at 0).
                e = tk.Entry(report_container, justify = "center")
                e.grid(row = n+1, column = i)

                # Handle label row
                if n == -1:
                    e.insert(tk.END, label)
                    e.configure(font = (default_font["family"], default_font["size"]-1, "bold"))
                
                # Handle data rows by looking up the correct quarter from template based on
                # current value of n OR correct number of items from data_dict based on both
                # the current value of n and the current label
                else:
                    if label == "Quarter":
                        e.insert(tk.END, template['quarter'][n])
                    else:
                        e.insert(tk.END, data_dict[label]["number"][n])
    
    # Function to generate a report on equipment sales trends
    def equipment_report():
       
        # Clear report container frame
        clear_frame(report_container)

        '''SETTING UP THE DATA QUERIES'''

        # Get earliest date between orders and rentals
        query = "select order_date from orders order by order_date limit 1;"
        cursor.execute(query)
        earliest_order = cursor.fetchone()[0]
        query = "select rental_date from rental order by rental_date limit 1;"
        cursor.execute(query)
        earliest_rental = cursor.fetchone()[0]
        earliest_date = min(earliest_rental, earliest_order)
        
        # Get latest date between orders and rentals
        query = "select order_date from orders order by order_date desc limit 1;"
        cursor.execute(query)
        latest_order = cursor.fetchone()[0]
        query = "select rental_date from rental order by rental_date desc limit 1;"
        cursor.execute(query)
        latest_rental = cursor.fetchone()[0]
        latest_date = max(latest_rental, latest_order)
                
        # Throw these dates into our function that generates the needed variables
        quarter_end_dates, template = generate_quarter_template(earliest_date, latest_date)
        
        '''MAIN QUERY LOOP'''

        # make a query for each table, store in results dictionary
        results = {'order': deepcopy(template), 'rental': deepcopy(template)}
        for n in range(2):
            # Establish table name based on n; annoyingly, "alt" is needed bc
            # we had to pluralize order table to deconflict SQL keyword
            if n == 0:
                table1 = "orders"
                alt = "order"
                table2 = "order_item"
            else:
                table1 = "rental"
                alt = "rental"
                table2 = "rental_history"
            
            # Start of query; get from correct table, initiate a case
            query = "select case "

            # for loop with the quarter array we generated to build the query case
            for i, entry in enumerate(quarter_end_dates[:-1]):
                query += "when " + table1 + "." + alt + "_date <= '" + entry
                query += "' then '" + template['quarter'][i] + "' "
            
            # order_item has a quantity column that needs to be factored in so...
            if n==0:
                query += "else'" + template['quarter'][-1] + "' end, sum("
                query += "order_item.quantity) from order_item"
            else:
                query += "else '" + template['quarter'][-1] + "' end, count("
                query += "rental_history.id) from  rental_history"

            # left join the tables & group by quarter
            query += " left join " + table1 + " on " + table1 + "." + alt
            query += "_id = " + table2 + "." + alt + "_id group by 1"

            # Send query to the database, store in temp_results
            cursor.execute(query)
            temp_results = cursor.fetchall()

            # Our template has every possible quarter with a corresponding 0 in the number key's list,
            # so we want to look up the index of the current quarter in the quarter key and then
            # change the number at that index in the number key's list to the corresponding value
            for result in temp_results:
                results[alt]['number'][results[alt]['quarter'].index(result[0])] = result[1]
       
        '''GENERATE TEXTUAL REPORT'''

        # Set the summary/help text in tkinter
        report = "A chart should populate in a new window that will give a better visual of the following results. "
        report += "For each quarter, the numbers shown represents the number of ordered/rented items during that quarter."
        report += " Q1 is January through March, Q2 is April through June, and so on.\n\n"
        report += f"Equipment Sales Trends Report Generated {date.today().strftime("%#d %B %Y")}:"
        help_label.config(text = report)

        # Create an initial list of labels (Quarter, each continent name)
        labels = ["Quarter"]
        labels.extend(results.keys())

        # Send to our handy dandy table generator
        generate_table(template, labels, results)

        '''GRAPHICAL REPORT VIA MATPLOTLIB'''

        # Plot the results as a bar graph        
        x = np.arange(len(template['quarter'])) # For label locations
        width = 0.2 # width of the bars

        fig, ax = plt.subplots(layout='constrained')

        offset = width * 0
        rects = ax.bar(x + offset, results['order']['number'], width, label="Ordered Items")
        ax.bar_label(rects, padding=3)

        offset = width * 1
        rects = ax.bar(x + offset, results['rental']['number'], width, label="Rented Items")
        ax.bar_label(rects, padding=3)
        
        # Configure titles etc for plot and axes, add a legend, show the plot
        ax.set_title("Equipment Rentals vs Orders")
        ax.set_xlabel('Quarter')
        ax.set_ylabel("Number of Items Rented/Ordered")
        ax.set_xticks(x + width, template['quarter'])
        ax.set_ylim(0, 35)
        ax.legend(loc="upper left", ncols=2)
        plt.show()

    def trip_report():

        # Clear report container frame
        clear_frame(report_container)
        
        '''INITIAL QUERIES TO GET DISTINCT CONTINENTS, EARLIEST/LATEST TRIP'''

        # Get all continent values in database where
        # continent follows the final ', ' in the destination string
        query = "select distinct substring_index(destination, ', ', -1) as 'Continent' from trip;"
        cursor.execute(query)
        continents = cursor.fetchall()

        # Get earliest trip end in database to help find earliest quarter
        query = "select trip_end from trip order by trip_end limit 1;"
        cursor.execute(query)
        earliest_trip = cursor.fetchone()[0] # returns a tuple, of which we want index 0

        # Get latest trip end in database to help find latest quarter
        query = "select trip_end from trip order by trip_end desc limit 1;"
        cursor.execute(query)
        latest_trip = cursor.fetchone()[0]

        # Throw these dates into our function that generates the needed variables
        quarter_end_dates, template = generate_quarter_template(earliest_trip, latest_trip)
        
        '''MAIN QUERY LOOP'''

        # make a query for each continent, store in results dictionary
        results = {}
        for res in continents:
            continent = res[0] # Get just the continent name out of result tuple

            # Use copy module's deepcopy method to get an actual copy of the template
            # that won't be mutated by each run of the loop
            results[continent] = deepcopy(template)

            # Start of query; get by continent name, initiate a case
            query = "select substring_index(destination, ', ', -1) as 'Continent', case "

            # for loop with the quarter array we generated to build the query case
            for i, entry in enumerate(quarter_end_dates[:-1]):
                query += "when trip_end <= '" + entry + "' then '" + template['quarter'][i] + "' "
            
            # capture that final index as the else statement for the case
            query += "else '" + template['quarter'][-1] + "' end, count(*) from trip "
            
            # finish up query with grouping, limiting to current continent, ordering
            query += "group by 2, 1 having continent = '" + continent + "' order by 2;"

            # Send query to the database, store in temp_results
            cursor.execute(query)
            temp_results = cursor.fetchall()

            # Our template has every possible quarter with a corresponding 0 in the number key's list,
            # so we want to look up the index of the current quarter in the quarter key and then
            # change the number at that index in the number key's list to the corresponding value
            for result in temp_results:
                results[continent]['number'][results[continent]['quarter'].index(result[1])] = result[2]
        
        '''GENERATE TEXTUAL REPORT'''

        # Set the summary/help text in tkinter
        report = "A chart should populate in a new window that will give a better visual of the following results. "
        report += "For each quarter and continent, the number shown represents the number of trips to that continent "
        report += "that ended during that quarter. Q1 is January through March, Q2 is April through June, and so on.\n\n"
        report += f"Trip Destination Trends Report Generated {date.today().strftime("%#d %B %Y")}:"
        help_label.config(text = report)

        # Create an initial list of labels (Quarter, each continent name)
        labels = ["Quarter"]
        labels.extend(results.keys())

        # Send to our handy dandy table generator
        generate_table(template, labels, results)

        '''GRAPHICAL REPORT VIA MATPLOTLIB'''

        # Create an array of possible colors to use; more would need to be added if there
        # were trips to more than 6 continents/major continental areas          
        colors = ['red', 'blue', 'green', 'purple', 'orange', 'brown']

        # For each continent, use its index to pick its line color and use its "quarter" list for
        # x values and its "number" list for y values; also label it by name
        for i, continent in enumerate(results.keys()):
            plt.plot(results[continent]['quarter'], results[continent]['number'], label=continent, c=colors[i])
        
        # Configure titles etc for plot and axes, add a legend, show the plot
        plt.title("Trip Destination Trends", fontsize=18)
        plt.xlabel('Quarter', fontsize=14)
        plt.ylabel("Number of Trips", fontsize=14)
        plt.tick_params(axis='both', which='major', labelsize=12)
        plt.legend()
        plt.show()

    # Function to display the report of rental items with more than 5 years of use
    def inventory_report():

        # Clear report container frame
        clear_frame(report_container)

        # Execute the query
        cursor.execute("""SELECT 
                       ri.rental_id, ri.initial_use, oi.name,
                       timestampdiff(year, ri.initial_use, curdate()),
                       timestampdiff(month, ri.initial_use, curdate()) % 12
                       FROM rental_inventory ri INNER JOIN order_inventory oi
                       ON ri.product_code = oi.product_code 
                       HAVING initial_use < CURDATE() - INTERVAL 54 MONTH
                       order by ri.initial_use desc;""")
        inventoryAges = cursor.fetchall()
        
        # Handle an empty result set
        if not inventoryAges:
            help_label.config(text="No results were found. Congratulations, no rental inventory has been in use for over 4.5 years.")
        
        # Generate the report
        else:
            help_text = "Below, find a report on rental equipment that has been rented out for over 4.5 years. "
            help_text += "This is meant to help ID rental equipment that should be retired already, as well as "
            help_text += "rental equipment coming up on its fifth year of use within the next 6 months. Note that "
            help_text += "if an item has a Rental ID, it implies that it is currently reserved or rented.\n\n"
            help_text += "You may need to scroll to view all items.\n"

            # Use a tkinter Text widget to enable different font colors
            text_widget = tk.Text(report_container, width=75, font=(default_font["family"], default_font["size"]))
            text_widget.pack(side="left", fill="both", expand=True)
            scrollbar = tk.Scrollbar(report_container, orient="vertical", command=text_widget.yview)
            scrollbar.pack(side="right", fill="y")
            text_widget.configure(yscrollcommand=scrollbar.set)

            # Set the highlight and red font tags
            text_widget.tag_configure("red", foreground="red")
            text_widget.tag_configure("hl", background="yellow")

            # Info key for the report
            text_widget.insert(1.0, f"Inventory Age Report Generated {date.today().strftime("%#d %B %Y")}\n", "")
            text_widget.insert("end", "Highlight", "hl")
            text_widget.insert("end", ": has been in rental circulation between 4.5 and 5 years.\n", "")
            text_widget.insert("end", "Red", "red")
            text_widget.insert("end", ": has been in rental circulation 5 years or more.", "")

            # Build out the actual report data, making the "In Use" line for items that have been in
            # rental circulation for 5 or more years red, and otherwise "highlighting" the "In Use" line
            for inventoryAge in inventoryAges:
                if inventoryAge[3] >= 5:
                    text_tag = "red"
                else:
                    text_tag = "hl"
                text_widget.insert("end", "\n\nRental ID: {}\n".format(inventoryAge[0]), "")
                text_widget.insert("end", "Name: {}\n".format(inventoryAge[2]), "")
                text_widget.insert("end", "Initial Use: {}\n".format(inventoryAge[1].strftime("%#d %B %Y")), "")
                text_widget.insert("end", "In Use: {} years, {} months".format(inventoryAge[3], inventoryAge[4]), text_tag)
            
            # Update the help text above the report
            help_label.config(text = help_text)

    """ BUILD TKINTER APP WINDOW """
    
    # Build the main app window.
    window = tk.Tk()
    window.title("Outland Adventure Reports")
    window.geometry("520x700")

    # Get the default font values
    default_font = font.nametofont("TkDefaultFont").actual()

    # Include a static greeting with instructions the user can refer back to as needed.
    greeting = tk.Label(window,
                        text = welcome,
                        wraplength = 480,
                        justify = "left")
    greeting.grid(row = 0,
                columnspan = 3,
                padx = 10,
                pady = 5,
                sticky = "NSEW")
    
    # Create the buttons that generate the reports and set command to the matching function
    equipment_button = tk.Button(window,
                            text = "Equipment Sales Trends",
                            command = equipment_report)
    equipment_button.grid(row = 1,
                        column = 0,
                        padx = 20,
                        pady = 5,
                        sticky = "NESW")

    trip_button = tk.Button(window,
                            text = "Trip Destination Trends",
                            command = trip_report)
    trip_button.grid(row = 1,
                    column = 1,
                    padx = 20,
                    pady = 5,
                    sticky = "NSEW")
    
    inventory_button = tk.Button(window,
                                 text = "Inventory Age Report",
                                 command = inventory_report)
    inventory_button.grid(row = 1,
                          column = 2,
                          padx = 20,
                          pady = 5,
                          sticky = "NSEW")
    
    # Create the container for the help/description text for reports
    help_label = tk.Label(window,
                          text = help_text,
                          wraplength = 480,
                          justify = "left")
    help_label.grid(row = 2,
                    columnspan = 3,
                    padx = 10,
                    pady = 5,
                    sticky = "NSEW")
    
    # Create the container for the report itself; it's a frame, as each
    # function will generate its own label or what-have-you
    report_container = tk.Frame(window)
    report_container.grid(row = 3,
                          columnspan = 3,
                          padx = 10,
                          pady = 5,
                          sticky = "NSEW")
    
    # Open the tkinter window
    window.mainloop()

# MySQL connection error resolution actions
except mysql.connector.Error as err:
    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        print("  The supplied username or password are invalid")
    elif err.errno == errorcode.ER_BAD_DB_ERROR:
        print("  The specified database does not exist")
    else:
        print(err)

# Close the database
finally:
    db.close()