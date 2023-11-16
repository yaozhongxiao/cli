#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Wrapper to run git-clang-format and parse its output."""
import argparse
import hashlib
import io
import os
import platform
import subprocess
import sys

# Since we're asking git-clang-format to print a diff, all modified filenames
# that have formatting errors are printed with this prefix.
DIFF_MARKER_PREFIX = "+++ b/"

# The sys.path monkey patching confuses the linter.
SCRIPT_DIR = os.path.dirname(__file__)
BUILDTOOLS_PATH = os.path.join(os.path.dirname(SCRIPT_DIR), "utils")


def GetDefaultGitClangFormat():
    """Gets the default git-clang-format binary path.
    This also ensures that the binary itself is up-to-date.
    """
    git_clang_format_path = os.path.join(BUILDTOOLS_PATH, "git-clang-format")
    if os.path.exists(git_clang_format_path):
        return git_clang_format_path
    return "git-clang-format"  # use global envorinment git-clang-format or fail


def GetDefaultClangFormat():
    """Gets the default clang-format binary path.
    This also ensures that the binary itself is up-to-date.
    """
    clang_format_path = os.path.join(
        BUILDTOOLS_PATH, platform.system().lower(), "clang-format"
    )
    if os.path.exists(clang_format_path):
        return clang_format_path
    return "clang-format"  # use global envorinment clang-format or fail


def DoClangFormat(cmd, opts):
    if not opts.quiet:
        print(" ".join(cmd))
    try:
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print("clang-format failed:\n" + str(e), file=sys.stderr)
        return 1
    print(result.stdout)
    return 0

default_extensions = [
        # From clang/lib/Frontend/FrontendOptions.cpp, all lower case
        "c",
        "h",  # C
        "m",  # ObjC
        "mm",  # ObjC++
        "cc",
        "cp",
        "cpp",
        "c++",
        "cxx",
        "hh",
        "hpp",
        "hxx",
        "inc",  # C++
        "ccm",
        "cppm",
        "cxxm",
        "c++m",  # C++ Modules
        "cu",
        "cuh",  # CUDA
        # Other languages that clang-format supports
        "proto",
        "protodevel",  # Protocol Buffers
        "java",  # Java
        "js",  # JavaScript
        "ts",  # TypeScript
        "cs",  # C Sharp
        "json",  # Json
    ]

def filter_by_extension(files_list, allowed_extensions):
    """Delete every key in `dictionary` that doesn't have an allowed extension.
    `allowed_extensions` must be a collection of lowercase file extensions,
    excluding the period."""
    required_files = []
    for filename in files_list:
        base_ext = filename.rsplit(".", 1)
        if len(base_ext) == 1 and "" in allowed_extensions:
            continue
        if (len(base_ext) > 1 and (base_ext[1].lower() in allowed_extensions)):
            required_files.append(filename)
        # else:
        #     print("skip %s" %filename)
    return required_files


def CommitFormatChecking(opts):
    # retrieve all modified files
    # cmd = "git diff-tree --no-commit-id --name-only -r HEAD | xargs " + opts.clang_format + " -i"
    cmd = "git diff-tree --no-commit-id --name-only -r HEAD"
    try:
        result = subprocess.run(
            cmd, check=True, shell=True, capture_output=True, text=True
        )
    except Exception as e:
        print("\033[31m error: %s \033[0m" % str(e))
        return 1
    # remove interested extention
    modified_files = result.stdout.splitlines()
    if len(modified_files) > 0:
        modified_files = filter_by_extension(modified_files, default_extensions)
        if len(modified_files) > 0:
            # format modified files
            fmtcmd = opts.clang_format + " -i " + (" ".join(modified_files))
            try:
                result = subprocess.run(
                    fmtcmd, check=True, shell=True, capture_output=True, text=True
                )
            except Exception as e:
                print("\033[31m error: %s \033[0m" % str(e))
                return 1
    if opts.fix:
        return 0
    # retrive the formated files
    statuscmd = ["git", "diff", "--name-only"]
    try:
        result = subprocess.run(statuscmd, check=True, capture_output=True, text=True)
    except Exception as e:
        print("\033[31m error: %s \033[0m" % str(e))
        return 1
    formatted_files = result.stdout.splitlines()
    if len(formatted_files) > 0:
        print("\nThe following files have formatting errors:")
        print("-------------------------------------------")
        index = 1
        for filename in formatted_files:
            print("\033[31m -> [%s] %s \033[0m" % (index, filename))
            index += 1
        print(
            "\nYou can run `%s --fix %s` to fix"
            % (sys.argv[0], " ".join(arg for arg in sys.argv[1:]))
        )
        return 1
    print("\033[92m commit format passed\033[0m")
    return 0


def GitClangFormatChecking(cmd, opts):
    if not opts.quiet:
        print(" ".join(cmd))
    # invoke git-clang-format diff
    try:
        result = subprocess.run(cmd, check=False, capture_output=True, text=True)
    except subprocess.CalledProcessError as e:
        print("clang-format failed:\n" + str(e), file=sys.stderr)
        return 1
    except Exception as e:
        print("\033[31m %s \033[0m" % str(e))
        return 1
    # handle git-clang-format output
    if result.returncode:
        print("clang-format-diff failed with %s" % result.stderr)
    else:
        print("clang-format-diff suc with %s" % result.stdout)
    stdout = result.stdout
    diffout = stdout.rstrip("\n")
    if (diffout == "no modified files to format"
        or diffout == "clang-format did not modify any files"):
        # This is always printed when only files that clang-format does not
        # understand were modified.
        print("\033[92m commit format passed with %s \033[0m" % diffout)
        return 0
    # format check fail handling
    diff_filenames = []
    for line in stdout.splitlines():
        # print(line)
        if line.startswith(DIFF_MARKER_PREFIX):
            diff_filenames.append(line[len(DIFF_MARKER_PREFIX) :].rstrip())
            # diff_filenames.append(line[:].rstrip())
    if diff_filenames:
        print("\nThe following files have formatting errors:")
        print("-------------------------------------------")
        index = 1
        for filename in diff_filenames:
            print("\033[31m -> [%s] %s \033[0m" % (index, filename))
            index += 1
        print(
            "\nYou can run `%s --fix %s` to fix"
            % (sys.argv[0], " ".join(arg for arg in sys.argv[1:]))
        )
    return 1


def main(argv):
    """Checks if a project is correctly formatted with clang-format.
    Returns 1 if there are any clang-format-worthy changes in the project (or
    on a provided list of files/directories in the project), 0 otherwise.
    """
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--clang-format",
        default=GetDefaultClangFormat(),
        help="The path of the clang-format executable.",
    )
    parser.add_argument(
        "--git-clang-format",
        default=GetDefaultGitClangFormat(),
        help="The path of the git-clang-format executable.",
    )
    parser.add_argument(
        "--style",
        metavar="STYLE",
        type=str,
        default="file",
        help="The style that clang-format will use.",
    )
    parser.add_argument(
        "--extensions",
        metavar="EXTENSIONS",
        type=str,
        help="Comma-separated list of file extensions to " "format.",
    )
    parser.add_argument(
        "--fix",
        action="store_true",
        default=False,
        help="Fix any formatting errors automatically.",
    )
    scope = parser.add_mutually_exclusive_group(required=False)
    scope.add_argument(
        "--commit", type=str, default=None, help="Specify the commit to validate."
    )
    scope.add_argument(
        "--working-tree",
        action="store_true",
        default=True,
        help="Validates the files that have changed from "
        "HEAD in the working directory.",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        default=False,
        help="Run clang-tidy in quiet mode",
    )
    parser.add_argument(
        "files",
        type=str,
        nargs="*",
        default=".",
        help="If specified, only consider differences in " "these files/directories.",
    )
    opts = parser.parse_args(argv)
    cmd = [opts.git_clang_format]
    # cmd = [opts.git_clang_format, "--verbose"]

    return CommitFormatChecking(opts)

    if opts.fix:
        cmd.extend(["--binary", opts.clang_format, "--force"])
    else:
        cmd.extend(["--binary", opts.clang_format, "--diff"])
    if opts.style:
        cmd.extend(["--style", opts.style])
    if opts.extensions:
        cmd.extend(["--extensions", opts.extensions])
    if opts.commit:
        cmd.extend(["%s^" % opts.commit, opts.commit])
    else:
        cmd.extend(["HEAD^"])
    cmd.extend(["--", opts.files])

    if opts.fix:
        return DoClangFormat(cmd, opts)
    else:
        return ClangFormatChecking(cmd, opts)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
