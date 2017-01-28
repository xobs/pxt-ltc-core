/*
The MIT License (MIT)

Copyright (c) 2016 British Broadcasting Corporation.
This software is provided by Lancaster University by arrangement with the BBC.

Modifications Copyright (c) 2016 Calliope GbR
Modifications are provided by DELTA Systems (Georg Sommer) - Thomas Kern
und Björn Eberhardt GbR by arrangement with Calliope GbR. 

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

#include <stdint.h>
#include "app.h"
#include "pxt.h"

/* Variables provided by the linker */
extern uint32_t _textdata;
extern uint32_t _data;
extern uint32_t _edata;
extern uint32_t _bss_start;
extern uint32_t _bss_end;
extern uint32_t __init_array_start;
extern uint32_t __init_array_end;
extern uint32_t __heap_base__;
extern uint32_t __heap_end__;

uint16_t *bytecode;
uint32_t *globals;
const char *panic_msg = "";
int error_code = 0;
int error_subcode = 0;

void *malloc(size_t size);
void *memset(void *s, int c, size_t n);

static uint32_t *allocate(uint16_t sz) {
  uint32_t *arr;
  
  arr = malloc(sz * sizeof(*arr));
  memset(arr, 0, sz * sizeof(*arr));

  return arr;
}

static int templateHash(void)
{
  return ((int*)bytecode)[4];
}

static int getNumGlobals(void) {
  return bytecode[16];
}

__attribute__((noreturn))
void panic(const char *str) {
  panic_msg = str;
  setSerialSpeed(9600);
  while (1)
    printf("PANIC: %s\r\n", str);
}

__attribute__((noreturn))
void error(ERROR code, int subcode) {
  error_code = code;
  error_subcode = subcode;
  setSerialSpeed(9600);
  while(1)
    printf("ERROR %d: %d\r\n", code, subcode);
}

static void assert(int cond, const char *msg) {
  if (!cond)
    panic(msg);
}

static void exec_binary(int32_t *pc) {

  // XXX re-enable once the calibration code is fixed and [editor/embedded.ts]
  // properly prepends a call to [internal_main].
  // ::touch_develop::internal_main();

  // unique group for radio based on source hash
  // ::touch_develop::micro_bit::radioDefaultGroup = programHash();
    
  // repeat error 4 times and restart as needed
  // microbit_panic_timeout(4);
    
  int32_t ver = *pc++;
  assert(ver == 0x4209, ":( Bad runtime version");

  bytecode = *((uint16_t**)pc++);  // the actual bytecode is here
  globals = allocate(getNumGlobals());

  // just compare the first word
  assert(((uint32_t*)bytecode)[0] == 0x923B8E70 &&
           templateHash() == *pc,
           ":( Failed partial flash");

  uint32_t startptr = (uint32_t)bytecode;
  startptr += 48; // header
  startptr |= 1; // Thumb state

  ((uint32_t (*)())startptr)();

  return;
}

void Esplanade_Main(void) {
  exec_binary((int32_t*)functionsAndBytecode);
}

__attribute__ ((used, section(".progheader")))
struct app_header app_header = {
  .data_load_start  = &_textdata,
  .data_start       = &_data,
  .data_end         = &_edata,
  .bss_start        = &_bss_start,
  .bss_end          = &_bss_end,
  .entry            = Esplanade_Main,
  .magic            = APP_MAGIC,
  .version          = APP_VERSION,
  .const_start      = &__init_array_start,
  .const_end        = &__init_array_end,
  .heap_start       = &__heap_base__,
  .heap_end         = &__heap_end__,
};

// vim: ts=2 sw=2 expandtab
