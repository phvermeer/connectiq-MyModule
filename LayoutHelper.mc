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
			LEFT = 1,
			RIGHT = 2,
			TOP = 4,
			BOTTOM = 8,
		}

		enum Quadrant {
			QUADRANT_TOP_RIGHT = 1,
			QUADRANT_TOP_LEFT = 2,
			QUADRANT_BOTTOM_LEFT = 4,
			QUADRANT_BOTTOM_RIGHT = 8,
			QUADRANTS_ALL = 15
		}

		class Area{
			// The area uses x and y with 4 quadrant orientation
			// xyCenter = (0,0)
			// xyTopLeft = (screenHeight/2, -screenWidth/2)
			// xyBottomRight = (-screenHeight/2, screenWidth/2)
			var xOffset as Number;
			var yOffset as Number;
			var xMin as Numeric;
			var xMax as Numeric;
			var yMin as Numeric;
			var yMax as Numeric;

			function initialize(locX as Numeric, locY as Numeric, width as Numeric, height as Numeric) {
				// Transposes screen orientation to 4 quadrant orientation
				// 	screen: xy(0,0) => topleft
				//	4 quadrant: xy(0,0) => center
				var deviceSettings = System.getDeviceSettings();
				xOffset = deviceSettings.screenWidth / 2;
				yOffset = deviceSettings.screenHeight / 2;

				xMin = locX - xOffset;
				xMax = (locX + width) - xOffset;
				yMax = yOffset - locY;
				yMin = yOffset - (locY + height);
			}
			static function create(xMin as Numeric, xMax as Numeric, yMin as Numeric, yMax as Numeric) as Area{
				// creates an area based upon the coordinate system with the center of the circle as point (0,0)
				var area = new Area(0,0,0,0);
				area.xMin = xMin;
				area.yMin = yMin;
				area.xMax = xMax;
				area.yMax = yMax;
				return area;
			}

			function clone() as Area{ return Area.create(xMin, xMax, yMin, yMax); }
			function locX() as Numeric{ return xMin + xOffset; }
			function locY() as Numeric { return yOffset - yMax; }
			function width() as Numeric{ return xMax - xMin; }
			function height() as Numeric{ return yMax - yMin; }
			function roundToInt() as Void{
				// round down all coordinates to integers
				xMin = Math.ceil(xMin).toNumber();
				xMax = Math.floor(xMax).toNumber();
				yMin = Math.ceil(yMin).toNumber();
				yMax = Math.floor(yMax).toNumber();
			}

			function rotateToNextQuadrant() as Void{
				var xMin = self.xMin;
				self.xMin = -yMax;
				self.yMax = xMax;
				self.xMax = -yMin;
				self.yMin = xMin;
			}
			function rotateToPreviousQuadrant() as Void{
				var xMin = self.xMin;
				self.xMin = yMin;
				self.yMin = -xMax;
				self.xMax = yMax;
				self.yMax = -xMin;
			}
			function flipHorizontal() as Void{
				var xMin = self.xMin;
				self.xMin = -xMax;
				self.xMax = -xMin;
			}
			function flipVertical() as Void{
				var yMin = self.yMin;
				self.yMin = -yMax;
				self.yMax = -yMin;
			}
			function toString() as String{
				return Lang.format("(x, y) = ($1$, $2$), (width, height) = ($3$, $4$)", [locX(), locY(), width(), height()]);
				// return Lang.format("xyMin = ($1$, $2$), xyMax = ($3$, $4$)", [xMin, yMin, xMax, yMax]);
			}
		}

		class LayoutHelper{
			// Simple helper not taking account of round edges

			function getAreaWithRatio(boundaries as Area, ratio as Float) as Area|Null{
				// returnes an area with given ratio (=width/height) within given boundaries
				var w = boundaries.width();
				var h = boundaries.height();
				var r = w/h;

				if(r > ratio){
					// shrink width
					var width = h * ratio;
					var dx = 0.5f * (w - width);
					return Area.create(boundaries.xMin + dx, boundaries.xMax - dx, boundaries.yMin, boundaries.yMax);
				}else if(r < ratio){
					// shrink height
					var height = w / ratio;
					var dy = 0.5f * (h - height);
					return Area.create(boundaries.xMin, boundaries.xMax, boundaries.yMin + dy, boundaries.yMax - dy);
				}else{
					// already has requested ratio
					return boundaries.clone();
				}
			}

			function setAreaAligned(boundaries as Area, area as Area, alignment as Direction|Number) as Void{
				var left = (alignment & LEFT) > 0;
				var right = (alignment & RIGHT) > 0;
				var top = (alignment & TOP) > 0;
				var bottom = (alignment & BOTTOM) > 0;

				// horizontal alignment
				var dx = (left && !right) ? area.xMin - boundaries.xMin // align left
					: (right && !left) ? boundaries.xMax - area.xMax  // align right
					: ((boundaries.xMin + boundaries.xMax) - (area.xMin + area.xMax))/2; // align centered

				// vertical alignment
				var dy = (top && !bottom) ? boundaries.yMax - area.yMax	// align top
					: (bottom && !top) ? boundaries.yMin - area.yMin	// align bottom
					: ((boundaries.yMin + boundaries.yMax) - (area.yMin + area.yMax))/2; // align middle

				area.xMin += dx;
				area.xMax += dx;
				area.yMin += dy;
				area.yMax += dy;
			}		
		}

		class RoundScreenLayoutHelper extends LayoutHelper{
			var radius as Number;

			function initialize(radius as Number){
				self.radius = radius;
				LayoutHelper.initialize();
			}

			function setAreaAligned(boundaries as Area, area as Area, alignment as Direction|Number) as Void{
				LayoutHelper.setAreaAligned(boundaries, area, alignment);
			}

			function getAreaWithRatio(boundaries as Area, ratio as Float) as Area|Null {
				var xMin = boundaries.xMin;
				var xMax = boundaries.xMax;
				var yMin = boundaries.yMin;
				var yMax = boundaries.yMax;
				var area = null;

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

				// No quadrants reached -> return the full area
				if(quadrants == 0){
					area = boundaries.clone();
					area.roundToInt();
					return area;
				}

				// check if the circle edge can be reached with all 4 corners
				if(quadrants == (QUADRANT_TOP_RIGHT|QUADRANT_TOP_LEFT|QUADRANT_BOTTOM_LEFT|QUADRANT_BOTTOM_RIGHT)){
					area = reachCircleEdge_4Points(radius, ratio);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(boundaries, area);
					if(exceeded_quadrants != 0){
						//quadrants &= ~exceeded_quadrants;
					}else{
						area.roundToInt();
						return area;
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
						if(boundaries.xMin + boundaries.xMax > 0){
							directions &= ~LEFT;
						}else{
							directions &= ~RIGHT;
						}
					}
					if(directions & (TOP|BOTTOM) == (TOP|BOTTOM)){
						if(boundaries.yMin + boundaries.yMax > 0){
							directions &= ~BOTTOM;
						}else{
							directions &= ~TOP;
						}
					}

					var directionsArray = MyMath.getBitValues(directions);
					for(var i=0; i<directionsArray.size(); i++){
						var direction = directionsArray[i] as Direction;
						area = reachCircleEdge_2Points(radius, boundaries, ratio, direction);

						// check boundaries
						var exceeded_quadrants = checkBoundaries(boundaries, area);
						if(exceeded_quadrants > 0){
							// quadrants &= ~exceeded_quadrants;
						}else{
							area.roundToInt();
							return area;
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
								if(boundaries.xMin+boundaries.xMax > 0){
									removed_quadrants |= QUADRANT_TOP_LEFT;
								}else{
									removed_quadrants |= QUADRANT_TOP_RIGHT;
								}
							}
							if(quadrants & QUADRANT_BOTTOM_RIGHT > 0){
								if(boundaries.yMin+boundaries.yMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_RIGHT;
								}else{
									removed_quadrants |= QUADRANT_TOP_RIGHT;
								}
							}
						}
						if(quadrants & QUADRANT_BOTTOM_LEFT > 0){
							if(quadrants & QUADRANT_BOTTOM_RIGHT > 0){
								if(boundaries.xMin+boundaries.xMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_LEFT;
								}else{
									removed_quadrants |= QUADRANT_BOTTOM_RIGHT;
								}
							}
							if(quadrants & QUADRANT_TOP_LEFT > 0){
								if(boundaries.yMin+boundaries.yMax > 0){
									removed_quadrants |= QUADRANT_BOTTOM_LEFT;
								}else{
									removed_quadrants |= QUADRANT_TOP_LEFT;
								}
							}
						}
						quadrant &= ~removed_quadrants;
					}
					area = reachCircleEdge_1Point(radius, boundaries, ratio, quadrant);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(boundaries, area);
					if(exceeded_quadrants == 0){
						area.roundToInt();
						return area;
					}
				}

				if(quadrants > 0){
					// shrink to fit within boundaries (ratio only to determine shrink and grow direction)
					if(area != null){
						shrinkAndResize(area, radius, boundaries, quadrants);
						area.roundToInt();
						return area;
					}
				}

				// No restrictions for the edge found
				return LayoutHelper.getAreaWithRatio(boundaries, ratio);
			}

			private function checkBoundaries(boundaries as Area, area as Area) as Quadrant|Number{
				// this number results with the quadrants in which the limits are exceeded
				var quadrants_exceeded = 0;
				if(area.xMin < boundaries.xMin){
					if(area.yMax > 0) { quadrants_exceeded |= QUADRANT_TOP_LEFT; }
					if(area.yMin < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_LEFT; }
				}
				if(area.xMax > boundaries.xMax){
					if(area.yMax > 0) { quadrants_exceeded |= QUADRANT_TOP_RIGHT; }
					if(area.yMin < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_RIGHT; }
				}
				if(area.yMax > boundaries.yMax){
					if(area.xMax > 0) { quadrants_exceeded |= QUADRANT_TOP_RIGHT; }
					if(area.xMin < 0) { quadrants_exceeded |= QUADRANT_TOP_LEFT; }
				}
				if(area.yMin < boundaries.yMin){
					if(area.xMax > 0) { quadrants_exceeded |= QUADRANT_BOTTOM_RIGHT; }
					if(area.xMin < 0) { quadrants_exceeded |= QUADRANT_BOTTOM_LEFT; }
				}
				return quadrants_exceeded;
			}

			private static function reachCircleEdge_4Points(radius as Numeric, ratio as Float) as Area{
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

				return Area.create(
					-xMax,	// xMin
					xMax,	// xMax
					-yMax,	// yMin
					yMax	// yMax
				);
			}

			private static function reachCircleEdge_2Points(radius as Numeric, boundaries as Area, ratio as Float, direction as Direction|Number) as Area{
				// determine the direction
				var offset = 0;
				if(direction == TOP){
					offset = boundaries.yMin;
				}else if(direction == BOTTOM){
					offset = -boundaries.yMax;
				}else if(direction == LEFT){
					offset = -boundaries.xMax;
					ratio = 1 / ratio;
				}else if(direction == RIGHT){
					offset = boundaries.xMin;
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
					return Area.create(
						- range, 	// xMin
						range, 		// xMax
						offset,		// yMin
						max		    // yMax
					);
				}else if(direction == BOTTOM){
					return Area.create(
						-range, 	// xMin
						range, 		// xMax
						-max,		// yMin
						-offset		// yMax
					);
				}else if(direction == RIGHT){
					return Area.create(
						offset, 	// xMin
						max, 		// xMax
						-range,		// yMin
						range		// yMax
					);
				}else{ //(direction == LEFT){
					return Area.create(
						-max, 		// xMin
						-offset,	// xMax
						-range,		// yMin
						range		// yMax
					);
				}
			}

			private static function reachCircleEdge_1Point(radius as Numeric, boundaries as Area, ratio as Float, quadrant as Quadrant|Number) as Area{
				// This function calculates the xy coordinates where the circle edge in given quadrant is reached from a point within the circle and with a given ratio (slope)
				var xOffset = 0;
				var yOffset = 0;
				if(quadrant == QUADRANT_TOP_RIGHT){
					xOffset = boundaries.xMin;
					yOffset = boundaries.yMin;
				}else if(quadrant == QUADRANT_TOP_LEFT){
					xOffset = -boundaries.xMax;
					yOffset = boundaries.yMin;
				}else if(quadrant == QUADRANT_BOTTOM_RIGHT){
					xOffset = boundaries.xMin;
					yOffset = -boundaries.yMax;
				}else if(quadrant == QUADRANT_BOTTOM_LEFT){
					xOffset = -boundaries.xMax;
					yOffset = -boundaries.yMax;
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
					return Area.create(
						xOffset,	// xMin
						xMax,		// xMax
						yOffset,	// yMin
						yMax		// yMax
					);
				}else if(quadrant == QUADRANT_TOP_LEFT){
					return Area.create(
						-xMax,		// xMin
						-xOffset,	// xMax
						yOffset,	// yMin
						yMax		// yMax
					);
				}else if(quadrant == QUADRANT_BOTTOM_RIGHT){
					return Area.create(
						xOffset,	// xMin
						xMax,		// xMax
						-yMax,	    // yMin
						-yOffset	// yMax
					);
				}else{ // if(quadrants == QUADRANT_BOTTOM_LEFT){
					return Area.create(
						-xMax,		// xMin
						-xOffset,	// xMax
						-yMax,	    // yMin
						-yOffset	// yMax
					);
				}
			}

			private static function shrinkAndResize(area as Area, radius as Numeric, boundaries as Area, quadrants as Quadrant|Number) as Void{
				// first shrink and then determine the resize direction(s)
				var directions = 0;
				if(area.xMin < boundaries.xMin){
					area.xMin = boundaries.xMin;
					directions |= TOP|BOTTOM;
				}
				if(area.xMax > boundaries.xMax){
					area.xMax = boundaries.xMax;
					directions |= TOP|BOTTOM;
				}
				if(area.yMax > boundaries.yMax){
					area.yMax = boundaries.yMax;
					directions |= LEFT|RIGHT;
				}
				if(area.yMin < boundaries.yMin){
					area.yMin = boundaries.yMin;
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
				var x = MyMath.max([-boundaries.xMin, boundaries.xMax] as Array<Numeric>);
				var y = MyMath.max([-boundaries.yMin, boundaries.yMax] as Array<Numeric>);

				if(directions & TOP > 0){ area.yMax = Math.sqrt(r2 - x*x); }
				if(directions & LEFT > 0){ area.xMin = -Math.sqrt(r2 - y*y); }
				if(directions & BOTTOM > 0){ area.yMin = -Math.sqrt(r2 - x*x); }
				if(directions & RIGHT > 0){ area.xMax = Math.sqrt(r2 - y*y); }
			}
		}
	}
}