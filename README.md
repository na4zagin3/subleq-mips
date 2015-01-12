# subleq-mips
Implementation of MIPS instructions with subleq

# Architecture
## Registers
Each registers is mapped to the memory.

| Address | Meaning |
|---------|---------|
| R0-R15 (=0x100-0x10f) | General registers |
| PC | |
| lo, hi (=0x120-0x121) | for multiplication |
| trap | interruption |

## Aliases
There are a few aliases.

| Address | Comment |
|---------|---------|
| Rd, Imm (0) | |
| Rs (1) | |
| Rt (2) | |
| Mem (3) | the location whither the indirect reference points |

## Special Registers
For internal use.
It allows to modify, but it should be resumed at the end of the subroutine.

| Address | Comment |
|---------|---------|
| inc (4) | stores (-1) |
| dec (5) | stores (+1) |
| Z (6) | stores 0 |
| T0-T7 (8-f) | temporary registers, stores 0 |

## Special Addresses
Following jump addresses have special meanings.

| Address | Comment |
|---------|---------|
| End (-1)| implementation is end |

## Subroutine
Name of subroutine that implements a MIPS instruction is "`@[a-z]+`".

## Macros
Name of macro is "`@@[a-z]+`".
Arguments of a macro are "`A[:alnum:]*`".
Macro expansion is like "`(@@name Arg0,Arg1,Arg2)`".

# Format
Format is as shown.
The scope of internal labels "`L[:alnum:]*`" is limited in a routine or a macro where the label lexically exists.

## Examples
```
@add Rd,Rs,Rt
Rs Z; // Z <- -Rs, it assumes Z = 0
Rt Z; // Z <- Z - Rt = -(Rs + Rt)
Rd; // clear Rd
Z Rd;
Z Z End;
```
becomes (and I assume `@add` is placed 0x1000)
```
1 6 3
2 6 6
0 0 9
6 0 c
6 6 -1
```

```
@mult Rs,Rt // incomplete
Z Rs Lns;                   // if Rs < 0 then Lns else Lps
Lps:Rs Z; Z T2; Z Z Lmultu; // T2 <- Rs  = abs(Rs)
Lns:Rs T2; dec T1;          // T2 <- -Rs = abs(Rs), T1 <- -1  
Lmultu:lo;                  // it's ok because Rt and lo are not aliased.
(@@multu lo,T2,Rt,Linv);    // lo <- abs(Rs) * (-Rt)
Linv:Z T1 Lend;             // if Rs < 0 (i.e. T1 < 0) then Lend else next
lo T1; T1 Z; lo; Z lo Lend; // (in this case Rs >= 0 and T1 = 0), lo <- -lo
Lend:T1; T2; Z Z End;

@@multu Ad,Ax,Ay,Aend // internal subroutine macro: Ad <- Ax * (-Ay) + Ad; assumes Ax >= 0; modifies Ax, Ad
Lloop:dec Ax Aend;
Ay Ad Lloop;
```
is equivalent to
```
@mult Rs,Rt // incomplete
Z Rs Lns;                   // if Rs < 0 then Lns else Lps
Lps:Rs Z; Z T2; Z Z Lmultu; // T2 <- Rs  = abs(Rs)
Lns:Rs T2; dec T1;          // T2 <- -Rs = abs(Rs), T1 <- -1  
Lmultu:lo;                  // it's ok because Rt and lo are not aliased.
// (@@multu lo,T2,Rt,Linv);    // lo <- abs(Rs) * (-Rt)
Lmultuloop:dec T2 Linv;
Rt lo Lmultuloop;

Linv:Z T1 Lend;             // if Rs < 0 (i.e. T1 < 0) then Lend else next
lo T1; T1 Z; lo; Z lo Lend; // (in this case Rs >= 0 and T1 = 0), lo <- -lo
Lend:T1; T2; Z Z End;
```
and (and I assume `@mult` is placed 0x2000)
```
2000:   6   1 2006 // Z Rs Lns;
2003:   1   6 2006 // Lps:Rs Z;
2006:   6  10 2009 // Z T2;
2009:   6   6 2012// Z Z Lmultu
200c:   1  10 200f // Lns:Rs T2;
200f:   5   9 2012 // dec T1;
2012: 120 120 2015 // Lmultu:lo;
2015:   5  10 201b // Lmultuloop:dec T2 Linv;
2018:   3 120 2015 // Rt lo Lmultuloop;
201b:   6   9 202a // Linv:Z T1 Lend;
201e: 120   9 2021 // lo T1;
2021:   9   6 2024 // T1 Z;
2024: 120 120 2027 // lo;
2027:   6 120 202a // Z lo Lend;
202a:   9   9 202d // Lend:T1;
202d:  10  10 2030 // T2;
2030:   6   6   -1 // Z Z End;
```
