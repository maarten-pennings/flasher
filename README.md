# flasher
Script to facilitate flashing an ESP8266/NodeMCU without installing a full IDE.


## Introduction
For novice users, flashing a firmware into an ESP8266/NodeMCU board is 
quite a hurdle. Either they have to download an install the Arduino IDE 
with ESP8266 plugin as described in
[Arduino web page](http://www.arduinesp.com/getting-started).
Or they have to learn the command line interface of the 
[esptool](https://github.com/igrr/esptool-ck/releases).

This project delivers a Windows batch `flash.cmd` script that should 
deliver a "one-click" flash experience. It relies on the [esptool]
(https://github.com/igrr/esptool-ck) from Christian Klippel to do the 
actual flashing.


## User manual
The `flash.cmd` script executes these steps
 - Find flash tool
 - Find firmware image
 - Find COM port of a connected ESP8266
 - Execute flashing

 
### Find flash tool
By default the `flash.cmd` script looks for `esptool.exe` in the same 
directory as the script itself. 

If the tool is not present in that directory it checks if Arduino with 
ESP8266 has been installed, and tries to pick up `esptool.exe`.

So, if your PC has Arduino with ESP8266 in its default directory, 
there is no need to download a copy of the esptool.


### Find firmware image
By default the `flash.cmd` script looks for a binary firmware file `*.bin` 
in the same directory as the script itself. 

If the firmware is not present in that directory it checks if there is an 
Arduino build cache, and tries to pick up a binary there. 

Note that Arduino clears its build cache upon exit.


### Find COM port of a connected ESP8266
The `flash.cmd` script enumerates all known COM ports. If only one is found
it is selected automatically. Otherwise a dialog pops up for the user to 
enter the COM port of choice.


### Execute flashing
Just before executing the actual flash command, the `flash.cmd` script 
pops up a dialog with a summary of its findings. The user clicks Ok to flash
or cancel to abort.

Note that while the `flash.cmd` script is running it prints all its findings
to a windows console, and a copy to a the file `flash.log` in the same 
directory as the script.


