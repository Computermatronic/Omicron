module omc.type;

enum Traits
{
    none = 0,
    isNumeric = 1 << 1,
    isInteger = 1 << 2,
    isFloating = 1 << 3,
    isUnsigned = 1 << 4,
}

abstract class Type
{
    string name;
    size_t size;
    Triats traits;

    //Type checking
    abstract bool assignOpIsSupported(string op, Type inputType);
    abstract bool unaryOpIsSupported(string op);
    abstract bool binaryOpIsSupported(string op, Type inputType);
    abstract bool implicitCastOpIsSupported(Type castType);
    abstract bool castOpIsSupported(Type castType);
    abstract bool callOpIsSupported(Type[] argTypes);
    abstract bool newOpIsSupported(Type[] argTypes);
    abstract bool indexOpIsSuppored(Type[] argTypes);
    abstract bool hasMember(string name, Type[] argTypes = null);

    //Type info
    abstract Type assignOpType(string op, Type inputType);
    abstract Type urnayOpType(string op);
    abstract Type binayOpType(string op, Type inputType);
    abstract Type callOpType(Type[] argTypes);
    abstract Type newOpType(Type[] argTypes);
    abstract Type IndexOpType(Type[] argTypes);
    abstract Type memberType(string name, Type[] argTypes = null);
    
    static PtrType[Type] ptrTypes;
    
    static PtrType getPtrType(Type type)
    {
        auto ptr = type in this.ptrTypes;
        if (ptr !is null)
            return *ptr;
        auto ptrType = new PtrType(type);
        ptrTypes[type] = ptrType;
        return ptrType;
    }
}

class BoolType : Type
{
    this()
    {
        this.name == "bool";
        this.size = 1;
    }

    bool assignOpIsSupported(string op, Type inputType)
    {
        if (op == "=")
            return true;
        return false;
    }

    bool unaryOpIsSupported(string op)
    {
        if (op == "!")
            return true;
        return false;
    }

    bool binaryOpIsSupported(string op, Type inputType)
    {
        if (op == "==" || op == "!=")
            return true;
        return false;
    }

    bool implicitCastOpIsSupported(Type castType)
    {
        return false;
    }

    bool castOpIsSupported(Type castType)
    {
        return false;
    }

    bool callOpIsSupported(Type[] argTypes)
    {
        return false;
    }

    bool newOpIsSupported(Type[] argTypes)
    {
        if (args.length == 0)
            return true;
        if (args.length == 1 && args[0] == this)
            return true;
        return false;
    }

    bool indexOpIsSuppored(Type[] argTypes)
    {
        return false;
    }

    bool hasMember(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return true;
        case "size":
            return true;
        default:
            return false;
        }
    }

    //Type info
    Type assignOpType(string op, Type inputType)
    {
        return this;
    }

    Type urnayOpType(string op)
    {
        return this;
    }

    Type binayOpType(string op, Type inputType)
    {
        return this;
    }

    Type callOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type newOpType(Type[] argTypes)
    {
        return getPtrType(this);
    }

    Type IndexOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type memberType(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return this;
        case "size":
            return getSizeType();
        default:
            assert(0, "Compiler BUG!!");
        }
    }
}

class ByteType : Type
{
    this()
    {
        this.name == "byte";
        this.size = 1;
        this.traits = Traits.isNumeric | Traits.isInteger;
    }

    mixin IntegerBehavour!();
}

class UbyteType : Type
{
    this()
    {
        this.name == "ubyte";
        this.size = 1;
        this.traits = Traits.isNumeric | Traits.isInteger | Traits.isUnsigned;
    }

    mixin IntegerBehavour!();
}

class ShortType : Type
{
    this()
    {
        this.name == "short";
        this.size = 2;
        this.traits = Traits.isNumeric | Traits.isInteger;
    }

    mixin IntegerBehavour!();
}

class UshortType : Type
{
    this()
    {
        this.name == "ushort";
        this.size = 2;
        this.traits = Traits.isNumeric | Traits.isInteger | Traits.isUnsigned;
    }

    mixin IntegerBehavour!();
}

class IntType : Type
{
    this()
    {
        this.name == "int";
        this.size = 4;
        this.traits = Traits.isNumeric | Traits.isInteger;
    }

    mixin IntegerBehavour!();
}

class UintType : Type
{
    this()
    {
        this.name == "uint";
        this.size = 4;
        this.traits = Traits.isNumeric | Traits.isInteger | Traits.isUnsigned;
    }

    mixin IntegerBehavour!();
}

class LongType : Type
{
    this()
    {
        this.name == "long";
        this.size = 8;
        this.traits = Traits.isNumeric | Traits.isInteger;
    }

    mixin IntegerBehavour!();
}

class UlongType : Type
{
    this()
    {
        this.name == "ulong";
        this.size = 8;
        this.traits = Traits.isNumeric | Traits.isInteger | Traits.isUnsigned;
    }

    mixin IntegerBehavour!();
}

class Float : Type
{
    this()
    {
        this.name = "float";
        this.size = 4;
        this.traits = Traits.isNumeric | Traits.isFloating;
    }
    
    mixin FloatingBehavour!();
}

class Double : Type
{
    this()
    {
        this.name = "double";
        this.size = 8;
        this.traits = Traits.isNumeric | Traits.isFloating;
    }
    
    mixin FloatingBehavour!();
}

class Real : Type
{
    this()
    {
        this.name = "real";
        this.size = 10;
        this.traits = Traits.isNumeric | Traits.isFloating;
    }
    
    mixin FloatingBehavour!();
}

class PtrType : Type
{
    Type wrappedType;
    
    this(Type wrappedType)
    {
        this.name = wrappedType.name ~ "*";
        this.size = m64 ? 8 : 4;
        this.wrappedType = wrappedType;
    }
}

mixin template IntegerBehavour()
{
    bool assignOpIsSupported(string op, Type inputType)
    {
        if (op != "=~" && inputType.implicitCastOpIsSupported(this))
            return true;
        return false;
    }

    bool unaryOpIsSupported(string op)
    {
        if (op != "*")
            return true;
        return false;
    }

    bool binaryOpIsSupported(string op, Type inputType)
    {
        if (op != "~" && this.castOpIsSupported(inputType))
            return true;
        return false;
    }

    bool implicitCastOpIsSupported(Type castType)
    {
        return (castType.traits & Traits.isInteger) == Traits.isInteger && castType.size >= this.size;
    }

    bool castOpIsSupported(Type castType)
    {
        return (castType.traits & Traits.isNumeric) == Traits.isNumeric;
    }

    bool callOpIsSupported(Type[] argTypes)
    {
        return false;
    }

    bool newOpIsSupported(Type[] argTypes)
    {
        if (args.length == 0)
            return true;
        if (args.length == 1 && args[0].implisitCastOpIsSupported(this))
            return true;
        return false;
    }

    bool indexOpIsSuppored(Type[] argTypes)
    {
        return false;
    }

    bool hasMember(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return true;
        case "size":
            return true;
        case "min":
            return true;
        case "max":
            return true;
        default:
            return false;
        }
    }

    //Type info
    Type assignOpType(string op, Type inputType)
    {
        return this;
    }

    Type urnayOpType(string op)
    {
        if (op == "&")
            return getPtrType(this);
        return this;
    }

    Type binayOpType(string op, Type inputType)
    {
        return inputType.size > this.size ? inputType : this; //integer promotion.
    }

    Type callOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type newOpType(Type[] argTypes)
    {
        return getPtrType(this);
    }

    Type IndexOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type memberType(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return this;
        case "size":
            return getSizeType();
        case "min":
            return this;
        case "max":
            return this;
        default:
            assert(0, "Compiler BUG!!");
        }
    }
}

mixin template FloatingBehavour()
{
    bool assignOpIsSupported(string op, Type inputType)
    {
        if (op != "=~" && inputType.implicitCastOpIsSupported(this))
            return true;
        return false;
    }

    bool unaryOpIsSupported(string op)
    {
        if (op != "*")
            return true;
        return false;
    }

    bool binaryOpIsSupported(string op, Type inputType)
    {
        if (op != "~" && this.castOpIsSupported(inputType))
            return true;
        return false;
    }

    bool implicitCastOpIsSupported(Type castType)
    {
        return (castType.traits & Traits.isFloating) == Traits.isFloating
            && castType.size >= this.size;
    }

    bool castOpIsSupported(Type castType)
    {
        return (castType.traits & Traits.isNumeric) == Traits.isNumeric;
    }

    bool callOpIsSupported(Type[] argTypes)
    {
        return false;
    }

    bool newOpIsSupported(Type[] argTypes)
    {
        if (args.length == 0)
            return true;
        if (args.length == 1 && args[0].implisitCastOpIsSupported(this))
            return true;
        return false;
    }

    bool indexOpIsSuppored(Type[] argTypes)
    {
        return false;
    }

    bool hasMember(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return true;
        case "size":
            return true;
        case "min":
            return true;
        case "max":
            return true;
        case "nan":
            return true;
        case "infinity":
            return true;
        default:
            return false;
        }
    }

    //Type info
    Type assignOpType(string op, Type inputType)
    {
        return this;
    }

    Type urnayOpType(string op)
    {
        if (op == "&")
            return getPtrType(this);
        return this;
    }

    Type binayOpType(string op, Type inputType)
    {
        return inputType.size > this.size ? inputType : this; //integer promotion.
    }

    Type callOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type newOpType(Type[] argTypes)
    {
        return getPtrType(this);
    }

    Type IndexOpType(Type[] argTypes)
    {
        assert(0, "Compiler BUG!!");
    }

    Type memberType(string name, Type[] argTypes = null)
    {
        switch (name)
        {
        case "init":
            return this;
        case "size":
            return getSizeType();
        case "min":
            return this;
        case "max":
            return this;
        case "nan":
            return this;
        case "infinity":
            return this;
        default:
            assert(0, "Compiler BUG!!");
        }
    }
}
