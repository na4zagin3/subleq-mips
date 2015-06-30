define(`ARCH',`subleqr')
include(`subleq-lib.sq.m4')

@srl1dTest Rh, Rl
$(@@sl1d Rh, Rl, End);

@mflo Rd,Lo
Rd;
Lo Z;
Z Rd;
Z Z End;

@mtlo Lo,Rs
Lo;
Rs Z;
Z Lo;
Z Z End;

@sltu Rd,Rs,Rt
Min Rs; Min Rt;
$(@@sltSub Rd,Rs,Rt,T0,Finish);
Finish:Min Rs; Min Rt; Z Z End;

@multD Hi, Lo, Rs, Rt // destructive
Inc T4; $(@@jnzp Rs, Lsn, Clear, Lsp);
Lsn:Inc T4; $(@@neg Rs, Rs, T0, Lsp);
Lsp:$(@@jnzp Rt, Ltn, Clear, Ltp);
Ltn:Inc T4; $(@@neg Rt, Rt, T0, Lsp);
Ltp:$(@@multuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, Lneg);
Lneg:Dec T4 Finish;
$(@@inv Hi, Hi, T0, LinvL);
LinvL:$(@@inv Lo, Lo, T0, Linc);
Linc:$(@@addc Hi, Lo, Dec, T0, Lneg);
Clear:Hi; Lo Lo;
Finish:T4 T4 End;

@mult Hi, Lo, Rs, Rt
Rs T5; Rt T6;
Inc T4; $(@@jnzp Rs, Lsn, Clear, Lsp);
Lsn:Inc T4; $(@@neg Rs, Rs, T0, Lsp);
Lsp:$(@@jnzp Rt, Ltn, Clear, Ltp);
Ltn:Inc T4; $(@@neg Rt, Rt, T0, Lsp);
Ltp:$(@@multuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, Lneg);
Lneg:Dec T4 Finish;
$(@@inv Hi, Hi, T0, LinvL);
LinvL:$(@@inv Lo, Lo, T0, Linc);
Linc:$(@@addc Hi, Lo, Dec, T0, Lneg);
Clear:Hi; Lo Lo;
Finish:Rs; T5 Rs; T5; Rt; T6 Rt; T6; T4 T4 End;

@slt Rd,Rs,Rt
$(@@sltSub Rd,Rs,Rt,T0,End);

@syscall Rd
Rd;
2 Z;
Z Rd;
Z Z End;

@addu Rd,Rs,Rt
$(@@add Rd, Rs, Rt, End);

@subu Rd,Rs,Rt
Rs Z;
Rt T0;
T0 Z;
T0;
Rd;
Z Rd;
Z Z End;

@shl1 Rd,Rs
Rs Z; // Z <- -Rs, it assumes Z = 0
Rs Z; // Z <- Z - Rt = -(Rs + Rt)
Rd; // clear Rd
Z Rd;
Z Z End;

@bne Rs, Rt, Offset, PCq // I assume Offset is already sign-extended.
	Rs T1; T1 T2; Rt T2;
	Inc T2 LFinish;
	Dec T2 LTaken;
	LFinish:T1; T2 T2 End;
	LTaken:Offset Z; Z PCq; Z Z LFinish;

@bnea Rs, Offset, PCq // I assume Offset is already sign-extended.
	Rs T1; T1 T2; Rs T2;
	Inc T2 LFinish;
	Dec T2 LTaken;
	LFinish:T1; T2 T2 End;
	LTaken:Offset Z; Z PCq; Z Z LFinish;

@sll Rd, Rt, Sa
$(@@sllsub Rd, Rt, Sa, T0, T1, End);

@srl Rd, Rt, Sa
$(@@srlsub Rd, Rt, Sa, T0, T1, End);

@sra Rd, Rt, Sa
$(@@srasub Rd, Rt, Sa, T0, T1, T2, End);

@srlS Rd, Rt, Sa // Original Subleq
Rt T1; Rd;
Sa T0; CW Sa;
Loop:Inc Sa LBody;
LFinish:Sa; T0 Sa; T0; Rt; T1 Rt; T1 T1 End;
LBody:$(@@sl1d Rd, Rt, Loop);

@sraO Rd, Rt, Sa
Rt T1; Rd;
$(@@jnzp Rt, Ln, Lzp, Lzp);
Ln:Dec Rd;
Lzp:Sa T0; CW Sa;
Loop:Inc Sa LBody;
LFinish:Sa; T0 Sa; T0; Rt; T1 Rt; T1 T1 End;
LBody:$(@@sl1d Rd, Rt, Loop);

@srl1dcTest Rd, Rh, Rl
$(@@sl1dc Rd, Rh, Rl, End);

@srl1Test Rd, Rs
$(@@srl1 Rd, Rs, End);

@multu Hi, Lo, Rs, Rt
$(@@multuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, End);

@jezoTest R
$(@@jezo R, Le, Lz, Lo);
Le:R; Inc R End; Z Z End;
Lz:R; Z Z End;
Lo:R; Dec R End; Z Z End;

