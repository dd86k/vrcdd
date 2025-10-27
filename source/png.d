module png;

import std.stdio;
import core.bitop : bswap;

struct PNGMetadata
{
    string vrc;
    string vrcx;
}

/*
Textual information: iTXt, tEXt, zTXt (see 11.3.3 Textual information).
Miscellaneous information: bKGD, hIST, pHYs, sPLT, eXIf (see 11.3.4 Miscellaneous information). 
*/

PNGMetadata getPNGmetadata(string path, bool vrc, bool vrcx, bool trace)
{
    File file = File(path, "rb");
    
    // structure:
    // - magic (c[8])
    // - chunks...
    //   - length (u32)
    //   - type (char[4])
    //   - data...
    //   - crc (u32)
    
    ubyte[8] sigbuf;
    ubyte[] sig = file.rawRead(sigbuf);
    if (sig.length < magic.length)
        throw new Exception("magic length");
    if (sig != magic)
        throw new Exception("invalid magic");
    
    PNGMetadata meta;
    
    // Loop chunks until we find good shit
    union DUMB
    {
        PNGChunkHeader hdr;
        ubyte[PNGChunkHeader.sizeof] raw;
    }
    DUMB dumb;
    ubyte[] datbuf;
    bool gotvrc;
    bool gotvrcx;
    L: while (true)
    {
        if (gotvrc && gotvrcx)
            break;
        
        size_t len = file.rawRead(dumb.raw).length;
        if (len < PNGChunkHeader.sizeof)
            return meta;
        
        uint chksize = bswap(dumb.hdr.Length);
        
        if (trace)
            writeln("chksize=", chksize);
        
        switch (dumb.hdr.ChunkType) {
        case "iTXt":
            datbuf.length = chksize;
            
            // Read data
            size_t chklen = file.rawRead(datbuf).length;
            if (chklen < datbuf.length)
                throw new Exception("GRRRR missing chunk data");
            
            // Read CRC
            ubyte[4] crc32;
            size_t crclen = file.rawRead(crc32).length;
            if (crclen < crc32.length)
                throw new Exception("GRRRR missing crc data");
            
            // "XML:com.adobe.xmp\0\0\0\0\0" (22)... VRC, XML
            static immutable string vrcmagic = "XML:com.adobe.xmp\0\0\0\0\0";
            if (vrc &&
                chksize > vrcmagic.length &&
                datbuf[0..vrcmagic.length] == vrcmagic)
            {
                meta.vrc = cast(string)datbuf[vrcmagic.length..$].idup;
                gotvrc = true;
                if (vrcx == false) // no VRCX and got VRC, get out
                    break L;
                continue;
            }
            
            // "Description\0\0\0\0\0" (16)... VRCX, JSON
            static immutable string vrcxmagic = "Description\0\0\0\0\0";
            if (vrcx &&
                chksize > vrcxmagic.length &&
                datbuf[0..vrcxmagic.length] == vrcxmagic)
            {
                meta.vrcx = cast(string)datbuf[vrcxmagic.length..$].idup;
                gotvrcx = true;
                if (vrc == false) // no VRC and got VRCX, get out
                    break L;
                continue;
            }
            break;
        case "IEND":
            break L;
        /*case "tEXt":
            break;
        case "zTXt":
            break;
        case "bKGD":
            break;
        case "hIST":
            break;
        case "pHYs":
            break;
        case "sPLT":
            break;
        case "eXIf":
            break;
        case "tIME":
            break;*/
        default:
            file.seek(chksize + 4, SEEK_CUR);
        }
    }
    
    return meta;
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
