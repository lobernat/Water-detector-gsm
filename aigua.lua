--------------------------------------------
--------Inicialitzar pantalla---------------
--------------------------------------------
--tipografia
--font_6x10
--font_courR08
--font_courR10
--font_courR12
--font_courR14
--font_courR18
--font_helvB08
--font_helvB10
--font_helvB12
--font_helvB14
--font_helvB18
-- Hardware: 
--   ESP-12E Devkit
--   4 pin I2C OLED 128x64 Display Module
-- Connections:
--   ESP  --  OLED
--   3v3  --  VCC
--   GND  --  GND
--   D5   --  SDA
--   D6   --  SCL

-- Variables 
sda = 5 -- SDA Pin
scl = 6 -- SCL Pin

function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3C
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     --disp:setFont(u8g.font_6x10)
     --disp:setFontRefHeightExtendedText()
     --disp:setDefaultForegroundColor()
     --disp:setFontPosTop()
     --disp:setRot180()           -- Rotate Display if needed
end



---persistensia amb ssid
-----------------------------------------------------------
--guardar persistencia
-----------------------------------------------------------

function GuardarPersistencia (telefon, parametres)
    wifi.setmode(wifi.STATION)
    --La contrasenya ha de ser de mes de 8 caracters,per aixo la guardem al ssid.
    wifi.sta.config(parametres,telefon)
    display_3files("Reinicia","Cal reiniciar","Per guardar")
    print("Cal apagar i encendre per guardar els canvis")
end

function LlegirPersistencia ()
    --mostrar persistencia
    parametres, telefon = wifi.sta.getconfig()
    print ("Telefon a la memoria: ",telefon)
    print ("parametres: ",parametres)
    return telefon, parametres
end

-----------------------------------------------------------
--parametres a text
-----------------------------------------------------------
function ParametresToText(parametre)
    if parametre == "11" then return "Perduda + SMS" end
    if parametre == "10" then return "Perduda" end
    if parametre == "01" then return "SMS" end   
end
-----------------------------------------------------------
--Crear modo AP
-----------------------------------------------------------
 
function TelefonAp()
     print("Ready to start soft ap")
     local str=wifi.ap.getmac();
     local ssidTemp=string.format("%s%s%s",string.sub(str,10,11),string.sub(str,13,14),string.sub(str,16,17));
     
     cfg={}
     cfg.ssid="_Regador_Config";
     --cfg.pwd="12345678"
     wifi.ap.config(cfg)
     
     cfg={}
     cfg.ip="192.168.4.1";
     cfg.netmask="255.255.255.0";
     cfg.gateway="192.168.4.1";
     wifi.ap.setip(cfg);
     wifi.setmode(wifi.SOFTAP)
     
     str=nil;
     ssidTemp=nil;
     collectgarbage();
     
     print("Soft AP OK")
    
end


-----------------------------------------------------------
--Servidor WEB
-----------------------------------------------------------

function ServidorWeb()
    telefon, parametres = LlegirPersistencia()
    
    
srv=net.createServer(net.TCP) srv:listen(80,function(conn)
    conn:on("receive",function(conn,payload)
    --next row is for debugging output only
    print("Payload: ",payload)
------------------
    --Parsejar el payload
    function Actualitzar_Persistencia()
    Parametres=string.sub(payload,RespostaPost[2]+1)
   -- print ("Paramertres POST:", Parametres)

    --Parsejar tot payload     678093111hdjdhsk&parametre=perduda0sms0               
   print ("Paramertres POST:", Parametres)

    TelefonPost= string.find(Parametres, "&parametre=")
    TelefonPost=string.sub(Parametres, 0,TelefonPost-1 )

    ParametrePost= string.find(Parametres, "=")
    ParametrePost=string.sub(Parametres,ParametrePost+1)
    print (TelefonPost)
    print (ParametrePost)
    GuardarPersistencia (TelefonPost, ParametrePost)     
    end
                    
    --Parsejar el payload per comprobar si ni ha
    RespostaPost={string.find(payload,"telefon=")}
    --If POST value exist, set LED power
    if RespostaPost[2]~=nil then Actualitzar_Persistencia()end                   

             


                    
-----------------  

    conn:send('HTTP/1.1 200 OK\n\n')
    conn:send('<!DOCTYPE HTML>\n')
    conn:send('<html>\n')
    conn:send('<head><meta  content="text/html; charset=utf-8">\n')
    conn:send('<title>Regador - Configuracio</title></head>\n')
  --  conn:send('<body><h3>Configurar Regador</h3>\n')
   conn:send(' Configuracio actual:<br>Telefon: <b>'..telefon..'</b><br>Parametres:<b> '..parametres..'</b><br><br>\n')
    conn:send('<form action="" method="POST">\n')
 conn:send('La casella parametre es per configurar si es vol fer perduda i/o enviar SMS<br>\n')
conn:send('Exemple: fer nomes perduda, els parametres serien 10, o fer perduda i enviar sms seria 11, enviar solament sms 01<br>\n')
 --conn:send(' parametres: 680167236,0,1<br>\n')
 conn:send('<br>Telefon: <input type="text" name="telefon" value='..telefon..'>\n<br>')
  conn:send('Parametres: <input type="text" name="parametre" value='..parametres..'>\n')
  conn:send('<br><br>\n')
  conn:send('<input type="submit" value="Submit">\n')
    conn:send('</form>\n')
    conn:send('</body></html>\n')
    conn:on("sent",function(conn) conn:close() end)
    end)
end) 
end --end funcio ServidorWEb


--------------------------------------------
----------Mostrar display-------------------
--------------------------------------------
function xxdisplay_3files(text, t1, t2)
   disp:firstPage()
   repeat
     disp:setFont(u8g.font_6x10)
     disp:drawStr(0, 15, text)
    --disp:setFont(u8g.font_fur20)
    disp:setFont(u8g.font_helvB14) 
     disp:drawStr(0, 40, t1)    
     disp:drawStr(0, 60, t2)
   
   until disp:nextPage() == false 
end



function display_3files(text1,text2,text3)
   disp:firstPage()
   repeat
        disp:setFont(u8g.font_helvB14)    
    disp:drawStr(0, 15, text1)
     disp:setFont(u8g.font_courR12)
    disp:drawStr(0, 40, text2)
    disp:drawStr(0, 60, text3)
   until disp:nextPage() == false 
end

-----------------------------------------------------------
--Detectar aigua
-----------------------------------------------------------
function DetectarAigua()
  --programa deteccio aigua
    display_3files("aigua","sensor preparat"," ")
end


-----------------------------------------------------------
--iniciar programa
-----------------------------------------------------------
--cridar funcio per iniciar display
init_OLED(sda,scl)


print (gpio.read(1) )
--inicialitzar polsador i lectura aigua
gpio.mode(1, gpio.INPUT ) --Polsador config
gpio.mode(2, gpio.INPUT ) --Deteccio aigua

--mostrar pel display "Aguantar boto per entrar en mode configuracio"
--posar un delay de 30 segons
--despres del delay mirar si el polsador esta polsat.
-- si esta polsat entrar en mode config
--sino iniciar programa deteccio aigua

function IniciPrograma()
    --mostrar configuracio persistencia per display
    ptelf, pparam = LlegirPersistencia ()
    pparam = ParametresToText(pparam)
    display_3files(ptelf,pparam," ")
    --Delay 30 segons per mostrar per pantalla la config
    tmr.delay(30000)
    DetectarAigua()
end

function IniciConfig()
    display_3files("CONFIGURACIO","192.168.4.1"," ")
    TelefonAp() 
    ServidorWeb()
end

--Comprobar si polsador apretat i entra en mode configuracio sino iniciar programa
if gpio.read(1) == 1 then
    IniciConfig()
else
    IniciPrograma()
end


