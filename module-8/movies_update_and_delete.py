# Jessica Monnier
# CSD310 Assignment 8.2
# 16 February 2025

import os
import mysql.connector as db
from mysql.connector import errorcode
from dotenv import dotenv_values

# .env is in parent folder; this gets absolute path to parent folder
# Did this so I don't have to move to file's folder for it to execute properly
parent_dir = "\\".join(os.path.realpath(__file__).split("\\")[:-2])

# .env file must be in parent folder for this to work
# e.g. this script is in csd-310\module-8 and .env is in csd-310
secrets = dotenv_values(parent_dir + "\\.env")

""" database config object """
config = {
    "user": secrets["USER"],
    "password": secrets["PASSWORD"],
    "host": secrets["HOST"],
    "database": secrets["DATABASE"],
    "raise_on_warnings": True, #not in .env file
    "autocommit": True # was confused why updates didn't stick... now they do
}

def show_films(cursor, title):
    ''' method to execute an inner join on all tables,
        iterate over the dataset and output results to terminal window '''
    
    # inner join query
    ''' I did the "as" bits as directed but don't really see why since
        the results are pulled positionally, not by name... 
        Also I did the query incrementally to keep the left-to-right
        sizing appropriate to a python script '''
    query = "SELECT film_name as Name, film_director as Director, "
    query += "genre_name as Genre, studio_name as Studio FROM film "
    query += "INNER JOIN genre ON film.genre_id = genre.genre_id "
    query += "INNER JOIN studio ON film.studio_id = studio.studio_id"
    cursor.execute(query)

    # Store results of query
    films = cursor.fetchall()

    print(f"\n -- {title} --")

    # Iterate over film data set and display the results
    for film in films:
        print(f"Name: {film[0]}")
        print(f"Director: {film[1]}")
        print(f"Genre: {film[2]}")
        print(f"Studio: {film[3]}")
        print()

try:
    """ try/catch block for handling potential MySQL database errors """ 

    movies = db.connect(**config) # connect to the movies database 
    
    # output the connection status 
    print(f"\n  Database user {config["user"]} connected to MySQL on host {config["host"]} with database {config["database"]}")

    # Create cursor to use for executing queries
    cursor = movies.cursor()

    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to display films in initial database...\n")

    # Call the function
    show_films(cursor, "DISPLAYING FILMS")

    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to add The Fifth Element & then re-display films...\n")

    # The Fifth Element: Gaumont, 126 minutes, 1997, SciFi, Luc Besson
    # Add studio first
    query = "INSERT INTO studio (studio_name) VALUES ('Gaumont')"
    cursor.execute(query)

    # Now add movie, looking up genre_id and studio_id on the go
    query = "INSERT INTO film (film_name, film_releaseDate, film_runtime, film_director, studio_id, "
    query += "genre_id) VALUES ('The Fifth Element', '1997', 126, 'Luc Besson', (SELECT studio_id FROM "
    query += "studio WHERE studio_name = 'Gaumont'), (SELECT genre_id FROM genre WHERE genre_name = 'SciFi'))"
    cursor.execute(query)

    # Call the function
    show_films(cursor, "DISPLAYING FILMS AFTER INSERT")

    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to update Alien genre & then re-display films...\n")

    # Update Alien's genre to Horror
    query = "UPDATE film SET genre_id = (SELECT genre_id FROM genre WHERE genre_name = 'Horror') "
    query += "WHERE film_name = 'Alien'"
    cursor.execute(query)

    # Call the function
    show_films(cursor, "DISPLAYING FILMS AFTER Alien Horror UPDATE")

    # Control flow of program with input "breaks"
    input("\n  Press Enter to continue to remove Gladiator & then display films...\n")

    # Remove Gladiator from database
    query = "DELETE FROM film WHERE film_name = 'Gladiator'"
    cursor.execute(query)

    # Call the function
    show_films(cursor, "DISPLAYING FILMS AFTER Gladiator DELETION")

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