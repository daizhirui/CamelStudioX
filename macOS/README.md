# CamelStudioX

CamelStudioX is an IDE designed for embedded system designed by Camel Microelectronic Inc.

This IDE is expected to provide a much robuster and more convenient using experience than CamelStudio.

If you are interested in CamelStudioX(for macOS) lower than 4.0 (like 3.8.0), please visit [CamelStudioX_Mac](https://github.com/daizhirui/CamelStudioX_Mac).

## Bugs to fix

## Improvement to do

- [] Unify debugging print
- [] Add file system monitor to file browser
- [] Update software structure diagram
- [] Write a formal README.md file

## pending features

- hardware debugging system


## Something to say

### 10/07/2018

CamelStudioX for macOS, version 4.0, third generation, is completed!

After the IDE being tested frequently and many precious feedbacks, the macOS version of CamelStudioX has been redesigned and recoded twice. As a student, I have learned a lot from three times of huge work of building this software. 

To build CamelStudioX and make it perform perfectly, many practical problems have to be solved because of the lack of existing reliable open source frameworks for macOS App in Swift.

For example:

- building a portable gcc x86-mips cross compiler toolchains
- building a module which supports compiling code without using makefile and make system
- designing and building a converter which can recognizing the program code, data section, string table and other necessary staffs in the ELF file produced by the cross compiler and assemble them as a binary which is executable in the embedded system
- building a serial communication module which wraps the basic device file system
- building a PC-end serial uploader to load a binary to the embedded system
- building a small and high-performing file browser for basic file operation
- building a simple code processing module which supports syntax highlighting, auto-completion and other common features in some popular code editor like VSCode and Atom, to provide better coding experience
- designing a suitable project file structure to process diverse compiling demands without the help of GNU make
- ... to be continued

As an undergraduate student, time is so limited. It is really difficult to build an IDE individually but I have learned many knowledge about compiler, computer structure, algorithm, Linux, multi thread, real time processing, C, Swift, and so on. I do this project with strong passion and I am very excited to hear some suggestions from you.
