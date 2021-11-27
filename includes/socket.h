#ifndef __SOCKET_H__
#define __SOCKET_H__

#define CLOSED      0
#define SYN_SENT    1
#define SYN_RCVD    2
#define ESTABLISHED 3
#define FIN_WAIT1   4
#define FIN_WAIT2   5
#define TIME_WAIT   6
#define CLOSE_WAIT  7
#define LAST_ACK    8
#define LISTEN      9

enum{
    MAX_NUM_OF_SOCKETS = 10,
    ROOT_SOCKET_ADDR = 255,
    ROOT_SOCKET_PORT = 255,
    SOCKET_BUFFER_SIZE = 128,
};
/*
enum socket_state{
    CLOSED,
    LISTEN,
    ESTABLISHED,
    SYN_SENT,
    SYN_RCVD,
    NONE,
};
*/
enum My_port{
    SERVER,
    CLIENT,
};


typedef nx_uint8_t nx_socket_port_t;
typedef uint8_t socket_port_t;

// socket_addr_t is a simplified version of an IP connection.
typedef nx_struct socket_addr_t{
    //nx_socket_port_t port;
   // nx_uint16_t addr;

    nx_uint16_t addr;
    nx_uint8_t port;
}socket_addr_t;


// File descripter id. Each id is associated with a socket_store_t
//typedef uint8_t socket_t;

// State of a socket. 
typedef struct socket_t{// was b4 typedef struct socket_store_t
    uint8_t flag;
   // enum socket_state state;
   // socket_port_t src;
    socket_addr_t dest;
    uint8_t state;

    socket_addr_t src;
    enum My_port TYPE;
    //socket_t fd;

    // This is the sender portion.
    uint8_t sendBuff[64];//SOCKET_BUFFER_SIZE];
    uint8_t lastWritten;
    uint8_t lastAck;
    uint8_t lastSent;

    // This is the receiver portion
    uint8_t rcvdBuff[64];//SOCKET_BUFFER_SIZE];
    uint8_t lastRead;
    uint8_t lastRcvd;
    uint8_t nextExpected;
    uint8_t seq;

    uint16_t RTT;
    uint8_t effectiveWindow;
    nx_uint16_t transfer;
}socket_t;//was b4 socket_store_t

#endif
