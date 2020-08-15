#!/usr/bin/python

# Author : Prince Abraham

import csv


import os


str1="Host Name,IP Address,FUSE Version,FQDN,CPU Model,CPU Operating  @,Server Model,Server S/N,CPU FreQ Governor," \
     "Manufacuturer,Virtualization type,CPU socket(s),Core(s) per socket,CPU Cores,CPU Threads,Physical memory(RAM),Disk space in GB,SAN(GB),HTTP Processes,Application,Environment,Location,Symantec CSP,Kernel Ver\n"


dire="/ced/sarlog/"
flist=[]
ofpath="/xxxx/Sxxs.csv"
ofh=open(ofpath,'w')
ofh.write(str1)
ofh.close()

for filename in os.listdir(dire):
    if filename.endswith(".com.txt"):
        flist.append(os.path.join(dire, filename))
        continue
    else:
        continue

ofh=open(ofpath,'a')
for f in flist:
    count = len(open(f).readlines())
    if count==24:
        with open(f, "rt") as inputfile:
            readinput = csv.reader(inputfile, delimiter=':')
            for row in readinput:
                ofh.write(row[1])
                ofh.write(",")
            ofh.write('\n')

ofh.close()
