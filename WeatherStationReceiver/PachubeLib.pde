/* Pachube Library  
GET
PUT
*/

///#define DATESET 1

byte server[4];
long lastConnectionTime;
///Client client(server, 80);

//#define LINE_BUFF_SIZE 79

#define MAX_STRING 100
/*
const char pachubeAPI[]   PROGMEM = "XXX"; // fill in your API key 
const char pachubeFeed[]  PROGMEM = "19886";    // this is the ID of the remote Pachube feed that you want to connect to

const char httpHost[]     PROGMEM = ".csv HTTP/1.1\r\nHost: api.pachube.com\r\nX-PachubeApiKey: ";
const char httpAgent[]    PROGMEM = "\r\nUser-Agent: Arduino\r\n\r\n";
const char httpContent[]  PROGMEM = "\r\nContent-Type: text/csv";
///const char httpContent[] PROGMEM = "\r\nContent-Type: application/x-www-form-urlencoded";
const char httpLength[]   PROGMEM = "\r\nUser-Agent: Arduino\r\nContent-Length: ";
*/
//char stringBuffer[MAX_STRING];

String pachube(char* verb, char* dataStr)
{
  // The data needs line feeds.
  // Example: "0,8\r\n1,21.2\r\n";

  if (millis() - lastConnectionTime < 250) 
  { 
    TEST_PRINTLN("Too Soon.");
    return "";
  }

  int iLen = strlen(dataStr);
  int iAttempts = 0;
  boolean bOK = false;
  while(iAttempts++ < 4 && bOK==false)
  {
    TEST_PRINT(freeMemory());
    TEST_PRINT(" Connect ");
    TEST_PRINTLN(iAttempts);
    
/*    if (iAttempts >= 2) {
      ethernetInit();
      TEST_PRINT(freeMemory());
      TEST_PRINTLN(" Reset.");
      digitalWrite(resetPin, false);
      delay(200);
      digitalWrite(resetPin, true);
      delay(2000);
      Ethernet.begin(mac, ip);
      delay(250);
      iConnections -= 5;
    } */
    ///else {continue;}

    Client client(server, 80);
    if (!client.connect()) {
      ///TEST_PRINTLN("connect failed");
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
      DEBUG_PRINT(freeMemory());
      DEBUG_PRINTLN(" PUT");
      if (1==1) {
/*
        DEBUG_PRINT("PUT /v2/feeds/");
        DEBUG_PRINT(getString(pachubeFeed)); 
        DEBUG_PRINT(getString(httpHost));
        DEBUG_PRINT(getString(pachubeAPI));
        DEBUG_PRINT(getString(httpContent));
        DEBUG_PRINT(getString(httpLength));
        DEBUG_PRINTDEC(iLen);
        // There needs to be an empty line after the data.
        ///Serial.print("\r\nConnection: close\r\n\r\n");
        DEBUG_PRINT("\r\n\r\n");
        DEBUG_PRINT(dataStr);
        DEBUG_PRINT("\r\n\r\n");
*/
        client.print("PUT /v2/feeds/");
        client.print(FEEDPUT);
        client.print(".csv HTTP/1.1\r\nHost: api.pachube.com\r\nX-PachubeApiKey: ");
        client.print(APIKEY1);
        client.print(APIKEY2);
        client.print("\r\nContent-Type: text/csv\r\nUser-Agent: Arduino\r\nContent-Length: ");
        client.print(iLen, DEC);
        // There needs to be an empty line after the data.
        ///client.print("\r\nConnection: close\r\n\r\n");
        client.print("\r\n\r\n");
        client.print(dataStr);
        client.print("\r\n\r\n");
      }
      else {
/*        httpSend("PUT /v2/feeds/");
        httpSend(getString(pachubeFeed)); 
        httpSend(getString(httpHost));
        httpSend(getString(pachubeAPI));
        httpSend(getString(httpContent));
        httpSend(getString(httpLength));
        httpSend(iLen);
        // There needs to be an empty line before and after the data.
        httpSend("\r\n");
        httpSend(dataStr);
        httpSend("\r\n\r\n");
*/      }

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
          setTime(hr,min,sec,day,month,yr);
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
/*
void httpSend(String in) {
  client.print(in);
  TEST_PRINT(in);
}
*/
void ethernetInit()
{
  int ms = 1200;
  ///ping();
  TEST_PRINT(freeMemory());
  TEST_PRINT(" Ethernet init...");
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
  ///Ethernet.begin(mac,ip,gateway,subnet);
  delay(ms);  //for ethernet chip to reset
  while (Dhcp.beginWithDHCP(mac) != 1)
  {
    TEST_PRINTLN("Error getting IP address via DHCP, trying again...");
    delay(15000);
  }
  Dhcp.getLocalIp(server);
  TEST_PRINTLN(ip_to_str(server));
  /*
  const byte* ipAddr = Dhcp.getLocalIp();
  TEST_PRINT("IP:");
  TEST_PRINTLN(ip_to_str(ipAddr));
  */
  
  ///Ethernet.begin(mac,ip,gateway,subnet);
  delay(ms);  //for ethernet chip to reset

  ///ping();
  
  DNSClient dns;
  // Use "server" to hold the DNS server address while we initialise
  // the DNS code
  Dhcp.getDnsServerIp(server);
  dns.begin(server);

  // Resolve the hostname to an IP address
  // Re-use "server" to hold the address for the resolved hostname
  int err = dns.gethostbyname(kHostname, server);
  if (err == 1)
  {
    TEST_PRINT(kHostname);
    TEST_PRINT(" resolved to ");
    /*
    if (client.connect()) {
      Serial.println("connected");
      client.println("GET /search?q=arduino HTTP/1.0");
      client.println();
    } else {
      Serial.println("connection failed");
    } */
  }
  else
  {
    TEST_PRINT("DNS lookup failed, defaulted to ");
    server[0] = 173; server[1] = 203; server[2] = 98; server[3] = 29 ; // api.pachube.com
  }
  TEST_PRINTLN(ip_to_str(server));
}

void procReset()
{
  TEST_PRINTLN("Reset board");
  MCUSR=0;
  wdt_enable(WDTO_1S); // setup Watch Dog Timer to 1 sec
  delay(2000);
}

/*
///include ICMP;
SOCKET pingSocket = 3;
char pingBuf [60];

void ping()
{
  ICMPPing ping(pingSocket);
  ping(1, gateway, pingBuf);
  TEST_PRINTLN(pingBuf);
}
*/
// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}
