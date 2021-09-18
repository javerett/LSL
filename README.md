# About

This is a collection of older scripts in a C like language called LSL.

This language's compiler has almost no optimizations, so even constant folding must be done by hand. This unfortunately
includes a lack of inlining of any kind, which meant that for performance most functions needed to be "large"
The resulting bytecode from the compiler plus the run time data must be less than 64kB, meaning that memory as well as
execution time are very limited resources.

This language has a small standard library which does not include any cryptographic protocols, and there are no existing
implementations for most cryptographic standards due to the difficulty of implementing computationally intensive tasks
into the limited memory and time budgets available to scripts in this VM.

Finally, the language only has a fixed set of built in types. It has 32 bit integers and floats, strings(also called keys), 3 and 4 component
vectors, and heterogenous lists. Due to this limitation, all structured types must be implemented as strided lists, where each
entry in the list corresponds to an entry in the struct that would normally be used in languages supporting such features.

# Curve25519.lsl

Included is an implementation of Curve25519 using an internally simulated register machine running a fixed program.
This program had to be written using a lot of macros to define the operations of the simulated register machine.
The core of the system is a small call macro, which pushes the call stack with an integer representing the return location.
Due to limitations of the language, there is no way to push the instruction pointer directly, however using labels and macros
I simulate this behavior. This was all unfortunately necessary to get the program to meet the limited space and time budgets.

# ChaCha20.lsl

Additionally included is ChaCha20 for symmetric encryption. This is a much simpler system, it still uses macros to get around
the problems associated with the compiler however. All constants are again hand expanded and macros are used instead of function
calls in several places to save memory(the memory overhead per function is very large) and improve performance.

# Forth.lsl and VM.lsl

Finally, I've included a simple stack based VM and compiler from a forth-like language. It listens for commands and upon getting
a valid command, uses the built in lexing function to generate a list of words, which are then compiled by a simple translation
into the VM's bytecode.

The VM is has a threading mechanism built in to enable preemptive multitasking. The macros for controlling that can be seen in
VM-thread.h.

The fetch mechanism in VM-fetch.h grabs n bits at a time from the bitcode stream(implemented as a list of integers due to language
limitations). This enables packing bits more effeciently, which is important for memory constraint reasons.

The decode mechanism in VM-decode.h operates as a simple state machine, first fetching the opcode, then fetching the argument
bits as needed. There are relatively few base opcodes as the majority of the system was pushed to a set of library calls. This
was to enable splitting the different parts of the library across multiple instances of the VM. Combined with the threading
mechanism, this allowed for programs to be halted when an unknown library function was encountered and then the state of the
program could be transfered to another VM which had the appropriate library function. This was necessary due again to the memory
limitations of the language.

The remaining VM-ds.h anv VM-cs.h define the data and call stacks for the VM.

# Other files

For the supporting library, recursive includes are prevented by the compiler, so no include guards are needed on header files.
Most of the additional library is simply providing utility functions
