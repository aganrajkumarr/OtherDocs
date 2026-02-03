function find_large_files() {
  find . -type f -size +50M | xargs ls -lh
}

# Encrypt and split a file into 99MB parts
# Usage: gpg_split /path/to/large_file.pdf
function gpg_split() {
  local input_file="$1"

  if [[ ! -f "$input_file" ]]; then
    echo "Error: File '$input_file' not found."
    return 1
  fi

  # Output prefix: /path/to/large_file.pdf.gpg.part
  local output_prefix="${input_file}.gpg.part"

  echo "Encrypting and splitting: $input_file"
  gpg \
    --symmetric \
    --no-symkey-cache \
    --pinentry-mode loopback \
    --cipher-algo AES256 -o - "$input_file" |
    split -b 49M -d - "$output_prefix"

  echo "Done. Created parts starting with: ${output_prefix}00"
}

# Recombine and decrypt split GPG parts
# Usage: gpg_join /path/to/large_file.pdf.gpg.part00
function gpg_join() {
  local first_part="$1"

  if [[ ! -f "$first_part" ]]; then
    echo "Error: File '$first_part' not found."
    return 1
  fi

  # Remove the '.gpg.part00' suffix to get original filename
  # This works if you provide any part, but usually you provide part00
  local output_file="${first_part%.gpg.part*}"

  # Prefix to match all parts (e.g., /path/to/large_file.pdf.gpg.part)
  local part_prefix="${first_part%[0-9][0-9]}"

  echo "Combining and decrypting into: $output_file"
  cat "${part_prefix}"* | gpg \
    --decrypt \
    --no-symkey-cache \
    --pinentry-mode loopback -o "$output_file"

  echo "Decryption complete: $output_file"
}
