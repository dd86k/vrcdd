Quick tool to extract metadata from VRChat PNG images.

Usage: invoke with `--vrc` and/or `--vrcx` to get respective data.

Data formats:
- VRC
  - Data appeared around early 2025-08.
  - XML, Adobe format.
- VRCX
  - Data appeared 2023-08-01.
  - JSON.

Example:

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

License: CC0-1.0
