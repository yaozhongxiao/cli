#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
import re
import os,sys

def should_ignore_keywords(ignore_list_keywords, line):
    for ignore_key in ignore_list_keywords:
        pattern1 = re.compile(ignore_key, flags=re.I)
        if len(pattern1.findall(line)) >0:
            return True
    return False


def get_file(keywords_list, ignore_list_keywords):
    for root,dirs,files in os.walk(os.getcwd()):    # provides with project path
        for file in files:
            print("scan " + os.path.join(root, file))
            if file.endswith(('.gif','.jpg','.png','.jpeg')):
                continue
            with open(os.path.join(root, file), 'r', encoding='ISO-8859-1') as f:
                for line in f.readlines():
                    line = line.strip()
                    if (should_ignore_keywords(ignore_list_keywords, line) == False):
                        for keyword in keywords_list:
                            pattern = re.compile(keyword, flags=re.I)
                            if len(pattern.findall(line)) > 0:
                                print(os.path.join(root, file) + " \nforbidden info:" + str(pattern.findall(line)[0]))
                                with open(os.getcwd() + './result.txt', 'a+',  encoding='utf-8') as g:
                                    g.write(os.path.join(root, file) + " \nforbidden info:" + str(pattern.findall(line)[0]) + '\n')


def detection_result():
    if os.path.exists(os.getcwd() + './result.txt'):
        print('======= Failed: forbidden infos has been dectected ! =======')
        pass
    else:
        print('======= Passed: forbidden infos has not been dectected ! =======')

def main():
    keywords_list = []
    ignore_list_keywords = ["[^*<>]{0,6}token[^]()!<>;/@&,]{0,10}[=:].{0,1}null,", ".{0,5}user.{0,10}[=:].{ 0,1}null", ".{0,5}pass.{0,10}[=:].{0,1}null", "passport[=:].", "[^*<>]{0,6}key[^]()!<>;/]{0,10}[=:].{0,1}string.{0,10}", ".{0,5}user.{0,10}[=:].{0,1}string", ".{0,5}pass.{0,10}[=:].{0,1}string",".{0,5}app_id[^]()!<>;/@&,]{0,10}[=:].{0,10}\+",".{0,5}appid[^]()!<>;/@&,]{0,10}[=:].{0,10}\+"]
    get_file(keywords_list, ignore_list_keywords)
    detection_result()


if __name__=="__main__":
    main()
