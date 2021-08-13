# Questo script prende un file CSV ed il nome della relativa tabella. Nel file CSV sono contenute le tuple della tabella di cui abbiamo passato il nome al medesimo script.
# Fra il primo e l'ultimo parametro lo script accetta i tipi di dati della tabella. In particolare basta inserire NUMBER, TEXT o DATE.
# In output fornisce un file testuale contenente lo script SQL Oracle di popolamento
# Autore: Gennaro Farina
# Vincoli: 
#	. Il file CSV deve contenere un header col nome dei campi
#	. Il separatore di campi deve essere una virgola

import sys
import csv
import re


BUFFER_SIZE = 100 # ogni 100 tuple scriviamo nel file e liberiamo la RAM
italian = True

# Se e' stato passato il nome del file
if(len(sys.argv) > 1):

		print("Usage should be this: " + sys.argv[0] + " <filename> <field_type>...<field_type> <table_name>")
		print("<field_type> should be 'NUMBER', 'DATE' or 'TEXT'")
		filename = str(sys.argv[1])
		table_name = str(sys.argv[len(sys.argv)-1])
		
		out_file = open( table_name + "_DML.sql","w")
		out_file.close()
		# len(sys.argv) - 1 perche' l'ultimo viene escluso dalla funzione range. Quindi corrisponde ad i che va da 2 a len(sys.argv) - 2
		field_type = []		
		for i in range(2, len(sys.argv) - 1 ):
			field_type.append( str( sys.argv[i] ) )
		
		# Recuperiamo il nome dei campi della tabella dall'header CSV
		columnsName = []
		try:
			with open(filename, 'r') as f:
				first_line = f.readline()
    			first_line = first_line.rstrip(' \t\r\n\0')
    			columnsName = first_line.split(',')
    			#print(columnsName)
    			columnsName
		except:
			print("EXC0 " + sys.argv[0] + " exception: unable to find file " + sys.argv[1])

		if( len(field_type) <> len(columnsName) ):
			print(str(len(field_type)) + " " + str(len(columnsName)) ) 
			print( field_type)
			print("Dimension of data type and data not compatible")
		else:
			print("Input filename: " + filename)
			print("Wait a moment please...")

			#creo l'istruzione SQL a partire dai dati del CSV
			try:
				listOfSQLInstructions = []
				iteration = 0
				with open(filename) as csvfile:
					reader = csv.DictReader(csvfile)#, delimiter=';')#, quoting=csv.QUOTE_NONE)
					for row in reader:
						# INSERT INTO <table_name>(<columnName>...<columnName>) VALUES (
						singleString = ""
						singleString = singleString + "INSERT INTO " + table_name + " ("
						for field in columnsName:
							singleString = singleString + field + ", "
						singleString = singleString[:-2]
						singleString = singleString + ") VALUES ("

						# Values
						index = 0
						for field in columnsName:
							if( field_type[index] == 'NUMBER'):
								singleString = singleString +  row[field] + ", "
							elif( field_type[index] == 'TEXT'):
								singleString = singleString + '\'' + re.sub('[^A-Za-z0-9]+', '', row[field]) + '\'' + ", "
							elif(field_type[index]=='DATE'): #( field_type[index] == 'DATE'):
								singleString = singleString + '\''
								fieldAsDate = row[field]
								fieldAsDate = fieldAsDate.upper()

								if (italian == True):
									fieldAsDate = fieldAsDate.replace("-JAN-", "-GEN-")
									fieldAsDate = fieldAsDate.replace("-FEB-", "-FEB-")
									fieldAsDate = fieldAsDate.replace("-MAR-", "-MAR-")
									fieldAsDate = fieldAsDate.replace("-APR-", "-APR-")
									fieldAsDate = fieldAsDate.replace("-MAY-", "-MAG-")
									fieldAsDate = fieldAsDate.replace("-JUN-", "-GIU-")
									fieldAsDate = fieldAsDate.replace("-JUL-", "-LUG-")
									fieldAsDate = fieldAsDate.replace("-AUG-", "-AGO-")
									fieldAsDate = fieldAsDate.replace("-SEP-", "-SET-")
									fieldAsDate = fieldAsDate.replace("-OCT-", "-OTT-")
									fieldAsDate = fieldAsDate.replace("-NOV-", "-NOV-")
									fieldAsDate = fieldAsDate.replace("-DEC-", "-DIC-")

									fieldAsDate = fieldAsDate.replace("-1-", "-GEN-")
									fieldAsDate = fieldAsDate.replace("-2-", "-FEB-")
									fieldAsDate = fieldAsDate.replace("-3-", "-MAR-")
									fieldAsDate = fieldAsDate.replace("-4-", "-APR-")
									fieldAsDate = fieldAsDate.replace("-5-", "-MAG-")
									fieldAsDate = fieldAsDate.replace("-6-", "-GIU-")
									fieldAsDate = fieldAsDate.replace("-7-", "-LUG-")
									fieldAsDate = fieldAsDate.replace("-8-", "-AGO-")
									fieldAsDate = fieldAsDate.replace("-9-", "-SET-")
									fieldAsDate = fieldAsDate.replace("-10-", "-OTT-")
									fieldAsDate = fieldAsDate.replace("-11-", "-NOV-")
									fieldAsDate = fieldAsDate.replace("-12-", "-DIC-")
								singleString = singleString + fieldAsDate
								singleString = singleString + '\'' + ", "
							else: #NULL
								singleString = 'Plese use only argument NUMBER, TEXT OR DATE in program call'

							index = index + 1

						# Terminiamo l'istruzione sql chiudendo la parentesi e aggiungendo un punto e virgola
						singleString = singleString[:-2]
						singleString = singleString + ");\n"

						listOfSQLInstructions.append(singleString)
						#print(row['id'])#, row['last_name'])
						iteration = iteration + 1
						if iteration == BUFFER_SIZE:
							out_file = open( table_name + "_DML.sql","a")
							out_file.write("".join(listOfSQLInstructions))
							out_file.close()
							iteration = 0
							listOfSQLInstructions = []

				out_file = open(table_name + "_DML.sql","a")
				out_file.write("".join(listOfSQLInstructions))
				out_file.close()
				print("Done, " + table_name + "_DML.sql created!")
			except:
				print("EXC1 " + sys.argv[0] + " exception: unable to find file " + sys.argv[1])
else:
		print ("You should put filename in argument list")

