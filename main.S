/*
 * main.S
 *
 *  Created on: 07.01.2017
 *      Author: Lukas Bachamnn <lukas.bachmann0610@gmail.com>
 */

.section .init
.globl _start
_start:


/*Lege BCM5 als Input und BCM23 und BCM24 als Output fest*/
	ldr r0, =0x202000000;		//lade anfangsadresse des GPIO Controllers, weiterer Zugriff mit Offset
	mov r1, #9;					//9=1001, in das Register GPFSEL2 nach links schieben um 9 Stellen
								//letzte 1 von 1001 muss am ende bei FSEL23 an letzter Stelle stehen
	lsl r1, #9;
	str r1, [r0,#8];			//Maske in GPFSEL2 schreiben, (Offset von r0 = 8)
	mov r10, #0;

main_loop:
/*Zähle die Betätigungen des Knopfes*/
	mov r2, #32;				//32 entspricht einer 100000-->Maske für Bit nr. 5
	cmp r10, #0;
	beq loop;
	cmp r10, #2;
	beq END;					//beide Lampen haben Geleuchtet, Ende
	mov r10, #2;				//letzter Durchlauf
loop:
	ldr r0, =0x202000000;		//Registerstatus aktualisieren
	and r3, r0, r2;				//Bit 5 maskieren
	nop;
	cmp r3, #0;
	beq time;					//solange Bit nicht gesetzt ist wiederholen
	add r4, #1;					//Zähler in r4 inkrementieren
	str r2, r0;					//Register mit Maske clearen (siehe Datenblatt: schreiben mit 1 an betroffener Stelle = clr)
	mov r5, #0;					//timer reseten, wenn gedrückt wurde
	nop;
	b	loop;


time:
	add r5, #1					//Zeitfunktion hier einfügen
	nop;
	cmp r5, #200000;			//r5 enthält einen Timer; bei 2 sec Schleife verlassen
	blt loop;

wait:							//warten bis zur zweiten eingabe
	add r5, #1;
	nop;
	cmp r5, #500000;			//5 sec timer
	blt wait;
	mov r5, #0;					//timer reseten

LED:
	cmp r10, #1
	bgt LED_2;					//wennn ja wurde für LED 2 gezählt und sie soll leuchten
	b	LED_1;					// sonst erst LED 1 leuchten lassen
	LED_1u2:					//gemeinsamer Ablauf bei beiden LEDs
		str r6, [r0, #28];		//Adresse für Setzen von LED_1 (BCM 23) = 0x2020001C	LED leuchtet
		nop;
		sub r4, #1;
		cmp r4, #0;
		blt main_loop;			//erneut Zählen
		b	LED;
		LED_1:
			mov r10, #1;		//LED 1 beginnt zu leuchten, d.h. noch einmal Zählen für LED 2 und dann Ende
			mov r6, #23;		//Bit 23 muss auf 1 gesetzt werden;
			b	LED_1u2;
		LED_2:
			mov r10, #2;
			mov r6, #23;		//Bit auf 24, andere LED
			b	LED_1u2;
END:
	mov r0, #0;
