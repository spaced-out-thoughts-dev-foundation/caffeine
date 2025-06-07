# Formal Specification

## Overview

Caffeine is a domain specific language (DSL) for specifying the intents of a system from which service level objectives (SLOs) can be defined. Intent is described in formulaic prose alongside system metadata such as constraints.

## Concrete Syntax

```
SYSTEM                 ::= SERVICE { NEWLINE SERVICE } ;

SERVICE                ::= ALPHANUM_STR RELIABILITY_STATEMENTS DEPENDENCY_STATEMENT ;

RELIABILITY_STATEMENTS ::= RELIABILITY_STATEMENT { 'and' RELIABILITY_STATEMENT } ;
RELIABILITY_STATEMENT  ::= 'is' 'expected' 'to' 'be' 'available' THRESHOLD 'of' 'the' 'time' ;

THRESHOLD              ::= DIGITS [ FRACTION ] '%' ;
FRACTION               ::= '.' DIGITS ;
DIGITS                 ::= DIGIT { DIGIT } ;
DIGIT                  ::= '0'..'9' ;

DEPENDENCY_STATEMENT   ::= 'and' 'has' DEPENDENCY_TYPE ;

DEPENDENCY_TYPE        ::= NO_DEPENDENCY | SINGLE_DEPENDENCY | MULTI_DEPENDENCY ;

NO_DEPENDENCY          ::= 'no dependencies.' ;
SINGLE_DEPENDENCY      ::= 'a dependency on' ALPHANUM_STR '.' ;
MULTI_DEPENDENCY       ::= 'dependencies on' ALPHANUM_STR 'and' ALPHANUM_STR '.'
                         | 'dependencies on' ALPHANUM_STR { ',' ALPHANUM_STR } ',' 'and' ALPHANUM_STR '.' ;

ALPHANUM_STR           ::= ALPHANUM_CHAR { ALPHANUM_CHAR } ; 
ALPHANUM_CHAR          ::= 'a'..'z' | 'A'..'Z' | '0'..'9' ;

NEWLINE                ::= '\n' ;
```

## Example

```caffeine
service_a is expected to be available 99.9% of the time and has dependencies on service_b, and service_d.

service_b is expected to be available 99.99% of the time and has no dependencies.

service_c is expected to be availble 99.9% of the time and has a dependency on service_b.

service_d is expected to be available 99% of the time and has no dependencoes.
```