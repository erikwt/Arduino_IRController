/**
 *  IRController.pde
 *
 *  Arduino sketch for controlling a simple circuit with a normal led,
 *  IR-led and a IR-receiver from the serial port.
 */

#include <string.h>

#define RETURN '\n'
#define COMMAND_LEN 126

int boardled    = 13;
int led         = 12;
int irin        = 5;
int irout       = 6;

/**
 *  Setup: Called once, on boot
 */
void setup(){
    pinMode(boardled, OUTPUT);
    pinMode(led, OUTPUT);
    pinMode(irout, OUTPUT);
    pinMode(irin, INPUT);

    Serial.begin(9600);
}

void loop(){
    char input[COMMAND_LEN + 1]; // + 1 for the \0 terminator
    int index = 0;
      
    do{
        while(!Serial.available());
        input[index] = Serial.read();
        if(input[index] == RETURN) break;
    }while(++index < COMMAND_LEN);
    
    input[index] = '\0';
    command(input);
    Serial.flush();
}

/**
 *  Handle input command
 */
void command(char *input){
    if(!strcmp(input, "blink")){
        blink();
    }else if(!strcmp(input, "ping")){
        Serial.write("pong");
    }else if(!strcmp(input, "uptime")){
        uptime();
    }else if(!strcmp(input, "makepic")){
        makepic();
    }else if(!strcmp(input, "irread")){
        irread();
    }else{
        Serial.write("Unknown command");
    }

    Serial.write(RETURN);
}

/**
 *  Blink the led 3 times
 */
void blink(){
    for(int i = 0; i < 3; i++){
        digitalWrite(led, HIGH);
        delay(500);
        digitalWrite(led, LOW);
        if(i != 2) delay(500);
    }
}

/**
 *  Print the time since the current program started running
 */
void uptime(){
    unsigned long time = millis() / 1000;
//    unsigned int seconds = time % 60;
//    unsigned int minutes = (time / 60) % 60;
//    unsigned int hours = (time / 3600) % 24;

    char uptime[64];
//    sprintf(uptime, "Uptime (%d seconds total): %d hours, %d minutes, %d seconds", time, hours, minutes, test);
    sprintf(uptime, "Uptime: %d seconds", time);
    Serial.print(uptime);
}

/**
 *  Read pulse-length from the IR-receiver
 */
void irread(){
    unsigned long duration;
    digitalWrite(led, HIGH);
    for(int i = 0; i < 50; i++){
        duration = pulseIn(irin, LOW);
        Serial.print(duration);
        Serial.print("\t");
    }
    digitalWrite(led, LOW);
}

/**
 *  Send make-picture signal to Canon IR1 supported devices
 */
void makepic(){
    for(int i = 0; i < 2; i++){
        for(int j = 0; j < 16; j++) { 
            digitalWrite(irout, HIGH);
            delayMicroseconds(11);
            digitalWrite(irout, LOW);
            delayMicroseconds(11);
        }
        if(i == 0) delayMicroseconds(7330);
    }
}
