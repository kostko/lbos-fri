# Terminal I/O server #

Proposed concept:
  * A system task serves as terminal I/O server accepting requests via message passing and pushing them to serial console driver.

# I/O request descriptors #

Descriptors should contain the following information:
  * **RequestType** - type of IO request (read, write, ...)
  * **BufferPtr** - buffer pointer
  * **BufferLen** - length of buffer

Note that buffers have to be properly copied to and from application virtual memory space.

# Serial console driver #

Both current `printk` implementation and the new terminal I/O server should use this driver and not do stuff directly. After the driver is written `printk` should be ported to use it. This driver should be simple to write as we can simply reuse code from existing `printk` function (we just need the receive part) and package it into its own `serial.s` with exported functions like `serial_write` and `serial_read`. The driver should be interrupt driven and not do polling! All driver code should be located in a single `serial.s` file (together with interrupt handlers).

# System calls #

No message passing, no server task. svc\_print, svc\_read and their likes forward requests directly to driver.