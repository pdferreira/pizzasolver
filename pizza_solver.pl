:- use_module(library(clpfd)).

sample_pizza([
	[0, 0, 0, 0, 0],
	[0, 1, 1, 1, 0],
	[0, 0, 0, 0, 0]
]).

encode_ingredient(tomato, 0).
encode_ingredient(mushroom, 1).

solve_sample(Slices, TotalArea) :-
    % variables
	SliceVars = [Slice1X, Slice1Y, Slice1W, Slice1H, Slice2X, Slice2Y, Slice2W, Slice2H, Slice3X, Slice3Y, Slice3W, Slice3H],
    Slices = [slice(Slice1X, Slice1W, Slice1Y, Slice1H), slice(Slice2X, Slice2W, Slice2Y, Slice2H), slice(Slice3X, Slice3W, Slice3Y, Slice3H)],
    % remove repeated solutions (different slice order)
	Slice1X #=< Slice2X,
	Slice2X #=< Slice3X,
	Slice1Y #=< Slice2Y,
	Slice2Y #=< Slice3Y,
    % setup slice size and position ranges
	[Slice1X, Slice2X, Slice3X] ins 0..3,
	[Slice1Y, Slice2Y, Slice3Y] ins 0..1,
	[Slice1H, Slice2H, Slice3H] ins 1..3,
	[Slice1W, Slice2W, Slice3W] ins 1..3,
	Slice1X + Slice1W #=< 5,
	Slice2X + Slice2W #=< 5,
	Slice3X + Slice3W #=< 5,
	Slice1Y + Slice1H #=< 3,
	Slice2Y + Slice2H #=< 3,
	Slice3Y + Slice3H #=< 3,
    % constrain slices to be disjoint
	disjoint2(Slices),
    % define total slice area range
	AreaSlice1 #= Slice1W * Slice1H,
	AreaSlice2 #= Slice2W * Slice2H,
	AreaSlice3 #= Slice3W * Slice3H,
	sum([AreaSlice1, AreaSlice2, AreaSlice3], #=, TotalArea),
	TotalArea in 0..15,
    % get possible slice combinations, in order of max TotalArea
	labeling([max(TotalArea)], SliceVars),
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
	pieces_in_slice(Pizza, Slice1X, Slice1W, Slice1Y, Slice1H, Pieces1),
	global_cardinality(Pieces1, [MushroomValue-MinMushroom1,TomatoValue-MinTomato1]),
	pieces_in_slice(Pizza, Slice2X, Slice2W, Slice2Y, Slice2H, Pieces2),
	global_cardinality(Pieces2, [MushroomValue-MinMushroom2,TomatoValue-MinTomato2]),
	pieces_in_slice(Pizza, Slice3X, Slice3W, Slice3Y, Slice3H, Pieces3),
	global_cardinality(Pieces3, [MushroomValue-MinMushroom3,TomatoValue-MinTomato3]).
	
pieces_in_slice([], _, _, _, _, []).
pieces_in_slice([_|_], _, _, _, 0, []).
pieces_in_slice([P|Ps], X, W, 0, H, Cut) :-
	H > 0,
	pieces_in_line(P, X, W, CutP),
	Hm1 is H - 1,
	pieces_in_slice(Ps, X, W, 0, Hm1, CutPs),
	append(CutP, CutPs, Cut).
pieces_in_slice(Pizza, X, W, Y, H, Pieces) :-
	Y > 0,
	H > 0,
	Ym1 is Y - 1,
	pieces_in_slice(Pizza, X, W, Ym1, H, Pieces).
	
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
	