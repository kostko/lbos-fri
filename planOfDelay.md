# Requirements #

**DELAY LIST** (list of all processes that make the system call SVC\_DELAY sorted by time)

```
DLYLIST:  .space    80
```

| **P#1** | **P#2** | **P#3** | **P#4** | **P#5** | **P#6** | **P#7** | **P#8** | **P#9** | **P#10** |
|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:--------|:---------|
|D\_TCB|...|  |  |  |  |  |  |  |  |
|D\_TOUT|...|  |  |  |  |  |  |  |  |


**DLYLIST** ... pointer to DELAY LIST

**CDLYTCB** ... pointer to TCB of current process 'in timer'


Structure of DELAY LIST:
  * **D\_TCB** ... pointer to TCB of process
  * **D\_TOUT** ... timeout/delay for process

```
.equ  D_TCB,    0
.equ  D_TOUT,   D_TCB+4
```

Error code for overflow of DELAY LIST

```
.equ E_OVRFLV, -5
```

EOC

# Parameters #
  * **[r0](https://code.google.com/p/lbos-fri/source/detail?r=0)** Number of jiffies to delay execution for
  * **[r1](https://code.google.com/p/lbos-fri/source/detail?r=1)** Pointer to TCB

EOC

# Adding requirements for delay #

```
i = 1
n = lastFullPosition
if (DELAY LIST is not empty)
  /* Find right position */
  while ((D_TCB[i] is full) & (r0 > D_TOUT[i]))
    /* Subtract delay to the value of the current in DELAY LIST */
    r0 = r0 - D_TOUT[i]
    inc(i)
  loop
  /* We are in the right position */
  for (j=n+1;j>i;j--)
    D_TCB[j] = D_TCB[j-1]
    if ((j-1) = i)
      D_TOUT[j] = D_TOUT[j-1] - r0
    else  
      D_TOUT[j] = D_TOUT[j-1]
    end if
  next
end if
D_TCB[i] <- r1
D_TOUT[i] <- r0
```

_Example:_

First task that we want to insert:
  * D\_TCB = 0x30
  * D\_TOUT = 100 <- Number of jiffies

| **P#1** |
|:--------|
| **0x30** |
| **100** |

Second task that we want to insert:
  * D\_TCB = 0x40
  * D\_TOUT = 122 <- Number of jiffies

|P#1| **P#2** |
|:--|:--------|
|0x30| **0x40** |
|100| **22** |

Third task that we want to insert:
  * D\_TCB = 0x50
  * D\_TOUT = 60 <- Number of jiffies

| **P#3** |P#1|P#2|
|:--------|:--|:--|
| **0x50** |0x30|0x40|
| **60** |40|22|

EOC

# Deleting requirements for delay #

You always remove only first element of DELAY LIST / process with minimum D\_TOUT!

_Example:_

In DELAY LIST we have:

| **P#3** |P#1|P#2|
|:--------|:--|:--|
| **0x50** |0x30|0x40|
| **60** |40|22|

When timer count D\_TOUT of first block in DELAY LIST (in out example 60 jiffies) we remove first element and then we have:

| **P#1** |P#2|
|:--------|:--|
| **0x30** |0x40|
| **40** |22|


So, in those 60 jiffies timer count full delay of P#3, partial delay of P#1 and P#2 (60 jiffies). The residue shows the new table (40 jiffies for P#1 and 22 jiffies for P#2).

**Thus we have achieved more counting delays by one timer.**

EOC

# Critical-Section Graph #


The picture says it all.

![http://www.shrani.si/f/1V/ks/njwIY65/ko.jpg](http://www.shrani.si/f/1V/ks/njwIY65/ko.jpg)

EOC