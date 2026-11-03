import os
import sys
import zipfile
import shutil

def package(student_code="QE190111"):
    # Target submission folder: <student_code>/
    out_dir = os.path.join(".", "submission", student_code)
    os.makedirs(out_dir, exist_ok=True)

    zip_filename = os.path.join(out_dir, f"{student_code}.zip")
    print(f"Creating submission zip: {zip_filename}...")

    # Items to include at top level of the zip
    include_files = [
        "pubspec.yaml",
        "pubspec.lock",
        "firestore.rules",
    ]
    include_dirs = [
        "lib",
        "android",
    ]
    if os.path.exists("assets"):
        include_dirs.append("assets")

    # Excluded patterns
    exclude_dirs = {
        ".git",
        ".dart_tool",
        "build",
        ".gradle",
        ".idea",
        ".system_generated",
    }
    exclude_extensions = {
        ".jks",
        ".keystore",
    }

    with zipfile.ZipFile(zip_filename, "w", zipfile.ZIP_DEFLATED) as zipf:
        # Add files
        for filename in include_files:
            if os.path.isfile(filename):
                zipf.write(filename, arcname=filename)
                print(f"  + Added file: {filename}")
            else:
                print(f"  ! Warning: {filename} not found!")

        # Add directories
        for dirname in include_dirs:
            if not os.path.isdir(dirname):
                continue
            for root, dirs, files in os.walk(dirname):
                # Filter out excluded directories in-place
                dirs[:] = [d for d in dirs if d not in exclude_dirs and not d.startswith(".")]

                for f in files:
                    ext = os.path.splitext(f)[1].lower()
                    if ext in exclude_extensions:
                        continue
                    if "service-account" in f.lower() or "admin" in f.lower():
                        continue
                    # Skip android build outputs or local cache
                    if ".gradle" in root or "build" in root or ".cxx" in root:
                        continue

                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, ".")
                    zipf.write(full_path, arcname=rel_path)

    print(f"\n[SUCCESS] Successfully created {zip_filename}!")

    # Copy Word docx into the submission folder
    src_doc = f"{student_code}.docx"
    dest_doc = os.path.join(out_dir, f"{student_code}.docx")
    if os.path.exists(src_doc):
        shutil.copy(src_doc, dest_doc)
        print(f"[SUCCESS] Copied {src_doc} into submission folder: {dest_doc}")
    else:
        print(f"[WARNING] {src_doc} not found! Please check.")

    print(f"\n=======================================================")
    print(f"SUBMISSION FOLDER READY AT: {os.path.abspath(out_dir)}")
    print(f"Contains:")
    print(f"  1. {student_code}.docx")
    print(f"  2. {student_code}.zip")
    print(f"=======================================================\n")

if __name__ == "__main__":
    code = sys.argv[1] if len(sys.argv) > 1 else "QE190111"
    package(code)
