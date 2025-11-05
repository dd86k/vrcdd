module png;

import std.stdio;
import core.bitop : bswap;

struct PNGMetadata
{
    string vrc;
    string vrcx;
}

private
union ChunkBuffer
{
    PNGChunkHeader chunk;
    ubyte[PNGChunkHeader.sizeof] raw;
}

/*
Textual information: iTXt, tEXt, zTXt (see 11.3.3 Textual information).
Miscellaneous information: bKGD, hIST, pHYs, sPLT, eXIf (see 11.3.4 Miscellaneous information). 
*/
struct PNG
{
    this(string path)
    {
        open(path);
    }
    ~this()
    {
        close();
    }
    
    void open(string path)
    {
        file = File(path, "rb");
    
        // Reading magic for validation makes sense when opening
        ubyte[8] sigbuf;
        ubyte[] sig = file.rawRead(sigbuf);
        if (sig.length < magic.length)
            throw new Exception("magic length");
        if (sig != magic)
            throw new Exception("invalid magic");
    }
    
    void close()
    {
        if (file.isOpen()) // just in case if close() & ~this()
            file.close();
    }
    
    PNGMetadata metadata(bool vrc, bool vrcx)
    {
        PNGMetadata meta;
        bool gotvrc, gotvrcx;
        
        L: while (true)
        {
            PNGChunkHeader chunk = readchunk();
            
            ubyte[] chunkbuf;
            switch (chunk.ChunkType) {
            case "iTXt":
                // Size buffer to chunk's... assuming it's okay haha
                chunkbuf.length = chunk.Length;
                
                // Read data
                size_t chklen = file.rawRead(chunkbuf).length;
                if (chklen < chunkbuf.length)
                    throw new Exception("GRRRR missing chunk data");
                
                // Read CRC (which we skip, assuming it's fine)
                ubyte[4] crc32;
                size_t crclen = file.rawRead(crc32).length;
                if (crclen < crc32.length)
                    throw new Exception("GRRRR missing crc data");
                
                // VRC (XML) format
                // "XML:com.adobe.xmp\0\0\0\0\0" (22)
                static immutable string vrcmagic = "XML:com.adobe.xmp\0\0\0\0\0";
                if (vrc &&
                    chunk.Length > vrcmagic.length &&
                    chunkbuf[0..vrcmagic.length] == vrcmagic)
                {
                    meta.vrc = cast(string)chunkbuf[vrcmagic.length..$].idup;
                    gotvrc = true;
                    if (vrcx == false) // no VRCX and got VRC, get out
                        break L;
                    continue;
                }
                
                // VRCX (JSON) format
                // "Description\0\0\0\0\0" (16)
                static immutable string vrcxmagic = "Description\0\0\0\0\0";
                if (vrcx &&
                    chunk.Length > vrcxmagic.length &&
                    chunkbuf[0..vrcxmagic.length] == vrcxmagic)
                {
                    meta.vrcx = cast(string)chunkbuf[vrcxmagic.length..$].idup;
                    gotvrcx = true;
                    if (vrc == false) // no VRC and got VRCX, get out
                        break L;
                    continue;
                }
                break;
            case "IEND":
                break L;
            default:
                // Jump chunk + checksum
                file.seek(chunk.Length + 4, SEEK_CUR);
            }
        }
        
        return meta;
    }
    
    /* TODO: void stripmeta()
    {
        // 1. random new filename
        // 2. open temp file in same dir
        // 3. write data, skip unwanted chunks (blacklist)
        // 4. close both handles
        // 5. replace target file
    }*/
    
private
    File file;
    
    PNGChunkHeader readchunk()
    {
        ChunkBuffer buffer = void;
        
        size_t len = file.rawRead(buffer.raw).length;
        if (len < PNGChunkHeader.sizeof)
            throw new Exception("Unexpected EOF");
        
        buffer.chunk.Length = bswap(buffer.chunk.Length);
        
        /*if (trace)
            stderr.writeln("chksize=", chksize, " chk=", dumb.hdr.ChunkType);*/
        
        return buffer.chunk;
    }
}

private:

immutable ubyte[] magic = [ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A ];

struct PNGChunkHeader
{
    align(1):
    uint Length;
    char[4] ChunkType;
    // data ...
    // uint crc
}
