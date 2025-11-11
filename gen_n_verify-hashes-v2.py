#!/usr/bin/env python3
"""
Smart hash generator / verifier
- Auto-installs missing dependencies (tqdm, blake3)
- Supports blake3 or sha256
"""

import os, sys, hashlib, subprocess

def ensure_module(mod):
    try:
        __import__(mod)
    except ImportError:
        print(f"Missing dependency '{mod}', installing via pip...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", mod])
        __import__(mod)

# Ensure deps
for m in ("tqdm", "blake3"):
    ensure_module(m)

from tqdm import tqdm
import blake3

CHUNK = 1024 * 1024

def hash_file(path, algo="sha256"):
    if algo == "blake3":
        h = blake3.blake3()
    else:
        h = hashlib.new(algo)
    with open(path, "rb") as f:
        while True:
            chunk = f.read(CHUNK)
            if not chunk:
                break
            h.update(chunk)
    return h.hexdigest()

def hash_dir(directory, output, algo="sha256"):
    files = [os.path.join(r, f) for r, _, fs in os.walk(directory) for f in fs]
    with open(output, "w", encoding="utf-8") as out:
        for path in tqdm(files, desc="Hashing", unit="file"):
            rel = os.path.relpath(path, directory)
            out.write(f"{hash_file(path, algo)}  *{rel}\\n")
    print(f"Hashes written to {output}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python gen_n_verify-hashes-v2.py <dir> <output> [algo]")
        sys.exit(1)
    hash_dir(sys.argv[1], sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "sha256")
