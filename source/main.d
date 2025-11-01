module main;

import std.stdio;
import std.getopt;
import std.file : dirEntries, DirEntry, SpanMode;
import std.json;
import std.path : baseName;
import png;

enum APP_VERSION = "0.2.0";

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
            default: osep = val;
            }
        },
        "stats",        "Compile statistics from folder globally (count)", &ostats,
        "stats-dir",    "Compile statistics from folder per directory (count)", &ostats_dir,
        "stats-file",   "Compile statistics from folder per file (list)", &ostats_file,
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
            foreach (entry_file; dirEntries(entry_dir.name, SpanMode.shallow))
            {
                
                PNGMetadata meta = getPNGmetadata(entry_file.name, false, true, otrace);
                if (meta.vrcx is null)
                    continue;
                if (otrace)
                    stderr.writeln("file+vrcx: ", entry_file.name);
                JSONValue json = parseJSON(meta.vrcx);
                
                if (ostats_file)
                    write(baseName(entry_file.name), osep);
                foreach (i, user; json["players"].array())
                {
                    string displayName = user["displayName"].str;
                    
                    if (ostats)
                        displayNames.update(displayName, () => 1, (ref int v) { v++; });
                    
                    if (ostats_dir)
                        displayNamesDir.update(displayName, () => 1, (ref int v) { v++; });
                    
                    if (ostats_file)
                    {
                        if (i) write(osep);
                        write(displayName);
                    }
                }
                if (ostats_file)
                    writeln;
            }
            if (ostats_dir)
            {
                write(baseName(entry_dir.name));
                foreach (key, value; displayNamesDir)
                {
                    write(osep, value, osep, key);
                }
                writeln();
            }
        }
        if (ostats)
            foreach (key, value; displayNames)
                writeln(value, osep, key);
        return 0;
    }
    
    if (ovrc == false && ovrcx == false)
    {
        stderr.writeln("error: Need --vrc and/or --vrcx");
        return 2;
    }
    
    PNGMetadata meta = getPNGmetadata(path, ovrc, ovrcx, otrace);
    
    if (ovrc && meta.vrc)
        writeln(meta.vrc);
    if (ovrcx && meta.vrcx)
        writeln(meta.vrcx);
    
    return 0;
}
