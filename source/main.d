module main;

import std.stdio;
import std.getopt;
import png;
import core.stdc.stdlib : exit;

enum APP_VERSION = "0.1.0";

void page_version()
{
    writeln("vrcdd version ", APP_VERSION);
    writeln("Built ", __TIMESTAMP__);
    exit(0);
}

void main(string[] args)
{
    string oformat = "YYYY-MM";
    string odestination = "stats";
    bool ovrc;
    bool ovrcx;
    bool otrace;
    GetoptResult res;
    try res = getopt(args, config.caseSensitive,
        "vrc",      "Get VRC (XML) metadata", &ovrc,
        "vrcx",     "Get VRCX (JSON) metadata", &ovrcx,
        "trace",    "Print trace on stderr", &otrace,
        "version",  "Version page", &page_version);
    catch (Exception ex)
    {
        stderr.writeln("error: ", ex);
        exit(1);
    }
    
    if (args.length <= 1)
    {
        stderr.writeln("error: Give me file path... NOW");
        exit(2);
    }
    
    if (ovrc == false && ovrcx == false)
    {
        stderr.writeln("error: Need --vrc and/or --vrcx");
        exit(2);
    }
    
    string path = args[1];
    
    PNGMetadata meta = getPNGmetadata(path, ovrc, ovrcx, otrace);
    
    if (ovrc)
        writeln(meta.vrc);
    if (ovrcx)
        writeln(meta.vrcx);
}
