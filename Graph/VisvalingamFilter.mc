import Toybox.Lang;
using Toybox.Math;
using MyModule.MyMath;

module MyModule{
	(:Graph)
	module Graph{
		class VisvalingamFilter // extends Math.Filter
		{
			var maxCount as Number? = null; // This amount is handy for the Dc.fillPolygon(pts) function with max 64 points
			var minInfluence as Decimal = 0.0f;

			function initialize(options as { 
				:maxCount as Number,
				:minInfluence as Decimal,
			}){
				//Filter.initialize(options);
				if(options.hasKey(:maxCount)){
					maxCount = options.get(:maxCount) as Number;
					// Less then 3 points is meaningless
					if(maxCount < 3){
						maxCount = 3;
					}
				}
				if(options.hasKey(:minInfluence)){
					minInfluence = options.get(:minInfluence) as Decimal;
				}
			}

			function apply(pts as Array<Array< Numeric> >) as Void {
				// Loop through points and calculate the area of a triangle with his neighbour points
				// The size of the triangle will indicate if the point is important => the smallest value will be removed (and recalculate its neighbours) 
				// until the given amount of points will remain.

				var size = pts.size();

				// Get a list of surfaces of all relevant points and their neighbours
				var surfaces = [];
				for(var i=1; i<size-1; i++){
					var surface = getTriangleSurface(pts[i-1], pts[i], pts[i+1]);
					if(surface <= minInfluence){
						// remove point and recalculate previous surface
						var pt = pts[i];
						pts.remove(pt);
						i--;
						if(i>0){
							surfaces[i-1] = getTriangleSurface(pts[i-1], pts[i], pts[i+1]);
						}
						size--;
					}else{
						surfaces.add(surface);
					}
				}

				// Now remove the smallest surfaces untill the number of points equals maxCount
				if(maxCount != null){
					while(size > 2){
						var minValue = MyMath.min(surfaces as Array<Numeric>);
						if(size > maxCount as Number){
							var i = surfaces.indexOf(minValue) + 1;
							var pt = pts[i];
							pts.remove(pt);
							surfaces.remove(minValue);
							size--;

							// recalculate surface for points with a new neighbour
							if(size > 2){
								// point before
								if(i > 1){
									surfaces[i-2] = getTriangleSurface(pts[i-2], pts[i-1], pts[i]);
								}
								// point after
								if(i < (size-1)){
									surfaces[i-1] = getTriangleSurface(pts[i-1], pts[i], pts[i+1]);
								}
							}
						}else{
							break;
						}
					}
				}
			}

			hidden function getTriangleSurface(pt1 as Array<Numeric>, pt2 as Array<Numeric>, pt3 as Array<Numeric>) as Numeric{
				return MyMath.abs(0.5 * (pt1[0] * pt2[1] + pt2[0] * pt3[1] + pt3[0] * pt1[1] - pt1[0] * pt3[1] - pt2[0] * pt1[1] - pt3[0] * pt2[1]));
			}
		}
	}
}