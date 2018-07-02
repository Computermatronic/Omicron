/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module omicron.ast.token;

import std.algorithm : sort;
import std.range : retro;
import std.array : array;
import std.format : format;

struct SourceLocation {
	uint line, colunm;
	string file;

	static SourceLocation fromBuffer(string text, size_t position, string file) {
		import std.string : splitLines;
		auto lines = text[0..position].splitLines();
		return SourceLocation(lines.length, lines.length == 0 ? 1 : lines[$-1].length, file);
	}

	@property string toString() {
		return format("%s:(line: %s, colunm:%s)", file, line, colunm);
	}
}

struct Token {
	TokenType type;
	SourceLocation location;
	string text;
}

enum TokenType {
	tk_eof,
	tk_plus,
	tk_minus,
	tk_asterick,
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
	tk_at,
	tk_varidic,
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
	ud_string,
	ud_char,
	ud_integer,
	ud_float,
	ud_comment,
}

enum TokenType[string] tokenNameMap = [
	"+": TokenType.tk_plus,
	"-": TokenType.tk_minus,
	"*": TokenType.tk_asterick,
	"/": TokenType.tk_slash,
	"%": TokenType.tk_percent,
	"^": TokenType.tk_power,
	"~": TokenType.tk_tilde,
	"&": TokenType.tk_ampersand,
	"|": TokenType.tk_poll,
	"#": TokenType.tk_hash,
	"<<": TokenType.tk_shiftLeft,
	">>": TokenType.tk_shiftRight,
	"&&": TokenType.tk_logicalAnd,
	"||": TokenType.tk_logicalOr,
	"##": TokenType.tk_logicalXor,

	"=": TokenType.tk_assign,
	"+=": TokenType.tk_assignAdd,
	"-=": TokenType.tk_assignSubtract,
	"*=": TokenType.tk_assignMultiply,
	"/=": TokenType.tk_assignDivide,
	"%=": TokenType.tk_assignModulo,
	"^=": TokenType.tk_assignPower,
	"~=": TokenType.tk_assignConcat,
	"&=": TokenType.tk_assignAnd,
	"|=": TokenType.tk_assignOr,
	"#=": TokenType.tk_assignXor,

	"==": TokenType.tk_equal,
	"!=": TokenType.tk_notEqual,
	">": TokenType.tk_greaterThan,
	"<": TokenType.tk_lessThan,
	">=": TokenType.tk_greaterThanEqual,
	"<=": TokenType.tk_lessThanEqual,

	"++": TokenType.tk_increment,
	"--": TokenType.tk_decrement,
	"!": TokenType.tk_not,

	"?": TokenType.tk_question,

	".": TokenType.tk_dot,
	".?": TokenType.tk_apply,
	",": TokenType.tk_comma,
	":": TokenType.tk_colon,
	";": TokenType.tk_semicolon,
	"@": TokenType.tk_at,
	"...": TokenType.tk_varidic,
	"..": TokenType.tk_slice,

	"(": TokenType.tk_leftParen,
	")": TokenType.tk_rightParen,
	"[": TokenType.tk_leftBracket,
	"]": TokenType.tk_rightBracket,
	"{": TokenType.tk_leftBrace,
	"}": TokenType.tk_rightBrace,

	"module": TokenType.kw_module,
	"import": TokenType.kw_import,
	"enum": TokenType.kw_enum,
	"template": TokenType.kw_template,
	"struct": TokenType.kw_struct,
	"class": TokenType.kw_class,
	"interface": TokenType.kw_interface,
	"function": TokenType.kw_function,
	"def": TokenType.kw_def,
	"alias": TokenType.kw_alias,

	"if": TokenType.kw_if,
	"else": TokenType.kw_else,
	"while": TokenType.kw_while,
	"do": TokenType.kw_do,
	"for": TokenType.kw_for,
	"foreach": TokenType.kw_foreach,
	"switch": TokenType.kw_switch,
	"case": TokenType.kw_case,
	"with": TokenType.kw_with,

	"cast": TokenType.kw_cast,
	"typeof": TokenType.kw_typeof,
	"break": TokenType.kw_break,
	"continue": TokenType.kw_continue,
	"return": TokenType.kw_return,
	"is": TokenType.kw_is,
	"new": TokenType.kw_new,
	"delete": TokenType.kw_delete
];

enum tokenDescriptionMap = [ 
	TokenType.tk_eof: "<End of File>",
	TokenType.tk_plus: "+",
	TokenType.tk_minus: "-",
	TokenType.tk_asterick: "*",
	TokenType.tk_slash: "/",
	TokenType.tk_percent: "%",
	TokenType.tk_power: "^",
	TokenType.tk_tilde: "~",
	TokenType.tk_ampersand: "&",
	TokenType.tk_poll: "|",
	TokenType.tk_hash: "#",
	TokenType.tk_shiftLeft: "<<",
	TokenType.tk_shiftRight: ">>",
	TokenType.tk_logicalAnd: "&&",
	TokenType.tk_logicalOr: "||",
	TokenType.tk_logicalXor: "##",

	TokenType.tk_assign: "=",
	TokenType.tk_assignAdd: "+=",
	TokenType.tk_assignSubtract: "-=",
	TokenType.tk_assignMultiply: "*=",
	TokenType.tk_assignDivide: "/=",
	TokenType.tk_assignModulo: "%=",
	TokenType.tk_assignPower: "^=",
	TokenType.tk_assignConcat: "~=",
	TokenType.tk_assignAnd: "&=",
	TokenType.tk_assignOr: "|=",
	TokenType.tk_assignXor: "#=",

	TokenType.tk_equal: "==",
	TokenType.tk_notEqual: "!=",
	TokenType.tk_greaterThan: ">",
	TokenType.tk_lessThan: "<",
	TokenType.tk_greaterThanEqual: ">=",
	TokenType.tk_lessThanEqual: "<=",

	TokenType.tk_increment: "++",
	TokenType.tk_decrement: "--",
	TokenType.tk_not: "!",

	TokenType.tk_question: "?",

	TokenType.tk_dot: ".",
	TokenType.tk_apply: ".?", 
	TokenType.tk_comma: ",",
	TokenType.tk_colon: ":",
	TokenType.tk_semicolon: ";",
	TokenType.tk_at: "@",
	TokenType.tk_varidic: "...",
	TokenType.tk_slice: "..",

	TokenType.tk_leftParen: "(",
	TokenType.tk_rightParen: ")",
	TokenType.tk_leftBracket: "[",
	TokenType.tk_rightBracket: "]",
	TokenType.tk_leftBrace: "{",
	TokenType.tk_rightBrace: "}",

	TokenType.kw_module: "module",
	TokenType.kw_import: "import",
	TokenType.kw_enum: "enum",
	TokenType.kw_template: "template",
	TokenType.kw_struct: "struct",
	TokenType.kw_class: "class",
	TokenType.kw_interface: "interface",
	TokenType.kw_function: "function",
	TokenType.kw_def: "def",
	TokenType.kw_alias: "alias",

	TokenType.kw_if: "if",
	TokenType.kw_else: "else",
	TokenType.kw_while: "while",
	TokenType.kw_do: "do",
	TokenType.kw_for: "for",
	TokenType.kw_foreach: "foreach",
	TokenType.kw_switch: "switch",
	TokenType.kw_case: "case",
	TokenType.kw_with: "with",

	TokenType.kw_cast: "cast",
	TokenType.kw_typeof: "typeof",
	TokenType.kw_break: "break",
	TokenType.kw_continue: "continue",
	TokenType.kw_return: "return",
	TokenType.kw_is: "is", 
	TokenType.kw_new: "new",
	TokenType.kw_delete: "delete",

	TokenType.ud_identifier: "<Identifier>",
	TokenType.ud_string: "<String Literal>",
	TokenType.ud_char: "<Charecter Literal>",
	TokenType.ud_integer: "<Integer Literal>",
	TokenType.ud_float: "<Floating Point Literal>",
	TokenType.ud_comment: "<Comment>"
];

enum tokenNames = sort(tokenNameMap.keys).retro().array();