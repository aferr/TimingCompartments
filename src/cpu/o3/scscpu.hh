#include "cpu/o3/deriv.hh"
#include "params/DerivO3CPU.hh"
class SCSCPU : public DerivO3CPU
{
  public:
  SCSCPU(DerivO3CPUParams *p)
    : DerivO3CPU(p)
    {
    }

  protected:
  virtual void fakeContextSwitch(){
  }
};
