#!/usr/bin/python3
# -*- coding: utf-8 -*-
# coding: utf8

# sudo apt install python3.12
# python3.12 --version
# sudo apt install python3-pip
# pip3.12 -V

##########################################################################
#
# usage: python3 wipe.py
#
##########################################################################

# https://docs.python.org/fr/3/library/random.html ,   
# /!\ Avertissement  Les générateurs pseudo-aléatoires de ce module ne doivent pas être utilisés à des fins de sécurité. 
# Pour des utilisations de sécurité ou cryptographiques, voir le module secrets. 
import secrets

bytes = [0,1]
print(bytes)

def getByte():
    b=secrets.choice(bytes)
    # bytes.remove(b)
    return b
                                                            
# 1 Gb = 1024 Mb = 1024 * 1024 Kb = 1024 * 1024 * 1024 bytes = 1073741824 bytes = 8 589 934 592 bits
data_volume_size = 8589934592
for i in range (data_volume_size):
    print("Bit %i : %s " % ( i+1, getByte()))