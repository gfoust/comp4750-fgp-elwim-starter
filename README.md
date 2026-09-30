# Comp 4750 Project: Elwim Interpreter

## Overview

For this project we will start with a parser for the
[Elwim](https://cs.harding.edu/gfoust/classes/comp4750/projects/elwim/language) programming language
and convert it into an interpreter.  This will require designing a data type to use as an Abstract
Syntax Tree (AST), updating the parser to use your new type, and then implementing functions that
can execute your new type.

## The Starting Project

The project as you [downloaded](https://github.com/gfoust/comp4750-fgp-elwim-starter) it contains a
scanner and parser for Elwim.  It will read input from the standard input stream, scan it to find
tokens, then parse the tokens to build an AST.  It then prints the AST to the standard output
stream.

The project layout is as follows:
- **[Elwim]** - directory holding example Elwim programs (for testing purposes)
- **[Parser]** - directory holding modules related to parsing
  + **Ast.hs** - definition of simplistic AST type
  + **Impl.hs** - implementation for parsing methods
  + **Precedence.hs** - helper data structures for operator precedence
- **[Scanner]** - directory holding modules related to scanning
  + **Impl.hs** - implementation for scanning methods
  + **Token.hs** - definition of token and operator types
  + **TokenItr.hs** - definition of token iterator type which can be used to iterate over resulting
    tokens
- **[Source]** - directory holding modules related to source text
  + **Position.hs** - definition of type representing a position in the source text
  + **SourceItr.hs** - definition of source iterator type which can be used to iterate over source
    text string
- **Iterator.hs** - type class defining interface for iterator types
- **Main.hs** - application entry point
- **MoreIO.hs** - contains an IO action for reading a single number
- **Parser.hs** - front end to parser modules
- **Scanner.hs** - front end to scanner modules
- **Source.hs** - front end to source modules
- **Stream.hs** - definition of monad used for scanning and parsing


You will need to make a few changes to the existing program.  In particular, the existing AST type
(defined in [Parser/Ast.hs](Parser/Ast.hs)) is oversimplified. It contains only two forms: one for a leaf
node (no children) and one for an internal node (list of children).  This simplistic tree type would
be very difficult to work with: there is nothing distinguishing the different kinds of nodes.

## Project Requirements

### Step 1: Define better AST types

You will need to design and implement better types for representing a program.  You may simply add
your type definitions to [Parser/Ast.hs](Parser/Ast.hs), or you may create additional modules for
them if you prefer.

There are two major syntactic categories in Elwim:  *expressions* and *statements*.  You should
therefore create two different data types: one to represent expressions, and one to represent
statements.  You will notice in the
[Elwim language definition](https://cs.harding.edu/gfoust/classes/comp4750/projects/elwim/language)
that there are four different possible forms an expression can take, and eight different possible
forms a statement can take.  You will need to define a separate constructor for each one of these
forms.

As you define your constructors, consider carefully what data also needs to be stored for each
particular constructor.  Try to store only the data needed to know exactly what that language
structure represents.

Make sure that you can `show` your data types so that they can be printed to the screen.  The
default implementation of `show` will be fine.  You may also define your own if you want it to
look prettier, but make sure that it completely represents the data and structure of your type.

### Step 2: Modify the parser to construct values of your types instead of the `Ast` type

The only file you need to modify for this is [Parser/Impl.hs](Parser/Impl.hs).  Search for every
place an `Ast.Node` or `Ast.Leaf` is created, and modify it to create a value of either your
expression type or your statement type instead.  All the data you need to create your value should
already be in the function, although you may have to pattern match tokens in order to pull out
some of it. (See [Scanner/Token.hs](Scanner/Token.hs) for token definitions.)

As you make changes to parsing functions you will also have to modify their types as well.  The
functions you will be changing all return a value of type `Parser Ast`; you will need to swap out
`Ast` for either your expression type or your statement type depending on the function.

When there are no longer any references to `Ast.Node` or `Ast.Leaf` in
[Parser/Impl.hs](Parser/Impl.hs) then you may safely delete the `Ast` type (and its `Show`
instantiation).

At the end of step 2, you should be able to compile and run the Elwim parser again.  It should now
parse and print your AST types instead of the original `Ast` type.

Note that, while it is possible to view an Elwim program as a list of statements, the parser
actually wraps those statements in an implicit block (as if there were curly braces around the whole
program).  Thus, the return value of the parser is simply a single value (the block), not a list of
values.

### Step 3: Create execute/evaluate functions for your AST types

You will need to be able to evaluate values of your expression type, and execute objects of your
statement type.

Evaluating expressions is simple and stateless: expressions never perform I/O, and never modify
program state.  They may, however, need to look up the value of variables.  We use the term
*context* to refer to a data structure that allows you to store and retrieve variable values.  A
good data structure for a context is a map from strings to doubles.

For example, a signature for your evaluate function might look like this:

```hs
type Context = Data.Map.Map String

evaluate :: Context -> Expression -> Double
```

Statements are more complicated.  For one thing, they can perform I/O; therefore the execution
function will need to be an I/O action.  Also, they can make modifications to program state; i.e.,
change the values of variables.  Thus, they will need to not only take a context as a parameter,
but also return an updated context reflecting the resulting values of variables.

All together, that gives an IO action that takes (1) an AST statement, (2) a map of variable values,
and that returns an updated map of variable values.  You may recognize this as following the state
pattern, where the state is the map of variable values.


### Step 4: Modify the application to be an interpreter

Modify main so that your application will now execute Elwim programs instead of simply printing out
their ASTs.  To do this you should first parse the AST, then pass it off to your execution function.

Use the standard input stream as input for Elwim program input: turn the entire input stream into a
list of doubles that you can pass to your execute function.

Use `getArgs :: IO [String]` to get the list of program arguments.  Treat these as the names of
files that have Elwim programs.  For each file name, read the contents of that file, parse it
into an AST, then execute it.

The value of variables should persist between files.

