import os
import random
import string

# ANSI color codes
GREEN = "\033[92m"
RED = "\033[91m"
RESET = "\033[0m"


def get_random_string(length=8):
    return "".join(
        random.choice(string.ascii_letters + string.digits) for _ in range(length)
    )


def rename_files_and_folders(path):
    # Rename directories first
    for root, dirs, files in os.walk(path, topdown=False):
        for dir_name in dirs:
            full_dir_path = os.path.join(root, dir_name)
            new_name = get_random_string()
            new_dir_path = os.path.join(root, new_name)
            os.rename(full_dir_path, new_dir_path)

    # Rename files
    for root, dirs, files in os.walk(path):
        for file_name in files:
            full_file_path = os.path.join(root, file_name)
            new_name = get_random_string() + os.path.splitext(file_name)[1]
            new_file_path = os.path.join(root, new_name)
            os.rename(full_file_path, new_file_path)

    print(f"{GREEN}Renaming completed!{RESET}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        path = sys.argv[1]
        if os.path.exists(path):
            rename_files_and_folders(path)
        else:
            print(f"{RED}Error: The path {path} does not exist.{RESET}")
    else:
        print(f"{RED}Usage: python rename_files.py <path>{RESET}")
