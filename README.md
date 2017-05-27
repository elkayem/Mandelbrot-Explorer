# Mandelbrot-Explorer

[![Mandelbrot Explorer](/images/video.JPG)](https://www.youtube.com/watch?v=OqxMnT_Ruuk) 

(Click on image above for link to YouTube video)

<img src="/images/IMG_1034.JPG" alt="Fractal1" width="320" height="240"> <img src="/images/IMG_1035.JPG" alt="Fractal2" width="320" height="240">

This is an FPGA-based Mandelbrot Set explorer.  I used the Papilio Duo board from Gadget Factory, which includes a Xilinx Spartan 6 LX9 FPGA, an ATmega32U4 microcontroller (the same one used in the Arduino Leonardo), and 512 MB SRAM.  A few notable features of this project:

* I used the Atmega32U4 to process the analog joystick, buttons, and rotary encoder to set the cursor position, zoom, and color map.  This information is sent over to the FPGA via an SPI interface.
* The FPGA runs the 800x600 pixel fractal calculations at 200 MHz using the onboard DSP48s.
* The fractals are saved to SRAM, with each pixel stored as a 1 byte word.
* A set of selectable 12-bit color maps are stored using the FPGA BRAM.  I currently have over a dozen, and am planning on adding more color maps.
* An 800x600 pixel SVGA controller on the FPGA is used to send a 12-bit color image to the LCD.  I used the snap-off VGA wing that came with Gadget Factory’s LogicStart Shield.  The LCD was an inexpensive 7” screen purchased off eBay, typically used for Raspberry Pi projects.
* The case for this design was 3D printed, and custom designed just for this project.

I embarked on this project to learn how to program in VHDL.  The Papilio boards are a great and inexpensive way to learn about FPGA design.  The one I used was $88, with all the necessary software tools free from Xilinx.  This project was inspired by a similar project by Mike Field (aka Hamster), who also has a great self-paced tutorial on learning VHDL using a Spartan FPGA.  Although my project was not a copy of Mike's Mandelbrot projects, I did learn quite a bit from his project and tutorials on how to pipeline an algorithm, implement a finite state machine, and many other bread and butter skills needed for FPGA design.  In fact, you can find Mike's pipelining entities used in my VHDL code.

Please feel free to use the VHDL, Arduino code, and even print yourself a 3D printed case for your own Mandelbrot explorer project.  I do have one word of caution: *Please don't try to learn VHDL from my code!*   As a self-taught novice, I'm sure I've implemented all sorts of bad coding practices that would have been weeded out in any undergraduate course.  Instead, head over to (http://hamsterworks.co.nz/mediawiki/index.php/FPGA_Projects) for a dizzying list of FPGA projects done the right way.  

You can also find the 3D printed case design over at: (https://www.thingiverse.com/thing:1655662)
