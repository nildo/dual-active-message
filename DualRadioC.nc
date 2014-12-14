module DualRadioC {
  uses {
    interface Receive as Receive1;
    interface Receive as Receive2;
    interface AMSend as AMSend1;
    interface AMSend as AMSend2;
    interface SplitControl as SplitControl1;
    interface SplitControl as SplitControl2;
    interface Packet as Packet1;
    interface Packet as Packet2;
    interface AMPacket as AMPacket1;
    interface AMPacket as AMPacket2;
  }
  provides {
    interface AMSend;
    interface Receive;
    interface SplitControl;
  }
}

implementation {
  bool radio1_on = FALSE;
  bool radio2_on = FALSE;
  bool radio1_locked = FALSE;
  bool radio2_locked = FALSE;
  message_t *msg1;
  message_t *msg2;
  uint8_t last_radio = 1;

  event message_t* Receive1.receive(message_t* bufPtr, void* payload, uint8_t len) {
    last_radio = 1;
    signal Receive.receive(bufPtr, payload, len);
    return bufPtr;
  }

  event message_t* Receive2.receive(message_t* bufPtr, void* payload, uint8_t len) {
    last_radio = 2;
    signal Receive.receive(bufPtr, payload, len);
    return bufPtr;
  }

  event void AMSend1.sendDone(message_t* bufPtr, error_t error) {
    if (msg1 == bufPtr) {
      radio1_locked = FALSE;
      signal AMSend.sendDone(bufPtr, error);
    }
  }

  event void AMSend2.sendDone(message_t* bufPtr, error_t error) {
    if (msg2 == bufPtr) {
      radio2_locked = FALSE;
      signal AMSend.sendDone(bufPtr, error);
    }
  }

  event void SplitControl1.startDone(error_t err) {
    if (err == SUCCESS) {
      radio1_on = TRUE;
    } else {
      signal SplitControl.startDone(err);
    }
    if (radio1_on && radio2_on) {
      signal SplitControl.startDone(err);
    }
  }

  event void SplitControl2.startDone(error_t err) {
    if (err == SUCCESS) {
      radio2_on = TRUE;
    } else {
      signal SplitControl.startDone(err);
    }
    if (radio1_on && radio2_on) {
      signal SplitControl.startDone(err);
    }
  }

  /**
   * FIXME: There's probably a bug in here when both give an error. 
   */
  event void SplitControl1.stopDone(error_t err) {
    if (err == SUCCESS) {
      radio1_on = FALSE;
    } else {
      signal SplitControl.stopDone(err);
    }
    if (!(radio1_on || radio2_on)) {
      signal SplitControl.stopDone(err);
    }
  }

  event void SplitControl2.stopDone(error_t err) {
    if (err == SUCCESS) {
      radio1_on = FALSE;
    } else {
      signal SplitControl.stopDone(err);
    }
    if (!(radio1_on || radio2_on)) {
      signal SplitControl.stopDone(err);
    }
  }

  /**
   * SplitControl
   * To signal: 
   *     event void startDone(error_t error);
   *     event void stopDone(error_t error);
   */
  command error_t SplitControl.start() {
    error_t r1 = call SplitControl1.start();
    error_t r2 = call SplitControl2.start();
    if (r1 == SUCCESS && r2 == SUCCESS)
      return SUCCESS;
    else
      return FAIL;
  }

  command error_t SplitControl.stop() {
    error_t r1 = call SplitControl1.stop();
    error_t r2 = call SplitControl2.stop();
    if (r1 == SUCCESS && r2 == SUCCESS)
      return SUCCESS;
    else
      return FAIL;
  }

  /**
   * AMSend
   * To signal: 
   *     event void sendDone(message_t* msg, error_t error);
   */

  command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    error_t ret_value = FAIL;
    if (last_radio == 2) {
      if (!radio1_locked) {
        radio1_locked = TRUE;
        msg1 = msg;
        ret_value = call AMSend1.send(addr, msg, len);
        last_radio = 1;
      } else if (!radio2_locked) {
        radio2_locked = TRUE;
        msg2 = msg;
        ret_value = call AMSend2.send(addr, msg, len);
        last_radio = 2;
      }
    } else {
      if (!radio2_locked) {
        radio2_locked = TRUE;
        msg2 = msg;
        ret_value = call AMSend2.send(addr, msg, len);
        last_radio = 2;
      } else if (!radio1_locked) {
        radio1_locked = TRUE;
        msg1 = msg;
        ret_value = call AMSend1.send(addr, msg, len);
        last_radio = 1;
      }
    }
    return ret_value;
  }

  command error_t AMSend.cancel(message_t* msg) {
    // TODO: implement this. For now, impossible to cancel.
    return FAIL;
  }

  command uint8_t AMSend.maxPayloadLength() {
    // TODO: verify if both radios have the same max payload length.
    return call AMSend1.maxPayloadLength();
  }

  command void* AMSend.getPayload(message_t* msg, uint8_t len) {
    // TODO: verify if it will work for both radios.
    return call AMSend1.getPayload(msg, len);
  }

}
