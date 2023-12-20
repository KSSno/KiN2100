

#On l-klima-app05 run as: 
# $ python3.6 write_metadataCSV_to_ini.py

#"Metadata_KiN-2025_231102.csv" need to have scandianvian characters correct. 
# I do this now by:
#     - Downloading Metadata_KiN-2025.xlsx from ny KiN-2100 shared drive.
#     - Saving the sheet "Stadie 2: indeksberegning" as semicolon separated csv. 
#     - The name of this csv is inserted as ifile_csv below

import pandas as pd

ifile_csv = "Metadata_KiN-2025_20231214.csv" #input  file of type csv
ofile_ini = "config_for_calc_generalised_indices.ini"              #output file of type ini
ifile_separator_char = ";"  #separator in input file
ifile_encoding="iso8859_10" #iso8859_10 allow scandinavian characters #https://docs.python.org/3/library/codecs.html#standard-encodings

# Requirements of ifile_csv:
#  - first 6 rows will be deleted, and thus table should start with header in row 7
#  - all 'variabelnavn' need to be unique
#  - need one row where variabelnavn column is 'attr_typename', and values either varattr, globalattr or globalattr_met
#  - the row where variabelnavn column is 'attr_type_and_source' is deleted

meta = pd.read_csv(ifile_csv, skiprows=6, sep=ifile_separator_char,encoding=ifile_encoding) 
meta = meta[meta.columns[2:]][1:].set_index("Variabelnavn") #drop two first cols and first row which don't have useful information.
meta = meta.drop(labels=meta.columns[meta.columns.str.contains("Unnamed")],axis=1) #drop columns without name (i.e. missing attribute key)
meta = meta.iloc[~meta.index.isnull()] #drop empty rows

attr_type = meta.loc["attr_typename"] #to know if variable attribute or global attribute
meta = meta.drop(["attr_type_and_source","attr_typename"]) #remove rows with attribute type information

print("Write [varattr_*] and [globattr_*] of:")
for count,varname in enumerate(meta.index):
    print(f"\t{count+1}:  {varname}.")
    row = meta.loc[varname]                                             #select attributes for one variable
    row_varattr  = row[attr_type=="varattr"]                            #select variable attributes
    row_globattr = row[attr_type.isin(["globalattr","globalattr_met"])] #select global   attributes

    row_varattr  = row_varattr[~row_varattr.isnull()]   #delete variable attributes that doesn't have a value
    row_globattr = row_globattr[~row_globattr.isnull()] #delete global   attributes that doesn't have a value
    
    #Write to .ini file
    access_mode='w' if count==0 else 'a' #overwrite potentially existing file if first iteration, append otherwise.
    with open(ofile_ini, access_mode, encoding='utf-8',newline="\n") as the_file: #newline="\n" make sure LF line ending, and not CRLF
        
        # Write all variable attributes to file
        the_file.write(f"[varattr_{varname}]\n")
        for attr_key in row_varattr.index:
            the_file.write(f"\t{attr_key} = {row_varattr[attr_key]}\n")
        
        # Write all global attributes for the given variable to file
        the_file.write(f"[globattr_{varname}]\n")
        for attr_key in row_globattr.index:
            the_file.write(f"\t{attr_key} = {row_globattr[attr_key]}\n")