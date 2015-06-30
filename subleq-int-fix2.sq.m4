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

@@sltSub Rd,Rs,Rt, T0, AEnd
Rt T0; Rd;
Z Rs Lsnz;
Lsp:Z Rt Lf;
Lsptp:Rd Rd Lcomp;
Lsnz:Z Rt Lcomp;
Lsnztp:Rd Rd Lt;
Lcomp:Rs Rt;
$(@@jnzp Rt, Lf, Lf, Lt);
Lt:Inc Rd;
Lf:Rt; T0 Rt; T0 T0 AEnd;

@syscall Rd
Rd;
2 Z;
Z Rd;
Z Z End;

@addu Rd,Rs,Rt
Rs Z; // Z <- -Rs, it assumes Z = 0
Rt Z; // Z <- Z - Rt = -(Rs + Rt)
Rd; // clear Rd
Z Rd;
Z Z End;

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

@@sllsub Rd, Rt, Sa, S1, S2, Aend
Rt S2; Rd; S2 Rd;
Sa S1; // S1 = -Sa
Loop:Inc S1 LBody;
LFinish:S2; S1 S1 Aend;
LBody:S2 Rd; S2; Rd S2; Z Z Loop;

@srl Rd, Rt, Sa
Rt T1; Rd;
Sa T0; CW Sa;
Loop:Inc Sa LBody;
LFinish:Sa; T0 Sa; T0; Rt; T1 Rt; T1 T1 End;
LBody:$(@@sl1d Rd, Rt, Loop);

@sra Rd, Rt, Sa
Rt T1; Rd;
$(@@jnzp Rt, Ln, Lzp, Lzp);
Ln:Dec Rd;
Lzp:Sa T0; CW Sa;
Loop:Inc Sa LBody;
LFinish:Sa; T0 Sa; T0; Rt; T1 Rt; T1 T1 End;
LBody:$(@@sl1d Rd, Rt, Loop);

@@sl1d Ah, Al, Aend // {1'd_, Ah, Al} <- {Ah, Al, 1'd0}
$(@@sl1m Ah, L1); L1:Z Al Lzn;
Lp:$(@@sl1m Al, Aend);
Lzn:Inc Al Ln; Dec Al Lp;
Ln:Dec Al; Inc Ah; $(@@sl1m Al, Aend);

@srl1dcTest Rd, Rh, Rl
$(@@sl1dc Rd, Rh, Rl, End);

@@sl1dc Ad, Ah, Al, Aend
$(@@sl1m Ah, L1); L1:Ad;
Z Al Lzn;
Lp:$(@@sl1m Al, Aend);
Lzn:Inc Al Ln; Dec Al Lp;
Ln:Dec Al; Inc Ad; Inc Ah; $(@@sl1m Al, Aend);

@@sl1c Ad, Al, Aend // {Ad, Al} <- {残り ,Al, 1'd0}
L1:Ad;
Z Al Lzn;
Lp:$(@@sl1m Al, Aend);
Lzn:Inc Al Ln; Dec Al Lp;
Ln:Dec Al; Inc Ad; $(@@sl1m Al, Aend);

@@sl1 Ad, As, Aend
As Z; Ad; Z Ad; Z Ad; Z Z Aend;

@@sl1m A, Aend // {1'd_, A} <- {A, 1'd0}
A Z; Z A; Z Z Aend;

@@jnzp A, An, Az, Ap
Z A Lzn; Z Z Ap;
Lzn:Inc A Ln; Dec A Az;
Ln:Dec A An;

@@addc Ah, Al, A, T, Aend
$(@@jnzp Al, Lln, Llp, Llp);
Lln:Inc T;
Llp:$(@@jnzp A, Lan, Lap, Lap);
Lan:Inc T;
Lap:A Z; Z Al; Z;
$(@@jnzp Al, Lxn, Lxp, Lxp);
Lxn:Dec T;
Lxp:Z T Ltnz;
Ltp:Inc Ah;
Ltnz:T T Aend;

@multu Hi, Lo, Rs, Rt
$(@@multuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, End);

@@multuDumbSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, End
Lo; Hi; Rs T1;
Loop:Z Rs Lnz;
Lp:Dec Rs; $(@@addc Hi, Lo, Rt, T0, Loop);
Lnz:Inc Rs Ln; 
LFinish:T0; Rs; T1 Rs; T1 T1 End;
Ln:Dec Dec Rs; Z Z Lp;

@@multuDumbSub2 Hi, Lo, Rs, Rt, T0, T1, T2, T3, End
Lo; Hi; Rs T1;
Loop:$(@@jnzp Rs, LBody, LFinish, LBody);
LFinish:T0; Rs; T1 Rs; T1 T1 End;
LBody:Dec Rs; $(@@addc Hi, Lo, Rt, T0, Loop);

@@multuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, End
Lo; Rs T1;
CW T0;
Loop:Inc T0 LBody;
LFinish:T0; Rs; T1 Rs; T1; T3 T3 End;
LBody:$(@@sl1d Hi, Lo, LBody2);
LBody2:$(@@sl1c T3, Rs, LBody3);
LBody3:Z T3 Loop;
$(@@addc Hi, Lo, Rt, T2, Loop);

@@neg Ad, A, T, Aend
A Z; Z T; Ad; T Ad; T; Z Z Aend;

@@inv Ad, A, T, Aend
$(@@neg Ad, A, T, L);
L:Dec Ad Aend;

@@divuSub Hi, Lo, Rs, Rt, T0, T1, T2, T3, End
Hi; Rs T1;
CW T0;
Loop:Inc T0 LBody;
LFinish:T0; Rs; T1 Rs; T3; T1 T1 End;
LBody:$(@@sl1m Lo); $(@@sl1d Hi, Rs, LBody2);
LBody2:T2; Rs T2; Rt Rs; $(@@jnzp Rs, LResume, LNext, LNext);
LNext:End; // we must fix
LResume:Rs; T2 Rs; T2 T2;
$(@@addc Hi, Lo, Rt, T2, Loop);

