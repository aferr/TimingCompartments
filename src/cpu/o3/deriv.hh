
#include <string>

#include "cpu/o3/cpu.hh"
#include "cpu/o3/impl.hh"
#include "params/DerivO3CPU.hh"
class DerivO3CPU : public FullO3CPU<O3CPUImpl>
{
  public:
    DerivO3CPUParams *params;
    DerivO3CPU(DerivO3CPUParams *p)
        : FullO3CPU<O3CPUImpl>(p)
    {
      params = p;
    }
};
