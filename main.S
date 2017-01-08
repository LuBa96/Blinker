/*
 * main.S
 *
 *  Created on: 07.01.2017
 *      Author: Lukas Bachamnn <lukas.bachmann0610@gmail.com>
 */

.section .init
.globl _start
_start:


/*
Registerzuweisungen:
r0 = Anfangsadresse des GPIO Controllers
r1 = Maske für das Setzen der Output-Funktion für FSEL23 und FSEL24
r2 = Maske für BCM 5; Test ob Bit gesetzt
r3 = Und-Ergebnis des Bittests
r4 = Zähler Tastenbetätigungen
r5 = Clock
r6 = Maske für das Setzen der Output GPIOs BCM23 und BCM24
*/

/*Lege BCM5 als Input (default) und BCM23 und BCM24 als Output fest*/
	ldr r0, =0x20200000;			//lade anfangsadresse des GPIO Controllers, weiterer Zugriff mit Offset
	mov r1, #9;						//9=1001, in das Register GPFSEL2 nach links schieben um 9 Stellen
									//letzte 1 von 1001 muss am ende bei FSEL23 an letzter Stelle stehen
	lsl r1, #9;
	str r1, [r0,#8];				//Maske in GPFSEL2 schreiben, (Offset von r0 = 8)

main_loop:
/*Zähle die Betätigungen des Knopfes*/
	mov r2, #32;					//32 entspricht einer 100000-->Maske für Bit nr. 5
begin:
	ldr r10, [r0, #76];

	and r3, r2, r10;				//Startzustand; Warten auf erste Eingabe
	cmp r3, #0
	beq begin;
loop:
	ldr r10, [r0, #76];
	and r3, r2, r10;				//Bit 5 maskieren
	nop;
	cmp r3, #0;
	beq time;						//solange Bit nicht gesetzt ist wiederholen
	add r4, #1;						//Zähler in r4 inkrementieren
	str r2, [r0, #76];				//Register mit Maske clearen (siehe Datenblatt: schreiben mit 1 an betroffener Stelle = clr)
	mov r5, #0;						//timer reseten, wenn gedrückt wurde
	nop;
	b	loop;


time:
	add r5, #1						//Zeitfunktion hier einfügen
	nop;
	cmp r5, #2000;					//r5 enthält einen Timer; bei 2 sec Schleife verlassen
	blt loop;

wait:								//warten bis zum Leuchten
	add r5, #1;
	nop;
	cmp r5, #500;					//5 sec timer
	blt wait;
	mov r5, #0;						//timer reseten
	mov r8, r4;						//Zähler für LED2

	mov r7, #1;						//Bit 23 muss auf 1 gesetzt werden;
	lsl r7, #23;
	orr r6, r6, r7;

LED_1:
	str r6, [r0, #28];				//Adresse für Setzen von LED_1 (BCM 23) = 0x2020001C	LED leuchtet
	sub r4, #1;

WAIT_2:
	add r5, #1;
	nop;
	cmp r5, #500;
	blt WAIT_2;
	mov r5, #0;
	str r10, [r0, #28];
	and r10, r10, #0;				//alle Outputs auf 0; LED aus
	str r10, [r0, #28];
	WAIT_3:							//LED gönnt sich Auszeit
		add r5, #1;
		nop;
		cmp r5, #500;
		blt WAIT_3;
		mov r5, #0;
	cmp r4, #0;
	bne	LED_1;
	cmp r8, #0;
	bne LED_2;
	b _start;

LED_2:
	mov r6, #1;					//Bit 23 muss auf 1 gesetzt werden;
	lsl r6, #24;
	str r6, [r0, #28];			//LED 2 an
	sub r8, #1;
	b	WAIT_2;

