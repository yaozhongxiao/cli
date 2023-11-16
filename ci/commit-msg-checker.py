#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import os
import re
import subprocess
import sys

def print_msg_template():
    print(
        "\033[31m\n"
        "your commit message is not valid! please following the template below!"
        "\033[0m"
    )
    print(
        """
        [module] short title of the commit about changes
        
        Longer description for describing why the change is  implemented  
        rather than what it does. The latter can be inferred from the code.  
        
        Further paragraphs come after blank lines.
        - Bullet points are okay, too
        - Typically a hyphen or asterisk is used for the bullet, preceded   
        by a single space, with blank lines in between, but conventions   
        vary here
        
        If you use an issue tracker, put references to them at the bottom.  
        like this:
        
        Resolves: #123  
        See also: #456, #789
        """
    )

def check_commit_format(opts):
    repo_path = opts.project
    # Get the commit messages using Git log command
    # git_log_command = ["git", "log", "HEAD^..HEAD", "--pretty=medium"]
    git_log_command = ["git", "log", "-n 1", "--pretty=medium"]
    if repo_path:
        git_log_command.extend([repo_path])
    if not opts.quiet:
        print(" ".join(git_log_command))
    commit_messages = []
    try:
        # subprocess.run(["cd", repo_path], shell=True)
        result = subprocess.run(git_log_command, check=True, capture_output=True, text=True)
        # git_log_command will retrive the commit message in the following manner.
        #  commit <hash>
        #  Author: <author>
        #  Date:   <author date>
        #          (newline)
        #  <title line>
        #          (newline)
        #  <full commit message>

        # Split the output into individual commit messages
        commit_messages = result.stdout.splitlines()
    except subprocess.CalledProcessError as e:
        print("error mesage : %s" %str(e))
    except Exception as e:
        print("error mesage : %s" %str(e))

    check_pass = True
    if len(commit_messages) > 6:
        # check newline ahead title
        if not re.match(r"\s*$", commit_messages[3]):
            print("\033[31m there need to be a newline ahead the title \033[0m")
            print("-> %s" % commit_messages[3])
            check_pass = False
        # check title
        if not re.match(r"\s*\[\S+\] [\s*\S+\s*]*$", commit_messages[4]):
            print("\033[31m the title of your commit message is invalid \033[0m")
            print("-> %s" % commit_messages[4])
            check_pass = False
        # check newline follow title
        if not re.match(r"\s*$", commit_messages[5]):
            print("\033[31m there need to be a newline follow the title \033[0m")
            print("-> %s" % commit_messages[5])
            check_pass = False
        # check the commit message body

        index = 6
        while index < len(commit_messages):
            if re.match(r"\s*\S+", commit_messages[index]):
                check_pass = check_pass and True
                break
            index += 1
    else:
        print("\033[31mplease make you has commit title or body\033[0m")
        check_pass = False

    if check_pass:
        print("\033[92m commit message passed \033[0m")
    else:
        print_msg_template()
    return not check_pass

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--quiet",
        action="store_true",
        default=False,
        help="Run clang-tidy in quiet mode",
    )
    parser.add_argument(
        "project",
        type=str,
        nargs="?",
        default="",
        help="If specified, only consider project in 'project' directory",
    )
    opts = parser.parse_args(sys.argv[1:])
    sys.exit(check_commit_format(opts))
