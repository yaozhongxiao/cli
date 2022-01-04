#!/usr/bin/env python
# -*- coding: utf-8 -*-

import lldb
import re
import os
import shlex

def goto_main(debugger, command, result, internal_dict):
    """
    goto main
    """
    interpreter = lldb.debugger.GetCommandInterpreter()
    return_object = lldb.SBCommandReturnObject()     # 用来保存结果
    interpreter.HandleCommand('dis', return_object)  # 执行dis命令
    output = return_object.GetOutput(); #获取反汇编后的结果

    br_index = output.rfind('br     x16') #查找最后的 bx x16
    br_index = br_index - 20 #位置减去20
    addr_index = output.index('0x', br_index) #查找0x开头的字符串
    br_addr = output[br_index:br_index+11] #找到之后偏移11位

    debugger.HandleCommand('b ' + br_addr) #添加断点
    debugger.HandleCommand('continue') #运行
    debugger.HandleCommand('si') #单步步入

def get_aslr():

    interpreter = lldb.debugger.GetCommandInterpreter()
    return_object = lldb.SBCommandReturnObject()

    interpreter.HandleCommand('image list -o -f', return_object) #执行image list -o -f命令
    output = return_object.GetOutput(); #获取命令的返回值
    match = re.match(r'.+(0x[0-9a-fA-F]+)', output) #正则匹配(0x开头)
    if match:
        return match.group(1)
    else:
        return None

def aslr(debugger, command, result, internal_dict):
    """
    get ASLR offset
    """
    aslr = get_aslr()
    print >>result, "ASLR offset is:", aslr

def breakpoint_address(debugger, command, result, internal_dict):
    """
    breakpoint aslr address
    """
    fileoff = shlex.split(command)[0] #获取输入的参数
    if not fileoff:
        print >>result, 'Please input the address!'
        return

    aslr = get_aslr()
    if aslr:
        #如果找到了ASLR偏移，就设置断点
        debugger.HandleCommand('br set -a "%s+%s"' % (aslr, fileoff))
    else:
        print >>result, 'ASLR not found!'


def __lldb_init_module(debugger, internal_dict):
    debugger.HandleCommand('command script add -f myscript.aslr aslr')
    debugger.HandleCommand('command script add -f myscript.goto_main gm')
    debugger.HandleCommand('command script add -f myscript.breakpoint_address ba')
