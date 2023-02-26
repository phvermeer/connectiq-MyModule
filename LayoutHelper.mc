import Toybox.System;
import Toybox.Math;
import Toybox.Lang;
import MyModule.MyMath;
import MyModule.Tools;

module MyModule{

	(:Layout)
	module Layout {
		function createLayoutHelper() as LayoutHelper{
			var deviceSettings = System.getDeviceSettings();
			if(deviceSettings.screenShape == System.SCREEN_SHAPE_ROUND){
				return new RoundScreenLayoutHelper(deviceSettings.screenWidth/2);
			}else{
				return new LayoutHelper();
			}
		}

		enum Direction {
			TOP = 1,
			LEFT = 2,
			BOTTOM = 4,
			RIGHT = 8,
		}

		enum Quadrant {
			QUADRANT_TOP_RIGHT = 1,
			QUADRANT_TOP_LEFT = 2,
			QUADRANT_BOTTOM_LEFT = 4,
			QUADRANT_BOTTOM_RIGHT = 8,
			QUADRANTS_ALL = 15
		}

		typedef Area as interface{
			var locX as Numeric;
			var locY as Numeric;
			var width as Numeric;
			var height as Numeric;
		};

		class MyArea{
			var locX as Numeric;
			var locY as Numeric;
			var width as Numeric;
			var height as Numeric;

			function initialize(locX as Numeric, locY as Numeric, width as Numeric, height as Numeric) {
				self.locX = locX;
				self.locY = locY;
				self.width = width;
				self.height = height;
			}
		}

		class LayoutHelper{
			// Simple helper not taking account of round edges
			function fitAreaWithRatio(area as Area, boundaries as Area, ratio as Float) as Void{
				// returnes an area with given ratio (=width/height) within given boundaries
				var w = boundaries.width;
				var h = boundaries.height;
				var r = w/h;

				if(r > ratio){
					// shrink width
					var width = h * ratio;
					var dx = 0.5f * (w - width);
					area.locX = boundaries.locX + dx;
					area.locY = boundaries.locY;
					area.width = boundaries.width - dx;
					area.height = boundaries.height;
				}else if(r < ratio){
					// shrink height
					var height = w / ratio;
					var dy = 0.5f * (h - height);
					area.locX = boundaries.locX;
					area.locY = boundaries.locY + dy;
					area.width = boundaries.width;
					area.height = boundaries.height - dy;
				}else{
					// already has requested ratio
					copyArea(boundaries, area);
				}
			}

			function setAreaAligned(area as Area, boundaries as Area, alignment as Direction|Number) as Void{
				var left = (alignment & LEFT) > 0;
				var right = (alignment & RIGHT) > 0;
				var top = (alignment & TOP) > 0;
				var bottom = (alignment & BOTTOM) > 0;

				// horizontal alignment
				var dx = (left && !right)
					? area.locX - boundaries.locX // align left
					: (right && !left)
						? (boundaries.locX + boundaries.width) - (area.locX + area.width)  // align right
						: ((boundaries.locX + boundaries.width) - (area.locX + area.width))/2; // align centered

				// vertical alignment
				var dy = (top && !bottom) ? boundaries.locY - area.locY	// align top
					: (bottom && !top) ? (boundaries.locY + boundaries.height) - (area.locY + area.height)	// align bottom
					: ((boundaries.locY + boundaries.height) - (area.locY + area.height))/2; // align middle

				area.locX += dx;
				area.locY += dy;
			}

			function copyArea(source as Area, destination as Area) as Void{
				destination.locX = source.locX;
				destination.locY = source.locY;
				destination.width = source.width;
				destination.height = source.height;
			}		
		}

		class RoundScreenLayoutHelper extends LayoutHelper{
			var radius as Number;

			function initialize(radius as Number){
				self.radius = radius;
				LayoutHelper.initialize();
			}

			function setAreaAligned(area as Area, boundaries as Area, alignment as Direction|Number) as Void{
				throw new MyException("not yet implemented");
			}

			function fitAreaWithRatio(area as Area, boundaries as Area, ratio as Float) as Void {
				var xMin = xMin(boundaries);
				var xMax = xMax(boundaries);
				var yMin = yMin(boundaries);
				var yMax = yMax(boundaries);

				// check if which quadrants the boundaries are outside the circle
				//                          ┌─────────┐
				//	                     ┌──┘    ·    └──┐  
				//	                   ┌─┘       ·       └─┐
				//	                   │      Q2 · Q1      │
				//	                   │ · · · · + · · · · │
				//	                   │      Q3 · Q4      │
				//	                   └─┐       ·       ┌─┘
				//	                     └──┐    ·    ┌──┘
				//	                        └─────────┘

				var r2 = radius*radius;

				var xMin2 = xMin*xMin;
				var xMax2 = xMax*xMax;
				var yMin2 = yMin*yMin;
				var yMax2 = yMax*yMax;

				var quadrants = 0;

				// top right corner in quadrant 1
				if((xMax2 + yMax2 > r2) && (xMax > 0) && (yMax > 0)){
					quadrants |= QUADRANT_TOP_RIGHT;
				}
				// top left corner in quadrant 2
				if((xMin2 + yMax2 > r2) && (xMin < 0) && (yMax > 0)){
					quadrants |= QUADRANT_TOP_LEFT;
				}
				// bottom left corner in quadrant 3
				if((xMin2 + yMin2 > r2) && (xMin < 0) && (yMin < 0)){
					quadrants |= QUADRANT_BOTTOM_LEFT;
				}
				// bottom right corner in quadrant 4
				if((xMax2 + yMin2 > r2) && (xMax > 0) && (yMin < 0)){
					quadrants |= QUADRANT_BOTTOM_RIGHT;
				}

				// No quadrants reached -> return the full boundaries area
				if(quadrants == 0){
					copyArea(boundaries, area);
					return;
				}

				// check if the circle edge can be reached with all 4 corners
				if(quadrants == (QUADRANT_TOP_RIGHT|QUADRANT_TOP_LEFT|QUADRANT_BOTTOM_LEFT|QUADRANT_BOTTOM_RIGHT)){
					reachCircleEdge_4Points(area, ratio);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(area, boundaries);
					if(exceeded_quadrants != 0){
						//quadrants &= ~exceeded_quadrants;
					}else{
						roundArea(area);
						return;
					}
				}

				var quadrantCount = MyMath.getBitsHigh(quadrants);
				if(quadrantCount > 1){
					// No sollution yet......
					// check if the circle edge can be reached with 2 corners
					// collect in which directions the circle can be reached
					var directions = 0;

					if((quadrants & QUADRANT_TOP_LEFT) > 0){
						if((quadrants & QUADRANT_TOP_RIGHT) > 0){
							directions |= TOP;
						}
						if((quadrants & QUADRANT_BOTTOM_LEFT) > 0){
							directions |= LEFT;
						}
					}
					if((quadrants & QUADRANT_BOTTOM_RIGHT) > 0){
						if((quadrants & QUADRANT_TOP_RIGHT) > 0){
							directions |= RIGHT;
						}
						if((quadrants & QUADRANT_BOTTOM_LEFT) > 0){
							directions |= BOTTOM;
						}
					}

					// Choose direction from opposite directions
					if(directions & (LEFT|RIGHT) == (LEFT|RIGHT)){
						if(xMin + xMax > 0){
							directions &= ~LEFT;
						}else{
							directions &= ~RIGHT;
						}
					}
					if(directions & (TOP|BOTTOM) == (TOP|BOTTOM)){
						if(yMin + yMax > 0){
							directions &= ~BOTTOM;
						}else{
							directions &= ~TOP;
						}
					}

					var directionsArray = MyMath.getBitValues(directions);
					for(var i=0; i<directionsArray.size(); i++){
						var direction = directionsArray[i] as Direction;
						reachCircleEdge_2Points(area, boundaries, ratio, direction);

						// check boundaries
						var exceeded_quadrants = checkBoundaries(area, boundaries);
						if(exceeded_quadrants > 0){
							// quadrants &= ~exceeded_quadrants;
						}else{
							roundArea(area);
							return;
						}
					}
				}

				if(quadrants > 0){
					// No sollution yet......
					// Check if edge of circle can be reached at 1 corner

					// reduce quadrants (remove quadrants with smallest space within boundaries)
					var quadrant = quadrants;
					quadrantCount = MyMath.getBitsHigh(quadrant);
					if(quadrantCount > 1){
						var removed_quadrants = 0;
						if(quadrants & QUADRANT_TOP_RIGHT > 0){
							if(quadrants & QUADRANT_TOP_LEFT > 0){
								if(xMin + xMax > 0){
									removed_quadrants |= QUADRANT_TOP_LEFT;
								}else{
									removed_quadrants |= QUADRANT_TOP_RIGHT;
								}
							}
							if(quadrants & QUADRANT_BOTTOM_RIGHT > 0){
								if(yMin + yMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_RIGHT;
								}else{
									removed_quadrants |= QUADRANT_TOP_RIGHT;
								}
							}
						}
						if(quadrants & QUADRANT_BOTTOM_LEFT > 0){
							if(quadrants & QUADRANT_BOTTOM_RIGHT > 0){
								if(xMin + xMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_LEFT;
								}else{
									removed_quadrants |= QUADRANT_BOTTOM_RIGHT;
								}
							}
							if(quadrants & QUADRANT_TOP_LEFT > 0){
								if(yMin + yMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_LEFT;
								}else{
									removed_quadrants |= QUADRANT_TOP_LEFT;
								}
							}
						}
						quadrant &= ~removed_quadrants;
					}
					reachCircleEdge_1Point(area, boundaries, ratio, quadrant);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(area, boundaries);
					if(exceeded_quadrants == 0){
						roundArea(area);
						return;
					}
				}

				if(quadrants > 0){
					// shrink to fit within boundaries (ratio only to determine shrink and grow direction)
					if(area != null){
						shrinkAndResize(area, boundaries, quadrants);
						roundArea(area);
						return;
					}
				}
			}

			private function checkBoundaries(area as Area, boundaries as Area) as Quadrant|Number{
				// this number results with the quadrants in which the limits are exceeded
				var quadrants_exceeded = 0;

				var xMin = Math.ceil(xMin(boundaries)).toNumber();
				var xMax = Math.floor(xMax(boundaries)).toNumber();
				var yMin = Math.ceil(yMin(boundaries)).toNumber();
				var yMax = Math.floor(yMax(boundaries)).toNumber();

				var xMin_ = Math.ceil(xMin(area)).toNumber();
				var xMax_ = Math.floor(xMax(area)).toNumber();
				var yMin_ = Math.ceil(yMin(area)).toNumber();
				var yMax_ = Math.floor(yMax(area)).toNumber();

				if(xMin_ < xMin){
					if(yMax_ > 0) { quadrants_exceeded |= QUADRANT_TOP_LEFT; }
					if(yMin_ < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_LEFT; }
				}
				if(xMax_ > xMax){
					if(yMax_ > 0) { quadrants_exceeded |= QUADRANT_TOP_RIGHT; }
					if(yMin_ < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_RIGHT; }
				}
				if(yMax_ > yMax){
					if(xMax_ > 0) { quadrants_exceeded |= QUADRANT_TOP_RIGHT; }
					if(xMin_ < 0) { quadrants_exceeded |= QUADRANT_TOP_LEFT; }
				}
				if(yMin_ < yMin){
					if(xMax_ > 0) { quadrants_exceeded |= QUADRANT_BOTTOM_RIGHT; }
					if(xMin_ < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_LEFT; }
				}
				return quadrants_exceeded;
			}

			private function reachCircleEdge_4Points(area as Area, ratio as Float) as Void{
				// this functions returns 2 Float values: xMax, yMax which indicate the top left corner of the found rectangle with given ratio
				//         radius   ↑      ┌─────────┐
				//	(from center)   ·    ┌─○· · · · ·○─┐   ↑ yMax (from vertical center)
				//	                ·  ┌─┘ ·         · └─┐ · 
				//	                ·  │   ·         ·   │ ·
				//	                ─  │   ·    +    ·   │ ─
				//	                   │   ·         ·   │ 
				//	                   └─┐ ·         · ┌─┘
				//	                     └─○· · · · ·○─┘
				//	                       └─────────┘
				//                         <----|---->
				//	                      -xMax | xMax  (from horizontal center)
		
				//	formula1:	radius² = x² + y²
				//		=> radius² = xMax² + yMax²
				//
				//	formula2: ratio = width / height
				//		=> ratio = (2 * xMax) / (2 * yMax)
				//		=> ratio = xMax / yMax
				//		=> xMax = ratio * yMax
				//
				//	radius² = (ratio * yMax)² + yMax²
				//	radius² = ratio² * yMax² + yMax²
				//	radius² = (ratio² + 1) * yMax²
				//	yMax² = radius² / (ratio² + 1)
				//	yMax = √(radius² / (ratio² + 1))
				var yMax = Math.sqrt(radius*radius / (ratio*ratio + 1));
				var xMax = ratio * yMax;

				setXmin(area, -xMax);
				setXmax(area, xMax);
				setYmin(area, -yMax);
				setYmax(area, yMax);
			}

			private function reachCircleEdge_2Points(area as Area, boundaries as Area, ratio as Float, direction as Direction|Number) as Void{
				// determine the direction
				var offset = 0;
				var xMin = xMin(boundaries);
				var xMax = xMax(boundaries);
				var yMin = yMin(boundaries);
				var yMax = yMax(boundaries);

				if(direction == TOP){
					offset = yMin;
				}else if(direction == BOTTOM){
					offset = -yMax;
				}else if(direction == LEFT){
					offset = -xMax;
					ratio = 1 / ratio;
				}else if(direction == RIGHT){
					offset = xMin;
					ratio = 1 / ratio;
				}else{
					throw new Lang.InvalidValueException("The given quadrants do not represent a straight single direction");
				}
				// this functions returns 2 Float values: max and range
				//		max: the distance from the center to the outer rectangel side
				//		range: the distance from the center to both sides of the rectangle
				//
				//         radius   ↑      ┌─────────┐
				//	(from center)   ·    ┌─○· · · · ·○─┐   ↑ max (from vertical center)
				//	                ·  ┌─┘ ·         · └─┐ · 
				//	                ·  │   ·         ·   │ ·
				//	                ─  │   ·    +    ·   │ ─
				//	                   │---• · · · · •---│ ↓ offset (from vertical center)
				//	                   └─┐             ┌─┘
				//	                     └─┐         ┌─┘
				//	                       └─────────┘
				//       						       <----|---->
				//	                     -range | +range  (from horizontal center)
				//	                       <--------->
				//                          2 * range
		
				//	formula1:	radius² = x² + y²
				//		radius² = range² + max²
				//	formula2: ratio = width / height
				//		ratio = 2*range / (max - offset)
				//	=> range = ratio * (max - offset) / 2
		
				//	combine: radius² = range² + max² AND range = ratio * (max - offset) / 2
				//	=> radius² = (ratio * (max - offset) / 2)² + max²
				//	use abc formula where max is the value to be calculated: (all other variables are known)
				//	=> (ratio/2 * (max - offset))² + max² - radius² = 0
				//	=> (ratio/2 * max - ratio/2*offset)² + max² - radius² = 0
				//	=> (ratio/2)² * max² -2 * ratio/2 * max * ratio/2*offset + (ratio/2*offset)² + max² - radius² = 0
				//	=> (1+(ratio/2)²) * max² + (-2 * ratio/2 * ratio/2*offset) * max + (ratio/2*offset)² - radius² = 0
				//	=>	a = 1+(ratio/2)²
				//			b = -2 * ratio/2 * ratio/2 * offset = -ratio²/2 * offset
				//			c = (ratio/2*offset)² - radius²
				//	=>	D = b² - 4*a*c
				//	=>	max = (-b ± √D)/(2 * a)
		
				var a = 1+Math.pow(ratio/2, 2);
				var b = -ratio*ratio/2 * offset;
				var c = Math.pow(ratio/2 * offset, 2) - radius*radius;
				var results = MyMath.getAbcFormulaResults(a, b, c);
				var max = results[1];
				var range = ratio * (max - offset) / 2;


				// Now transpose to given direction
				if(direction == TOP){

					setXmin(area, -range);
					setXmax(area, range);
					setYmin(area, offset);
					setYmax(area, max);
				}else if(direction == BOTTOM){
					setXmin(area, -range);
					setXmax(area, range);
					setYmin(area, -max);
					setYmax(area, -offset);
				}else if(direction == RIGHT){
					setXmin(area, offset);
					setXmax(area, max);
					setYmin(area, -range);
					setYmax(area, range);
				}else if(direction == LEFT){
					setXmin(area, -max);
					setXmax(area, -offset);
					setYmin(area, -range);
					setYmax(area, range);
				}
			}

			private function reachCircleEdge_1Point(area as Area, boundaries as Area, ratio as Float, quadrant as Quadrant|Number) as Void{
				// This function calculates the xy coordinates where the circle edge in given quadrant is reached from a point within the circle and with a given ratio (slope)
				var xOffset = 0;
				var yOffset = 0;

				if(quadrant == QUADRANT_TOP_RIGHT){
					xOffset = xMin(boundaries);
					yOffset = yMin(boundaries);
				}else if(quadrant == QUADRANT_TOP_LEFT){
					xOffset = -xMax(boundaries);
					yOffset = yMin(boundaries);
				}else if(quadrant == QUADRANT_BOTTOM_RIGHT){
					xOffset = xMin(boundaries);
					yOffset = -yMax(boundaries);
				}else if(quadrant == QUADRANT_BOTTOM_LEFT){
					xOffset = -xMax(boundaries);
					yOffset = -yMax(boundaries);
				}else{
					throw new Lang.InvalidValueException(Lang.format("The qiven quadrant $1$ does not represent a single valid quadrant", [quadrant]));
				}				

				// this functions returns 2 Float values: xMax, yMax which indicate the top left corner of the found rectangle with given ratio
				//         radius   ↑      ┌─┬───────┐
				//	(from center)   ·    ┌─┘ •· · · ·○─┐   ↑ yMax (from vertical center)
				//	                ·  ┌─┘   │       · └─┐ · 
				//	                ·  │     │       ·   │ ·
				//	                ─  │     │  +    ·   │ ─
				//	                   │     •───────•───│ ↓ yOffset (from vertical center)
				//	                   └─┐             ┌─┘
				//	                     └─┐         ┌─┘
				//	                       └─────────┘
				//       						         <--|---->
				//	                     xOffset| xMax  (from horizontal center)
				//
				//	xOffset -> x
				//	yOffset -> y
				//	radius -> r
				//	ratio -> C
				//
				//	(x+w)²+(y+h)²=r²
				//	h=w/C	→	(x+w)²+(y+w/C)²=r²	
				//	(x²+2wx+w²) + (y²+(2y/C)w+(1/C²)w²) = r²
				//	(1+1/C²)*w² + (2x+2y/C)*w + (x²+y²-r²) = 0
				//
				//	w? -> use abc formula where w->x
				//
				//	ax² + bx + c = 0
				//
				//	a = (1+1/C²)
				//	b = (2x+2y/C)
				//	c = (x²+y²-r²)

				var a = 1 + 1/(ratio*ratio);
				var b = 2 * xOffset + 2 * yOffset / ratio;
				var c = xOffset * xOffset + yOffset * yOffset - radius * radius;
				var results = MyMath.getAbcFormulaResults(a, b, c);
				var w = MyMath.max(results); // use the positive result
				var h = w / ratio;
				var yMax = yOffset + h;
				var xMax = xOffset + w;

				// Now transpose back to original quadrant
				if(quadrant == QUADRANT_TOP_RIGHT){
					setXmin(area, xOffset);
					setXmax(area, xMax);
					setYmin(area, yOffset);
					setYmax(area, yMax);
				}else if(quadrant == QUADRANT_TOP_LEFT){
					setXmin(area, -xMax);
					setXmax(area, -xOffset);
					setYmin(area, yOffset);
					setYmax(area, yMax);
				}else if(quadrant == QUADRANT_BOTTOM_RIGHT){
					setXmin(area, xOffset);
					setXmax(area, xMax);
					setYmin(area, -yMax);
					setYmax(area, -yOffset);
				}else if(quadrant == QUADRANT_BOTTOM_LEFT){
					setXmin(area, -xMax);
					setXmax(area, -xOffset);
					setYmin(area, -yMax);
					setYmax(area, -yOffset);
				}
			}

			private function shrinkAndResize(area as Area, boundaries as Area, quadrants as Quadrant|Number) as Void{
				var xMin = xMin(boundaries);
				var xMax = xMax(boundaries);
				var yMin = yMin(boundaries);
				var yMax = yMax(boundaries);

				// first shrink and then determine the resize direction(s)
				var directions = 0;
				if(xMin(area) < xMin){
					setXmin(area, xMin);
					directions |= TOP|BOTTOM;
				}
				if(xMax(area) > xMax){
					setXmax(area, xMax);
					directions |= TOP|BOTTOM;
				}
				if(yMax(area) > yMax){
					setYmax(area, yMax);
					directions |= LEFT|RIGHT;
				}
				if(yMin(area) < yMin){
					setYmin(area, yMin);
					directions |= LEFT|RIGHT;
				}

				// check which resizing direction is required
				var include_directions = 0;
				if(quadrants & (QUADRANT_TOP_LEFT|QUADRANT_TOP_RIGHT) > 0){ include_directions |= TOP; }
				if(quadrants & (QUADRANT_TOP_RIGHT|QUADRANT_BOTTOM_RIGHT) > 0){ include_directions |= RIGHT; }
				if(quadrants & (QUADRANT_BOTTOM_LEFT|QUADRANT_BOTTOM_RIGHT) > 0){ include_directions |= BOTTOM; }
				if(quadrants & (QUADRANT_TOP_LEFT|QUADRANT_BOTTOM_LEFT) > 0){ include_directions |= LEFT; }
				directions &= include_directions;

				// Do the resizing till the circle edge
				var r2 = radius * radius;
				var x = MyMath.max([-xMin, xMax] as Array<Numeric>);
				var y = MyMath.max([-yMin, yMax] as Array<Numeric>);

				if(directions & TOP > 0){ setYmax(area, Math.sqrt(r2 - x*x)); }
				if(directions & LEFT > 0){ setXmin(area, -Math.sqrt(r2 - y*y)); }
				if(directions & BOTTOM > 0){ setYmin(area, -Math.sqrt(r2 - x*x)); }
				if(directions & RIGHT > 0){ setXmax(area, Math.sqrt(r2 - y*y)); }
			}

			// helper functions:
			// converts drawable locX, locY:
			//
			//   0 →
			// 0 ┌────────
			// ↓ │
			//   │
			//   │
			//
			// to: (based upon circle center):
			//  ↑     │
			//  0 ────┼────
			//        │
			//        0 →
						
			function xMin(area as Area) as Numeric{ return area.locX - radius; }
			function xMax(area as Area) as Numeric{ return area.locX + area.width - radius; }
			function yMin(area as Area) as Numeric{ return radius - (area.locY + area.height); }
			function yMax(area as Area) as Numeric{ return radius - area.locY; }

			private function setXmin(area as Area, xMin as Numeric) as Void{
				var dx = xMin - xMin(area);
				area.locX += dx;
				area.width -= dx;
			}
			private function setXmax(area as Area, xMax as Numeric) as Void{
				var dx = xMax - xMax(area);
				area.width += dx;
			}
			private function setYmin(area as Area, yMin as Numeric) as Void{
				var dy = yMin - yMin(area);
				area.height -= dy;
			}
			private function setYmax(area as Area, yMax as Numeric) as Void{
				var dy = yMax - yMax(area);
				area.locY -= dy;
				area.height += dy;
			}
			function roundArea(area as Area) as Void{
				var xMin = Math.round(xMin(area)).toNumber();
				var xMax = Math.round(xMax(area)).toNumber();
				var yMin = Math.round(yMin(area)).toNumber();
				var yMax = Math.round(yMax(area)).toNumber();
				area.locX = xMin + radius;
				area.width = xMax - xMin;
				area.locY = radius - yMax;
				area.height = yMax - yMin;
			}
		}
	}
}