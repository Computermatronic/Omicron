/* 
 * omc: The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018-2021 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MPL-2.0 license (See LICENCE file).
 */
module omc.parse.ast;

import omc.utils;
import omc.parse.token;

interface OmAstVisitor {
	void visit(OmAstModule node);
	void visit(OmAstAlias node);
	void visit(OmAstDef node);
	void visit(OmAstImport node);
	void visit(OmAstFunction node);
	void visit(OmAstTemplate node);
	void visit(OmAstTypeParamater node);
	void visit(OmAstAliasParamater node);
	void visit(OmAstEnum node);
	void visit(OmAstEnumMember node);
	void visit(OmAstStruct node);
	void visit(OmAstClass node);
	void visit(OmAstInterface node);
	void visit(OmAstIf node);
	void visit(OmAstSwitch node);
	void visit(OmAstCase node);
	void visit(OmAstWhile node);
	void visit(OmAstDoWhile node);
	void visit(OmAstFor node);
	void visit(OmAstForeach node);
	void visit(OmAstWith node);
	void visit(OmAstDelete node);
	void visit(OmAstReturn node);
	void visit(OmAstBreak node);
	void visit(OmAstContinue node);
	void visit(OmAstExpressionStatement node);
	void visit(OmAstIdentifier node);
	void visit(OmAstTuple node);
	void visit(OmAstDispatch node);
	void visit(OmAstSubscript node);
	void visit(OmAstTemplateInstance node);
	void visit(OmAstTypeOf node);
	void visit(OmAstPointerType node);
	void visit(OmAstBinaryOperator node);
	void visit(OmAstUnaryOperator node);
	void visit(OmAstTrinaryOperator node);
	void visit(OmAstAssignmentOperator node);
	void visit(OmAstCall node);
	void visit(OmAstApply node);
	void visit(OmAstCast node);
	void visit(OmAstIs node);
	void visit(OmAstNew node);
	void visit(OmAstArray node);
	void visit(OmAstString node);
	void visit(OmAstChar node);
	void visit(OmAstInteger node);
	void visit(OmAstFloat node);
	void visit(OmAstAttribute node);
}

abstract class OmAstNode {
	OmSrcLocation location;

	abstract void accept(OmAstVisitor);
}

abstract class OmAstStatement: OmAstNode {
	OmAstAttribute[] attributes;
}

abstract class OmAstDeclaration: OmAstStatement {
	string name;
}

abstract class OmAstExpression: OmAstNode {
}

abstract class OmAstReference: OmAstExpression {
}

class OmAstModule : OmAstDeclaration {
	string[] packageName;
	OmAstDeclaration[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstAlias: OmAstDeclaration {
	OmAstReference type;
	OmAstExpression initializer;

	mixin Visitor!(OmAstVisitor);
}

class OmAstDef: OmAstDeclaration {
	OmAstReference type;
	OmAstExpression initializer;

	mixin Visitor!(OmAstVisitor);
}

class OmAstImport: OmAstDeclaration {
	string[] packageName;
	string[] memberWhitelist; 

	mixin Visitor!(OmAstVisitor);
}

class OmAstFunction: OmAstDeclaration {
	OmAstReference type;
	OmAstDef[] paramaters;
	OmAstStatement[] members;

	bool isVariadic;
	bool isLinkage;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTemplate: OmAstDeclaration {
	OmAstDeclaration[] paramaters;
	OmAstDeclaration[] members;

	bool isVariadic;
	bool isAnonymous;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTypeParamater: OmAstDeclaration {
	OmAstReference type;
	OmAstReference initializer;

	mixin Visitor!(OmAstVisitor);
}

class OmAstAliasParamater: OmAstDeclaration {
	OmAstReference type;
	OmAstExpression initializer;

	mixin Visitor!(OmAstVisitor);
}

class OmAstEnum: OmAstDeclaration {
	OmAstReference type;
	OmAstEnumMember[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstEnumMember: OmAstDeclaration {
	OmAstExpression initializer;

	mixin Visitor!(OmAstVisitor);
}

class OmAstStruct: OmAstDeclaration {
	OmAstReference[] baseTypes;
	OmAstDeclaration[] members;

	bool isLinkage;

	mixin Visitor!(OmAstVisitor);
}

class OmAstClass: OmAstDeclaration {
	OmAstReference[] baseTypes;
	OmAstDeclaration[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstInterface: OmAstDeclaration {
	OmAstReference[] baseTypes;
	OmAstDeclaration[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstAttribute: OmAstNode {
	string name;
	OmAstExpression[] arguments;

	mixin Visitor!(OmAstVisitor);
}

class OmAstIf: OmAstDeclaration {
	OmAstExpression subject;
	OmAstStatement[] members;
	OmAstStatement[] elseMembers;

	mixin Visitor!(OmAstVisitor);
}

class OmAstSwitch: OmAstStatement {
	OmAstExpression subject;
	OmAstCase[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstCase: OmAstStatement {
	OmAstExpression[] subjects;
	OmAstStatement[] members;

	bool isElseCase;

	mixin Visitor!(OmAstVisitor);
}

class OmAstWhile: OmAstStatement {
	OmAstExpression subject;
	OmAstStatement[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstDoWhile: OmAstStatement  {
	OmAstExpression subject;
	OmAstStatement[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstFor: OmAstStatement {
	OmAstDef initializer;
	OmAstExpression subject;
	OmAstExpression step;
	OmAstStatement[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstForeach: OmAstDeclaration {
	OmAstDef[] initializers;
	OmAstExpression subject;
	OmAstStatement[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstWith: OmAstStatement {
	OmAstExpression subject;
	OmAstReference type;
	OmAstStatement[] members;

	bool isCast;

	mixin Visitor!(OmAstVisitor);
}

class OmAstDelete: OmAstStatement {
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstReturn: OmAstStatement {
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstBreak: OmAstStatement {
	mixin Visitor!(OmAstVisitor);
}

class OmAstContinue: OmAstStatement {
	mixin Visitor!(OmAstVisitor);
}

class OmAstExpressionStatement: OmAstStatement {
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstIdentifier: OmAstReference {
	string name;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTuple: OmAstReference {
	OmAstExpression[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstDispatch: OmAstReference {
	OmAstExpression subject;
	string name;

	mixin Visitor!(OmAstVisitor);
}

class OmAstSubscript: OmAstReference {
	OmAstExpression subject;
	OmAstExpression[] arguments;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTemplateInstance: OmAstReference {
	OmAstExpression subject;
	OmAstExpression[] arguments;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTypeOf: OmAstReference {
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstPointerType: OmAstReference {
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstBinaryOperator: OmAstExpression {
	enum Operator:int {
		add = OmToken.Type.tk_plus, 
		subtract = OmToken.Type.tk_minus, 
		multiply = OmToken.Type.tk_asterisk, 
		divide = OmToken.Type.tk_slash, 
		modulo = OmToken.Type.tk_percent, 
		concat = OmToken.Type.tk_tilde, 
		equal = OmToken.Type.tk_equal, 
		notEqual = OmToken.Type.tk_notEqual, 
		lessThan = OmToken.Type.tk_lessThan, 
		greaterThan = OmToken.Type.tk_greaterThan, 
		lessThanEqual = OmToken.Type.tk_lessThanEqual, 
		greaterThanEqual = OmToken.Type.tk_greaterThanEqual, 
		and = OmToken.Type.tk_logicalAnd, 
		or = OmToken.Type.tk_logicalOr, 
		xor = OmToken.Type.tk_logicalXor, 
		bitwiseAnd = OmToken.Type.tk_ampersand, 
		bitwiseOr = OmToken.Type.tk_poll, 
		bitwiseXor = OmToken.Type.tk_hash,
		bitwiseShiftLeft = OmToken.Type.tk_shiftLeft, 
		bitwiseShiftRight = OmToken.Type.tk_shiftRight,
		slice = OmToken.Type.tk_slice
	}

	OmAstExpression lhs, rhs;
	Operator operator;

	mixin Visitor!(OmAstVisitor);
}

class OmAstUnaryOperator: OmAstExpression {
	enum Operator:int {
		increment = OmToken.Type.tk_increment, 
		decrement = OmToken.Type.tk_decrement,
		positive = OmToken.Type.tk_plus,
		negative = OmToken.Type.tk_minus, 
		reference = OmToken.Type.tk_ampersand, 
		dereference = OmToken.Type.tk_asterisk, 
		not = OmToken.Type.tk_not, 
		bitwiseNot = OmToken.Type.tk_tilde, 
		postIncrement = 75, 
		postDecrement = 76
	}

	OmAstExpression subject;
	Operator operator;

	mixin Visitor!(OmAstVisitor);
}

class OmAstAssignmentOperator: OmAstExpression {
	enum Operator:int { 
		assign = OmToken.Type.tk_assign, 
		add = OmToken.Type.tk_assignAdd, 
		subtract = OmToken.Type.tk_assignSubtract, 
		multiply = OmToken.Type.tk_assignMultiply, 
		divide = OmToken.Type.tk_assignDivide, 
		modulo = OmToken.Type.tk_assignModulo, 
		concat = OmToken.Type.tk_assignConcat, 
		and = OmToken.Type.tk_assignAnd, 
		or = OmToken.Type.tk_assignOr, 
		xor = OmToken.Type.tk_assignXor
	}

	OmAstExpression subject, assignment;
	Operator operator;

	mixin Visitor!(OmAstVisitor);
}

class OmAstTrinaryOperator: OmAstExpression {
	OmAstExpression subject, lhs, rhs;

	mixin Visitor!(OmAstVisitor);
}

class OmAstCall: OmAstExpression {
	OmAstExpression subject;
	OmAstExpression[] arguments;

	mixin Visitor!(OmAstVisitor);
}

class OmAstApply: OmAstExpression {
	OmAstExpression subject;
	string name;

	mixin Visitor!(OmAstVisitor);
}

class OmAstCast: OmAstExpression {
	OmAstReference type;
	OmAstExpression subject;

	mixin Visitor!(OmAstVisitor);
}

class OmAstIs: OmAstExpression {
	OmAstExpression lhs, rhs;

	mixin Visitor!(OmAstVisitor);
}

class OmAstNew: OmAstExpression {
	OmAstReference type;
	OmAstExpression[] arguments;

	mixin Visitor!(OmAstVisitor);
}

class OmAstArray: OmAstExpression {
	OmAstExpression[] members;

	mixin Visitor!(OmAstVisitor);
}

class OmAstString: OmAstExpression {
	string literal;

	mixin Visitor!(OmAstVisitor);
}

class OmAstChar: OmAstExpression {
	dchar literal;

	mixin Visitor!(OmAstVisitor);
}

class OmAstInteger: OmAstExpression {
	long literal;
	
	mixin Visitor!(OmAstVisitor);
}

class OmAstFloat: OmAstExpression {
	double literal;

	mixin Visitor!(OmAstVisitor);
}