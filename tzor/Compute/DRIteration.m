(* ::Package:: *)

tzorIntegrate::usage = "tzorIntegrate is an integral form.";
loopCalc::usage = "loopCalc will integrate one loop bubble diagram.;"
feynCalcViaDR::usage = "feynCalcViaDR will give feynmaan integral via DRI.";


TzorDeclareHeader[FileNameJoin[{$TzorDirectory,"Compute/IBubble.wl"}]]
TzorDeclareHeader[FileNameJoin[{$TzorDirectory,"Algebra/DIracAlgebra.m"}]]


Begin["`Private`"]


giveIndex[fourVector[x_,\[Mu]_],x_]:={\[Mu]}
giveIndex[a_ b_,x_]:=Flatten[{giveIndex[a,x],giveIndex[b,x]}];
giveIndex[Dot[a_,b_],x_]:=Flatten[{giveIndex[a,x],giveIndex[b,x]}];
giveIndex[x_,y_]:=Nothing;
giveParaProgSets[FeynAmpD[lists__]]:={lists};
giveParaProgSets[a_ b_]:=Join[giveParaProgSets[a],giveParaProgSets[b]];
giveParaProgSets[a_]:={Nothing};
listToSequence[{a__}]:=a;


Format[tzorIntegrate[integral_,lists__],TraditionalForm]:=DisplayForm[RowBox[Join[Riffle[SubsuperscriptBox["\[Integral]",#[[2]],#[[3]]]&/@{lists},"\[DifferentialD]"<>ToString[#[[1]]]&/@{lists}],{integral}]]]
tzorIntegrate[0,__]:=0
tzorIntegrate[a_]:=a
tzorIntegrate[-a_, lists__]:=-tzorIntegrate[a,lists]


loopCalc[a_+b_,s0_]:=Block[{$IterationLimit = 8192},loopCalc[a,s0]+loopCalc[b,s0]]
loopCalc[a_?NumberQ,_]:=0
loopCalc[Times[a__] FeynAmpD[lists__]diracDelta[deltalists0__],s0_,OptionsPattern["D"->4]]:=Times[a]loopCalc[FeynAmpD[lists]diracDelta[deltalists0],s0,"D"->OptionValue["D"]]
loopCalc[FeynAmpD[lists__]diracDelta[deltalists0__],s0_,OptionsPattern["D"->4]]:=Module[
			{kloop=0, p =0, int = FeynAmpD[lists], s = s0,
			qtemp = Unique["TZORq"], result, deltalists ={ deltalists0},
			a0list=Flatten[{a}], pN  = {},notpN = {},indices  = {},index = 0},
(*kloop \:79ef\:5206\:7684\:5708\:52a8\:91cf\:ff0cp Bubble \:56fe\:7684\:5916\:52a8\:91cf*)
	kloop = deltalists[[1]];
	p =deltalists[[2]];
	a0list = Times@@a0list//.{symbol[p]p-> symbol[p]qtemp - symbol[p]kloop}//Expand;
	If[Head[a0list] ===Plus,
			a0list = Table[FactorList[a0list[[i]]],{i,Length[a0list]}],
			a0list ={FactorList[a0list]}];
	a0list = Table[#[[1]]^#[[2]]&/@a0list[[i]],{i,Length[a0list]}];
	pN = Select[#,(Length[Intersection[{symbol[kloop]kloop},Level[#,{0,Infinity}]]]=!=0)&]&/@a0list;
	notpN=Select[#,(Length[Intersection[{symbol[kloop]kloop},Level[#,{0,Infinity}]]]===0)&]&/@a0list;
	pN = pN//.{scalarP[x_,y_]^n_:>metric[indexNew["sp\[Mu]"],indexNew["sp\[Nu]"]]fourVector[x,indexNew["sp\[Mu]"]]fourVector[y,indexNew["sp\[Nu]","EndQ"->True]]scalarP[x,y]^(n-1)};
	
	pN = pN//.{kloop^n_?EvenQ:>(metric[indexNew["sq\[Mu]"],indexNew["sq\[Nu]"]]fourVector[kloop,indexNew["sq\[Mu]"]]fourVector[kloop,indexNew["sq\[Nu]","EndQ"->True]])kloop^(n-2)};
	pN = pN//.{scalarP[x_,y_]:>metric[indexNew["sp\[Mu]"],indexNew["sp\[Nu]"]]fourVector[x,indexNew["sp\[Mu]"] ]fourVector[y,indexNew["sp\[Nu]","EndQ"->True]],
				slash[x_]:> gamma[indexNew["slash\[Mu]"]]fourVector[x,indexNew["slash\[Mu]","EndQ"->True]]};
int = int/.{symbol[p]p->  symbol[p]qtemp - symbol[p]kloop};
result = Select[giveParaProgSets[int],(Length[Intersection[{symbol[qtemp]qtemp,symbol[kloop]kloop},Level[#,{0,Infinity}]]]=!=0)&];

indices = Flatten[giveIndex[#,symbol[kloop]kloop]&/@(#)]&/@pN;
result = diracDelta@@Join[{qtemp},Select[deltalists,!MemberQ[{p,kloop},symbol[#]#,Infinity]&]]IBindex[result[[1,3]],result[[2,3]],result[[1,2]],result[[2,2]],s,symbol[kloop]qtemp,#]&/@indices;
result =(result (Times@@(#)&/@pN)(Times@@(#)&/@notpN))/.{fourVector[symbol[kloop]kloop,_]:>1}//Expand;

result = result//.{
	fourVector[p1_,\[Mu]_]fourVector[sq_,\[Mu]_]:>scalarP[p1,sq],
	fourVector[p1_,\[Mu]_]metric[\[Mu]_,\[Nu]_]:>fourVector[p1,\[Nu]],
	metric[\[Mu]_,\[Nu]_]^n_:>dim metric[\[Mu],\[Nu]]^(n-2);
metric[\[Mu]_,\[Nu]_]fourVector[x_,\[Nu]_]:> fourVector[x,\[Mu]],
	fourVector[s1_,\[Mu]_]gamma[\[Mu]_]:>slash[s1],
	fourVector[s1_,\[Mu]_]Dot[g1___,gamma[\[Mu]_],f1___]:> Dot[g1,slash[s1],f1]};

result = result//.{metric[\[Mu]_,\[Mu]_]:>dim , 
	metric[\[Mu]_,\[Nu]_]metric[\[Nu]_,\[Rho]_]:>metric[\[Mu],\[Rho]],fourVector[s_,_]^2:>scalarP[s,s],metric[\[Mu]_,\[Nu]_]^2:> dim,dim->OptionValue["D"]};
Plus@@(result//.{scalarP[qtemp,qtemp]->s} )FeynAmpD@@Select[giveParaProgSets[int],
											(Length[Intersection[{symbol[qtemp]qtemp,symbol[kloop]kloop},Level[#,{0,Infinity}]]]===0)&]*FeynAmpD[{qtemp,Sqrt[s],1}]//Expand
]


feynCalcViaDR[exp1_+exp2_,n_]:=feynCalcViaDR[exp1,n]+feynCalcViaDR[exp2,n]
feynCalcViaDR[exp0_ diracDelta[deltalists0__],n0_,OptionsPattern["D"->4]]:=Module[
		{exp = exp0 diracDelta[deltalists0],
		slists = ToExpression[ ("s"<>ToString[#])&/@Range[n0]],
		deltalist ={ deltalists0},limits = {},result,indices1, indices2, extend, factor  = 1},
			limits = Transpose[SortBy[giveParaProgSets[exp],
										(First@Flatten[Position[((# symbol[#])&/@deltalist),
																symbol[First[#]]First[#]]]&)][[;;n0+1]]];
indices1 = Join[{{limits[[3,1]],limits[[2,1]]}},Table[{1,Sqrt[slists[[i]]]},{i,n0-1}]];indices2 = Table[{limits[[3,i]],limits[[2,i]]},{i,2,Length[Transpose[limits]]}];
extend = Table[IB[indices1[[i,1]],indices2[[i,1]],indices1[[i,2]],indices2[[i,2]],slists[[i]],limits[[1,i+1]]],{i,Length[indices1]}];
limits = {slists,Table[Plus@@limits[[2,;;i]]^2,{i,2,Length[Transpose[limits]]}],Join[Table[(Sqrt[slists[[i]]]-limits[[2,i+1]])^2,{i,2,Length[slists]}],{Infinity}]}//Transpose//Reverse;
result =  Fold[( loopCalc[#1,#2,"D"->OptionValue["D"]]//Simplify)&,exp,slists];

factor = -\[Pi] ((-I \[Pi]^2)/(2\[Pi])^OptionValue["D"])^n0;
If[Head[result]===Plus,Plus@@Table[tzorIntegrate[factor result[[i]]Times@@extend,listToSequence[limits]],{i,Length[result]}],tzorIntegrate[factor result Times@@extend,listToSequence[limits]]]/.{tzorIntegrate[a_ FeynAmpD[{qtemp_,Sqrt[s_],_}]diracDelta[qtemp_,p_],{s_,_,Infinity},f__]:> (tzorIntegrate[a,f]//.{qtemp^2->s,qtemp->p})}
]


End[]
