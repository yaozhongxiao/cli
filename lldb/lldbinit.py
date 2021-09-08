#!/usr/bin/python

import lldb

"""
execute 'command script import ${PATH}/lldbinit.py' in lldb mode
"""
def __lldb_init_module(debugger, internal_dict):
  res = lldb.SBCommandReturnObject()
  ci = debugger.GetCommandInterpreter()
  print("init lldbinit for libdebug.so")
  # settings
  ci.HandleCommand("add-dsym ~/Workspace/Debug/libdebug.so", res)
  print(res)
  ci.HandleCommand("image lookup -vn DebugClass::DebugSym", res)
  print(res)
  # ci.HandleCommand("settings set target.source-map ${root-from-lookup}/ ~/source-root/", res)

if __name__ == "__main__":
  print("execute 'command script import ${PATH}/lldbinit.py' in lldb mode")
  print("Run only as script from LLDB... Not as standalone program!")