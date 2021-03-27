/* 
 * omc: The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.parse.token;

import std.algorithm : sort;
import std.range : retro;
import std.array : array;
import std.format : format;
import std.variant : Algebraic;

struct OmToken {
	alias Literal = Algebraic!(ulong, long, double, dchar, string);
	enum Type {
		tk_eof,
		tk_plus,
		tk_minus,
		tk_asterisk,
		tk_slash,
		tk_percent,
		tk_power,
		tk_tilde,
		tk_ampersand,
		tk_poll,
		tk_hash,
		tk_shiftLeft,
		tk_shiftRight,
		tk_logicalAnd,
		tk_logicalOr,
		tk_logicalXor,

		tk_assign,
		tk_assignAdd,
		tk_assignSubtract,
		tk_assignMultiply,
		tk_assignDivide,
		tk_assignModulo,
		tk_assignPower,
		tk_assignConcat,
		tk_assignAnd,
		tk_assignOr,
		tk_assignXor,

		tk_equal,
		tk_notEqual,
		tk_greaterThan,
		tk_lessThan,
		tk_greaterThanEqual,
		tk_lessThanEqual,

		tk_increment,
		tk_decrement,
		tk_not,

		tk_question,

		tk_dot,
		tk_apply,
		tk_comma,
		tk_colon,
		tk_semicolon,
		tk_variadic,
		tk_slice,

		tk_leftParen,
		tk_rightParen,
		tk_leftBracket,
		tk_rightBracket,
		tk_leftBrace,
		tk_rightBrace,

		kw_module,
		kw_import,
		kw_enum,
		kw_template,
		kw_struct,
		kw_class,
		kw_interface,
		kw_function,
		kw_def,
		kw_alias,

		kw_if,
		kw_else,
		kw_while,
		kw_do,
		kw_for,
		kw_foreach,
		kw_switch,
		kw_case,
		kw_with,

		kw_cast,
		kw_typeof,
		kw_break,
		kw_continue,
		kw_return,
		kw_is,
		kw_new,
		kw_delete,

		ud_identifier,
		ud_attribute,
		ud_string,
		ud_char,
		ud_integer,
		ud_float,
		ud_unknown
	}
	Type type;
	OmSrcLocation location;
	string lexeme;
	Literal literal;
}

struct OmSrcLocation {
	size_t line, column, position;
	string file;

	static OmSrcLocation fromBuffer(string text, size_t position, string file) {
		import std.string : splitLines;
		auto lines = text[0..position].splitLines();
		return OmSrcLocation(lines.length, lines.length == 0 ? 1 : lines[$-1].length, position, file);
	}

	@property string toString() const {
		return format("%s:(line: %s, column:%s)", file, line, column);
	}
}

string describeToken(OmToken.Type tokenType) {
	switch(tokenType) {
		case OmToken.Type.ud_identifier: return "<Identifier>";
		case OmToken.Type.ud_attribute: return "<Attribute>";
		case OmToken.Type.ud_string: return "<String Literal>";
		case OmToken.Type.ud_char: return "<Charecter Literal>";
		case OmToken.Type.ud_integer: return "<Integer Literal>";
		case OmToken.Type.ud_float: return "<Floating Point Literal>";
		default: static foreach(key, value; tokenLiterals) if (value == tokenType) return key;
	}
	assert(0, "Unknown or illegal token detected.");
}

enum OmToken.Type[string] tokenLiterals = [
	"+": OmToken.Type.tk_plus,
	"-": OmToken.Type.tk_minus,
	"*": OmToken.Type.tk_asterisk,
	"/": OmToken.Type.tk_slash,
	"%": OmToken.Type.tk_percent,
	"^": OmToken.Type.tk_power,
	"~": OmToken.Type.tk_tilde,
	"&": OmToken.Type.tk_ampersand,
	"|": OmToken.Type.tk_poll,
	"#": OmToken.Type.tk_hash,
	"<<": OmToken.Type.tk_shiftLeft,
	">>": OmToken.Type.tk_shiftRight,
	"&&": OmToken.Type.tk_logicalAnd,
	"||": OmToken.Type.tk_logicalOr,
	"##": OmToken.Type.tk_logicalXor,

	"=": OmToken.Type.tk_assign,
	"+=": OmToken.Type.tk_assignAdd,
	"-=": OmToken.Type.tk_assignSubtract,
	"*=": OmToken.Type.tk_assignMultiply,
	"/=": OmToken.Type.tk_assignDivide,
	"%=": OmToken.Type.tk_assignModulo,
	"^=": OmToken.Type.tk_assignPower,
	"~=": OmToken.Type.tk_assignConcat,
	"&=": OmToken.Type.tk_assignAnd,
	"|=": OmToken.Type.tk_assignOr,
	"#=": OmToken.Type.tk_assignXor,

	"==": OmToken.Type.tk_equal,
	"!=": OmToken.Type.tk_notEqual,
	">": OmToken.Type.tk_greaterThan,
	"<": OmToken.Type.tk_lessThan,
	">=": OmToken.Type.tk_greaterThanEqual,
	"<=": OmToken.Type.tk_lessThanEqual,

	"++": OmToken.Type.tk_increment,
	"--": OmToken.Type.tk_decrement,
	"!": OmToken.Type.tk_not,

	"?": OmToken.Type.tk_question,

	".": OmToken.Type.tk_dot,
	".?": OmToken.Type.tk_apply,
	",": OmToken.Type.tk_comma,
	":": OmToken.Type.tk_colon,
	";": OmToken.Type.tk_semicolon,
	"...": OmToken.Type.tk_variadic,
	"..": OmToken.Type.tk_slice,

	"(": OmToken.Type.tk_leftParen,
	")": OmToken.Type.tk_rightParen,
	"[": OmToken.Type.tk_leftBracket,
	"]": OmToken.Type.tk_rightBracket,
	"{": OmToken.Type.tk_leftBrace,
	"}": OmToken.Type.tk_rightBrace,

	"module": OmToken.Type.kw_module,
	"import": OmToken.Type.kw_import,
	"enum": OmToken.Type.kw_enum,
	"template": OmToken.Type.kw_template,
	"struct": OmToken.Type.kw_struct,
	"class": OmToken.Type.kw_class,
	"interface": OmToken.Type.kw_interface,
	"function": OmToken.Type.kw_function,
	"def": OmToken.Type.kw_def,
	"alias": OmToken.Type.kw_alias,

	"if": OmToken.Type.kw_if,
	"else": OmToken.Type.kw_else,
	"while": OmToken.Type.kw_while,
	"do": OmToken.Type.kw_do,
	"for": OmToken.Type.kw_for,
	"foreach": OmToken.Type.kw_foreach,
	"switch": OmToken.Type.kw_switch,
	"case": OmToken.Type.kw_case,
	"with": OmToken.Type.kw_with,

	"cast": OmToken.Type.kw_cast,
	"typeof": OmToken.Type.kw_typeof,
	"break": OmToken.Type.kw_break,
	"continue": OmToken.Type.kw_continue,
	"return": OmToken.Type.kw_return,
	"is": OmToken.Type.kw_is,
	"new": OmToken.Type.kw_new,
	"delete": OmToken.Type.kw_delete
];

enum tokenNames = sort(tokenLiterals.keys).retro().array();
