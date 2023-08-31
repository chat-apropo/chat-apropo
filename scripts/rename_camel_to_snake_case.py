import os
import re
import subprocess


def camel_to_snake(name):
    s1 = re.sub("(.)([A-Z][a-z]+)", r"\1_\2", name)
    return re.sub("([a-z0-9])([A-Z])", r"\1_\2", s1).lower()


def rename_git_tracked_files(directory):
    git_tracked_files = subprocess.check_output(["git", "ls-files"], cwd=directory, universal_newlines=True).split("\n")
    remap = {}
    filenames = []
    for filename in git_tracked_files:
        if filename.endswith(".dart"):
            old_name = filename
            new_name = camel_to_snake(filename[:-5]) + ".dart"
            print(f"Renaming {old_name} to {new_name}")
            os.rename(os.path.join(directory, old_name), os.path.join(directory, new_name))
            remap[os.path.basename(old_name)] = os.path.basename(new_name)
            filenames.append(new_name)

    for filename in filenames:
        if filename.endswith(".dart"):
            for old_name, new_name in remap.items():
                replace_references(filename, old_name, new_name)


def replace_references(filename, old_name, new_name):
    """Replaces all references of old_name with new_name if they are in a line starting with 'import'"""
    with open(filename, "r") as f:
        lines = f.readlines()
    with open(filename, "w") as f:
        for line in lines:
            if line.startswith("import") and old_name in line:
                line = line.replace(old_name, new_name)
            f.write(line)


if __name__ == "__main__":
    directory = os.getcwd()
    rename_git_tracked_files(directory)
