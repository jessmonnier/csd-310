# Jessica Monnier
# CSD310 Assignment 7.2
# 16 February 2025

import os
import mysql.connector as db
from mysql.connector import errorcode
from dotenv import dotenv_values

# .env is in parent folder; this gets absolute path to parent folder
# Did this so I don't have to move to file's folder for it to execute properly
parent_dir = "\\".join(os.path.realpath(__file__).split("\\")[:-2])

# .env file must be in parent folder for this to work
# e.g. this script is in csd-310\module-7 and .env is in csd-310
secrets = dotenv_values(parent_dir + "\\.env")

""" database config object """
config = {
    "user": secrets["USER"],
    "password": secrets["PASSWORD"],
    "host": secrets["HOST"],
    "database": secrets["DATABASE"],
    "raise_on_warnings": True #not in .env file
}

try:
    """ try/catch block for handling potential MySQL database errors """ 

    movies = db.connect(**config) # connect to the movies database 
    
    # output the connection status 
    print("\n  Database user {} connected to MySQL on host {} with database {}".format(config["user"], config["host"], config["database"]))

    # Create cursor to use for executing queries
    cursor = movies.cursor()

    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to first query...\n")

    # Query 1: print the ID & name of each entry in studio table
    print("\n-- DISPLAYING Studio RECORDS --")
    cursor.execute("SELECT studio_id, studio_name FROM studio")
    studios = cursor.fetchall()
    for studio in studios:
        print(f"Studio ID: {studio[0]}")
        print(f"Studio Name: {studio[1]}")
        print()
    
    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to second query...\n")

    # Query 2: print the ID & name of each entry in genre table
    print("\n-- DISPLAYING Genre RECORDS --")
    cursor.execute("SELECT genre_id, genre_name FROM genre")
    genres = cursor.fetchall()
    for genre in genres:
        print(f"Genre ID: {genre[0]}")
        print(f"Genre Name: {genre[1]}")
        print()
    
    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to third query...\n")

    # Query 3: print the name and runtime of movies < 2 hours long
    print("\n-- DISPLAYING Short Film RECORDS --")
    cursor.execute("SELECT film_name, film_runtime FROM film WHERE film_runtime < 120")
    shorts = cursor.fetchall()
    for short in shorts:
        print(f"Film Name: {short[0]}")
        print(f"Runtime: {short[1]} minutes")
        print()
    
    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to fourth query...\n")

    # Query 4: print the name and director of all films, ordered by director name
    print("\n-- DISPLAYING Director RECORDS in Order --")
    cursor.execute("SELECT film_name, film_director FROM film ORDER BY film_director")
    films = cursor.fetchall()
    for film in films:
        print(f"Film Name: {film[0]}")
        print(f"Director: {film[1]}")
        print()
    
    # Control flow of program with input "breaks"
    input("\n  Queries complete, press Enter to exit...\n")

except db.Error as err:
    """ on error code """

    if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
        print("  The supplied username or password are invalid")

    elif err.errno == errorcode.ER_BAD_DB_ERROR:
        print("  The specified database does not exist")

    else:
        print(err)

finally:
    """ close the connection to MySQL """

    movies.close()