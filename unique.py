# -*- coding: utf-8 -*-
# Questo script prende un file CSV ed il nome della relativa tabella e fornisce la tabella con campi univoci. Nel file CSV sono contenute le tuple della tabella.
# Input:
# - Nome del file CSV contenente la tabella
# - Nomi dei campi da rendere univoci.
# - In output fornisce un file CSV contenente le tuple. Queste tuple saranno univoche per il campo desiderato.
# Autore: GF
# Vincoli: 
#	. Il file CSV deve contenere un header col nome dei campi
#	. Il separatore di campi deve essere una virgola

import sys
import csv


FINAL_OUTPUT_NAME = "final" + sys.argv[1]
# Se e' stato passato il nome del file
if(len(sys.argv) > 1):
	print("Usage should be this: " + sys.argv[0] + " <filename> <field_name>...<field_name>")
		
	filename = str(sys.argv[1])
	field_name = [] #Lista contenente il nome dei campi da rendere univoci
	for i in range(2, len(sys.argv)):
		field_name.append(str(sys.argv[i]))

	print(field_name)
		
	try:
		with open(filename, 'r') as f:
			first_line = f.readline()
    		first_line = first_line.rstrip(' \t\r\n\0')
    		columnsName = first_line.split(',')
    		print(columnsName)
    		columnsName
	except:
		print("EXC0 " + sys.argv[0] + " exception: unable to find file " + sys.argv[1])

	print("Input filename: " + filename)

			#creo l'istruzione SQL a partire dai dati del CSV
	try:
		totalTuple = [] # Tuple ottenute da file
		finalTuple = [] # Tuple processate
			
		iteration = 0
		with open(filename) as csvfile:
			reader = csv.DictReader(csvfile)#, delimiter=';')#, quoting=csv.QUOTE_NONE)
			for row in reader:
				totalTuple.append(row)



		
		finalTuple.append(totalTuple[0])
		i = 1
		while i < len(totalTuple):
			trovato = False
			singleDict = totalTuple[i]
			i = i + 1

			for sDicts in finalTuple:
				counter = 0
				for attributes in field_name:
					if(sDicts[attributes] == singleDict[attributes]):
							counter = counter + 1
				
				if(counter == len(field_name)):
					trovato = True
			
			if(trovato==False):
					finalTuple.append(singleDict)


		print(len(finalTuple))
		with open(FINAL_OUTPUT_NAME, 'w') as csvfile:
		    writer = csv.DictWriter(csvfile, fieldnames= columnsName)

		    writer.writeheader()
		    for dictionare in finalTuple:
		    		writer.writerow(dictionare)
		
		#Conversione in utf-8
		import codecs
		BLOCKSIZE = 1048576 # or some other, desired size in bytes
		with open(FINAL_OUTPUT_NAME, "r") as sourceFile:
		    with codecs.open(FINAL_OUTPUT_NAME[:-4] + '-utf-8.csv', "w", "utf-8") as targetFile:
		        while sourceFile.read(BLOCKSIZE):
		            contents = sourceFile.read(BLOCKSIZE)
		            targetFile.write(contents)

		print("You can find output in " + FINAL_OUTPUT_NAME)
	except:
		print("EXC1 " + sys.argv[0] + " exception: unable to find file " + sys.argv[1])
else:
		print ("You should put filename in argument list")

print("Script completed!")

