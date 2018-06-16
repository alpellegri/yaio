#include <Arduino.h>
#include <SPI.h>

#include "cc1101.h"

#define DEBUG_PRINT(fmt, ...) Serial.printf_P(PSTR(fmt), ##__VA_ARGS__)

#define SPI_WAIT()                                                             \
  do {                                                                         \
    delayMicroseconds(100);                                                    \
  } while (0);
#define SPI_TXRX(x) SPI.transfer(x);

typedef void (*funcPointer)(void);

funcPointer SPI_BEGIN;
funcPointer SPI_END;
uint8_t SpiPinCs;

void spi_begin_softCs(void) { digitalWrite(SpiPinCs, LOW); }
void spi_end_softCs(void) { digitalWrite(SpiPinCs, HIGH); }
void spi_begin_hardCs(void) {}
void spi_end_hardCs(void) {}

/******************************************************************************
 * @fn          function name
 *
 * @brief       Description of the function
 *
 * @param       input, output parameters
 *
 * @return      describe return value, if any
 */
void SPI_INIT(bool mode, uint8_t pin) {
  if (mode == true) {
    SpiPinCs = pin;
    pinMode(SpiPinCs, OUTPUT);
    digitalWrite(SpiPinCs, HIGH);
    SPI_BEGIN = spi_begin_softCs;
    SPI_END = spi_end_softCs;
  } else {
    SPI.setHwCs(true);
    SPI_BEGIN = spi_begin_hardCs;
    SPI_END = spi_end_hardCs;
  }
  SPI.begin();
  SPI.setFrequency(1000000);
  SPI.setBitOrder(MSBFIRST);
  SPI.setDataMode(SPI_MODE0);
}

//------------------------------------------------------------------------------
//  void readBurstReg(uint8_t addr, uint8_t *buffer, uint8_t count)
//
//  DESCRIPTION:
//      This function reads multiple CCxxx0 register, using SPI burst access.
//
//  ARGUMENTS:
//      uint8_t addr
//          Address of the first CCxxx0 register to be accessed.
//      uint8_t *buffer
//          Pointer to a byte array which stores the values read from a
//          corresponding range of CCxxx0 registers.
//      uint8_t count
//          Number of bytes to be written to the subsequent CCxxx0 registers.
//------------------------------------------------------------------------------
void spiReadBurstReg(uint8_t addr, uint8_t *buffer, uint8_t count) {
  uint8_t i;
  SPI_BEGIN();
  SPI_TXRX(addr | READ_BURST);
  SPI_WAIT();
  for (i = 0; i < count; i++) {
    SPI_WAIT();
    buffer[i] = SPI_TXRX(0);
  }
  SPI_END();
} // halSpiReadBurstReg

//------------------------------------------------------------------------------
//  uint8_t readReg(uint8_t addr)
//
//  DESCRIPTION:
//      This function gets the value of a single specified CCxxx0 register.
//
//  ARGUMENTS:
//      uint8_t addr
//          Address of the CCxxx0 register to be accessed.
//
//  RETURN VALUE:
//      uint8_t
//          Value of the accessed CCxxx0 register.
//------------------------------------------------------------------------------
uint8_t spiReadReg(uint8_t addr) {
  uint8_t x;
  SPI_BEGIN();
  SPI_TXRX(addr | READ_SINGLE);
  SPI_WAIT();
  x = SPI_TXRX(0);
  SPI_END();
  return x;
} // halSpiReadReg

//------------------------------------------------------------------------------
//  uint8_t readStatus(uint8_t addr)
//
//  DESCRIPTION:
//      This function reads a CCxxx0 status register.
//
//  ARGUMENTS:
//      uint8_t addr
//          Address of the CCxxx0 status register to be accessed.
//
//  RETURN VALUE:
//      uint8_t
//          Value of the accessed CCxxx0 status register.
//------------------------------------------------------------------------------
uint8_t spiReadStatus(uint8_t addr) {
  uint8_t x;
  SPI_BEGIN();
  SPI_TXRX(addr | READ_BURST);
  SPI_WAIT();
  x = SPI_TXRX(0);
  SPI_END();
  return x;
} // halSpiReadStatus

//------------------------------------------------------------------------------
//  void strobe(uint8_t strobe)
//
//  DESCRIPTION:
//      Function for writing a strobe command to the CCxxx0
//
//  ARGUMENTS:
//      uint8_t strobe
//          Strobe command
//------------------------------------------------------------------------------
uint8_t spiStrobe(uint8_t strobe) {
  uint8_t x;
  SPI_BEGIN();
  x = SPI_TXRX(strobe);
  SPI_WAIT();
  SPI_END();
  return x;
} // halSpiStrobe

//------------------------------------------------------------------------------
//  void writeReg(uint8_t addr, uint8_t value)
//
//  DESCRIPTION:
//      Function for writing to a single CCxxx0 register
//
//  ARGUMENTS:
//      uint8_t addr
//          Address of a specific CCxxx0 register to accessed.
//      uint8_t value
//          Value to be written to the specified CCxxx0 register.
//------------------------------------------------------------------------------
void spiWriteReg(uint8_t addr, uint8_t value) {
  SPI_BEGIN();
  SPI_TXRX(addr);
  SPI_WAIT();
  SPI_TXRX(value);
  SPI_WAIT();
  SPI_END();
} // halSpiWriteReg

//------------------------------------------------------------------------------
//  void writeBurstReg(uint8_t addr, uint8_t *buffer, uint8_t count)
//
//  DESCRIPTION:
//      This function writes to multiple CCxxx0 register, using SPI burst
//      access.
//
//  ARGUMENTS:
//      uint8_t addr
//          Address of the first CCxxx0 register to be accessed.
//      uint8_t *buffer
//          Array of bytes to be written into a corresponding range of
//          CCxx00 registers, starting by the address specified in _addr_.
//      uint8_t count
//          Number of bytes to be written to the subsequent CCxxx0 registers.
//------------------------------------------------------------------------------
void spiWriteBurstReg(uint8_t addr, uint8_t *buffer, uint8_t count) {
  uint8_t i;
  SPI_BEGIN();
  SPI_TXRX(addr | WRITE_BURST);
  SPI_WAIT();
  for (i = 0; i < count; i++) {
    SPI_TXRX(buffer[i]);
    SPI_WAIT();
  }
  SPI_END();
} // halSpiWriteBurstReg

//------------------------------------------------------------------------------
//  uint8_t getStatus(void)
//
//  DESCRIPTION:
//  This function transmits a No Operation Strobe (SNOP) to get the status of
//  the radio.
// Status byte:
// ---------------------------------------------------------------------------
//  |          |            |                                                 |
//  | CHIP_RDY | STATE[2:0] | FIFO_uint8_tS_AVAIL (free bytes in the TX FIFO  |
//  |          |            |                                                 |
//  ---------------------------------------------------------------------------
// STATE[2:0]:
// Value | State
//  --------------------------
//  000   | Idle
//  001   | RX
//  010   | TX
//  011   | FSTXON
//  100   | CALIBRATE
//  101   | SETTLING
//  110   | RXFIFO_OVERFLOW
//  111   | TX_FIFO_UNDERFLOW
//------------------------------------------------------------------------------
uint8_t spiGetStatus(void) {
  uint8_t x;
  SPI_BEGIN();
  x = SPI_TXRX(CC1101_SNOP | READ_BURST);
  SPI_WAIT();
  SPI_END();
  return x;
} // spiGetTxStatus

/**
 * CC1101
 *
 * Class constructor
 */
CC1101::CC1101(void) {}

/**
 * CC1101
 *
 * Class constructor
 */
void CC1101::enableTransmit(uint8_t pin) { rcSwitch.enableTransmit(pin); }

void CC1101::enableReceive(uint8_t pin) {
  rcSwitch.setPolarity(true);
  rcSwitch.enableReceive(pin);
  strobe(CC1101_SIDLE);
  strobe(CC1101_SRX);
}

void CC1101::setSoftCS(uint8_t pin) {
  useSoftCS = true;
  pinSoftCS = pin;
}

/**
 * init
 *
 * Initialize CC1101 radio
 *
 * @param freq Carrier frequency
 */
void CC1101::begin(void) {
  DEBUG_PRINT("CC1101::begin\n");

  uint8_t writeByte;
#ifdef PA_TABLE
  uint8_t paTable[] = PA_TABLE;
#endif

  SPI_INIT(useSoftCS, pinSoftCS); // Initialize SPI interface

  // reset radio
  spiStrobe(CC1101_SRES);
  // write registers to radio
  for (uint16_t i = 0; i < preferredSettings_size; i++) {
    writeByte = preferredSettings[i].data;
    // halSpiWriteBurstReg(preferredSettings[i].addr, &writeByte, 1);
    spiWriteReg(preferredSettings[i].addr, writeByte);
  }
#ifdef PA_TABLE
  // write PA_TABLE
  writeBurstReg(CC1101_PATABLE, paTable, sizeof(paTable));
#endif
}

uint8_t CC1101::readStatus(uint8_t reg) { return spiReadStatus(reg); }
uint8_t CC1101::readReg(uint8_t reg) { return spiReadReg(reg); }
uint8_t CC1101::strobe(uint8_t value) { return spiStrobe(value); }
uint8_t CC1101::getStatus(void) { return spiGetStatus(); }

void CC1101::send(uint32_t code, uint16_t length) {
  strobe(CC1101_SIDLE);
  strobe(CC1101_STX);
  rcSwitch.send(code, length);
  // strobe(CC1101_SIDLE);
  strobe(CC1101_SRX);
}
