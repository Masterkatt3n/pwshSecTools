import os
import sys
import hashlib

try:
    from tqdm import tqdm
except ImportError:
    tqdm = None

try:
    import blake3

    USE_BLAKE3 = True
except ImportError:
    USE_BLAKE3 = False

CHUNK_SIZE = 1024 * 1024  # 1MB


def calculate_file_hash(file_path, hash_algorithm="sha256"):
    if USE_BLAKE3 and hash_algorithm.lower() == "blake3":
        h = blake3.blake3()
    else:
        try:
            h = hashlib.new(hash_algorithm)
        except ValueError:
            print(f"Unsupported hash algorithm: {hash_algorithm}", file=sys.stderr)
            sys.exit(1)

    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(CHUNK_SIZE)
            if not chunk:
                break
            h.update(chunk)

    return h.hexdigest()


def get_all_file_hashes(directory, output_file, hash_algorithm="sha256"):
    files = [
        os.path.join(root, file)
        for root, _, files in os.walk(directory)
        for file in files
    ]
    file_count = len(files)

    if file_count == 0:
        print(f"No files found in {directory}")
        return 0

    iterator = (
        tqdm(files, desc="Hashing Files", unit="file", colour="blue")
        if tqdm and file_count > 1
        else files
    )

    with open(output_file, "w", encoding="utf-8") as out_file:
        for file_path in iterator:
            try:
                file_hash = calculate_file_hash(file_path, hash_algorithm)
                relative_path = os.path.relpath(file_path, directory)
                out_file.write(f"{file_hash}  *{relative_path}\n")
            except Exception as e:
                print(f"Failed to hash {file_path}: {e}", file=sys.stderr)

    if not tqdm or file_count == 1:
        print(
            f"Hashed {file_count} file{'s' if file_count != 1 else ''} in {directory}"
        )

    return file_count


def verify_hashes(directory, hash_file, hash_algorithm="sha256"):
    try:
        with open(hash_file, "r", encoding="utf-8") as f:
            entries = [line.strip().split("\t") for line in f if "\t" in line]
    except Exception as e:
        print(f"Failed to read hash file: {e}", file=sys.stderr)
        sys.exit(1)

    total = len(entries)
    success, fail, missing = 0, 0, 0

    iterator = (
        tqdm(entries, desc="Verifying Files", unit="file", colour="green")
        if tqdm
        else entries
    )

    for rel_path, expected_hash in iterator:
        file_path = os.path.join(directory, rel_path)
        if not os.path.isfile(file_path):
            print(f"Missing: {rel_path}")
            missing += 1
            continue

        try:
            actual_hash = calculate_file_hash(file_path, hash_algorithm)
            if actual_hash.lower() == expected_hash.lower():
                success += 1
            else:
                print(f"Mismatch: {rel_path}")
                fail += 1
        except Exception as e:
            print(f"Error hashing {rel_path}: {e}", file=sys.stderr)
            fail += 1

    print(
        f"\nVerification complete: {success} OK, {fail} mismatched, {missing} missing, total {total}"
    )

    # Return success/fail counts as exit code guidance
    if fail > 0 or missing > 0:
        sys.exit(1)
    else:
        sys.exit(0)


def print_usage():
    print("Usage:")
    print("  Generate hashes:")
    print("    python generate_hashes.py <directory> <output_file> [hash_algorithm]")
    print("  Verify hashes:")
    print(
        "    python generate_hashes.py --verify <directory> <hash_file> [hash_algorithm]"
    )


if __name__ == "__main__":
    args = sys.argv[1:]

    if "--verify" in args:
        try:
            verify_idx = args.index("--verify")
            directory = args[verify_idx + 1]
            hash_file = args[verify_idx + 2]
            algorithm = args[verify_idx + 3] if len(args) > verify_idx + 3 else "sha256"
        except IndexError:
            print_usage()
            sys.exit(1)

        if algorithm.lower() == "blake3" and not USE_BLAKE3:
            print("blake3 module not installed. Run: pip install blake3")
            sys.exit(1)

        verify_hashes(directory, hash_file, algorithm)

    elif 2 <= len(args) <= 3:
        directory = args[0]
        output_file = args[1]
        algorithm = args[2] if len(args) == 3 else "sha256"

        if algorithm.lower() == "blake3" and not USE_BLAKE3:
            print("blake3 module not installed. Run: pip install blake3")
            sys.exit(1)

        get_all_file_hashes(directory, output_file, algorithm)

    else:
        print_usage()
        sys.exit(1)
