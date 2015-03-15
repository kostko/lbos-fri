# Requirements #

The system we implement has the following requirements:
  * It must export an API for task creation (accessed via `svc_fork`) and task deletion (accessed via `svc_exit`).
  * Each task gets its own _Process ID_ in the TCB (T\_PID). There should be an efficient method for determining the next free PID.
  * Each task also needs _Main segment size_ (T\_MAIN\_SEGMENT) which specifies the current amount of memory allocated to this task's main segment (code, data and heap). Task's main segment starts at `0x30000000` and ends at `0x30000000 + T_MAIN_SEGMENT` in virtual memory. Other possibilities include per-task defined _regions_ (code, data, stack and heap). Segment size is always a multiple of page size.
  * Task control blocks are dynamically allocated and consist of a single 4K page. First couple of bytes are used for the TCB and everything else is used as a system stack (stack starts at end of page).
  * Task size should no longer be static and set to 256K. We need a system (possibly a linked list or a tree) to store all task's allocated pages (note that we can allocate physically discontiguous pages and map them to task's virtual memory space). Task can request more memory using the `brk` system call which should map pages to end of task's virtual memory segment.
  * `fork` should currently copy everything from the current task space (CPU context and all allocated virtual memory) one page at a time. Later _copy-on-write_ should be implemented (since page fault ocurrs as soon as translation desriptor bits 0:1 are 0, we can use others to set physical address for faster source page lookup; also we need some bits to specify that this fault is due to COW).

# Task loading #

Since we now have dynamic task creation, we need an init task (but have no filesystem or ELF loader at the moment), so two methods of loading a task should be planned for:
  * Load task from existing RAM area (this is for existing "static" tasks) - should be used for the `init` (PID=0) task. We are given pointers to task's _text_ and _data_ sections and their lengths, then we map those to virtual memory (note that segments need to be page aligned - linker script change will be needed) directly and mark that space as used. Note that even "static" tasks no longer need to be 256K in size.
  * Load an ELF binary (after the loader is implemented).

# Fork implementation #

This should all be placed into `fork.s`.

```
/**
 * Returns the next free PID that we can assign to a newly
 * created process.
 *
 * @return Next available PID
 */
get_free_pid:
  /* Search list to get free PID */

/**
 * Actually executes a process fork.
 *
 * @param r0 Pointer to current task's context on stack
 * @return New task's PID
 */
do_fork:
  /* Allocate new TCB */
  /* Get free PID and use it */
  /* Copy CPU context (to new system stack), set parent PID, set task dispatchable */
  /* Copy all memory allocated by current task */
  /* LAST AND ATOMIC: Insert into list of processes */
```

**Proposed PID allocator in pseudo-code:
```
DISABLE_IRQ

INC(LAST_PID) % MAX_PID

for each TASK
  if TASK.PID == LAST_PID
    INC(LAST_PID) % MAX_PID
  endif
endfor

pid = LAST_PID

ENABLE_IRQ
```**

# Brk implementation #
TBD