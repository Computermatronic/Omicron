/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2015 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See licence.txt)
 */

module omc.lexer;

import std.regex;
import std.algorithm : reduce, sort;
import std.range : retro;
import std.string : indexOf, format;
import std.container : DList;
import std.ascii : isAlphaNum, isWhite ;

import omc.errors : LexError;
import omc.utils : getLineColunm;

class SRCLocation
{
    string file;
    uint line;
    uint colunm;
    
    this(string file, string text, uint i)
    {
    	this.file = file;
    	getLineColunm(text,i,&line,&colunm);
    }
    
    override
    string toString()
    {
        return format("%s:(%s,%s)",file,line,colunm);
    }
}

class Token
{
    SRCLocation loc;
    TokenType type;
    string text;
    
    this(SRCLocation loc, TokenType type, string text)
    {
        this.loc = loc;
        this.type = type;
        this.text = text;
    }
}

DList!Token lex(string file, string src)
{
    DList!Token result;
    uint i = 0;
    Next:
    for(;i<src.length; i++)
    {
        if (src[i].isWhite())
            continue;
        foreach(key;Tokens)
        {
            auto slice = src[i..src.length > i+key.length ? i+key.length : $];
            if (slice == key && (i+key.length >= src.length ||
                !src[i+key.length].isAlphaNum() ||
                reduce!((a,b)=> (b <= 'A' || b >= 'z') && a)(true,slice)))
            {
                result ~= new Token(new SRCLocation(file,src,i),TokenMap[key],slice);
                i+=slice.length;
                goto Next;
            }
        }
        if (src[i] == '"')
        {
            auto str = lexString(src[i..$]);
            if (str.length == 0)
                throw new LexError(new SRCLocation(file,src,i)
                ,"Unterminated string constant");
            result ~= new Token(new SRCLocation(file,src,i),TokenType.tk_sconst
                ,str);
            i+=str.length;
        }
        else if (src[i] == '\'')
        {
           if (src.length <= i+2 || src[i+2] != '\'')
                throw new LexError(new SRCLocation(file,src,i)
                ,"Unterminated charecter constant");
            result ~= new Token(new SRCLocation(file,src,i),TokenType.tk_cconst
                ,src[i..+1]);
            i++;
        }
        else if (src[i] >= '0' && src[i] <= '9')
        {
            auto cnst = lexNumber(src[i..$]);
            result ~= new Token(new SRCLocation(file,src,i),cnst.indexOf(".") == -1 ?
                TokenType.tk_iconst : TokenType.tk_fconst,cnst);
            i+=cnst.length-1;
        }
        else if (src[i] >= 'A' && src[i] <= 'z')
        {
            auto id = lexIdentifier(src[i..$]);
            result ~= new Token(new SRCLocation(file,src,i),TokenType.tk_id,
                id);
            i+=id.length-1;
        }
        else
            throw new LexError(new SRCLocation(file,src,i),"Illegal symbol");
    }
    return result;
}

auto lexIdentifier(string str)
{
    enum rex = ctRegex!(`[A-Z_a-z][A-Z_a-z0-9]*`);
    auto res = str.matchFirst(rex);
    if (!res.empty)
        return res.hit;
    else
        return null;
}

auto lexNumber(string str)
{
    if (str.length > 1 && (str[0..2] == "0x" || str[0..2] == "0X"))
    {
        enum rex = ctRegex!(`^0[xX][0-9A-Za-z]+`);
        auto res = str.matchFirst(rex);
        if (!res.empty && res.hit.length-2 % 2 == 0 && res.hit.length < 18)
            return res.hit;
        else
            return null;
    }
    else
    {
        enum rex = ctRegex!(`^[0-9]+(\.[0-9]+)?`);
        auto res = str.matchFirst(rex);
        if (!res.empty)
            return res.hit;
        else
            return null;
    }
}       

auto lexString(string str)
{
    if (str[0] == '"')
    {
        enum rex = ctRegex!(`^"[^"]*"`);
        auto res = str.matchFirst(rex);
        if (!res.empty)
            return res.hit;
        else
            return null;
    }
    else if (str[0] == '\'')
    {
        enum rex = ctRegex!(`^'[^']'`);
        auto res = str.match(rex);
        if (!res.empty)
            return res.hit;
        else
            return null;
    }
    return null;
}

string getTokenNameFromType(TokenType type)
{
    foreach(k,v;TokenMap)
        if (v == type)
            return k;
    switch(type)
    {
        case TokenType.tk_iconst:
            return "<integer constant>";
        case TokenType.tk_fconst:
            return "<float constant>";
        case TokenType.tk_cconst:
            return "<charecter constant>";
        case TokenType.tk_sconst:
            return "<string constant>";
        case TokenType.tk_id:
            return "<identifier>";
        default:
            return "";
    }
}

enum TokenType
{
    tk_add,
    tk_sub,
    tk_mul,
    tk_div,
    tk_mod,
    
    tk_inc,
    tk_dec,
    
    tk_and,
    tk_or,
    tk_xor,
    tk_not,
    
    tk_concat,
    
    tk_dot,
    tk_sep,
    tk_term,
    tk_tin,
    tk_colon,
    
    tk_ass,
    tk_addass,
    tk_subass,
    tk_mulass,
    tk_divass,
    tk_modass,
    tk_conass,
    
    tk_eq,
    tk_neq,
    tk_gr,
    tk_le,
    tk_geq,
    tk_leq,
    
    tk_rparen,
    tk_lparen,
    
    tk_rbrace,
    tk_lbrace,
    
    tk_rbracket,
    tk_lbracket,
    
    tk_fconst,
    tk_iconst,
    tk_sconst,
    tk_cconst,
    
    tk_id,
    
    tk_module,
    tk_import,
    tk_def,
    tk_func,
    tk_template,
    tk_struct,
    tk_class,
    tk_interface,
    
    tk_inherits,
    tk_prop,
    tk_new,
    tk_cast,
    
    tk_for,
    tk_foreach,
    tk_while,
    tk_do,
    
    tk_break,
    tk_jump,
    
    tk_if,
    tk_else,
    tk_switch,
    tk_case
}

enum TokenType[string] TokenMap = 
[
    "+":TokenType.tk_add,
    "-":TokenType.tk_sub,
    "*":TokenType.tk_mul,
    "/":TokenType.tk_div,
    "%":TokenType.tk_mod,
    
    "++":TokenType.tk_inc,
    "--":TokenType.tk_dec,
    
    "&":TokenType.tk_and,
    "|":TokenType.tk_or,
    "^":TokenType.tk_xor,
    "!":TokenType.tk_not,
    
    "~":TokenType.tk_concat,
    
    ".":TokenType.tk_dot,
    ",":TokenType.tk_sep,
    ";":TokenType.tk_term,
    "?":TokenType.tk_tin,
    ":":TokenType.tk_colon,
    
    "=":TokenType.tk_ass,
    "+=":TokenType.tk_addass,
    "-=":TokenType.tk_subass,
    "*=":TokenType.tk_mulass,
    "/=":TokenType.tk_divass,
    "%=":TokenType.tk_modass,
    "~=":TokenType.tk_conass,
    
    "==":TokenType.tk_eq,
    "!=":TokenType.tk_neq,
    ">":TokenType.tk_gr,
    "<":TokenType.tk_le,
    ">=":TokenType.tk_geq,
    "<=":TokenType.tk_leq,
    
    "(":TokenType.tk_lparen,
    ")":TokenType.tk_rparen,
    
    "{":TokenType.tk_lbrace,
    "}":TokenType.tk_rbrace,
    
    "[":TokenType.tk_rbracket,
    "]":TokenType.tk_lbracket,
    
    "module":TokenType.tk_module,
    "import":TokenType.tk_import,
    "def":TokenType.tk_def,
    "function":TokenType.tk_func,
    "template":TokenType.tk_template,
    "struct":TokenType.tk_struct,
    "class":TokenType.tk_class,
    "interface":TokenType.tk_interface,
    
    "inherits":TokenType.tk_inherits,
    "@":TokenType.tk_prop,
    "new":TokenType.tk_new,
    "cast":TokenType.tk_cast,
    
    "for":TokenType.tk_for,
    "foreach":TokenType.tk_foreach,
    "while":TokenType.tk_while,
    "do":TokenType.tk_do,
    
    "break":TokenType.tk_break,
    "jump":TokenType.tk_jump,
    
    "if":TokenType.tk_if,
    "else":TokenType.tk_else,
    "switch":TokenType.tk_switch,
    "case":TokenType.tk_case
];
enum Tokens = sort(TokenMap.keys).retro();

