from sqlalchemy import create_engine
import psycopg2
from psycopg2 import Error
import pandas as pd
from sqlalchemy import text


def run_sql_from_file(sql_file, psql_conn):
    '''
    read a SQL file with multiple stmts and process it
    adapted from an idea by JF Santos
    '''
    sql_command = ''
    for line in sql_file:
        # Ignore commented lines
        if not line.startswith('--') and line.strip('\n'):
            # Append line to the command string, prefix with space
            sql_command += ' ' + line.strip('\n')
        # If the command string ends with ';', it is a full statement
        if sql_command.endswith(';'):
            # Try to execute statement and commit it
            try:
                # print("running " + sql_command + ".")
                psql_conn.execute(text(sql_command))
                #psql_conn.commit()
            # Assert in case of error
            except:
                print('Error at command :' + sql_command + ".")
                ret_ = False
            # Finally, clear command string
            finally:
                sql_command = ''
    ret_ = True
    return ret_

# Here you define the credentials
DATABASE = 'group_8_2024' # TO BE REPLACED
USER = 'group_8_2024' # TO BE REPLACED
PASSWORD = '8Yy148rzOyOm' # TO BE REPLACED
HOST = 'dbcourse.cs.aalto.fi'

 # Our connection to the database
try :
    connection = psycopg2.connect (
        database = DATABASE ,
        user = USER ,
        password = PASSWORD ,
        host = HOST ,
        port = '5432'
    )
    connection.autocommit = True
    # Create a cursor to perform database operations
    cursor = connection.cursor()
# Connect to db using SQLAlchemy create_engine
    DIALECT = 'postgresql+psycopg2://'
    db_uri = "%s:%s@%s/%s" % (USER, PASSWORD, HOST, DATABASE)
    engine = create_engine(DIALECT + db_uri)
    sql_file1 = open('Creating_tables.sql')
    psql_conn = engine.connect()
    
    # Run statements to create tables
    run_sql_from_file(sql_file1, psql_conn)
    file_path = 'data.xlsx'
    
    # Read all sheets into a dictionary of DataFrames
    sheets_dict = pd.read_excel(file_path, sheet_name=None)
    for sheet_name, df in sheets_dict.items():
        df.to_sql (sheet_name, con = psql_conn , if_exists ='append', index = False)

    query = """
    SELECT * FROM Request LIMIT 10
    """
    test_df = pd.read_sql_query(query, psql_conn)
    print("Select 10 requests from Request table:")
    print(test_df)
    
except (Exception, Error) as error:  # In case we fail to establish the connection
    print("Error while connecting to PostgreSQL", error)

finally:  # Close the connection
    if connection:
        psql_conn.commit()
        psql_conn.close()
        # cursor.close()
        connection.close()
        print("PostgreSQL connection is closed")
