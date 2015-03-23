; Interpreter

org	256

         ld     de, STR_mainScreen
         call   BIOS_printstr
mainLoop:
         ld     de, STR_lineHeader
         call   BIOS_printstr
         
         call   BIOS_getcommand
         
         ld     de, STR_newLine
         call   BIOS_printstr
         
         jr     mainLoop
               
               
               
               
; Rutina za ocitavanje jednog karaktera. Ceka se da
; otkucani znak bude na raspolaganju pa se vraca
; u registru A.

BIOS_getchar:

_waitgc:
        in   a,(12h)
        bit  1,a
        jr   z,_waitgc

        in   a,(13h)
        ret
        
        
        
        
; Rutina za ispisivanje jednog karaktera na terminalu.
; Karakter se srosledjuje kroz registar. Rutina ceka
; terminal da bude spreman za upis.

BIOS_putchar:
        push af

_waitpc:
        in   a,(12h)
        bit  2,a
        jr   z,_waitpc

        pop  af
        out  (13h),a
        ret
        
        
        
        
; Rutina za ocitavanja niza karaktera sa tastature
; i smestanje u memoriju. Po pritisku ENTER na kraju
; se upisuje NULL i prekida se citanje

BIOS_getcommand:
                push        af
                push        bc
                push        hl

                ld          hl,LINE_BUFFER
                ld          b,64

_cmdloop:
                call        BIOS_getchar

                ; Proveri da li je pritisnut enter,
                ; pa ako jese, zavrsi sa unosom linije.

                cp          13
                jr          z,_exitgc

                ; Pravilno izvrsavanje backspace

                cp         8
                jr         nz,_gcback

                ld         a,b
                cp         64
                jr         z,_cmdloop

                ld         a,8
                call       BIOS_putchar
                ld         a,32
                call       BIOS_putchar
                ld         a,8
                call       BIOS_putchar
                inc        b
                dec        hl
                jr         _cmdloop

_gcback:

                ; Provera da li je unet maksimalni broj
                ; karaktera, pa ako jeste vrati se na
                ; ocitavanje bez promene brojaca.

                ex          af,af'
                ld          a,b
                cp          0
                jr          z,_cmdloop

                ; Ako nije ENTER, upisi karakter u memoriju

                ex          af,af'
                ld          (hl),a
                call        BIOS_putchar
                inc         hl
                dec         b
                jr          _cmdloop

_exitgc:
                ld          (hl),0
                pop         hl
                pop         bc
                pop         af
                call        BIOS_parseLine ;poziva rutinu za parsiranje linije
                ret
                
                
                
; Rutina za ispis NULL terminisanog stringa.
; Registar DE se koristi kao pocetna adresa
; stringa koji treba ispisati. Po zavrsetku
; de pokazuje na NULL karakter, a ostali
; registri su nepromenjeni

BIOS_printstr:
         push af

_seeknull:
         ld         a,(de)
         cp         0
         jr         z,_exitps

         call       BIOS_putchar

         inc         de
         jr          _seeknull

_exitps:
         pop         af
         ret
         
         


; Rutina za parsiranje unetog reda
BIOS_parseLine:
; Provera prve reci
               ld      bc, LINE_BUFFER
               ld      hl, STR_keyWords
               call    BIOS_compStr ; reg a=0 za prepoznatu
               jr      Z, _parseLineSucc1
               jr      _parseLine2
               
_parseLineSucc1:
               ld      de, STR_succParse
               call    BIOS_printstr
               call    BASIC_ComInc
               ret
_parseLine2:
; Provera druge reci
               ld      bc, 4
               ld      hl, STR_keyWords
               add     hl, bc
               ld      bc, LINE_BUFFER
               call    BIOS_compStr ; reg a=0 za prepoznatu
               jr      Z, _parseLineSucc2
               jr      _parseNext2

_parseLineSucc2:
               ld      de, STR_succParse
               call    BIOS_printstr
               call    BASIC_ComDec
               ret
_parseNext2:
; provera trece reci
               ld      bc, 8
               ld      hl, STR_keyWords
               add     hl, bc
               ld      bc, LINE_BUFFER
               call    BIOS_compStr ; reg a=0 za prepoznatu
               jr      Z, _parseLineSucc3
               jr      _parseNext3

_parseLineSucc3:
               ld      de, STR_succParse
               call    BIOS_printstr
               call    BASIC_ComOut
               ret
_parseNext3:
; provera cetvrte reci
               ld      bc, 12
               ld      hl, STR_keyWords
               add     hl, bc
               ld      bc, LINE_BUFFER
               call    BIOS_compStr ; reg a=0 za prepoznatu
               jr      Z, _parseLineSucc4
               jr      _parseNext4

_parseLineSucc4:
               ld      de, STR_succParse
               call    BIOS_printstr
               call    BASIC_ComInp
               ret
_parseNext4:
; provera pete reci
               ld      bc, 16
               ld      hl, STR_keyWords
               add     hl, bc
               ld      bc, LINE_BUFFER
               call    BIOS_compStr ; reg a=0 za prepoznatu
               jr      Z, _parseLineSucc5
               jr      _parseNext5

_parseLineSucc5:
               ld      de, STR_succParse
               call    BIOS_printstr
               call    BASIC_ComAdc
               ret
_parseNext5:
; provera seste reci.....


; Neuspesno parsiranje
               ld      de, STR_errParse
               call    BIOS_printstr
               ret




; poredjenje karaktera koji se nalaze u hl i bc
BIOS_compChar:
             ld        a, (bc)
             cp        32
             jr        NZ, _compCharSkip
             ld        a, 0
_compCharSkip:
             cp        (hl)
             ret
             
; poredjenje stringocva koji pocinju na hl i bc, resenje se vraca u registru a kao bool promenljiva
BIOS_compStr:
             call       BIOS_compChar
             jr         NZ, _compStrWrong
             cp         0
             jr         Z, _compStrTrue
             Inc        bc
             Inc        hl
             jr         BIOS_compStr
_compStrWrong:
              ld        a, 1
              ret
_compStrTrue:
             ld         a, 0
             ret
             
             
; BASIC instrukcija za uvecavanje vrednosti promenljive
BASIC_ComInc:
             ld     hl, LINE_BUFFER
             ld     bc, 4
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a
             
             add    hl, bc
             
             inc    (hl)
             
             ret


; BASIC instrukcija za smanjivanje vrednosti promenljive
BASIC_ComDec:
             ld     hl, LINE_BUFFER
             ld     bc, 4
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a

             add    hl, bc

             dec    (hl)

             ret
             
             
; BASIC instrukcija za ispis promenljive
BASIC_ComOut:
             ld     hl, LINE_BUFFER
             ld     bc, 4
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a

             add    hl, bc ; hl adresa memorije sa koje se ispisuje
             
             ld     a, (hl)
             sla    a
             sla    a
             ld     hl, MAT_binToChar
             ld     b, 0
             ld     c, a
             
             add    hl, bc
             ld     (0), hl
             ld     de, (0)
             call   BIOS_printstr
             
             
             ret
             
             
             
; BASIC instrukcija za unos promenljive
BASIC_ComInp:
             ld     hl, LINE_BUFFER
             ld     bc, 6
             Add    hl, bc
             ld     (0), hl
             ld     de, (0)
             
             ; StrToInt - hl je trazeni broj; de je moseto stringa
             ld hl,0 
_ComInpConvLoop:
             ld      a,(de)
             sub     30h
             cp      10
             jr      nc, _ComInpnumDone
             inc     de
     
             ld      b,h
             ld      c,l
             add     hl,hl
             add     hl,hl
             add     hl,bc
             add     hl,hl
     
             add     a,l
             ld      l,a
             jr      nc,_ComInpConvLoop
             inc     h
             jr      _ComInpConvLoop
             
_ComInpnumDone:
             
             ld      (LINE_BUFFER), hl ; na pocetku line_buffer je trazeni broj
             
             ; hl je pokazivac na promenljivu
             ld     hl, LINE_BUFFER
             ld     bc, 4
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a

             add    hl, bc
             
             ld     bc,(LINE_BUFFER)
             ld     (hl), c
             
             ret;kraj funkcje za unos promenljivve
             
             ld     a, (LINE_BUFFER)
             add    a, (hl)
             ld     (LINE_BUFFER), a
             
             ; hl je pokazivac na target promenljivu
             ld     hl, LINE_BUFFER
             ld     bc, 6
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a

             add    hl, bc
             
             ld     (hl), a
             
             ret
             
             
; BASIC instrukcija za sabiranje promenljive i konstante i smestanje u posebnu promenljivu
BASIC_ComAdc:
             ld      (LINE_BUFFER), hl

             ; hl je pokazivac na pocetnu promenljivu
             ld     hl, LINE_BUFFER
             ld     bc, 6
             Add    hl, bc
             ld     a, (hl)
             sub    97
             ld     hl, $1000
             ld     b, 0
             ld     c, a

             add    hl, bc
             

             ld     hl, LINE_BUFFER
             ld     bc, 6
             Add    hl, bc
             ld     (0), hl
             ld     de, (0)
             ; StrToInt - hl je trazeni broj de je moseto stringa
             ld hl,0
_ComAdcConvLoop:
             ld      a,(de)
             sub     30h
             cp      10
             jr      nc, _ComAdcnumDone
             inc     de

             ld      b,h
             ld      c,l
             add     hl,hl
             add     hl,hl
             add     hl,bc
             add     hl,hl

             add     a,l
             ld      l,a
             jr      nc,_ComAdcConvLoop
             inc     h
             jr      _ComAdcConvLoop

_ComAdcnumDone:
             
             ret
             
; ------------------------------------------
; Rutina za množenje brojeva
; Mnoze se brojevi na adresama (HL) i na adresama (BC)
; Izlaz se smesta u A registar
; ----------------------------------------
BIOS_mul:
	ld	a,(bc)
	ld	b,(hl)
	ld	d,a
_mul_loop:
	add 	a,d
	djnz	_mul_loop
	sub	d
	ret



STR_mainScreen:
               db "Basic interpreter", 13, 10, 0
               
STR_lineHeader:
               db "Command: ", 0
               
STR_newLine:
            db 13, 10, 0
            
STR_succParse:
              db 13, 10
              db "Usposno parsiranje", 13, 10, 0

STR_errParse:
             db 13, 10
             db "Greska prilikom parsiranja", 13, 10, 0

OPERAND1:
	db 10

OPERAND2:
	db 2

STR_keyWords:
             db "inc", 0 ; Uvecaj promenljivu za 1
             db "dec", 0 ; Unanji promenljivu za 1
             db "out", 0 ; ispisi promenjlivu
             db "inp", 0 ; upisi promenljivu
             db "adc", 0 ; dodavanje vrednosti
             db "adv", 0 ; dodavanje varijable
             db "muc", 0 ; mnozenje konstantom
             db "muv", 0 ; mozenje varijablom
             
MAT_binToChar:
              db "0", 0, 0, 0
              db "1", 0, 0, 0
              db "2", 0, 0, 0
              db "3", 0, 0, 0
              db "4", 0, 0, 0
              db "5", 0, 0, 0
              db "6", 0, 0, 0
              db "7", 0, 0, 0
              db "8", 0, 0, 0
              db "9", 0, 0, 0
              db "10", 0, 0
              db "11", 0, 0
              db "12", 0, 0
              db "13", 0, 0
              db "14", 0, 0
              db "15", 0, 0
              db "16", 0, 0
              db "17", 0, 0
              db "18", 0, 0
              db "19", 0, 0
              db "20", 0, 0
              db "21", 0, 0
              db "22", 0, 0
              db "23", 0, 0
              db "24", 0, 0
              db "25", 0, 0
              db "26", 0, 0
              db "27", 0, 0
              db "28", 0, 0
              db "29", 0, 0
              db "30", 0, 0
              db "31", 0, 0
              db "32", 0, 0
              db "33", 0, 0
              db "34", 0, 0
              db "35", 0, 0
              db "36", 0, 0
              db "37", 0, 0
              db "38", 0, 0
              db "39", 0, 0
              db "40", 0, 0
              db "41", 0, 0
              db "42", 0, 0
              db "43", 0, 0
              db "44", 0, 0
              db "45", 0, 0
              db "46", 0, 0
              db "47", 0, 0
              db "48", 0, 0
              db "49", 0, 0
              db "50", 0, 0
              db "51", 0, 0
              db "52", 0, 0
              db "53", 0, 0
              db "54", 0, 0
              db "55", 0, 0
              db "56", 0, 0
              db "57", 0, 0
              db "58", 0, 0
              db "59", 0, 0
              db "60", 0, 0
              db "61", 0, 0
              db "62", 0, 0
              db "63", 0, 0
              db "64", 0, 0
              db "65", 0, 0
              db "66", 0, 0
              db "67", 0, 0
              db "68", 0, 0
              db "69", 0, 0
              db "70", 0, 0
              db "71", 0, 0
              db "72", 0, 0
              db "73", 0, 0
              db "74", 0, 0
              db "75", 0, 0
              db "76", 0, 0
              db "77", 0, 0
              db "78", 0, 0
              db "79", 0, 0
              db "80", 0, 0
              db "81", 0, 0
              db "82", 0, 0
              db "83", 0, 0
              db "84", 0, 0
              db "85", 0, 0
              db "86", 0, 0
              db "87", 0, 0
              db "88", 0, 0
              db "89", 0, 0
              db "90", 0, 0
              db "91", 0, 0
              db "92", 0, 0
              db "93", 0, 0
              db "94", 0, 0
              db "95", 0, 0
              db "96", 0, 0
              db "97", 0, 0
              db "98", 0, 0
              db "99", 0, 0
              db "100", 0
              db "101", 0
              db "102", 0
              db "103", 0
              db "104", 0
              db "105", 0
              db "106", 0
              db "107", 0
              db "108", 0
              db "109", 0
              db "110", 0
              db "111", 0
              db "112", 0
              db "113", 0
              db "114", 0
              db "115", 0
              db "116", 0
              db "117", 0
              db "118", 0
              db "119", 0
              db "120", 0
              db "121", 0
              db "122", 0
              db "123", 0
              db "124", 0
              db "125", 0
              db "126", 0
              db "127", 0
              db "128", 0
              db "129", 0
              db "130", 0
              db "131", 0
              db "132", 0
              db "133", 0
              db "134", 0
              db "135", 0
              db "136", 0
              db "137", 0
              db "138", 0
              db "139", 0
              db "140", 0
              db "141", 0
              db "142", 0
              db "143", 0
              db "144", 0
              db "145", 0
              db "146", 0
              db "147", 0
              db "148", 0
              db "149", 0
              db "150", 0
              db "151", 0
              db "152", 0
              db "153", 0
              db "154", 0
              db "155", 0
              db "156", 0
              db "157", 0
              db "158", 0
              db "159", 0
              db "160", 0
              db "161", 0
              db "162", 0
              db "163", 0
              db "164", 0
              db "165", 0
              db "166", 0
              db "167", 0
              db "168", 0
              db "169", 0
              db "170", 0
              db "171", 0
              db "172", 0
              db "173", 0
              db "174", 0
              db "175", 0
              db "176", 0
              db "177", 0
              db "178", 0
              db "179", 0
              db "180", 0
              db "181", 0
              db "182", 0
              db "183", 0
              db "184", 0
              db "185", 0
              db "186", 0
              db "187", 0
              db "188", 0
              db "189", 0
              db "190", 0
              db "191", 0
              db "192", 0
              db "193", 0
              db "194", 0
              db "195", 0
              db "196", 0
              db "197", 0
              db "198", 0
              db "199", 0
              db "200", 0
              db "201", 0
              db "202", 0
              db "203", 0
              db "204", 0
              db "205", 0
              db "206", 0
              db "207", 0
              db "208", 0
              db "209", 0
              db "210", 0
              db "211", 0
              db "212", 0
              db "213", 0
              db "214", 0
              db "215", 0
              db "216", 0
              db "217", 0
              db "218", 0
              db "219", 0
              db "220", 0
              db "221", 0
              db "222", 0
              db "223", 0
              db "224", 0
              db "225", 0
              db "226", 0
              db "227", 0
              db "228", 0
              db "229", 0
              db "230", 0
              db "231", 0
              db "232", 0
              db "233", 0
              db "234", 0
              db "235", 0
              db "236", 0
              db "237", 0
              db "238", 0
              db "239", 0
              db "240", 0
              db "241", 0
              db "242", 0
              db "243", 0
              db "244", 0
              db "245", 0
              db "246", 0
              db "247", 0
              db "248", 0
              db "249", 0
              db "250", 0
              db "251", 0
              db "252", 0
              db "253", 0
              db "254", 0
              db "255", 0
              db "256", 0

LINE_BUFFER:
