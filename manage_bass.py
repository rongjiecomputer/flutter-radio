import os
import sys
import json
import hashlib
import platform
import urllib.request
import ssl
import zipfile
import shutil
import tempfile
import argparse

# Create unverified SSL context for environments with certificate issues
ssl_context = ssl._create_unverified_context()

# Configuration
BASS_URLS = {
    "windows": "https://www.un4seen.com/files/bass24.zip",
    "linux": "https://www.un4seen.com/files/bass24-linux.zip",
    "macos": "https://www.un4seen.com/files/bass24-osx.zip"
}

LOCK_FILE = "bass_deps.json"
TARGET_DIR = os.path.join("third_party", "bass")

def compute_sha256(file_path):
    """Compute SHA256 checksum of a file."""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def get_platform_info():
    """Get the current OS and architecture."""
    os_name = platform.system().lower()
    if os_name == "darwin":
        os_name = "macos"
    
    arch = platform.machine().lower()
    if arch in ["x86_64", "amd64"]:
        arch = "x64"
    elif arch in ["arm64", "aarch64"]:
        arch = "arm64"
    elif arch.startswith("arm"):
        arch = "arm"
    
    return os_name, arch

def download_file(url, dest_path):
    """Download a file from a URL to a destination path."""
    print(f"Downloading {url}...")
    try:
        with urllib.request.urlopen(url, context=ssl_context) as response, open(dest_path, 'wb') as out_file:
            shutil.copyfileobj(response, out_file)
    except Exception as e:
        print(f"Error downloading {url}: {e}")
        sys.exit(1)

def lock_deps():
    """Download all BASS libraries and record their SHA256 hashes."""
    print("Locking dependencies...")
    lock_data = {}
    
    with tempfile.TemporaryDirectory() as tmp_dir:
        for platform_name, url in BASS_URLS.items():
            dest_path = os.path.join(tmp_dir, f"bass_{platform_name}.zip")
            download_file(url, dest_path)
            checksum = compute_sha256(dest_path)
            lock_data[platform_name] = {
                "url": url,
                "sha256": checksum
            }
            print(f"  {platform_name}: {checksum}")
            
    with open(LOCK_FILE, "w") as f:
        json.dump(lock_data, f, indent=4)
    print(f"Successfully wrote {LOCK_FILE}")

CMAKE_BASS_FILE = """
# BASS Audio Library Import
add_library(bass SHARED IMPORTED)

set_target_properties(bass PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_LIST_DIR}"
)

if(WIN32)
    set_target_properties(bass PROPERTIES
        IMPORTED_IMPLIB "${CMAKE_CURRENT_LIST_DIR}/bass.lib"
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/bass.dll"
    )
elseif(APPLE)
    set_target_properties(bass PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/libbass.dylib"
    )
else()
    set_target_properties(bass PROPERTIES
        IMPORTED_LOCATION "${CMAKE_CURRENT_LIST_DIR}/libbass.so"
        IMPORTED_NO_SONAME TRUE
    )
endif()

add_library(BASS::BASS ALIAS bass)
"""

def write_cmake_file():
    os.makedirs(TARGET_DIR, exist_ok=True)
    with open(os.path.join(TARGET_DIR, "bass.cmake"), "w") as f:
        f.write(CMAKE_BASS_FILE)

def download_deps():
    """Download, verify, and extract BASS library for the current platform."""
    if not os.path.exists(LOCK_FILE):
        print(f"Error: {LOCK_FILE} not found. Run 'lock' command first.")
        sys.exit(1)
        
    with open(LOCK_FILE, "r") as f:
        lock_data = json.load(f)
        
    os_name, arch = get_platform_info()
    print(f"Detected platform: {os_name} ({arch})")
    
    if os_name not in lock_data:
        print(f"Error: Platform '{os_name}' not supported in {LOCK_FILE}")
        sys.exit(1)
        
    platform_info = lock_data[os_name]
    url = platform_info["url"]
    expected_sha256 = platform_info["sha256"]
    
    with tempfile.TemporaryDirectory() as tmp_dir:
        zip_path = os.path.join(tmp_dir, "bass.zip")
        download_file(url, zip_path)
        
        print("Verifying checksum...")
        actual_sha256 = compute_sha256(zip_path)
        if actual_sha256 != expected_sha256:
            print(f"Error: SHA256 mismatch!")
            print(f"  Expected: {expected_sha256}")
            print(f"  Actual:   {actual_sha256}")
            sys.exit(1)
            
        print(f"Extracting to {TARGET_DIR}...")
        if os.path.exists(TARGET_DIR):
            shutil.rmtree(TARGET_DIR)
        os.makedirs(TARGET_DIR, exist_ok=True)
        
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            all_files = zip_ref.namelist()
            print(f"Zip contains {len(all_files)} files")
            
            def extract_and_move(pattern, target_subfolder=None):
                """Find a file matching pattern and extract it to TARGET_DIR."""
                for f in all_files:
                    if f.lower().endswith(pattern.lower()):
                        # If target_subfolder is specified, check if it's in that path
                        if target_subfolder and target_subfolder.lower() not in f.lower():
                            continue
                        
                        print(f"  Extracting {f}...")
                        zip_ref.extract(f, tmp_dir)
                        src = os.path.join(tmp_dir, f)
                        dst = os.path.join(TARGET_DIR, os.path.basename(f))
                        if os.path.exists(dst):
                            os.remove(dst)
                        shutil.move(src, dst)
                        return True
                return False

            if os_name == "windows":
                if arch == "x64":
                    extract_and_move("bass.dll", "x64")
                    extract_and_move("bass.lib", "x64")
                else:
                    extract_and_move("bass.dll") # Should find root one
                    extract_and_move("bass.lib", "c")

            elif os_name == "linux":
                arch_folder = "x86_64" if arch == "x64" else ("aarch64" if arch == "arm64" else "armhf")
                extract_and_move("libbass.so", "libs/" + arch_folder)

            elif os_name == "macos":
                extract_and_move("libbass.dylib")

            # Always try to extract the header
            extract_and_move("bass.h")

    write_cmake_file()

    print("Dependencies downloaded and extracted successfully.")

def main():
    parser = argparse.ArgumentParser(description="BASS Dependency Manager")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    subparsers.add_parser("lock", help="Compute SHA256 and lock dependencies")
    subparsers.add_parser("download", help="Download and extract dependencies for current platform")
    
    args = parser.parse_args()
    
    if args.command == "lock":
        lock_deps()
    elif args.command == "download":
        download_deps()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
