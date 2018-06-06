/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2018 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See LICENCE file).
 */
module omicron.ast.core;

import omicron.ast.token;

interface ASTVisitor {
	void visit(ASTModule);
	void visit(ASTAlias);
	void visit(ASTDef);
	void visit(ASTImport);
	void visit(ASTFunction);
	void visit(ASTDefParamater);
	void visit(ASTTemplate);
	void visit(ASTTypeParamater);
	void visit(ASTAliasParamater);
	void visit(ASTEnum);
	void visit(ASTEnumMember);
	void visit(ASTStruct);
	void visit(ASTClass);
	void visit(ASTInterface);
	void visit(ASTIf);
	void visit(ASTElse);
	void visit(ASTSwitch);
	void visit(ASTCase);
	void visit(ASTWhile);
	void visit(ASTDoWhile);
	void visit(ASTFor);
	void visit(ASTForeach);
	void visit(ASTWith);
	void visit(ASTDelete);
	void visit(ASTReturn);
	void visit(ASTBreak);
	void visit(ASTContinue);
	void visit(ASTExpressionStatement);
	void visit(ASTIdentifier);
	void visit(ASTTuple);
	void visit(ASTDispatch);
	void visit(ASTSubscript);
	void visit(ASTTemplateInstance);
	void visit(ASTTypeOf);
	void visit(ASTPointerType);
	void visit(ASTBinaryOperator);
	void visit(ASTUnaryOperator);
	void visit(ASTTinaryOperator);
	void visit(ASTAssignmentOperator);
	void visit(ASTCall);
	void visit(ASTApply);
	void visit(ASTCast);
	void visit(ASTIs);
	void visit(ASTNew);
	void visit(ASTArray);
	void visit(ASTString);
	void visit(ASTChar);
	void visit(ASTInteger);
	void visit(ASTFloat);
	void visit(ASTAttribute);
}

abstract class ASTNode {
	SourceLocation location;

	abstract void accept(ASTVisitor);
}

abstract class ASTStatement: ASTNode {
	//ASTStatement outer;
	ASTAttribute[] attributes;
}

abstract class ASTStatic: ASTStatement {
}

abstract class ASTDeclaration: ASTStatic {
	string name;
}

abstract class ASTExpression: ASTNode {
	//ASTNode outer;
}

abstract class ASTReference: ASTExpression {
}

class ASTModule : ASTDeclaration {
	string[] packageName;
	ASTStatic[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTAlias: ASTDeclaration {
	ASTReference type;
	ASTExpression initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTDef: ASTDeclaration {
	ASTReference type;
	ASTExpression initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTImport: ASTDeclaration {
	string[] packageName;

	mixin Visitor!(ASTVisitor);
}

class ASTFunction: ASTDeclaration {
	ASTReference type;
	ASTDefParamater[] paramaters;
	ASTStatement[] members;

	bool isVaridic;
	bool isLinkage;

	mixin Visitor!(ASTVisitor);
}

class ASTDefParamater: ASTDeclaration {
	ASTReference type;
	ASTExpression initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTTemplate: ASTDeclaration {
	ASTDeclaration[] paramaters;
	ASTStatic[] members;

	bool isVaridic;
	bool isAnonymus;

	mixin Visitor!(ASTVisitor);
}

class ASTTypeParamater: ASTDeclaration {
	ASTReference type;
	ASTReference initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTAliasParamater: ASTDeclaration {
	ASTReference type;
	ASTExpression initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTEnum: ASTDeclaration {
	ASTReference type;
	ASTEnumMember[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTEnumMember: ASTDeclaration {
	ASTExpression initializer;

	mixin Visitor!(ASTVisitor);
}

class ASTStruct: ASTDeclaration {
	ASTReference[] baseTypes;
	ASTStatic[] members;

	bool isLinkage;

	mixin Visitor!(ASTVisitor);
}

class ASTClass: ASTDeclaration {
	ASTReference[] baseTypes;
	ASTStatic[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTInterface: ASTDeclaration {
	ASTReference[] baseTypes;
	ASTStatic[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTIf: ASTStatic {
	ASTExpression subject;
	ASTStatement[] members;
	ASTElse else_;

	mixin Visitor!(ASTVisitor);
}

class ASTElse: ASTStatic {
	ASTStatement[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTSwitch: ASTStatement {
	ASTExpression subject;
	ASTCase[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTCase: ASTStatement {
	ASTExpression[] subjects;
	ASTStatement[] members;

	bool isElseCase;

	mixin Visitor!(ASTVisitor);
}

class ASTWhile: ASTStatement {
	ASTExpression subject;
	ASTStatement[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTDoWhile: ASTStatement  {
	ASTExpression subject;
	ASTStatement[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTFor: ASTStatement {
	ASTDefParamater initializer;
	ASTExpression subject;
	ASTExpression step;
	ASTStatement[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTForeach: ASTStatic {
	ASTDefParamater[] initializers;
	ASTExpression subject;
	ASTStatement[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTWith: ASTStatement {
	ASTExpression subject;
	ASTReference type;
	ASTStatement[] members;

	bool isCast;

	mixin Visitor!(ASTVisitor);
}

class ASTDelete: ASTStatement {
	ASTExpression subject;

	mixin Visitor!(ASTVisitor);
}

class ASTReturn: ASTStatement {
	ASTExpression subject;

	mixin Visitor!(ASTVisitor);
}

class ASTBreak: ASTStatement {
	mixin Visitor!(ASTVisitor);
}

class ASTContinue: ASTStatement {
	mixin Visitor!(ASTVisitor);
}

class ASTExpressionStatement: ASTStatement {
	ASTExpression subject;

	mixin Visitor!(ASTVisitor);
}

class ASTIdentifier: ASTReference {
	string name;

	mixin Visitor!(ASTVisitor);
}

class ASTTuple: ASTReference {
	ASTExpression[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTDispatch: ASTReference {
	ASTExpression subject;
	string name;

	mixin Visitor!(ASTVisitor);
}

class ASTSubscript: ASTReference {
	ASTExpression subject;
	ASTExpression[] arguments;

	mixin Visitor!(ASTVisitor);
}

class ASTTemplateInstance: ASTReference {
	ASTExpression subject;
	ASTExpression[] arguments;

	mixin Visitor!(ASTVisitor);
}

class ASTTypeOf: ASTReference {
	ASTExpression subject;

	mixin Visitor!(ASTVisitor);
}

class ASTPointerType: ASTReference {
	ASTReference subject;

	mixin Visitor!(ASTVisitor);
}

class ASTBinaryOperator: ASTExpression {
	enum Operator:int {
		add = TokenType.tk_plus, 
		subtract = TokenType.tk_minus, 
		multiply = TokenType.tk_asterick, 
		divide = TokenType.tk_slash, 
		modulo = TokenType.tk_percent, 
		concat = TokenType.tk_tilde, 
		equal = TokenType.tk_equal, 
		notEqual = TokenType.tk_notEqual, 
		lessThan = TokenType.tk_lessThan, 
		greaterThan = TokenType.tk_greaterThan, 
		lessThanEqual = TokenType.tk_lessThanEqual, 
		greaterThanEqual = TokenType.tk_greaterThanEqual, 
		and = TokenType.tk_logicalAnd, 
		or = TokenType.tk_logicalOr, 
		xor = TokenType.tk_logicalXor, 
		bitwiseAnd = TokenType.tk_ampersand, 
		bitwiseOr = TokenType.tk_poll, 
		bitwiseXor = TokenType.tk_hash,
		bitwiseShiftLeft = TokenType.tk_shiftLeft, 
		bitwiseShiftRight = TokenType.tk_shiftRight,
		slice = TokenType.tk_slice
	}

	ASTExpression lhs, rhs;
	Operator operator;

	mixin Visitor!(ASTVisitor);
}

class ASTUnaryOperator: ASTExpression {
	enum Operator:int {
		increment = TokenType.tk_increment, 
		decrement = TokenType.tk_decrement,
		posative = TokenType.tk_plus,
		negative = TokenType.tk_minus, 
		enreference = TokenType.tk_ampersand, 
		dereference = TokenType.tk_asterick, 
		not = TokenType.tk_not, 
		bitwiseNot = TokenType.tk_tilde, 
		postIncrement = 75, 
		postDecrement = 76
	}

	ASTExpression subject;
	Operator operator;

	mixin Visitor!(ASTVisitor);
}

class ASTAssignmentOperator: ASTExpression {
	enum Operator:int { 
		assign = TokenType.tk_assign, 
		add = TokenType.tk_assignAdd, 
		subtract = TokenType.tk_assignSubtract, 
		multiply = TokenType.tk_assignMultiply, 
		divide = TokenType.tk_assignDivide, 
		modulo = TokenType.tk_assignModulo, 
		concat = TokenType.tk_assignConcat, 
		and = TokenType.tk_assignAnd, 
		or = TokenType.tk_assignOr, 
		xor = TokenType.tk_assignXor
	}

	ASTExpression subject, assignment;
	Operator operator;

	mixin Visitor!(ASTVisitor);
}

class ASTTinaryOperator: ASTExpression {
	ASTExpression subject, lhs, rhs;

	mixin Visitor!(ASTVisitor);
}

class ASTCall: ASTExpression {
	ASTExpression subject;
	ASTExpression[] arguments;

	mixin Visitor!(ASTVisitor);
}

class ASTApply: ASTExpression {
	ASTExpression subject;
	string name;

	mixin Visitor!(ASTVisitor);
}

class ASTCast: ASTExpression {
	ASTReference type;
	ASTExpression subject;

	mixin Visitor!(ASTVisitor);
}

class ASTIs: ASTExpression {
	ASTExpression lhs, rhs;

	mixin Visitor!(ASTVisitor);
}

class ASTNew: ASTExpression {
	ASTReference type;
	ASTExpression[] arguments;

	mixin Visitor!(ASTVisitor);
}

class ASTArray: ASTExpression {
	ASTExpression[] members;

	mixin Visitor!(ASTVisitor);
}

class ASTString: ASTExpression {
	string literal;

	mixin Visitor!(ASTVisitor);
}

class ASTChar: ASTExpression {
	string literal;

	mixin Visitor!(ASTVisitor);
}

class ASTInteger: ASTExpression {
	string literal;
	
	mixin Visitor!(ASTVisitor);
}

class ASTFloat: ASTExpression {
	string literal;

	mixin Visitor!(ASTVisitor);
}

class ASTAttribute: ASTNode {
	string name;
	ASTExpression[] arguments;

	mixin Visitor!(ASTVisitor);
}

mixin template Visitor(IVisitor) {
	override void accept(IVisitor visitor) {
		visitor.visit(this);
	}
}
