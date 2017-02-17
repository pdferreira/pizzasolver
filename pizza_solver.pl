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
	W #>= 1,
	X + W #=< MaxW,
	% constrain Y and H on pizza height
	Y #>= 0,
	H #>= 1,
	Y + H #=< MaxH.
	
constrain_area(slice(_, W, _, H), Area) :- 
	Area #= W * H.
	
remove_symmetry([]).
remove_symmetry([_]).
remove_symmetry([S1,S2|Ss]) :-
	remove_symmetry(S1, S2),
	remove_symmetry([S2|Ss]).
	
remove_symmetry(slice(X1, _, Y1, _), slice(X2, _, Y2, _)) :-
	X1 #=< X2,
	Y1 #=< Y2.

solve_sample(Slices, TotalSliceArea) :-
	% inputs
	R = 3,
	C = 5,
    % variables
	new_slice(C, R, Slice1),
	new_slice(C, R, Slice2),
	new_slice(C, R, Slice3),
    Slices = [Slice1, Slice2, Slice3],
    % remove repeated solutions (different slice order)
	remove_symmetry(Slices),
    % constrain slices to be disjoint
	disjoint2(Slices),
    % define total slice area range
	TotalPizzaArea is R * C,
	TotalSliceArea in 0..TotalPizzaArea,
	constrain_area(Slice1, Area1),
	constrain_area(Slice2, Area2),
	constrain_area(Slice3, Area3),
	sum([Area1, Area2, Area3], #=, TotalSliceArea),
    % get possible slice combinations, in order of max TotalArea
	term_variables(Slices, SliceVars),
	labeling([max(TotalSliceArea)], SliceVars),
    % setup min ingredient variables
	encode_ingredient(tomato, TomatoValue),
	encode_ingredient(mushroom, MushroomValue),
    MinMushroom1 #>= 1,
	MinTomato1 #>= 1,
	MinMushroom2 #>= 1,
	MinTomato2 #>= 1,
	MinMushroom3 #>= 1,
	MinTomato3 #>= 1,
    % read pizza
	sample_pizza(Pizza),
    % get variables for each slice and had restriction on min ingredients
	pieces_in_slice(Pizza, Slice1, Pieces1),
	global_cardinality(Pieces1, [MushroomValue-MinMushroom1,TomatoValue-MinTomato1]),
	pieces_in_slice(Pizza, Slice2, Pieces2),
	global_cardinality(Pieces2, [MushroomValue-MinMushroom2,TomatoValue-MinTomato2]),
	pieces_in_slice(Pizza, Slice3, Pieces3),
	global_cardinality(Pieces3, [MushroomValue-MinMushroom3,TomatoValue-MinTomato3]).
	
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
	
