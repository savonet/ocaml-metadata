---
title: Metadata extractor from pdf
autor: Gemini
---

This program uses a robust heuristic approach:

- It scans the file for the Metadata Object ID by looking at the trailer section (usually found at the end of the file).
- It locates the object in the file content by searching for the obj marker.
- It parses the dictionary to extract standard fields like Title, Author, and Creation Date.
- It handles both Hex strings (<A1B2>) and Literal strings ((Hello World)).

# Explanation

Here is a detailed breakdown of how the OCaml program works.

## High-Level Strategy: "Heuristic parsing"

A full PDF parser is incredibly complex because the file format supports graph structures, incremental updates, and binary compression. Since we cannot use external libraries (like zlib for decompression), this program uses a heuristic approach.

Instead of parsing the entire PDF tree, it acts like a "search engine" within the file:
- It jumps to the end of the file to find the Trailer, which acts as the table of contents.
- It looks for the "Info" entry (which points to metadata).
- It jumps to that specific location to read the raw text.
- It decodes the strange PDF string formats into readable text.

## Step-by-Step Implementation Details

### File Ingestion

The function read_file reads the entire PDF into a single memory string.

**Why**: PDF objects can be located anywhere in the file. Loading it into a string allows us to perform random access searches (jumping forward and backward) very easily using string indices.

### Locating the Metadata (The Trailer)

In a PDF, the very last part of the file (the `trailer`) tells the reader where the "Root" of the document is and where the "Info" (metadata) is.

- The Code: `find_info_object_id`
- Logic:
  1. It searches backwards from the end of the file for the string `/Info`.
  2. It expects a format like: `/Info 15 0 R`.
  3. `15` is the Object ID, `0` is the Generation ID, and `R` stands for Reference.
  4. It parses and returns the string `"15 0"`.

**Note**: We search backwards because if a PDF is modified, new trailers are appended to the end of the file. The last one is the most current.

### Fetching the Object Content

Once we know the metadata is in object 15 0, we need to find where that object lives in the file.

- The Code: `get_object_content`
- Logic:
  1. It constructs a search marker: `"15 0 obj"`.
  2. It scans the file content for this marker.
  3. Once found, it scans forward for the closing marker: `"endobj"`.
  4. It extracts everything between these two markers.

Example extraction:

```
15 0 obj
<<
/Title (Project Report)
  /Author (Bob Morane)
  /CreationDate (D:20231220140000)
>>
endobj
```

### Parsing the Dictionary

The content we extracted is a PDF Dictionary, wrapped in `<<` and `>>`. We need to separate the keys (e.g., `/Title`) from the values.

- The Code: `parse_dictionary_content`
- Logic:
  1. It iterates through the string character by character.
  2. Finding Keys: If it sees a `/`, it reads characters until it hits a delimiter (space, `(`, `<`, etc.). This is the Key (e.g., `Title`).
  3. Finding Values: After a key, it skips whitespace to find the Value. The value determines the parsing mode:
     - If it starts with `(`, it is a Literal String.
     - If it starts with `<`, it is a Hex String.

### Decoding PDF Strings

PDFs store text in two very specific ways. The program includes a decoder for both.

### Literal Strings (`decode_literal_string`) These look like standard text but are enclosed in parentheses: `(Hello World)`.

- Challenge: They can contain escape sequences.
- The Logic: The code iterates through the string. If it sees a backslash `\`, it peeks at the next character:
  - `\n`, `\r`, `\t`: Converted to standard newlines/tabs.
  - `\(` or `\)`: Converted to literal parenthesis (so they don't break the parser).
  - `\ddd` (e.g., `\101`): This is an Octal character code. The code parses the 3 digits, converts octal to int, and then to a character.
  
### Hex Strings (`decode_hex_string`) These look like random numbers enclosed in angle brackets: `<48656C6C6F>`.

- The Logic:
  1. It takes two characters at a time (e.g., `48`).
  2. It parses them as a Hexadecimal number (0x48 = 72).
  3. It converts 72 to its ASCII character (H).
  4. It repeats this for the whole string.

Summary Flowchart

```
graph TD
    A[Start: PDF File] --> B[Read entire file to String]
    B --> C{Find Trailer}
    C -->|Search '/Info' backwards| D[Extract Object ID e.g., '15 0']
    D --> E[Search for '15 0 obj']
    E --> F[Extract text between 'obj' and 'endobj']
    F --> G[Parse Dictionary Key/Values]
    G --> H{Value Type?}
    H -->|Starts with (| I[Decode Literal String]
    H -->|Starts with <| J[Decode Hex String]
    I --> K[Store in Metadata Map]
    J --> K
    K --> L[Print Metadata]
```

## Limitations of this Approach

This code relies on the metadata being stored as Plain Text.

- Encrypted PDFs: If the file is encrypted, the strings inside obj ... endobj will be garbage data.
- Compressed Metadata (XRef Streams): In PDF version 1.5+, metadata is sometimes compressed inside a "Cross-Reference Stream" to save space. Since we are using pure OCaml without zlib, we cannot decompress those streams, and this tool will fail to find the metadata in those specific files.
