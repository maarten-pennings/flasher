# Flasher
Windows script to facilitate flashing an ESP8266/NodeMCU without installing a full IDE.


## Introduction
For novice users, flashing a firmware into an ESP8266/NodeMCU board is 
quite a hurdle. Either they have to download and install the Arduino IDE 
with ESP8266 plugin as described on the
[Arduino web](http://www.arduinesp.com/getting-started).
Or they have to learn the command line interface of the 
[esptool](https://github.com/igrr/esptool-ck/releases).

This project delivers a Windows batch script (`flash.cmd`) that should 
deliver a "one-click" flash experience. It relies on the 
[esptool](https://github.com/igrr/esptool-ck) 
from Christian Klippel to do the actual flashing.


## Concepts
The `flash.cmd` script executes these steps
 - Find flash tool
 - Find firmware image
 - Find COM port of a connected ESP8266
 - Execute flashing

 
### Find flash tool
By default the `flash.cmd` script looks for `esptool.exe` in the same 
directory as the script itself. 

If the tool is not present in that directory it checks if Arduino with 
ESP8266 has been installed, and tries to pick up `esptool.exe` there.

So, if your PC has Arduino with ESP8266, there is no need to download 
a copy of the esptool.


### Find firmware image
By default the `flash.cmd` script looks for a binary firmware file 
(a file ending in `*.bin`) in the same directory as the script itself. 

If a firmware file is not present in that directory the script checks if 
there is an Arduino build-cache, and tries to pick up a firmware file there. 

Note that Arduino clears its build cache upon exit.


### Find COM port of a connected ESP8266
The `flash.cmd` script enumerates all known COM ports. If only one is found
it is selected automatically. Otherwise a dialog pops up for the user to 
enter the COM port of choice.


### Execute flashing
Just before executing the actual flash command, the `flash.cmd` script 
pops up a dialog with a summary of its findings. The user clicks Ok to flash
or Cancel to abort.

After pressing Ok, the `flash.cmd` script starts the esptool, which takes 
tens of seconds to complete. 

Note that while the `flash.cmd` script is running it prints all its findings
to a windows console. It saves a copy to a the file `flash.log` in the same 
directory as the script.


## Example
Create a directory (e.g. `flash` on the desktop) with the following content

```
flash.cmd
esptool.exe
mRPM.ino_v4.bin
```

The file `flash.cmd` is delivered by this project. The `esptool.exe` can be downloaded
from [Christian Klippel](https://github.com/igrr/esptool-ck/releases). The `bin` file 
is some binary that needs to be flashed.

A double click on `flash.cmd` generates the following log file of its actions.

```
flash.cmd by Maarten Pennings 
  2017 Aug 28 ; 23:22; C:\Users\maarten\Desktop\flash 
 
Flash tool found - with this script 
  C:\Users\maarten\Desktop\flash\esptool.exe 
 
Firmware found - with this script 
  C:\Users\maarten\Desktop\flash\mRPM.ino_v4.bin 
 
COM ports found: COM3  
  Auto selected: COM3 
 
Command 
  C:\Users\maarten\Desktop\flash\esptool.exe  -cd nodemcu  -cb 512000  -cp COM3  -cf C:\Users\maarten\Desktop\flash\mRPM.ino_v4.bin 
 
========================================================================================= 
Uploading 235264 bytes from C:\Users\maarten\Desktop\flash\mRPM.ino_v4.bin to flash at 0x00000000
................................................................................ [ 34% ]
................................................................................ [ 69% ]
......................................................................           [ 100% ]
========================================================================================= 
 
Completed successfully 
  See C:\Users\maarten\Desktop\flash\flash.log for a copy of this output 
```


(end of doc)
