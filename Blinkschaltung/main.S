/*
 * main.S
 *
 *  Created on: 12.01.2017
 *      Author: Gregor
 */


.extern map_peripheral
.global main
.func main
main:
push {r4-r11, lr}

mapping_addr:
bl 	map_peripheral
mov r9, r0  /* save the GPIO_BASE in r9 */

/*
Registerzuweisungen:
r0 - Übergabewert für Unterfunktionen (wait)
r1-r3 - reserviert für Unterfunktionen
r4 - Zwischenergebnisse für alles
r5 - Counter für LED1
r6 - Schleifencounter
r7 - Counter für LED2
*/

initialisierung:
mov r4, #9;				/*setzt GPIO23 und 24 als Output*/
lsl r4, #9;
str r4, [r9,#8];

/*seltsamerweise geht der Strom scheinbar auf 0, wenn man den Schalter	betätigt*/

mov r4, #1;				/*enable falling edge detect für GPIO-bit 15*/
lsl r4, #15;
str r4, [r9,#0x58];

ldr r4, [r9,#0x40];		/*cleart das event-detect-Register*/
str r4, [r9,#0x40];

mov r5,	#0;				/*Registerreset*/
mov r6,	#0;
mov r7,	#0;

anfang:					/*Die LED blinkt einmal, um zu signalisieren, dass das Programm läuft*/

mov r4, #3;				/*anschalten der LEDs über SET-Register*/
lsl r4, #23;
str r4, [r9,#28];

mov r0, #100;			/*speichert 100 als Übergabewert für wait-Funktion*/
bl	wait;				/*springt zu wait, retter aber den program counter,
						  damit danach wieder hier her gesprungen wird*/
						/*warte 1 Sekunde*/

mov r4, #3;				/*ausschalten der LEDs über Clear-Register - muss auf 1 gesetzt werden!*/
lsl r4, #23;
str r4, [r9, #40]

idle_loop:
ldr r4, [r9,#0x40];		/*lädt den Inhalt des Event-detect*/
cmp r4, #0;				/*sieh nach, ob etwas ins Event-detect geschrieben wurde*/
beq idle_loop;			/*wird immer wiederholt --> Startzustand*/

tasterdruck:

mov r0, #30;			/*nach jedem Tastendruck wird kurz gewartet, damit nicht der selbe*/
bl	wait				/*Druck mehrmals gezählt wird*/

add r5,	r5,	#1;			/*Counter setzen*/
ldr r4, [r9,#0x40];		/*r4 sollte zwar noch der Gleiche sein, aber nur zur Sicherheit*/
str r4, [r9,#0x40];		/*cleart Event-detect*/
mov r6,	#0;				/*nach jedem Tastendruck muss der Schleifenzähler resetted werden*/

ab_eingabe:
add r6,	r6,	#1;			/*erhöht Schleifenzähler um 1*/
cmp r6, #300;			/*damit insgesamt 3 Sekunden gewartet wird*/
beq eingabe_fertig;		/*wenn 3 Sekunden fertig*/
mov r0,	#1;				/*warte für 0,01 Sekunde*/
bl	wait;
ldr r4, [r9,#0x40];		/*check Event-Detect*/
cmp r4, #0;
beq ab_eingabe;			/*wenn kein Knopf gedrückt wurde*/
bne tasterdruck;		/*wenn Knopf gedrückt wurde*/

eingabe_fertig:
mov r7, r5;				/*rettet Counter für zweite LED*/

LED1_blinkt:
sub r5, r5, #1;			/*verringert den Zähler für LED1 um 1*/

mov r4, #1;				/*Anschalten der LED über SET-Register*/
lsl r4, #23;
str r4, [r9,#28];

mov r0, #100;			/*warte 1 Sekunde*/
bl	wait;

mov r4, #1;				/*Ausschalten der LED über Clear-Register*/
lsl r4, #23;
str r4, [r9, #40]

mov r0, #100;			/*warte 1 Sekunde*/
bl	wait;

cmp r5,	#0;				/*checkt, ob oft genug geblinkt wurde*/
bne LED1_blinkt;

warte_auf_zweite_eingabe:
ldr r4, [r9,#0x40];		/*lädt den Inhalt des Event-detect*/
cmp r4, #0;				/*sieht nach, ob etwas ins Event-detect geschrieben wurde*/
beq warte_auf_zweite_eingabe;

LED2_blinkt:
sub r7, r7, #1;			/*verringert den Zähle für LED2 um 1*/

mov r4, #1;				/*anschalten der LED über SET-Register*/
lsl r4, #24;
str r4, [r9,#28];

mov r0, #100;			/*warte 1 Sekunde*/
bl	wait;

mov r4, #1;				/*ausschalten der LED über Clear-Register*/
lsl r4, #24;
str r4, [r9, #40]

mov r0, #100;			/*warte 1 Sekunde*/
bl	wait;

cmp r7,	#0;				/*checkt, ob oft genug geblinkt wurde*/
bne LED2_blinkt;

ldr r4, [r9,#0x40];		/*cleart Event-detect*/
str r4, [r9,#0x40];

mov r4,	#0;				/*Registerreset*/
mov r5,	#0;
mov r6,	#0;
mov r7,	#0;

b	idle_loop;			/*wenn LED2 oft genug geblinkt hat, ist das Programm
						  fertig und kann wieder zum Ausgangszustand zurück kehren*/

mov r0, #0;
pop {r4-r11, pc}
.endfunc


.global wait
.func wait
/* delay for some time (0.01 * r0) second */
wait:
  mov r3, r0
wait_loop2:
  sub r3, #1
  mov r2, #0x3F0000
wait_loop1:
  sub r2,#1
  cmp r2,#0
  bne wait_loop1
  cmp r3, #0
  bne wait_loop2
  /* end main_loop */
  bx lr
.endfunc



