/* 
 * The official Omicron compiler.
 * Reference implementation of the Omicron programming language.
 * Copyright (c) 2015 by Sean Campbell.
 * Written by Sean Campbell.
 * Distributed under The MIT License (See licence.txt)
 */

module omc.ast;

import omc.lexer : SRCLocation;
import omc.utils : Accepter, SuperCtor, PrettyPrinter;

abstract class ASTNode
{
    ASTNode parent;
    SRCLocation loc;

    this(ASTNode parent, SRCLocation loc)
    {
        this.parent = parent;
        this.loc = loc;
    }

    abstract string getDescription();

    abstract void accept(ASTVisitor visitor);
}

abstract class ASTDecl : ASTNode
{
    string name;
    string[] properties;

    this(ASTNode parent, SRCLocation loc, string name, string[] properties)
    {
        super(parent, loc);
        this.name = name;
        this.properties = properties;
    }
}

class ASTImport : ASTDecl
{
    this(ASTNode parent, SRCLocation loc, string name, string[] properties)
    {
        super(parent, loc, name, properties);
    }

    override string getDescription()
    {
        return "import";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTModule : ASTDecl
{
    ASTNode[] moduleBody;

    this(SRCLocation loc)
    {
        super(null, loc, name, null);
    }

    override string getDescription()
    {
        return "module";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTDef : ASTDecl
{
    ASTNode typeNode;
    ASTNode exp;
    Type type;

    this(ASTNode parent, SRCLocation loc, string name, ASTNode typeNode,
        ASTNode exp, string[] properties = null)
    {
        super(parent, loc, name, properties);
        this.typeNode = typeNode;
        this.exp = exp;
    }

    override string getDescription()
    {
        return "def " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTFunction : ASTDecl
{
    ASTNode typeNode;
    ASTDef[] args;
    ASTNode[] funcBody;

    Type returnType;
    Type type;

    this(ASTNode parent, SRCLocation loc, string name, ASTNode typeNode, string[] properties = null)
    {
        super(parent, loc, name, properties);
        this.typeNode = typeNode;
    }

    override string getDescription()
    {
        return "function " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTTemplate : ASTDecl
{
    string[] args;
    ASTDecl[] templateBody;

    this(ASTNode parent, SRCLocation loc, string name, string[] properties = null)
    {
        super(parent, loc, name, properties);
    }

    override string getDescription()
    {
        return "template " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTStruct : ASTDecl
{
    ASTDecl[] structBody;

    this(ASTNode parent, SRCLocation loc, string name, string[] properties)
    {
        super(parent, loc, name, properties);
    }

    override string getDescription()
    {
        return "struct " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTClass : ASTDecl
{
    ASTDecl[] classBody;
    ASTNode[] inherits;
    
    TypeClass superClass;
    TypeInterface[] interfaces;

    this(ASTNode parent, SRCLocation loc, string name, string[] properties)
    {
        super(parent, loc, name, properties);
        this.inherits = inherits;
    }

    override string getDescription()
    {
        return "class " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTInterface : ASTDecl
{
    ASTDecl[] interfaceBody;
    ASTNode[] inherits;
    
    TypeInterface[] interfaces;

    this(ASTNode parent, SRCLocation loc, string name, string[] properties)
    {
        super(parent, loc, name, properties);
        this.inherits = inherits;
    }

    override string getDescription()
    {
        return "interface " ~ name;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTTemplateInstance : ASTNode
{
    ASTNode lhs;
    ASTNode[] args;

    this(ASTNode parent, SRCLocation loc, ASTNode lhs, ASTNode[] args)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.args = args;
    }

    override string getDescription()
    {
        return "template instance";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTIf : ASTNode
{
    ASTNode cond;
    ASTNode[] ifBody;
    ASTElse else_;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "if";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTElse : ASTNode
{
    ASTNode[] elseBody;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "else";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTSwitch : ASTNode
{
    ASTNode cond;
    ASTCase[] cases;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "switch";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTCase : ASTNode
{
    ASTNode exp;
    ASTNode[] caseBody;
    bool elseCase = false;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
        this.exp = exp;
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);

    override string getDescription()
    {
        return "case";
    }
}

class ASTFor : ASTNode
{
    ASTDef def;
    ASTNode cond;
    ASTNode exp;
    ASTNode[] forBody;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "for";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTForeach : ASTNode
{
    ASTDef[] defs;
    ASTNode exp;
    ASTNode[] foreachBody;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "foreach";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTWhile : ASTNode
{
    ASTNode cond;
    ASTNode[] whileBody;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "while";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTDo : ASTNode
{
    ASTNode cond;
    ASTNode[] doBody;

    this(ASTNode parent, SRCLocation loc)
    {
        super(parent, loc);
    }

    override string getDescription()
    {
        return "do";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTBreak : ASTNode
{
    ASTNode loop;

    this(ASTNode parent, SRCLocation loc, ASTNode loop)
    {
        super(parent, loc);
        this.loop = loop;
    }

    override string getDescription()
    {
        return "break";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTJump : ASTNode
{
    ASTNode loop;

    this(ASTNode parent, SRCLocation loc, ASTNode loop)
    {
        super(parent, loc);
        this.loop = loop;
    }

    override string getDescription()
    {
        return "jump";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTUnaryExp : ASTNode
{
    string op;
    ASTNode s;
    bool prefix;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, string op, ASTNode s, bool prefix)
    {
        super(parent, loc);
        this.op = op;
        this.s = s;
    }

    override string getDescription()
    {
        return "unary expression";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTBinaryExp : ASTNode
{
    ASTNode lhs;
    string op;
    ASTNode rhs;
    
    Type type;
 
    this(ASTNode parent, SRCLocation loc, ASTNode lhs, string op, ASTNode rhs)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.op = op;
        this.rhs = rhs;
    }

    override string getDescription()
    {
        return "binary expression";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTTinaryExp : ASTNode
{
    ASTNode cond;
    ASTNode lhs;
    ASTNode rhs;

    Type type;
    
    this(ASTNode parent, SRCLocation loc, ASTNode cond, ASTNode lhs, ASTNode rhs)
    {
        super(parent, loc);
        this.cond = cond;
        this.lhs = lhs;
        this.rhs = rhs;
    }

    override string getDescription()
    {
        return "tinary expression";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTCallExp : ASTNode
{
    ASTNode lhs;
    ASTNode[] args;
    
    ASTNode targer;

    this(ASTNode parent, SRCLocation loc, ASTNode lhs, ASTNode[] args)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.args = args;
    }

    override string getDescription()
    {
        return "function call";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTIdentifier : ASTNode
{
    string name;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, string name)
    {
        super(parent, loc);
        this.name = name;
    }

    override string getDescription()
    {
        return "identifier";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTDispatch : ASTNode
{
    ASTNode lhs;
    string name;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode lhs, string name)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.name = name;
    }

    override string getDescription()
    {
        return "dispatch";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTAssign : ASTNode
{
    ASTNode lhs;
    string assign_op;
    ASTNode rhs;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode lhs, string assign_op, ASTNode rhs)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.assign_op = assign_op;
        this.rhs = rhs;
    }

    override string getDescription()
    {
        return "assignment";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTIndexExp : ASTNode
{
    ASTNode lhs;
    ASTNode[] indexes;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode lhs, ASTNode[] indexes)
    {
        super(parent, loc);
        this.lhs = lhs;
        this.indexes = indexes;
    }

    override string getDescription()
    {
        return "index";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTCast : ASTNode
{
    ASTNode typeNode;
    ASTNode exp;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode typeNode, ASTNode exp)
    {
        super(parent, loc);
        this.typeNode = typeNode;
        this.exp = exp;
    }

    override string getDescription()
    {
        return "cast";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTNew : ASTNode
{
    ASTNode typeNode;
    ASTNode[] args;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode typeNode, ASTNode[] args)
    {
        super(parent, loc);
        this.typeNode = typeNode;
        this.args = args;
    }

    override string getDescription()
    {
        return "new expression";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTIntegerLiteral : ASTNode
{
    string value;
    
    Type type;
    
    this(ASTNode parent, SRCLocation loc, string value)
    {
        super(parent, loc);
        this.value = value;
    }

    override string getDescription()
    {
        return "integer literal";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTFloatLiteral : ASTNode
{
    string value;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, string value)
    {
        super(parent, loc);
        this.value = value;
    }

    override string getDescription()
    {
        return "float literal";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTStringLiteral : ASTNode
{
    string value;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, string value)
    {
        super(parent, loc);
        this.value = value;
    }

    override string getDescription()
    {
        return "string literal";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTCharacterLiteral : ASTNode
{
    string value;
    
    Type type;
    
    this(ASTNode parent, SRCLocation loc, string value)
    {
        super(parent, loc);
        this.value = value;
    }

    override string getDescription()
    {
        return "character literal";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

class ASTArrayLiteral : ASTNode
{
    ASTNode[] value;
    
    Type type;

    this(ASTNode parent, SRCLocation loc, ASTNode[] value)
    {
        super(parent, loc);
        this.value = value;
    }

    override string getDescription()
    {
        return "array literal";
    }

    mixin Accepter!(ASTVisitor);
    mixin PrettyPrinter!(ASTNode);
}

interface ASTVisitor
{
    void visit(ASTImport that);
    void visit(ASTModule that);
    void visit(ASTDef that);
    void visit(ASTFunction that);
    void visit(ASTTemplate that);
    void visit(ASTStruct that);
    void visit(ASTClass that);
    void visit(ASTInterface that);
    void visit(ASTTemplateInstance that);
    void visit(ASTIf that);
    void visit(ASTElse that);
    void visit(ASTSwitch that);
    void visit(ASTCase that);
    void visit(ASTFor that);
    void visit(ASTForeach that);
    void visit(ASTWhile that);
    void visit(ASTDo that);
    void visit(ASTBreak that);
    void visit(ASTJump that);
    void visit(ASTUnaryExp that);
    void visit(ASTTinaryExp that);
    void visit(ASTCallExp that);
    void visit(ASTIdentifier that);
    void visit(ASTDispatch that);
    void visit(ASTAssign that);
    void visit(ASTIndexExp that);
    void visit(ASTCast that);
    void visit(ASTNew that);
    void visit(ASTIntegerLiteral that);
    void visit(ASTFloatLiteral that);
    void visit(ASTStringLiteral that);
    void visit(ASTCharacterLiteral that);
    void visit(ASTArrayLiteral that);
}

/+
void visit(ASTImport that) {}

void visit(ASTModule that)
{
    foreach(node;that.moduleBody)
        node.accept(this);
}

void visit(ASTDef that)
{
    that.typeNode.accept(this);
    that.exp.accept(this);
}

void visit(ASTFunction that)
{
    that.typeNode.accept(this);
    foreach(arg;that.args)
        node.accept(this);
    foreach(node;that.funcBody)
        node.accept(this);
}
void visit(ASTTemplate that)
{
    foreach(node;that.templateBody)
        node.accept(this);
}

void visit(ASTStruct that)
{
    foreach(node;that.structBody)
        node.accept(this);
}

void visit(ASTClass that)
{
    foreach(node;that.inherits)
        node.visit(this);
    foreach(node;that.classBody)
        node.accept(this);
}

void visit(ASTInterface that)
{
    foreach(node;that.inherits)
        node.visit(this);
    foreach(node;that.interfaceBody)
        node.accept(this);
}

void visit(ASTTemplateInstance that)
{
    that.lhs.visit(this);
    foreach(arg;that.arg)
        arg.visit(this);
}

void visit(ASTIf that)
{
    that.cond.accept(this);
    foreach(node;that.ifBody)
        node.accept(this);
    if(that.else_ !is null)
       that.else_.accept(this);
} 

void visit(ASTElse that)
{
    foreach(node;that.elseBody)
        node.accept(this);
}

void visit(ASTSwitch that)
{
    that.cond.accept(this);
    foreach(node;that.cases)
        node.accept(this);
}

void visit(ASTCase that)
{
    foreach(node;that.caseBody)
        node.accept(this);
}

void visit(ASTFor that)
{
    if (that.def !is null)
        that.def.accept(this);
    if (that.cond !is null)
        that.cond.accept(this);
    if (that.exp !is null)
        that.exp.accept(this);
    foreach(node;that.forBody)
        node.accept(this);
}

void visit(ASTForeach that)
{
    foreach(node;that.defs)
        node.accept(this);
    that.exp.accept(this);
    foreach(node;that.foreachBody)
        node.accept(this);
}

void visit(ASTWhile that)
{
    that.cond.accept(this);
    foreach(node;that.whileBody)
        node.accept(this);
}

void visit(ASTDo that)
{
    foreach(node;that.doBody)
        node.accept(this);
    that.cond.accept(this);
}

void visit(ASTBreak that) {}

void visit(ASTJump that) {}

void visit(ASTUnaryExp that)
{
    that.s.accept(this);
}

void visit(ASTBinaryExp that)
{
    that.lhs.accept(this);
    that.rhs.accept(this);
}

void visit(ASTTinaryExp that)
{
    that.cond.accept(this);
    that.lhs.accept(this);
    that.rhs.accept(this);
}

void visit(ASTCallExp that)
{
    that.lhs.accept(this);
    foreach(node;that.args)
        node.accept(this);
}

void visit(ASTIdentifier that) {}

void visit(ASTDispatch that)
{
    that.lhs.accept(this);
}

void visit(ASTAssign that)
{
    that.lhs.accept(this);
    that.rhs.accept(this);
}

void visit(ASTIndexExp that)
{
    that.lhs.accept(this);
    foreach(node;that.indexes)
        node.accept(this);
}

void visit(ASTCast that)
{
    that.typeNode.accept(this);
    that.exp.accept(this);
}

void visit(ASTNew that)
{
    that.typeNode.accept(this);
    foreach(node;that.args)
        node.visit(this);
}

void visit(ASTIntegerLiteral that) {}

void visit(ASTFloatLiteral that) {}

void visit(ASTStringLiteral that) {}

void visit(ASTCharacterLiteral that) {}

void visit(ASTArrayLiteral that)
{
    foreach(node;that.value)
        node.visit(this);
}
+/
