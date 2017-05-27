#include <SPI.h>
#include "Switch.h"

//#define SERIAL_OUT

const int upDownPin = A0;   
const int leftRightPin = A1; 
const int slaveSelectPin = 10;
const int zoomInButtonPin = 3;
const int zoomOutButtonPin = 4;
const int refreshButtonPin = 2;
const int encoderPinA = 0;
const int encoderPinB = 1;

Switch zoomInButton   = Switch(zoomInButtonPin);
Switch zoomOutButton  = Switch(zoomOutButtonPin);
Switch refreshButton  = Switch(refreshButtonPin);

#define UPDATE_PX_COMMAND 0x01
#define UPDATE_AREA_COMMAND 0x02

// Fractal math done in fixed-point, with LSB = 2^(-33)
int64_t cr = -17179869184;  // Frame left edge, RW value = -2.0 = cr/LSB
int64_t ci = -10066329600;  // Frame bottom edge, RW value = -1.17 = ci/LSB
int64_t dc = 33554432; // Frame pixel size, RW value = 0.0039 = dc/LSB, dc = 2^25
const int64_t dc_max = 33554432;  

const float maxRate = 300; // 300 pixels per second
const int HD = 800, VD = 600; // 800x600 pixels
const int deadzone = 10; 
const int JS_UpdatePeriod = 50; // msec
const float rateSF = maxRate * (0.001 * (float)JS_UpdatePeriod);

const int edgeUpdatePeriod = 250; // msec
const float edgeScanRate = 150 * (0.001 * (float)edgeUpdatePeriod);  // 150 pix/sec

unsigned char current_color_palatte = 0;
const int max_palattes = 13;

float cursorX = 400, cursorY = 300;  // Start at center
float cursorXprev, cursorYprev;

unsigned long int serial_timer, JS_UpdateTimer, edgeTimer, cursorTimer;
const int cursorTimeout = 5000;

void setup() {
  Serial.begin(9600);
  pinMode(slaveSelectPin, OUTPUT);
  pinMode(encoderPinA, INPUT_PULLUP);
  pinMode(encoderPinB, INPUT_PULLUP);
  
  SPI.begin(); 
  SPI.beginTransaction (SPISettings (2000000, MSBFIRST, SPI_MODE0));  // 2 MHz clock, MSB first, mode 0
  serial_timer = millis();
}

void loop() {
  char str[100];
  static float JSx, JSy;
  int upDown, leftRight, i;  
  int64_t cursorX_fp, cursorY_fp;
  
  if (millis() - JS_UpdateTimer > JS_UpdatePeriod) {
    upDown = analogRead(upDownPin);
    leftRight = analogRead(leftRightPin);
    
    if (((leftRight - deadzone) > 512) || (leftRight + deadzone) < 512) {
     JSx = (float)(leftRight-512)/512.0f;  // Range -1 to 1
     cursorX += abs(JSx)*JSx*rateSF;
     if (cursorX > HD-1) cursorX = HD-1;
     else if (cursorX < 0) cursorX = 0;
    }
    else JSx = 0;
    
    if (((upDown- deadzone) > 512) || (upDown + deadzone) < 512) {
     JSy = (float)(upDown-512)/512.0f;
     cursorY += abs(JSy)*JSy*rateSF;  
     if (cursorY > VD-1) cursorY = VD-1;
     else if (cursorY < 0) cursorY = 0;
    }
    else JSy = 0;
    
    if ((cursorX != cursorXprev) || (cursorY != cursorYprev)) {  // reset cursor timeout counter
      cursorTimer = millis();
    }
    cursorXprev = cursorX; cursorYprev = cursorY;
    
    digitalWrite(slaveSelectPin, LOW);
    SPI.transfer(UPDATE_PX_COMMAND);
    if (millis() - cursorTimer < cursorTimeout) {
      SPI.transfer16((int)cursorX);
      SPI.transfer16((int)cursorY);
    }
    else { // Make cursor disappear (set to HD,VD) if cursor hasn't moved for more than timeout period
      SPI.transfer16(HD);
      SPI.transfer16(0);
    }      
    SPI.transfer(current_color_palatte);
    for (i=0; i<10; i++) SPI.transfer(0x00);  // Transfer 10 more empty bytes    
    digitalWrite(slaveSelectPin, HIGH);
    
    JS_UpdateTimer = millis();
  }
  
  zoomInButton.poll();
  zoomOutButton.poll();
  refreshButton.poll();
  
  if (zoomInButton.pushed()) {// zoom in
      cursorX_fp = cr + dc*cursorX;
      cursorY_fp = ci + dc*cursorY;
      if (dc != 1) dc >>= 1;
      cr = cursorX_fp - 400*dc;
      ci = cursorY_fp - 300*dc;
      sendUpdate120();
      cursorX = 400; cursorY = 300;  // Recenter cursor
  }
  else if (zoomOutButton.pushed()) {// zoom out
      cursorX_fp = cr + dc*cursorX;
      cursorY_fp = ci + dc*cursorY;
      if (dc < dc_max) dc <<= 1;
      cr = cursorX_fp - 400*dc;
      ci = cursorY_fp - 300*dc;
      sendUpdate120();
      cursorX = 400; cursorY = 300;  // Recenter cursor
  } else if (refreshButton.pushed()) {// refresh
      sendUpdate120();
  }
  current_color_palatte = updateEncoderPos();
  
  if (millis() - edgeTimer > edgeUpdatePeriod) {
    if (cursorX == HD-1 && JSx > 0.25) {
      cr += dc * edgeScanRate;
      sendUpdate120();
    }
    else if (cursorX == 0 && JSx < -0.25) {
      cr -= dc * edgeScanRate;
      sendUpdate120();
    }
    if (cursorY == VD-1 && JSy > 0.25) {
      ci += dc * edgeScanRate;
      sendUpdate120();
    }
    else if (cursorY == 0 & JSy < -0.25) {
      ci -= dc * edgeScanRate;
      sendUpdate120();
    }
    edgeTimer = millis();
  } 
       
#ifdef SERIAL_OUT

    
  if ((millis() - serial_timer) > 100) {
    Serial.print(digitalRead(encoderPinA));
    Serial.print(" ");
    Serial.print(digitalRead(encoderPinB));
    Serial.print(" ");
    Serial.println(current_color_palatte);
    
   // sprintf(str,"Up/Down = %d, Left/Right = %d", upDown, leftRight);
   // Serial.println(str);
   // sprintf(str,"X Pixel = %d, Y Pixel = %d", (int)cursorX, (int)cursorY);
    
   // Serial.println(str);
    serial_timer = millis();
  }
#endif

}

void sendUpdate120() {
  digitalWrite(slaveSelectPin, LOW);
  SPI.transfer(UPDATE_AREA_COMMAND);
  sendUpdate40(cr);
  sendUpdate40(ci);
  sendUpdate40(dc);
  digitalWrite(slaveSelectPin, HIGH);
}


void sendUpdate40(int64_t num) {
    int i;
    unsigned char byteArray[5];
    for (i = 0; i < 5; i++) {
      byteArray[i] = num & 0xFF;
      num >>= 8;
    }
    for (i=4; i>= 0; i--){  // Send MSB first
      SPI.transfer(byteArray[i]);
      //print_binary((int)byteArray[i],8);
      //Serial.print(" "); 
    }  
    //Serial.println();
}


int updateEncoderPos() {
    static int encoderA, encoderB, encoderA_prev;   

    static int encoderPos;

    encoderA = digitalRead(encoderPinA); 
    encoderB = digitalRead(encoderPinB);
 
    if((!encoderA) && (encoderA_prev)){ // A has gone from high to low 
      encoderB ? encoderPos++ : encoderPos--;         
    }
    encoderA_prev = encoderA;     
    // Wrap logic
    if (encoderPos >  max_palattes-1) encoderPos = 0;
    else if (encoderPos < 0) encoderPos = max_palattes-1;  

   return encoderPos;
}


void print_binary(int v, int num_places)
{
    int mask=0, n;

    for (n=1; n<=num_places; n++)
    {
        mask = (mask << 1) | 0x0001;
    }
    v = v & mask;  // truncate v to specified number of places

    while(num_places)
    {
        if (v & (0x0001 << num_places-1))
        {
             Serial.print("1");
        }
        else
        {
             Serial.print("0");
        }

        --num_places;
        if(((num_places%4) == 0) && (num_places != 0))
        {
            //Serial.print(" ");
        }
    }
}

