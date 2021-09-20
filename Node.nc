/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

typedef nx_struct neighboorDiscovery{ //first two fields are for nd header
nx_uint16_t petition;
nx_uint16_t sequenceNumber;
nx_uint16_t sourceAddress;  //last two fields are for link layer headers
nx_uint16_t destinationAddress;

nx_uint16_t node;
nx_uint16_t age;

}neighboorDiscovery;

module Node{
   uses interface Boot;

   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;

   uses interface Timer<TMilli> as NeighboorTimer;
   uses interface Random as RandomTimer;
   uses interface List<neighboorDiscovery> as NeighboorList;
   uses interface List<neighboorDiscovery *> as NeighboorList1;
   uses interface List<pack> as PacketList;


}

implementation{
   pack sendPackage;
   uint16_t sequenceNumber= 0;

   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void findNeighboors();
   void printNeighboors();
   bool seenPackage(pack* package);
   void pushPack(pack package);

   event void Boot.booted(){
   //uint16_t start, everySecond;

      call AMControl.start();
      //start = call RandomTimer.rand16()%1000;
      //everySecond = call RandomTimer.rand16()%4000;
      call NeighboorTimer.startPeriodic(2000);
      //call NeighboorTimer.startPeriodicAt(start,everySecond);
      dbg(GENERAL_CHANNEL, "Booted. \n");
   }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }

   event void NeighboorTimer.fired() {
  // dbg(GENERAL_CHANNEL,"firing timer \n");
  findNeighboors();
   
   }


   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");
      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
        // dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
         //return msg;

         if(myMsg->TTL==0 || seenPackage(myMsg))
         {

         }
         
         if(myMsg->dest == AM_BROADCAST_ADDR)
         {
            bool foundNeighbor;
            uint16_t i,sizeList;
            neighboorDiscovery* neighboor;
            neighboorDiscovery* temp;

            if(myMsg->protocol == PROTOCOL_PING)
            {
               makePack(&sendPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, myMsg->TTL-1, PROTOCOL_PINGREPLY, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
               pushPack(sendPackage);
               call Sender.send(sendPackage, myMsg->src);
            }

            if(myMsg->protocol == PROTOCOL_PINGREPLY)
            {
               sizeList = call NeighboorList1.size();
               foundNeighbor = FALSE;
               i=0;
               while(i<sizeList)
               {
                  temp = call NeighboorList1.get(i);
                  if(temp->node==myMsg->src)
                  {
                     temp->age=0;
                       foundNeighbor =TRUE;
                  }

               }

               if(!foundNeighbor)
               {

               }
            }
         }  
         else if(TOS_NODE_ID==myMsg->dest) //this package is for me
         {
            dbg(NEIGHBOR_CHANNEL," packet from %d. Content: %s",myMsg->src,myMsg->payload);
            if(myMsg->protocol != PROTOCOL_CMD)
            {
               pushPack(*myMsg);
            }

            if(myMsg->protocol == PROTOCOL_PING)
            {
               makePack(&sendPackage,TOS_NODE_ID,myMsg->src,MAX_TTL,PROTOCOL_PINGREPLY,sequenceNumber,(uint8_t *)myMsg->payload,sizeof(myMsg->payload));
               sequenceNumber++;
               pushPack(sendPackage);
               call Sender.send(sendPackage,AM_BROADCAST_ADDR);
            }

            if(myMsg->protocol == PROTOCOL_PINGREPLY)
            {
               dbg(NEIGHBOR_CHANNEL,"Ping is coming from %d",myMsg->src);
            }
         }

         else
         {
            makePack(&sendPackage, myMsg->src, myMsg->dest, myMsg->TTL-1, myMsg->protocol, myMsg->seq, (uint8_t *)myMsg->payload, sizeof(myMsg->payload));
            dbg("Project1F", "Received Message from %d, meant for %d. Rebroadcasting\n", myMsg->src, myMsg->dest);
            pushPack(sendPackage);
            call Sender.send(sendPackage, AM_BROADCAST_ADDR);
         }
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(sendPackage, destination);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}


   void findNeighboors()
   {

   //dbg(GENERAL_CHANNEL,"about to find neighboors");
   pack Package;
   char* message;
   neighboorDiscovery* neighboorPointer;
   neighboorDiscovery* temp;
   uint16_t i,sizeList,age;



   if(!call NeighboorList.isEmpty())
   {
      i=0;
      age=0;

      while(i<sizeList)
      {
         temp = call NeighboorList1.get(i);
         temp->age++;
         i++;
      }

      i=0;
      do{

         temp = call NeighboorList1.get(i);
        
         if((temp->age)>5)
         {
            neighboorPointer = call NeighboorList1.remove(i);
            i--;
            sizeList--;
         }
         i++;
      }while(i<sizeList);
   }



   }


   void printNeighboors()
   {

   
   uint16_t i, sizeList;
   neighboorDiscovery* temp;
   sizeList = call NeighboorList1.size();
   if(call NeighboorList1.isEmpty())
   {
      dbg(NEIGHBOR_CHANNEL,"No neighboors \n");
   }
   else
   {
   i=0;
   dbg(NEIGHBOR_CHANNEL,"Neighboor list for node %d \n", TOS_NODE_ID);
   while(i<sizeList)
   {
      temp = call NeighboorList1.get(i);
      dbg(NEIGHBOR_CHANNEL, "Neighboor: %d, Age: %d \n", temp->node,temp->age);
   }
   }
   dbg(GENERAL_CHANNEL, "Here in print neighboors. \n");

   }

   bool seenPackage(pack* package)
   {
      uint16_t sizeList = call PacketList.size();
      uint16_t i =0;
      pack seen;
      while(i<sizeList)
      {
         seen = call PacketList.get(i);
         if(seen.src = package->src && seen.dest == package->dest && seen.seq==package->seq)
         {
            return TRUE;
         }
         i++;
      }
      return FALSE;
   }

   void pushPack(pack Package)
   {
      if(call PacketList.isFull())
      {
         call PacketList.popfront();
      }

      call PacketList.pushback(Package);
   }

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
      memcpy(Package->payload, payload, length);
   }
}