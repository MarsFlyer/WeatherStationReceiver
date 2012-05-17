/* Pachube Library  
GET
PUT
*/

///#define DATESET 1

char serverName[] = "api.pachube.com";
String http;
long lastConnectionTime;

#define MAX_STRING 100

int pachube(char* verb, char* dataStr)
{
  // The data needs line feeds.
  // Example: "0,8\r\n1,21.2\r\n";

  if (millis() - lastConnectionTime < 250) 
  { 
    TEST_PRINTLN(F("Too Soon."));
    return false;
  }

  int iLen = strlen(dataStr);
  TEST_PRINTLN(iLen);
  TEST_PRINTLN(dataStr);
  int iAttempts = 0;
  boolean bOK = false;
  while(iAttempts++ < 4 && bOK==false)
  {
    TEST_PRINT(freeMemory());
    TEST_PRINT(" Connect ");
    TEST_PRINTLN(iAttempts);
    
    EthernetClient client;
    IPAddress ip = Ethernet.localIP();
    if (!client.connect(serverName, 80) || (ip[0]==0)) {
      TEST_PRINTLN("connect failed");
      if (iAttempts >= 4) {
        procReset();
      }
      else if (iAttempts >= 3) {
        ethernetInit();
      }
      else {
        delay(1000);
      }
      continue;
    }
    DEBUG_PRINTLN("connected");
      
    if (verb == "GET")
    {
      DEBUG_PRINT(freeMemory());
      DEBUG_PRINTLN(" GET");
  /*    client.print("GET /api/");
      client.print(getString(pachubeFeed)); 
      client.print(getString(httpHost)); 
      client.print(getString(pachubeAPI));
      client.print(getString(httpAgent));
 */   } 
    else if (verb == "PUT")
    {
      // send the HTTP PUT request. 
      TEST_PRINT(freeMemory());
      TEST_PRINTLN(" PUT");
      
      //httpSend(PSTR("PUT /v2/feeds/"));

      client.print("PUT /v2/feeds/");
      client.print(FEEDPUT);
      client.print(".csv HTTP/1.1");
      client.print("\r\nHost: api.pachube.com");
      client.print("\r\nX-PachubeApiKey: ");
      client.print(APIKEY1);
      client.print(APIKEY2);
      client.print("\r\nContent-Type: text/csv");
      client.print("\r\nUser-Agent: Arduino");
      client.print("\r\nContent-Length: ");
      client.print(iLen);
      // There needs to be an empty line after the data.
      ///client.print("\r\nConnection: close\r\n\r\n");
      client.print("\r\n\r\n");
      client.print(dataStr);
      ///client.print("\r\n"); //r\n");  // Not required as the data string is finished with \r\n.

      TEST_PRINT(freeMemory());
      TEST_PRINTLN(" Sent.");
    }

    int iLine = 0;
    while (client.connected())  // Get response.
    {
      int line_cursor = 0;
      ///String line = "";
      while (client.connected())  // Per line
      {
        if (client.available())
        {
          char c = client.read();
          #ifdef TESTING
            if (bOK==false) {
              TEST_PRINT(c);
            }
          #else
            DEBUG_PRINT(c);
          #endif
          if (c == '\n') {buf2[line_cursor] = '\0'; break;}
          // Ignore CRs
          if (c != '\r')
          {
            ///line += c;
            buf2[line_cursor] = c;
            line_cursor++;
            if (line_cursor >= LINE_BUFF_SIZE) {break;}
          }
        }
      }
      iLine++;
      ///Serial.println(line);
      if (line_cursor == 0) {break;}
      ///results += line;   // Only send the actual result lines.
      ///if (line.startsWith("Date:")) { 
      if (strstr(buf2, "200 OK") != NULL){
         TEST_PRINT(freeMemory());
         TEST_PRINTLN(" OK RECVD");
        // note the time that the connection was made:
        long lastConnectionTime = millis();
        iConnections++;
        ///iAttempts = 9; // No need to try again.
        bOK = true;
      }
      #ifdef DATESET
        if ((buf2[0] == 'D') && (buf2[1] == 'a') && (buf2[2] == 't') && (buf2[3] == 'e') && (buf2[4] == ':')) { 
          //Date: Wed, 16 Mar 2011 22:32:39 GMT\r\n
          int hr = intPart(buf2,23,25);
          int min = intPart(buf2,26,28);
          int sec = intPart(buf2,29,31);
          int day = intPart(buf2,11,13);
          int month = 4; // = intPart(line,14,17)
          int yr = intPart(buf2,18,22);
          ///setTime(hr,min,sec,day,month,yr);
          DEBUG_PRINT(freeMemory());
          DEBUG_PRINTLN(" Sync:");
          ///TEST_PRINTLN(datetimeString(now()));
        }
      #endif
      ///line = "";
    }

    DEBUG_PRINTLN("disconnecting.");
    client.stop();
    while(client.status() != 0) {
      delay(5);
    }
  }
}

int intPart(char* in, int iFrom, int iTo){
  char buf3[30] = "";
  int i=0;
  while(iFrom < iTo)  // go into assignment loop
  {
    buf3[i++] = in[iFrom++];  // assign them
  }
   // now append a terminator
  buf3[i] = '\0';
  return atoi(buf3);
}    

char* getString(const char* str) {
  char stringBuffer[MAX_STRING];
  strcpy_P(stringBuffer, (char*)str);
  ///TEST_PRINT(stringBuffer);
  return stringBuffer;
}

void httpSend(char* in) {
  //client.print(in);
  TEST_PRINT(in);
}

void ethernetInit()
{
  int ms = 1200;
  ///ping();
  TEST_PRINT(freeMemory());
  TEST_PRINT(F(" Ethernet init..."));
  #ifdef WATCHDOG
    wdt_reset();
  #endif
  pinMode(resetPin, OUTPUT);      // sets the digital pin as output
  digitalWrite(resetPin, LOW);
  delay(ms*4);  //for ethernet chip to reset - needs ~4 seconds to properly reset.
  digitalWrite(resetPin, HIGH);
  pinMode(resetPin, INPUT);      // sets the digital pin input
  delay(ms);  //for ethernet chip to reset
  #ifdef WATCHDOG
    wdt_reset();
  #endif

  delay(ms);  //for ethernet chip to reset
  if (Ethernet.begin(mac) == 0) {
    TEST_PRINTLN(F("Failed to configure Ethernet using DHCP"));
    // no point in carrying on, so do nothing forevermore:
    ///for(;;)
      ///;
  }
  // print your local IP address:
  TEST_PRINTLN(Ethernet.localIP());
  delay(ms);  //for ethernet chip to settle
}

void procReset()
{
  TEST_PRINTLN(F("Reset board"));
  MCUSR=0;
  wdt_enable(WDTO_4S); // setup Watch Dog Timer and wait longer to force reset.
  delay(6000);
}

