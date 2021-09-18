This is a collection of older scripts in a C like language called LSL.

This language's compiler has almost no optimizations, so even constant folding must be done by hand.

The resulting bytecode from the compiler plus the run time data must be less than 64k.

Included is an implementation of Curve25519 using an internally simulated register machine running a fixed program.
This program had to be written using a lot of macros to define the operations of the simulated register machine.
The core of the system is a small call macro, which pushes the call stack with an integer representing the return location.
Due to limitations of the language, there is no way to push the instruction pointer directly, however using labels and macros
I simulate this behavior.
