/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2015 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See licence.txt)
 */

module omc.utils;

import std.container, std.string, std.traits;

class Stack(T)
{
    alias peek this;
    private SList!T stack;

    void push(T value)
    {
        stack.stableInsertFront(value);
    }

    T peek()
    {
        assert(!stack.empty);
        return (stack.front());
    }

    T pop()
    {
        assert(!stack.empty);
        T Temp = stack.front();
        stack.stableRemoveFront();
        return Temp;
    }

    @property const bool empty()
    {
        return stack.empty();
    }
}

mixin template Accepter(T)
{
    override void accept(T t)
    {
        this.accept(t);
    }
}

/+
Suddenly, out of no where D-Man Appears
       ___          ____  
      /    \       /    \ 
      \_  _/       \_  _/ 
       / /           \ \  
      / /             \ \ 
     / /   ________    \ \
     \ \  /_______/\   / /
      \ \ |   __  \ \ / / 
       \ \|  |  \  \ / /  
        \ | /.\  /.\\ /   
         \| \_/  \_/ \ \  
          |  |    |  | |  
          |  |    |  | |  
          |  |    |  | |  
          |  |    /  / /  
          |  |   /  / /   
          |  |  /  / /    
          |  |_/  / /     
          |______/_/      
           / / \ \        
          / /   \ \       
         / /     \ \      
         | |     | |      
         | |     | |      
     ____| |     | |___   
    /______|     |______\ 
+/
mixin template PrettyPrinter(T)
{
    override string toString()
    {
        import std.conv, std.format, std.traits;

        string result = typeid(this).name ~ "\n{\n";
        foreach (i, field; __traits(allMembers, typeof(this)))
        {
            mixin(format(`
                static if(!isCallable!(this.%s)
                    && field != "loc" && field != "parent" && field != "Monitor")
                {
                    result ~= "%s = "~to!string(this.%s)~";\n";
                }
            `,
                field, field, field));
        }
        return result[0 .. $ - 2] ~ "\n}\n";
    }
}

//field constructor. allows for classes to be constructed like structs
mixin template FieldCtor()
{
    import std.traits;

    this(T...)(T t)
    {
        foreach (i, field; __traits(allMembers, typeof(this)))
        {
            static if (T.length > i && isAssignable!(T[i],
                    typeof(__traits(getMember, typeof(this), field))))
                mixin("this." ~ field ~ " = t[i];");
        }
    }
}

mixin template SuperCtor()
{
    this(T...)(T t)
    {
        super(t);
    }
}

void getLineColunm(string str, uint i, uint* line, uint* colunm)
{
    string[] lines = str[0 .. i].splitLines();
    *line = lines.length;
    if (lines.length > 0)
        *colunm = lines[$ - 1].length;
    else
        *colunm = i;
}

string fileName(string path)
{
    import std.regex;

    enum rex = ctRegex!(`(.+[/\\]+)?([^.^\n\r^ ]+)(\..+)?`);
    auto matches = path.matchFirst(rex);
    if (matches.length > 2)
        return matches[2];
    else
        return "";
}

//C stuff .cstr is shorter and more descriptive than .tostringz
public import std.string : cstr = toStringz;

string dstr(const(char)* str)
{
    string rstr;
    for (size_t i = 0; str[i] != '\0'; i++)
    {
        rstr ~= str[i];
    }
    return rstr;
}
