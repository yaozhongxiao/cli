#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Wrapper to run git-diff and parse its output."""
import argparse
import hashlib
import io
import os
import platform
import subprocess
import sys

from cpplint import cpplint

# Since we're asking git-diff to print a diff, all modified filenames
# that have formatting errors are printed with this prefix.
DIFF_MARKER_PREFIX = "+++ b/"

# The sys.path monkey patching confuses the linter.
SCRIPT_DIR = os.path.dirname(__file__)


def DiffLint(opts):
    cmd = "git diff-tree --no-commit-id --name-only -r HEAD"
    if not opts.quiet:
        print(cmd)
    try:
        result = subprocess.run(
            cmd, check=True, shell=True, capture_output=True, text=True
        )
    except subprocess.CalledProcessError as e:
        print("error mesage : %s" % str(e))
        return 1
    except Exception as e:
        print("error mesage : %s" % str(e))
        return 1

    diff_filenames = []
    diff_filenames.extend(result.stdout.splitlines())
    if len(diff_filenames) > 0:
        if not opts.verbose:
            diff_filenames = ["--quiet"] + diff_filenames
        return cpplint(diff_filenames)
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--commit", type=str, default="HEAD^", help="Specify the commit to validate."
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        default=False,
        help="Specify the commit to validate.",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        default=False,
        help="Specify the commit to validate.",
    )
    parser.add_argument(
        "files",
        type=str,
        nargs="*",
        default=".",
        help="If specified, only consider differences in " "these files/directories.",
    )
    opts = parser.parse_args(argv)
    if not DiffLint(opts):
        print("\033[92m cpplint-diff passed \033[0m")
        return 0
    print("\033[31m please correct your commit accroding cpplint message!\033[0m")
    return 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
