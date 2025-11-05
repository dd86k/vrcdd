Quick tool to extract metadata from VRChat PNG images.

Usage:
- `--vrc FILE`: extract VRC metadata
- `--vrcx FILE`: extract VRCX metadata
- `--stats DIR`: perform global statistics on VRChat pictures folder
- `--stats-dir DIR`: perform statistics per-directory on VRChat pictures folder
- `--stats-file DIR`: show who was present in each photo
- `--strip OLD NEW`: write NEW file without metadata from OLD picture

Data formats:
- VRC
  - Data appeared around early 2025-08 (Added in [VRChat 2025.3.2](https://docs.vrchat.com/docs/vrchat-202532)).
  - XML, Adobe format.
- VRCX
  - Added in [VRCX 2023.02.18](https://github.com/vrcx-team/VRCX/releases/tag/v2023.02.18).
  - JSON.

## VRC example

```
$ vrcdd --vrc 2025-10/VRChat_2025-10-05_00-16-24.415_1920x1080.png
<x:xmpmeta xmlns:x="adobe:ns:meta/">
  <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
    <rdf:Description>
      <xmp:CreatorTool>VRChat</xmp:CreatorTool>
      <xmp:Author>dd86k</xmp:Author>
      <xmp:CreateDate>2025-10-05T00:16:24.4735510-04:00</xmp:CreateDate>
      <xmp:ModifyDate>2025-10-05T00:16:24.4735510-04:00</xmp:ModifyDate>
    </rdf:Description>
    <rdf:Description xmlns:tiff="http://ns.adobe.com/tiff/1.0/">
      <tiff:DateTime>2025-10-05T00:16:24.4735510-04:00</tiff:DateTime>
    </rdf:Description>
    <rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/">
      <dc:title>
        <rdf:Alt>
          <rdf:li xml:lang="x-default"></rdf:li>
        </rdf:Alt>
      </dc:title>
    </rdf:Description>
    <rdf:Description xmlns:vrc="http://ns.vrchat.com/vrc/1.0/">
      <vrc:WorldID />
      <vrc:WorldDisplayName></vrc:WorldDisplayName>
      <vrc:AuthorID>usr_34f3d933-b091-4163-9565-59cb819aca45</vrc:AuthorID>
    </rdf:Description>
  </rdf:RDF>
</x:xmpmeta>
```

## VRCX example

```
$ vrcdd --vrcx 2024-07/VRChat_2024-07-25_18-04-06.921_1920x1080.png
{"application":"VRCX","version":1,"author":{"id":"usr_34f3d933-b091-4163-9565-59cb819aca45","displayName":"dd86k"},"world":{"name":"VRChat Home","id":"wrld_4432ea9b-729c-46e3-8eaf-846aa0a37fdd","instanceId":"wrld_4432ea9b-729c-46e3-8eaf-846aa0a37fdd:64104~private(usr_34f3d933-b091-4163-9565-59cb819aca45)~region(use)"},"players":[{"id":"usr_34f3d933-b091-4163-9565-59cb819aca45","displayName":"dd86k"}]}
```

    [!NOTE]
    You can use [jq](https://github.com/jqlang/jq) or similar tools for further processing.

## Statistic Modes

Invoking `--stats`, `--stats-dir`, or `--stats-file` will enable a statistic mode.

They're useful to know which players where present at the time of photos the most.

These modes select VRCX data by force (since VRC metadata is useless and does not
include instance players) and assumes the folder structure contains VRChat photos
per-month to match with the globbing of `????-??` (YYYY-MM, so year and month).

Its output uses hardware tabs ('\t') for easier usage with spreadsheet programs
(e.g., LibreOffice Calc, Microsoft Excel).

You can specify a separator by name: `--separator=tab` will output `'\t'` (default)

Separators:
- `tab`: `\t` (default)
- `column`: `:`
- `semi`: `;` (for Excel)
- `comma`: `,` (for CSV)
- other: Use as-is, so `-Sstupid` will use `"stupid"` as... a separator.

Results for each modes are printed on screen. Most important to pipe it into
a file or into the clipboard (Win32: `... | clip`, Xorg: `... | xclip -sel clip`).

Both global and directory stats are sorted descending.

To use stats mode, point the tool to your root VRChat photo directory:
```
vrcdd --stats C:\Users\%USERNAME%\Pictures\VRChat
```

### Global stats

`--stats` will perform a global count of all users by display name, unsorted (sort it yourself).

Format: count separator displayName

### Per-Directory stats

`--stats-dir` will perform a count per folder, unsorted (sort it yourself).

Format: directory [separator count separator displayName]...

### Per-Photo stats

`--stats-file` will simply list players per file.

Format: file [separator displayName]...

## Stripping metadata

The `--strip` option write a new file without metadata.

For example:
```
vrcdd --strip YES.png NO.png
```

Reads `YES.png` and writes `NO.png` without the metadata.

Technical: This rewrites all but `iTXt` PNG chunks, so it will also work for any other PNGs.

## License

CC0-1.0
