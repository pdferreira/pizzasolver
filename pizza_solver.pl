:- use_module(library(clpfd)).

sample_pizza([
	[0, 0, 0, 0, 0],
	[0, 1, 1, 1, 0],
	[0, 0, 0, 0, 0]
]).

encode_ingredient(tomato, 0).
encode_ingredient(mushroom, 1).

new_slice(MaxW, MaxH, slice(X, W, Y, H)) :-
	% constrain X and W on pizza width
	X #>= 0,
	W #>= 0, % allow empty slices
	X + W #=< MaxW,
	% constrain Y and H on pizza height
	Y #>= 0,
	H #>= 0, % allow empty slices
	Y + H #=< MaxH,
	% avoid considering all empty slices, just slice(0, 0, 0, 0)
	(W #= 0 #\/ H #= 0) #==> (X #= 0 #/\ W #= 0 #/\ Y #= 0 #/\ H #= 0).
	
constrain_area(MaxPieces, slice(_, W, _, H), Area) :- 
	Area #= W * H,
	Area #=< MaxPieces.
	
remove_symmetry([]).
remove_symmetry([_]).
remove_symmetry([S1,S2|Ss]) :-
	remove_symmetry(S1, S2),
	remove_symmetry([S2|Ss]).
	
remove_symmetry(slice(X1, W1, Y1, _), slice(X2, W2, Y2, _)) :-
	% remove slice order symmetry
	X1 #=< X2,
	Y1 #=< Y2,
	% remove empty slice symmetry
	(X1 #= X2 #/\ Y1 #= Y2) #==> (W1 #=< W2).

constrain_ingredients(_, _, _, slice(0, 0, 0, 0)) :- 
	% don't place restrictions on empty slices
	!.	
constrain_ingredients(Pizza, MinMushroom, MinTomato, Slice) :-
	pieces_in_slice(Pizza, Slice, Pieces),
	encode_ingredient(tomato, TomatoValue),
	encode_ingredient(mushroom, MushroomValue),
	NMushroom #>= MinMushroom,
	NTomato #>= MinTomato,
	global_cardinality(Pieces, [MushroomValue-NMushroom,TomatoValue-NTomato]).

solve_sample(Slices, TotalSliceArea) :-
	sample_pizza(Pizza),
	MinMushroom = 1,
	MinTomato = 1,
	MaxPieces = 6,
	MaxSlices = 3,
	solve_pizza(Pizza, MinMushroom, MinTomato, MaxPieces, MaxSlices, Slices, TotalSliceArea).
	
solve_pizza(Pizza, MinMushroom, MinTomato, MaxPieces, MaxSlices, Slices, TotalSliceArea) :-
	% constrain slices
	constrain_pizza_slices(Pizza, MaxPieces, MaxSlices, Slices, TotalSliceArea),
	% get possible slice combinations, in order of max TotalArea
	term_variables(Slices, SliceVars),
	labeling([max(TotalSliceArea)], SliceVars),
	% validate ingredients
	maplist(constrain_ingredients(Pizza, MinMushroom, MinTomato), Slices).

constrain_pizza_slices(Pizza, MaxPieces, MaxSlices, Slices, TotalSliceArea) :-
	% inputs
	length(Pizza, R),
	Pizza = [P|Ps],
	length(P, C),
    % variables
	length(Slices, MaxSlices),
	maplist(new_slice(C, R), Slices),
    % remove repeated solutions (different slice order)
	remove_symmetry(Slices),
    % constrain slices to be disjoint
	disjoint2(Slices),
    % define total slice area range
	TotalPizzaArea #= R * C,
	TotalSliceArea in 0..TotalPizzaArea,
	length(Areas, MaxSlices),
	maplist(constrain_area(MaxPieces), Slices, Areas),
	sum(Areas, #=, TotalSliceArea).
	
pieces_in_slice([], slice(_, _, _, _), []).
pieces_in_slice([_|_], slice(_, _, _, 0), []).
pieces_in_slice([P|Ps], slice(X, W, 0, H), Cut) :-
	H > 0,
	pieces_in_line(P, X, W, CutP),
	Hm1 is H - 1,
	pieces_in_slice(Ps, slice(X, W, 0, Hm1), CutPs),
	append(CutP, CutPs, Cut).
pieces_in_slice(Pizza, slice(X, W, Y, H), Pieces) :-
	Y > 0,
	H > 0,
	Ym1 is Y - 1,
	pieces_in_slice(Pizza, slice(X, W, Ym1, H), Pieces).
	
pieces_in_line([], _, _, []).
pieces_in_line([_|_], _, 0, []).
pieces_in_line([V|Vs], 0, W, [V|CutVs]) :-
	W > 0,
	Wm1 is W - 1,
	pieces_in_line(Vs, 0, Wm1, CutVs).
pieces_in_line([_|Vs], X, W, CutVs) :-
	X > 0,
	W > 0,
	Xm1 is X - 1,
	pieces_in_line(Vs, Xm1, W, CutVs).
	
