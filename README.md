# CSCB58_FinalProject


# For JTAG Error in Linux using the Cyclone II board
Make new file
sudo nano /etc/udev/rules.d/51-usbblaster.rules 
or sudo vi /etc/udev/rules.d/51-usbblaster.rules

Write this into it.
# USB-Blaster
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6001", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6002", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6003", MODE="0666"

# USB-Blaster II
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6010", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6810", MODE="0666"


sudo udevadm control --reload


# If above doesn't work
sudo nano /etc/udev/rules.d/92-usbblaster.rules 
or sudo vi /etc/udev/rules.d/92-usbblaster.rules

# USB-Blaster
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6001", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6002", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6003", MODE="0666"

# USB-Blaster II
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6010", MODE="0666"
BUS=="usb", SYSFS{idVendor}=="09fb", SYSFS{idProduct}=="6810", MODE="0666"


sudo udevadm control --reload



# If above doesn't work

sudo nano /etc/udev/rules.d/40-usbblaster.rules 
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb"}, ATTRS{idProduct}=="6001", MODE="0666", SYMLINK+="usbblaster"


sudo nano /etc/udev/rules.d/50-usbblaster.rules 
SUBSYSTEM=="usb", ATTRS{idVendor}=="09fb", ATTRS{idProduct}=="6001", GROUP="plugdev", MODE="0666", SYMLINK+="usbblaster"

