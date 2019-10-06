# CamelStudioX

CamelStudioX is an IDE designed for embedded system designed by Camel Microelectronic Inc.

This IDE is expected to provide a much robuster and more convenient using experience than CamelStudio.

If you are interested in CamelStudioX(for macOS) lower than 4.0 (like 3.8.0), please visit [CamelStudioX_Mac](https://github.com/daizhirui/CamelStudioX_Mac).

## Bugs to fix


## Improvement to do

- [ ] Migrate from HockeyApp to AppCenter
- [ ] Unify debugging print
- [ ] Update software architecture diagram
- [ ] Write a formal README.md file

## Pending features

- [ ] hardware debugging system: linker shouldn't use '-s' option!

```bash
~/D/C/C/Hello[14:10] > /Applications/CamelStudioX.app/Contents/Frameworks/CSXMake.framework/Resources/Toolchains/bin/mips-netbsd-elf-objdump -d --line-numbers release/Hello.o 

release/Hello.o:     file format elf32-littlemips


Disassembly of section .text:

00000000 <user_interrupt>:
user_interrupt():
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:25
0:    27bdfff8     addiu    sp,sp,-8
4:    afbe0004     sw    s8,4(sp)
8:    03a0f025     move    s8,sp
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:26
c:    00000000     nop
10:    03c0e825     move    sp,s8
14:    8fbe0004     lw    s8,4(sp)
18:    27bd0008     addiu    sp,sp,8
1c:    03e00008     jr    ra
20:    00000000     nop

00000024 <main>:
main():
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:34
24:    27bdffe8     addiu    sp,sp,-24
28:    afbf0014     sw    ra,20(sp)
2c:    afbe0010     sw    s8,16(sp)
30:    03a0f025     move    s8,sp
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:36
34:    3c020000     lui    v0,0x0
38:    24440000     addiu    a0,v0,0
3c:    0c000000     jal    0 <user_interrupt>
40:    00000000     nop
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:37
44:    00000000     nop
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:39
48:    3c020000     lui    v0,0x0
4c:    24440008     addiu    a0,v0,8
50:    0c000000     jal    0 <user_interrupt>
54:    00000000     nop
58:    00001025     move    v0,zero
/Users/daizhirui/Development/Camel/CamelProject/Hello/Hello.c:40
5c:    03c0e825     move    sp,s8
60:    8fbf0014     lw    ra,20(sp)
64:    8fbe0010     lw    s8,16(sp)
68:    27bd0018     addiu    sp,sp,24
6c:    03e00008     jr    ra
70:    00000000     nop
```

## History

### 4.1.8 Build 63

- Fix a problem of checking updates via GitHub.

### 4.1.7 Build 62

- Update to Swift 5.0

### 4.1.6 Build 61

- Solve a mistake in M2/IO.h
- Update Documentation

### 4.1.5 Build 60

- Improve AutoCompleter

### 4.1.4 Build 59

- Fix a crash on macOS 10.12.*
- Auto update recent project table in Welcome Window

### 4.1.3 Build 58

- Fix UI of Welcome Window in old systems
- Filter unexisting recent projects

### 4.1.2 Build 57

- Fix a bug of smart punctuation: '0' eats ')'
- Improve smart punctuation: auto pair of single quotation marks and double quotation marks
- New feature: quick comment by using "Command + /"

### 4.1.1 Build 56

- Replace HockkeyApp SDK with MSAppCenter SDK.

### 4.1.0 Build 55

- New toolbar! Now you can customize your own toolbar!
- Project Settings Panel is moved to the right side.
- Help and Documentation are opened in a new window now! CamelStudioX supports you open multiple help or documentation windows now!
- CamelStudioX Make System Output panel is slightly adjusted to become more readable.

### 4.0.4 Build 54

- Fix a bug of the OpenPortButton in the Serial Monitor
- Solve a mistake in M2/SPI.h

### 4.0.3 Build 53

- Improve the experience and the performance of the serial monitor
- Improve the auto-completer of the code editor

### 4.0.2 Build 52

- Fix the UI of the tabs when a mouse is connected

### 4.0.1 Build 51

- Update Sparkle Framework
- Add file system monitor to file browser, update files modified other-where automatically
- Add "Tools" to the main menu, which contains two submenus: "Serial Monitor Window" and "Serial Driver Installer"

### 4.0.0 Build 50
Third generation of CamelStudioX, modular software architecture. Its UI is totally redesigned.

Function List:

- Binary Converter:
    - supports converting optimized ELF files.
- Toolchain Interface:
    - does not need Xcode anymore!
    - supports switching between different target profiles.
    - supports processing multiple target profiles simultaneously.
    - supports printing more compiling details.
- Binary Uploader: 
    - upload binary to M2 chips faster and stabler.
    - supports uploading binary to different chips simultaneously.
- Serial monitor: 
    - a new stabler module architecture, all serial devices are managed by a manager. No more switching anymore.
    - supports sending text via the window directly, "chat with your chip"
    - supports sending file manually
- Documentation and Tutorial Viewer:
    - Now you can view the official documentation or the tutorial just inside the IDE, without switching to Safari.
- File browser: 
    - robuster file operation
    - avoids opening none-text files
- Code editor: 
    - multiple tabs
    - auto-completion
    - Syntax highlighting
    - auto-tab, auto-brace and auto-quotes

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
