/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2015 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See licence.txt)
 */

module omc.errors;

import std.format : format;

import omc.lexer : SRCLocation;

class LexError : Exception
{
    this(T...)(SRCLocation loc,T t)//, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(format("%s Error: %s",loc,str(t)));//,file,line,next);
    }
}

class ParseError : Exception
{
    this(T...)(SRCLocation loc,T t)//, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(format("%s Error: %s",loc,str(t)));//,file,line,next);
    }
}

class SemanticError : Exception
{
    this(T...)(SRCLocation loc,T t)//, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(format("%s Error: %s",loc,str(t)));//,file,line,next);
    }
}

class EnvironmentError : Exception
{
    this(T...)(SRCLocation loc,T t)//, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(format("%s Error: %s",loc,str(t)));//,file,line,next);
    }
}

private string str(T...)(T args)
{
    import std.conv : to;
    string result;
    foreach(arg;args)
        result ~= to!string(arg);
    return result;
}

