"Autum Expressions"
module AExpressions

using MLStyle
export AExpr

export istypesymbol,
       istypevarsymbol,
       args,
       arg,
       wrap

const autumngrammar = """
x           := a | b | ... | aa ...
program     := statement* 
statement   := externaldecl | assignexpr | typedecl | typedef

typedef     := type fields  #FIXME
fields      := field | fields field
field       := constructor | constructor typesymbol*
cosntructor := typesymbol

typedecl    := x : typeexpr
externaldecl:= external typedecl

assignexpr  := x = valueexpr

typeexpr    := typesymbol | paramtype | typevar | functiontype
funtype     := typeexpr -> typeexpr
producttype := typeexpr × typexexpr × ...
typesymbol  := primtype | customtype
primtype    := Int | Bool | Float
custontype  := A | B | ... | Aa | ...

valueexpr   := fappexpr | lambdaexpr | iteexpr | initnextexpr | letexpr |
               this | lambdaexpr
iteexpr     := if expr then expr else expr
intextexpr  := init expr next expr
fappexpr    := valueexpr valueexpr*
letexpr     := let x = valueexpr in valueexpr
lambdaexpr  := x -> expr
"""

"Autumn Expression"
struct AExpr
  head::Symbol
  args::Vector{Any}
  AExpr(head::Symbol, @nospecialize args...) = new(head, [args...])
end
"Arguements of expression"
function args end

args(aex::AExpr) = aex.args
head(aex::AExpr) = aex.head
args(ex::Expr) = ex.args

"Expr in ith location in arg"
arg(aex, i) = args(aex)[i]

Base.Expr(aex::AExpr) = Expr(aex.head, aex.args...)

# wrap(expr::Expr) = AExpr(expr)
# wrap(x) = x

# AExpr(xs...) = AExpr(Expr(xs...))

# function Base.getproperty(aexpr::AExpr, name::Symbol)
#   expr = getfield(aexpr, :expr)
#   if name == :expr
#     expr
#   elseif name == :head
#     expr.head
#   elseif name == :args
#     expr.args
#   else
#     error("no property $name of AExpr")
#   end
# end


# Expression types
"Is `sym` a type symbol"
istypesymbol(sym) = (q = string(sym); length(q) > 0 && isuppercase(q[1]))
istypevarsymbol(sym) = (q = string(sym); length(q) > 0 && islowercase(q[1]))

# ## Printing
isinfix(f::Symbol) = f ∈ [:+, :-, :/, :*]
isinfix(f) = false

"Pretty print"
function showstring(expr::Expr)
  @match expr begin
    Expr(:program, statements...) => join(map(showstring, expr.args), "\n")
    Expr(:producttype, ts) => join(map(showstring, ts), "×")
    Expr(:functiontype, int, outt) => "$(showstring(int)) -> $(showstring(outt))"
    Expr(:typedecl, x, val) => "$x : $(showstring(val))"
    Expr(:external, td) => "external $(showstring(td))"
    Expr(:assign, x, val) => "$x = $(showstring(val))"
    Expr(:if, i, t, e) => "if $(showstring(i)) then $(showstring(t)) else $(showstring(e))"
    Expr(:initnext, i, n) => "init $(showstring(i)) next $(showstring(n))"
    Expr(:fn, args, body) => "λ $(showstring(args)) -> $(showstring(body))"
    Expr(:args, args...) => join(map(showstring, args), " ")
    Expr(:call, f, arg1, arg2) && if isinfix(f) end => "$(showstring(arg1)) $f $(showstring(arg2))"
    Expr(:call, f, args...) => join(map(showstring, [f ; args]), " ")
    x                       => "Fail $x"

    # Expr(:let, x)
    # Parametric types
    # type def
    # Lambda expression
  end
end

showstring(aexpr::AExpr) = showstring(Expr(aexpr))
showstring(s::Union{Symbol, Integer}) = s
showstring(s::Type{T}) where {T <: Number} = s
Base.show(io::IO, aexpr::AExpr) = print(io, showstring(aexpr))

# # # Methods
# # "Number of nodes in expression tree"
# # nnodes(aexpr::AExpr) = 1 + reduce(+nnodes, args(aexpr))
# # nnodes(_) = 1

end