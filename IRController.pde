/**
 *  IRController.pde
 *
 *  Copyleft 2010 - Erik Wallentinsen
 *  FEEL FREE TO DO WHATEVER YOU WANT WITH THIS SOURCECODE
 *
 *  Description:
 *  Arduino sketch for controlling a simple circuit with a normal led,
 *  IR-led and a IR-receiver from the serial port.
 */


// Uncomment following line for debug output on Serial,
// comment out for normal output
#define DEBUG


#include <string.h>
#include <IRremote.h>

#define RETURN '\n'
#define COMMAND_LEN 126

int boardled    = 13;
int led         = boardled;
int irin        = 11;
int irout       = 3;
int button      = 12;

IRsend irsend;
IRrecv irrecv(irin);
decode_results ir_results;

/**
 *  Setup: Called once, on boot
 */
void setup(){
    pinMode(boardled, OUTPUT);
    pinMode(led, OUTPUT);
    pinMode(irout, OUTPUT);
    pinMode(irin, INPUT);
    pinMode(button, INPUT);

    Serial.begin(9600);
}

void loop(){
    char input[COMMAND_LEN + 1]; // + 1 for the \0 terminator
    int index = 0;
      
    do{
        while(!Serial.available());
        input[index] = Serial.read();
        if(index == 0) continue;
        if(input[index] == RETURN && input[index - 1] == RETURN) break;
    }while(++index < COMMAND_LEN);
    
    if(index == 0) return;
    input[index - 1] = '\0';
    command(input);
    Serial.flush();
}

/**
 *  Handle input command
 */
void command(char *command){
    char *args = strchr(command, ' ');
    if(args != NULL){
        command[args - command] = '\0';
        args++;
    }

    #ifdef DEBUG
    Serial.print("Command: ");
    Serial.print(command);
    
    Serial.print("\nArgs: ");
    if(args == NULL)
        Serial.print("<none>");
    else
        Serial.print(args);
    
    Serial.print("\n");
    #endif

    if(!strcmp(command, "blink")){
        blink();
    }else if(!strcmp(command, "ping")){
        Serial.write("pong");
    }else if(!strcmp(command, "uptime")){
        uptime();
    }else if(!strcmp(command, "makepic")){
        makepic();
    }else if(!strcmp(command, "irread")){
        irread();
    }else if(!strcmp(command, "irrecord")){
        irrecord();
    }else if(!strcmp(command, "irplay")){
        irplay(args);
    }else{
        Serial.print("Unknown command");
    }

    Serial.write(RETURN);
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
 *  TODO: Fix HH:MM:SS (why doesn't % work?)
 */
void uptime(){
    unsigned long time = millis() / 1000;

    char uptime[64];
    sprintf(uptime, "Uptime: %d seconds", time);
    Serial.print(uptime);
}

/**
 *  Read pulse-length from the IR-receiver
 */
void irread(){
    irrecv.enableIRIn();

    while(true){
        if (irrecv.decode(&ir_results)) {
            Serial.println(ir_results.value, HEX);
            irrecv.resume();
        }
    }
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

/**
 *  Record a IR-signal and store it for later use
 */
unsigned int ir_code_store[RAWBUF];
int ir_code_len = 0;
void irrecord(){
    Serial.println("Waiting for signal... Press button to cancel");
    irrecv.enableIRIn();

    int buttonState = 0;
    while(!buttonState){
        if(irrecv.decode(&ir_results)){
            ir_code_len = ir_results.rawlen - 1;
            for(int i = 0; i < ir_code_len; i++){
                if(i % 2){
                    ir_code_store[i] = ir_results.rawbuf[i + 1] * USECPERTICK + MARK_EXCESS;
                    
                    #ifdef DEBUG
                    Serial.print(" s");
                    #endif
                }else{
                    ir_code_store[i] = ir_results.rawbuf[i + 1] * USECPERTICK - MARK_EXCESS;

                    #ifdef DEBUG
                    Serial.print(" m");
                    #endif
                }
                
                #ifdef DEBUG
                Serial.print(ir_code_store[i], DEC);
                #endif
            }

            break;
        }
        
        buttonState = digitalRead(button);
    }
    
    if(buttonState)
        Serial.println("Exit by button-press");
}

/**
 *  Play a recorded IR-signal
 */
void irplay(char *args){
    if(ir_code_len == 0)
        Serial.print("No IR-code in store");
    else{
        int repeat = 1;
        if(args != NULL)
            repeat = atoi(args);

        #ifdef DEBUG
        Serial.print("Sending IR-code ");
        Serial.print(repeat);
        Serial.print(" times.\n");
        #endif

        for(int i = 0; i < repeat; i++){
            irsend.sendRaw(ir_code_store, ir_code_len, 36);
        
            #ifdef DEBUG
            Serial.println("Sent IR-code:");
            for(int j = 0; j < ir_code_len; j++){
                if(j % 2) Serial.print(" s");
                else Serial.print(" m");

                Serial.print(ir_code_store[j], DEC);
            }

            Serial.println();
            if(i + 1 < repeat)
                Serial.println();
            #endif

            if(repeat != 1)
                delay(1000);
        }
    }
}
