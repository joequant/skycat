#ifndef rtdSERVER_H
#define rtdSERVER_H
/*******************************************************************************
* E.S.O. - VLT project
*
* "@(#) $Id: rtdSERVER.h,v 1.1.1.1 2009/03/31 14:11:52 cguirao Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* pbiereic  01/03/01  created
*/

/************************************************************************
 *
 *----------------------------------------------------------------------
 */

#define MAX_CLNT 300  // max. number of clients which can connect

#include "rtdCLNT.h"  // includes almost all we need
#include "rtdLOG.h"
#include <time.h>
#include <sys/select.h>

// This class is handling semaphores, not rtdCLNT

#ifndef HAVE_UNION_SEMUN
// argument type needed by semctl - not used here
union semun 
{
    int val;               // used for SETVAL only
    struct semid_ds *buf;  // for IPC_STAT and IPC_SET
    ushort *array;         // used for GETALL and SETALL
};
#endif

class rtdSERVER : public rtdLOG
{
public:
    // constructor and destructor
    rtdSERVER(int, int, int);
    ~rtdSERVER();
  
    int      Loop();
  
protected:
    rtdCLNT *GetCurrClient();
    void     ServImageCmd(rtdPACKET *rtdPacket);
    void     ServStatusCmd(int socket);
    int      IncrSem(rtdPACKET *rtdPacket, int increment);
    rtdCLNT *Accept();
    void     DisconnectClient(rtdCLNT *client);

private:
    int       socketFd_;           // listen socket
    int       delay_;              // delay in msec
    int       numClnt_;            // number of clients which are currently connected
    rtdCLNT   *clnt_[MAX_CLNT+1];  // pointer array to camera objects
    int       reqCount_;           // total number of requests
    int       reqClnt_;            // total number of clients which connected
    fd_set    *readFd_;            // read file descriptor mask
    char startTime_[256];          // start time
};

#endif /*!rtdSERVER_H*/
