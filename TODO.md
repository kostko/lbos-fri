What needs to be done (or undone). **This is** the latest, **most accurate TODO list**.

Please note, if there were previous assignments you were supposed to fulfil, it might now not be so. Please checkout trunk to see what is and what is not yet. If you find yourself having nothing to do, grab [reference material](http://code.google.com/p/lbos-fri/source/browse/trunk/README.txt?r=90#116), and write a driver for some pheripheral or something (eth would be nice =p). You may also help out with other groups, but please resort to commiting to /branches/yourGroupName exclusively! When you have a segment of tested working code open a review request in the issue tracker to merge it into trunk.



# Group 8 / 2.1 #
  * Document task stack usage (USP), should be mapped into task virtual space - ?
  * Document task heap usage via the `brk` system call - ?
  * [Implement task terminal I/O](TerminalIOPlan.md) - **perice**, **kernc**
  * Write documentation on how MMC and MCI work - **kostko**
  * System task capability registration mechanism - ?
  * [Implement dynamic task creation, PIDs and the fork function](DynamicTasksPlan.md) - **zomb**
  * Implement ELF binary loader - ?
  * [Implement VM-mapped kernel heap](KernelHeapAndKmallocPlan.md) - **kostko**
  * [Research EMAC interface (based on ATMEL's)](EMAC.md) - **zomb**

  * ~~svc\_newtask, svc\_delay, svc\_send, svc\_recv, svc\_reply, svc\_led - **kostko**~~
  * ~~Improve the debugger to output registers (reg0-reg12 and SPSR/CPSR) - **kernc**~~
  * ~~Improve printk routine so it uses DMA - **kernc**~~
  * ~~Implement _vsprintf_-like function - **kernc**~~
  * ~~Implement _panic_ function (disable irq + printk + infinite loop) - **kostko**~~
  * ~~Add T\_PRIO to TCB struct (4 bytes) - **kostko**~~
  * ~~MMC driver and API for data transfer - svc\_mmc\_read, svc\_mmc\_write - **kostko**~~
  * ~~Implement basic string functions - **kostko**~~
  * ~~Implement contigous page allocation (currently in 32K blocks which is good enough for now - only needed for MMU translation tables) - **kostko**~~
  * ~~Make task system stack and user stack dynamically allocatable - **kostko**~~
  * ~~[Implement virtual memory](VirtualMemoryPlan.md) - **zomb**~~

# Group 6 / 2.2 #
  * ~~[Weighted Round-Robin](http://en.wikipedia.org/wiki/Weighted_round_robin)- **Hari**~~
  * ~~priority scheduler - **Hari**~~
  * ~~Bubble sort -for priority scheduler - **Hari**~~
  * ~~Debugging - **everyone**~~
  * ~~User programs - **Barbara, Anita, Romana**~~
  * ~~Testing with user programs - **Romana**~~
  * Documentation - Barbara, ?

# Group 2 / 2.5 #
  * ~~svc\_signal and svc\_wait for dynamic lock objects aquisitions~~
  * ~~User programs~~
  * Documentation


# Group 3 / 2.4 #
> Members: Gašper Rupnik, Anže Pečar, Tomaž Sečnik, Erik Hribar

  * Add 'print to terminal' for our tasks when communication with the serial port (Group ?) will be done.

  * ~~Test our code (24h)~~
  * ~~To translate some comments~~
  * ~~Implement some test tasks~~
  * ~~Implement timer and set/clear timer flags~~
  * ~~To comply with CODING\_STANDARD~~
  * ~~Added 'Critical-Section Graph' into [plan](planOfDelay.md)~~
  * ~~ENABLE\_IRQ/DISABLE\_IRQ (macros) to irq\_disable/irq\_restore (functions)~~
  * ~~Add ENABLE\_IRQ/DISABLE\_IRQ (macros)~~
  * ~~Implement protection for overflow of DELAY LIST~~
  * ~~Implement 'Deleting requirements for delay' from plan~~
  * ~~Implement 'Adding requirements for delay' from plan~~
  * ~~Implement 'Requirements' from plan~~
  * ~~[Plan for SVC\_DELAY](planOfDelay.md)~~

# Group 7 / 2.6 #
> Members: Nejc Potrebuješ, Andrej Šušmelj, Gorazd Štamcar, Klemen Rade
  * ~~svc\_getchar, svc\_putchar for communication with the serial port~~
  * ~~monitor process~~
  * ~~commit to branch~~
  * commit to trunk

# Group 5 / 2.7 #
> Members: Jernej Erker, Matjaž Verbole, Peter Hrvatin, Rok Kek
  * ~~directory structure~~
  * ~~svc\_mkdir, svc\_rmdir, svc\_chdir, svc\_dirup~~
  * testing with user programs

# Group ? / 2.8 #
  * [FAT-ng filesystem](FileSystemPlan.md) - ?
  * svc\_fread, svc\_fwrite, svc\_fappend, (svc\_fopen) - ?
  * ...

# Group 1 / 2.3 #
> Members: Luka Kacil, Štefan Šimec, Grega Kešpret, Nino Ostrc
  * ~~svc\_send, svc\_receive, svc\_reply~~
  * ~~testing with 2 user processes~~
  * ~~testing with 4 user processes~~
  * ~~modification to support virtual memory~~
  * ~~testing with 2 user processes~~
  * testing with 4 user processes => waitin 4 whoever s got the damn terminal...