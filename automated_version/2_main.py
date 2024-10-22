import psycopg2
from connexion import conn
from tools import executesql, executesql_with_string_format, create_directory, export_table_as_csv
import pandas as pd
import logging
import datetime
import time
import subprocess

# Path to the QGIS Python interpreter you want to use
python_interpreter = "pythonqgis"

# Path to the script to export tiles
script_to_run = "E:/codes/cadastre/automated_version/export_tiles.py"

def add_function_to_postgres():
    SQL_SCRIPT_6 = "6-FonctionConversionCoordonnees.sql"
    executesql(ROOT,SQL_SCRIPT_6)
    print('Function coord_carto_to_image created into Postgres database.')

    SQL_SCRIPT_2bis = "2bis-FonctionDecompteCaracteres.sql"
    executesql(ROOT,SQL_SCRIPT_2bis)
    print('Function char_count created into Postgres database.')

def run_scripts(ROOT,CONTROLS,ANNOTATIONS_FOLDER,SKIP_STEPS=[]):

    # Configure the logging module
    logging.basicConfig(filename=ANNOTATIONS_FOLDER +'/log.txt', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

    #Load controls panel and styles panel
    controls = pd.read_csv(CONTROLS, delimiter=",") #One row is one area of 100 crops
    controls = controls.rename(columns={'xmin': 'step1_decalage_x', 'ymin': 'step1_decalage_y'}) #Rename x_min and y_min into step1_decalage_x et step1_decalage_y
    controls = controls.head(2)
    styles = pd.read_csv(ROOT + "styles/styles.csv", delimiter=",")
    controls_csv = pd.merge(controls, styles, left_on='style', right_on='style', how='left')
    controls_csv = controls_csv.replace(',', '.', regex=True)
    print(controls)
    print(styles)
    print(controls_csv)

    SQL_SCRIPT_1 = "1-DecoupageZones.sql"
    SQL_SCRIPT_2 = "2-CalculBBOXNumParcelles.sql"
    SQL_SCRIPT_3 = "3-CalculBBOXNomCommunes.sql"
    SQL_SCRIPT_4 = "4-CalculBBOXNomRues.sql"
    SQL_SCRIPT_5 = "5-CalculBBOXNomRivieres.sql"
    SQL_SCRIPT_7 = "7-ExportAnnotations.sql"
    
    logging.info('Start treating areas')
    for index, row in controls_csv.iterrows():
        TOTAL_EXECUTION_TIME = 0
        logging.info(f'Start treating area {row["area_id"]}.')

        #Create a csv using only the current row and df header (it has to be formated as a csv)
        current_area = ROOT + 'automated_version/current_area.csv'
        current_area_df = controls_csv.iloc[[index]] 
        current_area_df.to_csv(current_area, sep=',', index=False)

        logging.info('Area infos are :')
        logging.info(row)

        #STEP 1: Cut one given area into zones and add plots ands streets in it
        step = 'step1'
        if step not in SKIP_STEPS:
            variables = {col: row[col] for col in row.index if step in col}
            variables["identifiant_area_from_csv"] = row['area_id']
            logging.info('Start STEP 1')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_1,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 1 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 1')

        #STEP 2: Compute bounding boxes of num plots words
        step = 'step2'
        if step not in SKIP_STEPS:
            variables = {col: row[col] for col in row.index if step in col}
            logging.info('Start STEP 2')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_2,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 2 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 2')

        #STEP 3: Compute bounding boxes of communes words
        step = 'step3'
        if step not in SKIP_STEPS:
            variables = {col: row[col] for col in row.index if step in col}
            logging.info('Start STEP 3')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_3,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 3 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 3')

        #STEP 4: Compute bounding boxes of street words
        step = 'step4'
        if step not in SKIP_STEPS:
            variables = {col: row[col] for col in row.index if step in col}
            logging.info('Start STEP 4')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_4,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 4 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 4')

        #STEP 5: Compute bounding boxes of rivers words
        step = 'step5'
        if step not in SKIP_STEPS:
            variables = {col: row[col] for col in row.index if step in col}
            logging.info('Start STEP 5')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_5,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 5 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 5')

        #STEP 7: Create annotation table
        step = 'step7'
        annotations_tab_name = 'area_' + str(row['area_id'])
        if step not in SKIP_STEPS:
            variables = {'annotations_tab_name': annotations_tab_name}
            logging.info('Start STEP 7 (there is no STEP 6 :) : Creating annotations table')
            start_time = time.time()
            executesql_with_string_format(SQL_SCRIPTS_FOLDER,SQL_SCRIPT_7,variables)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('STEP 7 is done. Execution time : ' + str(execution_time))
        else:
            logging.info('Skip STEP 7')

        #Step 8 : Export annotation table in csv
        step = 'export_annotations'
        if step not in SKIP_STEPS:
            folder_name = ANNOTATIONS_FOLDER + annotations_tab_name
            create_directory(folder_name)
            logging.info('Starting export of annotations table in csv')
            start_time = time.time()
            export_table_as_csv("public",annotations_tab_name,folder_name,"annotations")
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('Export step execution time : ' + str(execution_time))
            logging.info('Export done in folder ' + folder_name)

            #Create a timestamp file to know when the export has been done
            current_datetime = datetime.datetime.now()
            # Write the timestamp to the file
            with open(folder_name + '/' + annotations_tab_name + '_timestamp.txt', "w") as f:
                f.write(str(current_datetime))
        else:
            logging.info('Skip Export annotations table in csv')

        #Step 9 : Export tiles of synthetic maps
        step = 'export_tiles'
        if step not in SKIP_STEPS:
            folder_name = ANNOTATIONS_FOLDER + annotations_tab_name
            logging.info('Starting export of tiles')
            start_time = time.time()
            # Run the script using the specified Python interpreter
            subprocess.run([python_interpreter, script_to_run], capture_output=True, text=True)
            end_time = time.time()
            execution_time = end_time - start_time
            TOTAL_EXECUTION_TIME += execution_time
            logging.info('Export tiles step execution time : ' + str(execution_time))
            logging.info('Export done in folder ' + folder_name)
        else:
            logging.info('Skip Export annotations table in csv')

        logging.info(f'Execution time for {row["area_id"]}: ' + str(TOTAL_EXECUTION_TIME))
    
    logging.info('Dataset have been created !')
    conn.close()

if __name__ == "__main__":
    
    ############## Create annotation table part
    ROOT = "E:/codes/cadastre/"
    CONTROLS = ROOT + "automated_version/controls/controls.csv"
    SQL_SCRIPTS_FOLDER = ROOT + "automated_version/sql_scripts/"
    ANNOTATIONS_FOLDER = ROOT + "outputs/"
    FIRST_RUN_EVER = True #Is it the first time that the database is used ?
    SKIP_STEPS = [] #'step1','step2','step3','step4','step5','step7','export_annotations','export_tiles

    ############## Add functions to Postgres
    add_function_to_postgres()

    ############## Execute the SQL scripts for areas depicted in the controls.csv file
    run_scripts(ROOT,CONTROLS,ANNOTATIONS_FOLDER,SKIP_STEPS)