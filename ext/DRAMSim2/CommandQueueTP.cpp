#include "CommandQueueTP.h"
#include "assert.h"

using namespace DRAMSim;

CommandQueueTP::CommandQueueTP(vector< vector<BankState> > &states, 
        ostream &dramsim_log_, unsigned tpTurnLength_,
        int num_pids_, bool fixAddr_,
        bool diffPeriod_, int p0Period_, int p1Period_, int offset_,
        TPConfig* tp_config,
        bool partitioning_):
    CommandQueue(states,dramsim_log_,num_pids_)
{
    fixAddr = fixAddr_;
    tpTurnLength = tpTurnLength_;
    diffPeriod = diffPeriod_;
    tl[0] = tp_config->tl0;
    tl[1] = tp_config->tl1;
    tl[2] = tp_config->tl2;
    tl[3] = tp_config->tl3;
    tl[4] = tp_config->tl4;
    tl[5] = tp_config->tl5;
    tl[6] = tp_config->tl6;
    tl[7] = tp_config->tl7;
    relax_dtime = tp_config->relax_dtime;
	offset = offset_;
    partitioning = partitioning_;
#ifdef DEBUG_TP
    cout << "TP Debugging is on." <<endl;
#endif
}

void CommandQueueTP::enqueue(BusPacket *newBusPacket)
{
    unsigned rank = newBusPacket->rank;
    unsigned pid = newBusPacket->threadID;
    queues[rank][pid].push_back(newBusPacket);
#ifdef DEBUG_TP
    if(newBusPacket->physicalAddress == interesting)
        cout << "Enqueued interesting @ "<< currentClockCycle <<endl;
#endif /*DEBUG_TP*/
    if (queues[rank][pid].size()>CMD_QUEUE_DEPTH)
    {
        ERROR("== Error - Enqueued more than allowed in command queue");
        ERROR("						Need to call .hasRoomFor(int "
                "numberToEnqueue, unsigned rank, unsigned bank) first");
        exit(0);
    }
}

bool CommandQueueTP::hasRoomFor(unsigned numberToEnqueue, unsigned rank,
        unsigned bank, unsigned pid)
{
    vector<BusPacket *> &queue = getCommandQueue(rank, pid);
    return (CMD_QUEUE_DEPTH - queue.size() >= numberToEnqueue);
}

bool CommandQueueTP::isEmpty(unsigned rank)
{
    for(int i=0; i<num_pids; i++)
        if(!queues[rank][i].empty()) return false;
    return true;
}

vector<BusPacket *> &CommandQueueTP::getCommandQueue(unsigned rank, unsigned 
        pid)
{
    return queues[rank][pid];
}

void CommandQueueTP::refreshPopClosePage(BusPacket **busPacket, bool & 
        sendingREF)
{

    bool foundActiveOrTooEarly = false;
    //look for an open bank
    for (size_t b=0;b<NUM_BANKS;b++)
    {
        vector<BusPacket *> &queue = getCommandQueue(refreshRank,getCurrentPID());
        //checks to make sure that all banks are idle
        if (bankStates[refreshRank][b].currentBankState == RowActive)
        {
            foundActiveOrTooEarly = true;
#ifdef DEBUG_TP
            cout << "TooEarly because row is active with pid " << getCurrentPID()
                << " at time " << currentClockCycle <<endl;
            bankStates[refreshRank][b].print();
            print();
#endif /*DEBUG_TP*/
            //if the bank is open, make sure there is nothing else
            // going there before we close it
            for (size_t j=0;j<queue.size();j++)
            {
                BusPacket *packet = queue[j];
                if (packet->row == 
                        bankStates[refreshRank][b].openRowAddress &&
                        packet->bank == b)
                {
                    if (packet->busPacketType != ACTIVATE && 
                            isIssuable(packet))
                    {
                        *busPacket = packet;
                        queue.erase(queue.begin() + j);
                        sendingREF = true;
                    }

                    break;
                }
            }

            break;
        }
        //	NOTE: checks nextActivate time for each bank to make sure tRP 
        //	is being
        //				satisfied.	the next ACT and next REF can be issued 
        //				at the same
        //				point in the future, so just use nextActivate field 
        //				instead of
        //				creating a nextRefresh field
        else if (bankStates[refreshRank][b].nextActivate > 
                currentClockCycle)
        {
            foundActiveOrTooEarly = true;
#ifdef DEBUG_TP
            cout << "TooEarly because nextActivate is "
                <<bankStates[refreshRank][b].nextActivate
                << " at time " << currentClockCycle <<endl;
#endif /*DEBUG_TP*/
            break;
        }
        //}
    }

    //if there are no open banks and timing has been met, send out the refresh
    //	reset flags and rank pointer
    if (!foundActiveOrTooEarly && bankStates[refreshRank][0].currentBankState 
            != PowerDown)
    {
        *busPacket = new BusPacket(REFRESH, 0, 0, 0, refreshRank, 0, 0, 
                dramsim_log);
#ifdef DEBUG_TP
        // PRINTN("Refresh at " << currentClockCycle << " for rank " 
        //         << refreshRank << endl);
#endif /*DEBUG_TP*/
        refreshRank = -1;
        refreshWaiting = false;
        sendingREF = true;
    }
}

bool CommandQueueTP::normalPopClosePage(BusPacket **busPacket, bool 
        &sendingREF)
{
    bool foundIssuable = false;
    unsigned startingRank = nextRank;
    unsigned startingBank = nextBank;

    if(pid_last_pop!= getCurrentPID()){
        last_pid = pid_last_pop;
    }
    pid_last_pop = getCurrentPID();

    while(true)
    {
        //Only get the queue for the PID with the current turn.
        vector<BusPacket *> &queue = getCommandQueue(nextRank, getCurrentPID());
        vector<BusPacket *> &queue_last = getCommandQueue(nextRank, last_pid);

        if (false && !((nextRank == refreshRank) && refreshWaiting) &&
                !queue_last.empty())
        {
            //search from beginning to find first issuable bus packet
            for (size_t i=0; i<queue_last.size(); i++)
            {

                if (isIssuable(queue_last[i]))
                {
                    if(queue_last[i]->busPacketType==ACTIVATE){
                        continue;
                    }
                   
                    // Make sure a read/write that hasn't been activated yet 
                    // isn't removed. 
                    if (i>0 && queue_last[i-1]->busPacketType==ACTIVATE &&
                            queue_last[i-1]->physicalAddress == 
                            queue_last[i]->physicalAddress){
                        continue;
                    }

                    *busPacket = queue_last[i];

                    queue_last.erase(queue_last.begin()+i);
                    foundIssuable = true;
                    break;
                }
            }
        }
        
        if(!(false && foundIssuable)){
            if (!queue.empty() && !((nextRank == refreshRank) && refreshWaiting))
            {

                //search from beginning to find first issuable bus packet
                for (size_t i=0;i<queue.size();i++)
                {

                    if (isIssuable(queue[i]))
                    {
                        if(queue[i]->busPacketType==ACTIVATE){
                            // Search Queue for matching packet. If not found,
                            // the type given is activate which will use a 
                            // conservative dead time
                            BusPacketType type =  ACTIVATE;
                            for(int j=0; j<queue.size(); j++){
                                if(queue[j]->physicalAddress == queue[i]->physicalAddress &&
                                        queue[j]->busPacketType!= ACTIVATE){
                                    type = queue[j]->busPacketType;
                                    break;
                                }
                            }
                            if(isBufferTime(type)) continue;
                        }

                        //check to make sure we aren't removing a read/write that 
                        //is paired with an activate
                        if (i>0 && queue[i-1]->busPacketType==ACTIVATE &&
                                queue[i-1]->physicalAddress == 
                                queue[i]->physicalAddress){
                            continue;
                        }

                        *busPacket = queue[i];

                        queue.erase(queue.begin()+i);
                        foundIssuable = true;
                        break;
                    }
                }
            }
        }

        //if we found something, break out of do-while
        if (foundIssuable) break;

        nextRankAndBank(nextRank, nextBank);
        if (startingRank == nextRank && startingBank == nextBank)
        {
            break;
        }
    }

    return foundIssuable;
}

void CommandQueueTP::print()
{
    PRINT("\n== Printing Timing Partitioning Command Queue" );

    for (size_t i=0;i<NUM_RANKS;i++)
    {
        PRINT(" = Rank " << i );
        for (int j=0;j<num_pids;j++)
        {
            PRINT("    PID "<< j << "   size : " << queues[i][j].size() );

            for (size_t k=0;k<queues[i][j].size();k++)
            {
                PRINTN("       " << k << "]");
                queues[i][j][k]->print();
            }
        }
    }
}

unsigned CommandQueueTP::getCurrentPID(){
  unsigned ccc_ = currentClockCycle - offset;
  int schedule_length = 0;
  for(int i=0; i < num_pids; i++) schedule_length += tl[i];
  unsigned schedule_time = ccc_ % schedule_length;

  int test_time = 0;
  for(int i=0; i < num_pids; i++){
      test_time += tl[i];
      if(schedule_time < test_time) return i;
  }
  assert(false);
  return 0;
}

bool CommandQueueTP::isBufferTime(BusPacketType type){
  unsigned ccc_ = currentClockCycle - offset;
  unsigned current_tc = getCurrentPID();
  unsigned schedule_length = 0;
  for(int i=0; i < num_pids; i++) schedule_length += tl[i];
  unsigned schedule_start = ccc_ - ( ccc_ % schedule_length );

  unsigned turn_start = schedule_start;
  for(int i=0; i<current_tc; i++) turn_start += tl[i];
  unsigned turn_end = turn_start + tl[current_tc];

  // Time between refreshes to ANY rank.
  unsigned refresh_period = REFRESH_PERIOD/NUM_RANKS/tCK;
  unsigned next_refresh = ccc_ + refresh_period - (ccc_ % refresh_period);
 
  unsigned tlength = tl[current_tc];

  unsigned deadtime = (turn_start <= next_refresh && next_refresh < turn_end) ?
    refresh_deadtime( tlength ) :
    normal_deadtime( tlength, type );

#ifdef DEBUG_TP
  printf("-------------------------------------------------------\n");
  printf("clock cycle: %lu\n", currentClockCycle);
  printf("current tc:  %i\n", current_tc);
  printf("turn start:  %u\n", turn_start);
  printf("turn end:    %u\n", turn_end);
  printf("deadtime:    %u\n", deadtime);
  if( ccc_ >= (turn_end - deadtime)) printf("its deadtime\n");
  printf("-------------------------------------------------------\n\n\n");
#endif // DEBUG_TP

  return ccc_ >= (turn_end - deadtime);
}

#ifdef DEBUG_TP
bool CommandQueueTP::hasInteresting(){
    vector<BusPacket *> &queue = getCommandQueue(nextRank, 1);
    for(size_t i=0; i<queue.size(); i++){
        if (queue[i]->physicalAddress == interesting)
            return true;
    }
    return false;
}
#endif /*DEBUG_TP*/

