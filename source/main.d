module main;

import std.array : array;
import std.algorithm.sorting : sort;
import std.file : dirEntries, DirEntry, SpanMode;
import std.getopt;
import std.json;
import std.path : baseName;
import std.stdio;
import png;

enum APP_VERSION = "0.3.0";

void page_version()
{
    import core.stdc.stdlib : exit;
    writeln("vrcdd version ", APP_VERSION);
    writeln("Built ", __TIMESTAMP__);
    exit(0);
}

int main(string[] args)
{
    bool ovrc;
    bool ovrcx;
    bool otrace;
    bool ostats;
    bool ostats_dir;
    bool ostats_file;
    bool ostrip;
    string osep = "\t"; /// Separator
    string oglob = "????-??";
    GetoptResult res;
    // TODO: --exclude=Names...
    try res = getopt(args, config.caseSensitive,
        "S|separator",  "Choose separator for stats mode (Default: tab)",
        (string _, string val)
        {
            switch (val) {
            case "tab":     osep = "\t"; return;
            case "comma":   osep = ","; return;
            case "semi":    osep = ";"; return;
            case "column":  osep = ":"; return;
            default:        osep = val;
            }
        },
        "stats",        "Compile statistics from folder globally (count)", &ostats,
        "stats-dir",    "Compile statistics from folder per directory (count)", &ostats_dir,
        "stats-file",   "Compile statistics from folder per file (list)", &ostats_file,
        "strip",        "Strip metadata from file", &ostrip,
        "vrc",          "Get VRC (XML) metadata", &ovrc,
        "vrcx",         "Get VRCX (JSON) metadata", &ovrcx,
        "trace",        "Print trace on stderr", &otrace,
        "version",      "Version page", &page_version);
    catch (Exception ex)
    {
        stderr.writeln("error: ", ex);
        return 1;
    }
    
    if (res.helpWanted)
    {
        defaultGetoptPrinter("VRC image util", res.options);
        return 0;
    }
    
    if (args.length <= 1)
    {
        stderr.writeln("error: Give me file path... NOW");
        return 2;
    }
    
    string path = args[1];
    
    // Stats mode, force VRCX mode because it is useful.
    if (ostats || ostats_dir || ostats_file)
    {
        int[string] displayNames; /// global stats
        foreach (entry_dir; dirEntries(path, oglob, SpanMode.shallow))
        {
            if (otrace)
                stderr.writeln("folder: ", entry_dir.name);
            
            int[string] displayNamesDir; /// dir stats
            foreach (entry_file; dirEntries(entry_dir.name, SpanMode.depth))
            {
                if (entry_file.isDir()) // can't stat dir
                    continue;
                
                PNGMetadata meta = PNG(entry_file.name).metadata(false, true);
                if (meta.vrcx is null)
                    continue;
                if (otrace)
                    stderr.writeln("file+vrcx: ", entry_file.name);
                JSONValue json = parseJSON(meta.vrcx);
                
                if (ostats_file)
                {
                    write(baseName(entry_file.name), osep);
                    foreach (u; json["players"]
                        .array()
                        .sort!((a, b) => a["displayName"].str < b["displayName"].str))
                    {
                        write(osep, u["displayName"]);
                    }
                    writeln;
                }
                
                if (ostats || ostats_dir)
                {
                    foreach (i, user; json["players"].array())
                    {
                        string displayName = user["displayName"].str;
                        
                        if (ostats)
                            displayNames.update(displayName, () => 1, (ref int v) { v++; });
                        
                        if (ostats_dir)
                            displayNamesDir.update(displayName, () => 1, (ref int v) { v++; });
                    }
                }
            }
            
            // DIR STATS
            if (ostats_dir && displayNamesDir.length > 0)
            {
                write(baseName(entry_dir.name));
                foreach (pair; displayNamesDir.byKeyValue.array.sort!((a, b) => a.value > b.value))
                    write(osep, pair.value, osep, pair.key);
                writeln();
            }
        }
        
        // GLOBAL STATS
        if (ostats)
            foreach (pair; displayNames.byKeyValue.array.sort!((a, b) => a.value > b.value))
                writeln(pair.value, osep, pair.key);
        
        return 0;
    }
    
    PNG png = PNG(path);
    
    // strip metadata
    if (ostrip)
    {
        if (args.length < 2)
            throw new Exception("Need output path... NOW");
        png.strip(args[2]);
        // (a) output path: to path
        // (b) no output path but -y: in place
        return 0;
    }
    
    if (ovrc == false && ovrcx == false)
    {
        stderr.writeln("error: Need --vrc and/or --vrcx");
        return 2;
    }
    
    // Print metadata (default)
    PNGMetadata meta = png.metadata(ovrc, ovrcx);
    if (ovrc && meta.vrc)
        writeln(meta.vrc);
    if (ovrcx && meta.vrcx)
        writeln(meta.vrcx);
    
    return 0;
}
