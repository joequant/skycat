#ifndef rtdLOG_H
#define rtdLOG_H
/*******************************************************************************
* E.S.O. - VLT project
*
* "@(#) $Id: rtdLOG.h,v 1.1.1.1 2009/03/31 14:11:52 cguirao Exp $"
*
* who       when      what
* --------  --------  ----------------------------------------------
* pbiereic  01/03/01  created
*/

/************************************************************************
 *
 *----------------------------------------------------------------------
 */
#include <stdio.h>
#include <stdarg.h>

class rtdLOG
{
public:
    // constructor and destructor
    rtdLOG(int);
    ~rtdLOG();

    void  log(const char *format, ...);
    int   Verbose() { return verbose_; }

private:
    int verbose_;
  
protected:
};

#endif /*!rtdLOG_H*/
