#include "Timer.h"
#include "DualActiveMessage.h"

configuration DualActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend;
    interface Receive;
    interface Receive as Snoop[am_id_t id];
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
    //interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    //interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface LowPowerListening;
  }
}
implementation {
  components DualRadioC;
  components RF231ActiveMessageC as ActiveMessageC1;
  components RF212ActiveMessageC as ActiveMessageC2;

  DualRadioC.Receive1 -> ActiveMessageC1.Receive[AM_DUAL_RADIO_MSG];
  DualRadioC.AMSend1 -> ActiveMessageC1.AMSend[AM_DUAL_RADIO_MSG];
  DualRadioC.Receive2 -> ActiveMessageC2.Receive[AM_DUAL_RADIO_MSG];
  DualRadioC.AMSend2 -> ActiveMessageC2.AMSend[AM_DUAL_RADIO_MSG];
  DualRadioC.SplitControl1 -> ActiveMessageC1;
  DualRadioC.SplitControl2 -> ActiveMessageC2;
  DualRadioC.Packet1 -> ActiveMessageC1;
  DualRadioC.Packet2 -> ActiveMessageC2;
  DualRadioC.AMPacket1 -> ActiveMessageC1;
  DualRadioC.AMPacket2 -> ActiveMessageC2;

  SplitControl = DualRadioC;
  AMSend = DualRadioC.AMSend;
  Receive = DualRadioC.Receive;
  Snoop = ActiveMessageC1.Snoop;
  Packet = ActiveMessageC1;
  AMPacket = ActiveMessageC1;
  PacketAcknowledgements = ActiveMessageC1;
  LowPowerListening = ActiveMessageC1;

  //PacketTimeStamp32khz = ActiveMessageC1;
  //PacketTimeStampMilli = ActiveMessageC1;
}
