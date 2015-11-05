#include "CommandQueue.h"

#ifndef TPCONFIG
#define TPCONFIG
#include "TPConfig.h"
#endif

#define BLOCK_TIME 12

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
                    TPConfig* tp_config,
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
            int tl[8];
            int p0Period;
            int p1Period;
			int offset;
            bool partitioning;
            bool rank_bank_part;
            bool relax_dtime;

            unsigned getCurrentPID();
            bool isBufferTime(BusPacketType t);

            virtual int normal_deadtime(int tlength, BusPacketType type){
              if(partitioning & !rank_bank_part){
                  if(type==WRITE || type==WRITE_P && relax_dtime){
                      return FIX_WORST_CASE_DELAY_WRITE;
                  }
                  else if(type==READ || type==READ_P && relax_dtime){
                      return FIX_WORST_CASE_DELAY_READ;
                  }
                  else return FIX_WORST_CASE_DELAY;
              } else if(rank_bank_part){
                  return RANK_BANK_WORST_CASE;
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
