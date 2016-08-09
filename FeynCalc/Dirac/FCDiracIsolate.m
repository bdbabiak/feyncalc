(* ::Package:: *)

(* ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ *)

(* :Title: FCDiracIsolate													*)

(*
	This software is covered by the GNU General Public License 3.
	Copyright (C) 1990-2016 Rolf Mertig
	Copyright (C) 1997-2016 Frederik Orellana
	Copyright (C) 2014-2016 Vladyslav Shtabovenko
*)

(* :Summary:  Isolates chains of Dirac matrices								*)

(* ------------------------------------------------------------------------ *)

FCDiracIsolate::usage =
"FCDiracIsolate[expr,{q1,q2,...}] wraps chains of Dirac matrices into heads specified \
by the user " <> ToString[
Hyperlink[Style["\[RightSkeleton]", "SR"], "paclet:FeynCalc/ref/FCDiracIsolate"],
StandardForm];

FCDiracIsolate::fail =
"FCDiracIsolate failed to isolate loop integrals in `1`!";

Begin["`Package`"]
End[]

Begin["`FCDiracIsolate`Private`"]

Options[FCDiracIsolate] = {
	ClearHeads -> {FCGV["DiracChain"]},
	Collecting -> True,
	DiracGammaExpand -> True,
	DotSimplify -> True,
	ExceptHeads -> {},
	ExpandScalarProduct -> False,
	Expanding -> True,
	FCI -> False,
	Factoring -> Factor,
	Head -> FCGV["DiracChain"],
	Split -> True,
	Isolate -> False,
	IsolateNames -> KK,
	IsolateFast -> False,
	DiracGamma -> True,
	Spinor -> True,
	DiracTrace -> True
};

FCDiracIsolate[expr_, OptionsPattern[]] :=
	Block[ {res, null1, null2, ex,tmp, head, restHead},

		head = OptionValue[Head];

		If[OptionValue[FCI],
			ex = expr/. (Map[Rule[#, Identity] &, OptionValue[ClearHeads]]),
			ex = FCI[expr]/. (Map[Rule[#, Identity] &, OptionValue[ClearHeads]])
		];


		If[	FreeQ2[ex,DiracHeadsList],
			Return[ex]
		];

		If[	OptionValue[Expanding],
			ex = Expand2[ex, DiracHeadsList];
		];
(*
		(* Here we pull loop momenta out of Dirac slashes  *)
		If[	OptionValue[ExpandScalarProduct],
			tmp = FCSplit[ex, lmoms, Expanding->OptionValue[Expanding]];
			ex = tmp[[1]]+ ExpandScalarProduct[tmp[[2]],Momentum->lmoms]
		];

		(* Here we pull loop momenta out of Dirac slashes  *)
		If[	OptionValue[DiracGammaExpand] && !FreeQ[ex,DiracGamma],
			tmp = FCSplit[ex, lmoms, Expanding->OptionValue[Expanding]];
			ex = tmp[[1]]+ tmp[[2]]/. DiracGamma[x_,dim_:4]/;!FreeQ2[x,lmoms] :> DiracGammaExpand[DiracGamma[x,dim]]
		];
		*)
		(*	and out of the DOTs	*)
		If[	OptionValue[DotSimplify] && !FreeQ[ex,DOT],
			tmp = FCSplit[ex, DiracHeadsList, Expanding->OptionValue[Expanding]];
			ex = tmp[[1]]+ DotSimplify[tmp[[2]],Expanding->False]
		];

		If[	OptionValue[Collecting],
			ex = Collect2[ex,DiracHeadsList,Factoring->OptionValue[Factoring]];
		];

		res = (Map[(restHead[SelectFree[#, DiracHeadsList]]*
				head[SelectNotFree[#, DiracHeadsList]]) &,
				ex + null1 + null2] /. {null1 | null2 -> 0} /.
			head[1] -> 1);
		res = res /. {head[x_] /; !FreeQ2[x, OptionValue[ExceptHeads]] :> x};

		If[ Together[(res /. restHead|head -> Identity)-ex] =!= 0,
			Message[FCDiracIsolate::fail, ex];
			Abort[]
		];


		If[	OptionValue[Split],
			res = res /. DOT->holdDOT //. head[a_holdDOT b_holdDOT c_.] :> head[a]head[b c] /. holdDOT -> DOT
		];


		(* Here we unisolate objects that are not needed *)
		If[	!OptionValue[DiracTrace],
			res = res //. head[x_DiracTrace y_.] :> x head[y];
		];

		If[	!OptionValue[DiracGamma],
			res = res //. head[x_DiracGamma y_.] :> x head[y] //.
			head[DOT[x__] y_.]/; FreeQ[{x},Spinor] && !FreeQ[{x},DiracGamma] :> DOT[x] head[y];
		];

		If[	!OptionValue[Spinor],
			res = res //. head[DOT[x__] y_.]/; !FreeQ[{x},Spinor] :> DOT[x] head[y];
		];

		res = res //. head[x_]/; FreeQ2[x,DiracHeadsList] :> x;



		(*
		If[	OptionValue[SpinorChainsOnly],
			res = res /. head[x_]/;FreeQ2[x,Spinor] :> x /.
			head[DOT[s_Spinor,r___]]/;FreeQ2[r,Spinor] :> DOT[s,r];
		];
*)
		If[	OptionValue[Isolate],
			res = res/. restHead[x_]:> Isolate[x,IsolateNames->OptionValue[IsolateNames],IsolateFast->OptionValue[IsolateFast]],
			res = res /. restHead -> Identity
		];

		If [ !FreeQ[res/. head[__] :> 1, DiracHeadsList] & ,
			Message[FCDiracIsolate::fail, ex];
			Abort[]
		];

		res
	];

FCPrint[1,"FCDiracIsolate.m loaded."];
End[]