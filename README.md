# CLI
Commandline utils for development

## gcc-builder
The scripts to build and install target GCC compiler
- There are three different way to install prerequisition
  if there are some problems during installing prerequisiton,
  you can change the different install procedure by call
  ``` install_prerequisition ``` with different optios

## llvm-builder
The scripts to build and install target llvm & clang
- The default build is based on cmake without ninja,
  if you want to build with ninja, you can set the
  ``` ENABLE_NINJA=true ``` in llvm-builder

## riscv
The scripts to install risc-v64 tools-chains and provide
the riscv spike debugger.