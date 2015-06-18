#include "CommandQueue.h"

#define BLOCK_TIME 12
// #define DEBUG_TP

using namespace std;

namespace DRAMSim
{
    class CommandQueueTP : public CommandQueue
    {
        public:
            CommandQueueTP(vector< vector<BankState> > &states,
                    ostream &dramsim_log_,unsigned tpTurnLength,
                    int num_pids, bool fixAddr_,
                    bool diffPeriod_, int p0Period_, int p1Period_, int offset_,
                    bool partitioning=false);
            virtual void enqueue(BusPacket *newBusPacket);
            virtual bool hasRoomFor(unsigned numberToEnqueue, unsigned rank, 
                    unsigned bank, unsigned pid);
            virtual bool isEmpty(unsigned rank);
            virtual vector<BusPacket *> &getCommandQueue(unsigned rank, 
                    unsigned pid);
            virtual void print();

        protected:
            virtual void refreshPopClosePage(BusPacket **busPacket, bool & sendingREF);
            virtual bool normalPopClosePage(BusPacket **busPacket, bool & sendingREF);

#ifdef DEBUG_TP
            virtual bool hasInteresting();
#endif /*DEBUG_TP*/

            unsigned lastPID;
            unsigned last_pid;
            unsigned pid_last_pop;
            unsigned tpTurnLength;
            unsigned lastPopTime;
            bool fixAddr;
            bool diffPeriod;
            int p0Period;
            int p1Period;
			int offset;
            bool partitioning;

            unsigned getCurrentPID();
            bool isBufferTime();

            virtual int normal_deadtime(int tlength){
              if(partitioning){
                  return FIX_WORST_CASE_DELAY;
              } else {
                  return WORST_CASE_DELAY;
              }
            }

            virtual int refresh_deadtime(int tlength){
              if(partitioning){
                  return FIX_TP_BUFFER_TIME;
              } else {
                  return TP_BUFFER_TIME;
              }
            }
    };
}
