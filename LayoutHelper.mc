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

		typedef IArea as interface{
			var locX as Numeric;
			var locY as Numeric;
			var width as Numeric;
			var height as Numeric;
		};

		class Area{
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
			function fitAreaWithRatio(shape as IArea, boundaries as IArea, ratio as Float) as Void{
				// returnes an shape with given ratio (=width/height) within given boundaries
				var w = boundaries.width;
				var h = boundaries.height;
				var r = w/h;

				if(r > ratio){
					// shrink width
					var width = h * ratio;
					var dx = 0.5f * (w - width);
					shape.locX = boundaries.locX + dx;
					shape.locY = boundaries.locY;
					shape.width = boundaries.width - dx;
					shape.height = boundaries.height;
				}else if(r < ratio){
					// shrink height
					var height = w / ratio;
					var dy = 0.5f * (h - height);
					shape.locX = boundaries.locX;
					shape.locY = boundaries.locY + dy;
					shape.width = boundaries.width;
					shape.height = boundaries.height - dy;
				}else{
					// already has requested ratio
					copyArea(boundaries, shape);
				}
			}

			function setAreaAligned(shape as IArea, boundaries as IArea, alignment as Direction|Number) as Void{
				var left = (alignment & LEFT) > 0;
				var right = (alignment & RIGHT) > 0;
				var top = (alignment & TOP) > 0;
				var bottom = (alignment & BOTTOM) > 0;

				// horizontal alignment
				var dx = (left && !right)
					? shape.locX - boundaries.locX // align left
					: (right && !left)
						? (boundaries.locX + boundaries.width) - (shape.locX + shape.width)  // align right
						: 0.5f * ((boundaries.locX + boundaries.width) - (shape.locX + shape.width)); // align centered

				// vertical alignment
				var dy = (top && !bottom) ? boundaries.locY - shape.locY	// align top
					: (bottom && !top) ? (boundaries.locY + boundaries.height) - (shape.locY + shape.height)	// align bottom
					: 0.5f * ((boundaries.locY + boundaries.height) - (shape.locY + shape.height)); // align middle

				shape.locX += dx;
				shape.locY += dy;
			}

			function copyArea(source as IArea, destination as IArea) as Void{
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

			function setAreaAligned(shape as IArea, boundaries as IArea, alignment as Direction|Number) as Void{
				// remove opposite alignment values
				if(alignment & (TOP|BOTTOM) == (TOP|BOTTOM)){
					alignment &= ~(TOP|BOTTOM);
				}
				if(alignment & (LEFT|RIGHT) == (LEFT|RIGHT)){
					alignment &= ~(LEFT|RIGHT);
				}


				// common values
				var r2 = radius*radius;
				var diameter = 2 * radius;
				var xMin=0; var xMax=0; var yMin=0; var yMax=0; var xMin_=0; var xMax_=0; var yMin_=0; var yMax_=0;

				// calculate the following 2 variables to move the object
				var dx = 0;
				var dy = 0;

				// The number of directions indicates straight (single direction) or diagonal (combination of two directions)
				var alignType = MyMath.countBitsHigh(alignment as Number); // 0 => no direction (all centered), 1 => straight, 2 => diagonal

				// straight alignment
				if(alignType == 0){
					// No direction: CENTERED
					throw new Tools.MyException("Not yet supported");
				}else if(alignType == 1){
					// straight: LEFT or RIGHT or TOP or BOTTOM

					// Transpose all align direction to TOP using xMin, xMax, yMin, yMax as variables (with 0,0 as circle center)
					if(alignment == TOP){
						// no transpose required
						xMin = xMin(boundaries);
						xMax = xMax(boundaries);
						yMin = yMin(boundaries);
						yMax = yMax(boundaries);
						xMin_ = xMin(shape);
						xMax_ = xMax(shape);
						yMin_ = yMin(shape);
						yMax_ = yMax(shape);
					}else if(alignment == RIGHT){
						// rotate 90 degrees counter clockwise
						xMin = -yMax(boundaries);
						xMax = -yMin(boundaries);
						yMin =  xMin(boundaries);
						yMax =  xMax(boundaries);
						xMin_ = -yMax(shape);
						xMax_ = -yMin(shape);
						yMin_ =  xMin(shape);
						yMax_ =  xMax(shape);
					}else if(alignment == BOTTOM){
						// rotate 180 degrees
						xMin = -xMax(boundaries);
						xMax = -xMin(boundaries);
						yMin = -yMax(boundaries);
						yMax = -yMin(boundaries);
						xMin_ = -xMax(shape);
						xMax_ = -xMin(shape);
						yMin_ = -yMax(shape);
						yMax_ = -yMin(shape);
					}else if(alignment == LEFT){
						// rotate 90 degrees clockwise
						xMin =  yMin(boundaries);
						xMax =  yMax(boundaries);
						yMin = -xMax(boundaries);
						yMax = -xMin(boundaries);
						xMin_ =  yMin(shape);
						xMax_ =  yMax(shape);
						yMin_ = -xMax(shape);
						yMax_ = -xMin(shape);
					}

					// Do the TOP aligment

					// check if the width fits inside the boundaries
					if((xMax_ - xMin_) > (xMax - xMin)){
						// exceeds boundaries, ignore circle shape
						LayoutHelper.setAreaAligned(shape, boundaries, alignment);
						return;
					}

					// check space on top boundary within the circle
					//   y² + x² = radius²
					//   x = ±√(radius² - y²)
					//   xMax = +√(radius² - yMax²), xMin = -√(radius² - yMax²) 
					var xCircle = Math.sqrt(r2 - yMax*yMax);
					var xMaxCalc = (xCircle < xMax) ? xCircle : xMax;
					var xMinCalc = (-xCircle > xMin) ? -xCircle : xMin;

					// check if the object fits against the top boundary
					var width_ = xMax_ - xMin_;
					var height_ = yMax_ - yMin_;
					if((xMaxCalc - xMinCalc) >= width_){
						dx = 0.5 * ((xMinCalc + xMaxCalc) - (xMin_ + xMax_));
						dy = yMax - yMax_;
					}else{
						// move away from the border until the object fits
						// needs space on circle both left and right or only left or right
						var needsRight = false;
						var needsLeft = false;
						if(xMin > -width_/2){
							needsRight = true;
						}else if(xMax < width_/2){
							needsLeft = true;
						}else{
							needsLeft = true;
							needsRight = true;
						}
						var xNeeded = (needsLeft && needsRight) // x needed for each circle side
							? 0.5f * width_
							: needsLeft
								? width_ - xMax
								: width_ + xMin;
						// y² + x² = radius²
						// y = ±√(radius² - x²)
						var yMaxCalc = Math.sqrt(r2 - xNeeded*xNeeded);
						xMinCalc = (xMin > -xNeeded) ? xMin : -xNeeded;
						dx = xMinCalc - xMin_;
						dy = yMaxCalc - yMax_;
					}

					// move the object in the transposed direction
					xMin_ += dx;
					xMax_ += dx;
					yMin_ += dy;
					yMax_ += dy;
					dy *= -1;

					if(alignment == TOP){
						shape.locY += dy;
						shape.locX += dx;
					}else if(alignment == RIGHT){
						// rotate 90 degrees clockwise
						shape.locX += -dy;
						shape.locY += dx;
					}else if(alignment == BOTTOM){
						// rotate 180 degrees
						shape.locX += -dx;
						shape.locY += -dy;
					}else if(alignment == LEFT){
						// rotate 90 degrees counter clockwise
						shape.locX += dy;
						shape.locY += -dx;
					}
				}else if(alignType == 2){
					// diagonal: TOP-LEFT or TOP-RIGHT or BOTTOM-LEFT or BOTTOM-RIGHT
					// Transpose all align direction to TOP|RIGHT using xMin, xMax, yMin, yMax as variables (with 0,0 as circle center)
					if(alignment == TOP|RIGHT){
						// no rotation required
						xMin = xMin(boundaries);
						xMax = xMax(boundaries);
						yMin = yMin(boundaries);
						yMax = yMax(boundaries);
						xMin_ = xMin(shape);
						xMax_ = xMax(shape);
						yMin_ = yMin(shape);
						yMax_ = yMax(shape);
					}else if(alignment == TOP|LEFT){
						// flip horizontal
						xMin = -xMax(boundaries);
						xMax = -xMin(boundaries);
						yMin = yMin(boundaries);
						yMax = yMax(boundaries);
						xMin_ = -xMax(shape);
						xMax_ = -xMin(shape);
						yMin_ = yMin(shape);
						yMax_ = yMax(shape);

					}else if(alignment == BOTTOM|RIGHT){
						// flip vertical
						xMin = xMin(boundaries);
						xMax = xMax(boundaries);
						yMin = -yMax(boundaries);
						yMax = -yMin(boundaries);
						xMin_ = xMin(shape);
						xMax_ = xMax(shape);
						yMin_ = -yMax(shape);
						yMax_ = -yMin(shape);

					}else if(alignment == BOTTOM|LEFT){
						// flip both horizontal and vertical
						xMin = -xMax(boundaries);
						xMax = -xMin(boundaries);
						yMin = -yMax(boundaries);
						yMax = -yMin(boundaries);
						xMin_ = -xMax(shape);
						xMax_ = -xMin(shape);
						yMin_ = -yMax(shape);
						yMax_ = -yMin(shape);
					}

					// Now align with the top-right corner to the top-right corner of the boundaries or circle edge
					// 1 - if the top right corner of the boundaries is not outside the cirle, this will be the point to align to (go further to 4)
					// 2 - draw a diagonal line in the boundaries from bottom-left till top-right.
					// 3 - the crossing with the circle is the position to align to.
					// 4 - Now move the top-right corner of the object that has to be aligned to the refence point for alignment.
					//
					//         radius   ↑      ┏━━━┯━━━━━━┳╴╴.○
					//	(from center)        ┏━┛   ┆     .○˙┐ ┆
					//	                   ┏━┛     ┆  ·˙    └─┪
					//	                   ┃       ○˙╴╴╴╴╴╴╴╴╴┃
					//	                ─  ┃        +         ┃
					//	                   ┃                  ┃
					//	                   ┗━┓              ┏━┛
					//	                     ┗━┓          ┏━┛
					//	                       ┗━━━━━━━━━━┛

					// is the top-right corner of the boundaries within the circle?
					// radius² ≥ x² + y²

					// step 1
					var xMaxCalc = xMax;
					var yMaxCalc = yMax;

					if(xMax*xMax + yMax*yMax > r2){
						// step 2
						// get the point on the diagonal crossing with the circle
						// 	y = rc * x + C  (calculate rc and C)
						// 	=> rc = (yMax-yMin)/(xMax-xMin)
						var rc = 1.0f*(yMax-yMin)/(xMax-xMin);
						//	yMin = rc * xMin + C (should be on the line)
						// 	=> C = yMin - rc * xMin
						var C = yMin - rc * xMin;

						// step 3
						// Not get the crossing with the circle
						// radius² = x² + y²
						// radius² - x² = (rc * x + C)²
						// radius² - x² = rc² * x² + 2 * C * rc * x + C²
						// 0 = (rc²+1)*x² + 2*rc*C*x + C²-radius²
						// use the abc formula to retrieve the x
						var a = rc*rc + 1;
						var b = 2*rc*C;
						var c = C*C-r2;
						var results = MyMath.getAbcFormulaResults(a, b, c);
						xMaxCalc = results[1];
						// use the rc * x + C to retrieve the y
						yMaxCalc = rc * xMaxCalc + C;
					}

					// get the movement
					dx = xMaxCalc - xMax_;
					dy = yMaxCalc - yMax_;

					// move the object in the transposed direction
					if(alignment == TOP|RIGHT){
						// no transpose required
						shape.locX += dx;
						shape.locY -= dy;
					}else if(alignment == TOP|LEFT){
						// flip horizontal
						shape.locX += -dx;
						shape.locY -= dy;
					}else if(alignment == BOTTOM|RIGHT){
						// flip vertical
						shape.locX += dx;
						shape.locY -= -dy;
					}else if(alignment == BOTTOM|LEFT){
						// flip both horizontal and vertical
						shape.locX += -dx;
						shape.locY -= -dy;
					}						
				}
			}

			function fitAreaWithRatio(shape as IArea, boundaries as IArea, ratio as Float) as Void {
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

				// No quadrants reached -> return the full boundaries shape
				if(quadrants == 0){
					copyArea(boundaries, shape);
					return;
				}

				// check if the circle edge can be reached with all 4 corners
				if(quadrants == (QUADRANT_TOP_RIGHT|QUADRANT_TOP_LEFT|QUADRANT_BOTTOM_LEFT|QUADRANT_BOTTOM_RIGHT)){
					reachCircleEdge_4Points(shape, ratio);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(shape, boundaries);
					if(exceeded_quadrants != 0){
						//quadrants &= ~exceeded_quadrants;
					}else{
						roundArea(shape);
						return;
					}
				}

				var quadrantCount = MyMath.countBitsHigh(quadrants);
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
						reachCircleEdge_2Points(shape, boundaries, ratio, direction);

						// check boundaries
						var exceeded_quadrants = checkBoundaries(shape, boundaries);
						if(exceeded_quadrants > 0){
							// quadrants &= ~exceeded_quadrants;
						}else{
							roundArea(shape);
							return;
						}
					}
				}

				if(quadrants > 0){
					// No sollution yet......
					// Check if edge of circle can be reached at 1 corner

					// reduce quadrants (remove quadrants with smallest space within boundaries)
					var quadrant = quadrants;
					quadrantCount = MyMath.countBitsHigh(quadrant);
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
					reachCircleEdge_1Point(shape, boundaries, ratio, quadrant);

					// check boundaries
					var exceeded_quadrants = checkBoundaries(shape, boundaries);
					if(exceeded_quadrants == 0){
						roundArea(shape);
						return;
					}
				}

				if(quadrants > 0){
					// shrink to fit within boundaries (ratio only to determine shrink and grow direction)
					if(shape != null){
						shrinkAndResize(shape, boundaries, quadrants);
						roundArea(shape);
						return;
					}
				}
			}

			private function checkBoundaries(shape as IArea, boundaries as IArea) as Quadrant|Number{
				// this number results with the quadrants in which the limits are exceeded
				var quadrants_exceeded = 0;

				var xMin = Math.ceil(xMin(boundaries)).toNumber();
				var xMax = Math.floor(xMax(boundaries)).toNumber();
				var yMin = Math.ceil(yMin(boundaries)).toNumber();
				var yMax = Math.floor(yMax(boundaries)).toNumber();

				var xMin_ = Math.ceil(xMin(shape)).toNumber();
				var xMax_ = Math.floor(xMax(shape)).toNumber();
				var yMin_ = Math.ceil(yMin(shape)).toNumber();
				var yMax_ = Math.floor(yMax(shape)).toNumber();

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

			private function reachCircleEdge_4Points(shape as IArea, ratio as Float) as Void{
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

				setXmin(shape, -xMax);
				setXmax(shape, xMax);
				setYmin(shape, -yMax);
				setYmax(shape, yMax);
			}

			private function reachCircleEdge_2Points(shape as IArea, boundaries as IArea, ratio as Float, direction as Direction|Number) as Void{
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

					setXmin(shape, -range);
					setXmax(shape, range);
					setYmin(shape, offset);
					setYmax(shape, max);
				}else if(direction == BOTTOM){
					setXmin(shape, -range);
					setXmax(shape, range);
					setYmin(shape, -max);
					setYmax(shape, -offset);
				}else if(direction == RIGHT){
					setXmin(shape, offset);
					setXmax(shape, max);
					setYmin(shape, -range);
					setYmax(shape, range);
				}else if(direction == LEFT){
					setXmin(shape, -max);
					setXmax(shape, -offset);
					setYmin(shape, -range);
					setYmax(shape, range);
				}
			}

			private function reachCircleEdge_1Point(shape as IArea, boundaries as IArea, ratio as Float, quadrant as Quadrant|Number) as Void{
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
					setXmin(shape, xOffset);
					setXmax(shape, xMax);
					setYmin(shape, yOffset);
					setYmax(shape, yMax);
				}else if(quadrant == QUADRANT_TOP_LEFT){
					setXmin(shape, -xMax);
					setXmax(shape, -xOffset);
					setYmin(shape, yOffset);
					setYmax(shape, yMax);
				}else if(quadrant == QUADRANT_BOTTOM_RIGHT){
					setXmin(shape, xOffset);
					setXmax(shape, xMax);
					setYmin(shape, -yMax);
					setYmax(shape, -yOffset);
				}else if(quadrant == QUADRANT_BOTTOM_LEFT){
					setXmin(shape, -xMax);
					setXmax(shape, -xOffset);
					setYmin(shape, -yMax);
					setYmax(shape, -yOffset);
				}
			}

			private function shrinkAndResize(shape as IArea, boundaries as IArea, quadrants as Quadrant|Number) as Void{
				var xMin = xMin(boundaries);
				var xMax = xMax(boundaries);
				var yMin = yMin(boundaries);
				var yMax = yMax(boundaries);

				// first shrink and then determine the resize direction(s)
				var directions = 0;
				if(xMin(shape) < xMin){
					setXmin(shape, xMin);
					directions |= TOP|BOTTOM;
				}
				if(xMax(shape) > xMax){
					setXmax(shape, xMax);
					directions |= TOP|BOTTOM;
				}
				if(yMax(shape) > yMax){
					setYmax(shape, yMax);
					directions |= LEFT|RIGHT;
				}
				if(yMin(shape) < yMin){
					setYmin(shape, yMin);
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

				if(directions & TOP > 0){ setYmax(shape, Math.sqrt(r2 - x*x)); }
				if(directions & LEFT > 0){ setXmin(shape, -Math.sqrt(r2 - y*y)); }
				if(directions & BOTTOM > 0){ setYmin(shape, -Math.sqrt(r2 - x*x)); }
				if(directions & RIGHT > 0){ setXmax(shape, Math.sqrt(r2 - y*y)); }
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
						
			function xMin(shape as IArea) as Numeric{ return shape.locX - radius; }
			function xMax(shape as IArea) as Numeric{ return shape.locX + shape.width - radius; }
			function yMin(shape as IArea) as Numeric{ return radius - (shape.locY + shape.height); }
			function yMax(shape as IArea) as Numeric{ return radius - shape.locY; }

			private function setXmin(shape as IArea, xMin as Numeric) as Void{
				var dx = xMin - xMin(shape);
				shape.locX += dx;
				shape.width -= dx;
			}
			private function setXmax(shape as IArea, xMax as Numeric) as Void{
				var dx = xMax - xMax(shape);
				shape.width += dx;
			}
			private function setYmin(shape as IArea, yMin as Numeric) as Void{
				var dy = yMin - yMin(shape);
				shape.height -= dy;
			}
			private function setYmax(shape as IArea, yMax as Numeric) as Void{
				var dy = yMax - yMax(shape);
				shape.locY -= dy;
				shape.height += dy;
			}
			function roundArea(shape as IArea) as Void{
				var xMin = Math.round(xMin(shape)).toNumber();
				var xMax = Math.round(xMax(shape)).toNumber();
				var yMin = Math.round(yMin(shape)).toNumber();
				var yMax = Math.round(yMax(shape)).toNumber();
				shape.locX = xMin + radius;
				shape.width = xMax - xMin;
				shape.locY = radius - yMax;
				shape.height = yMax - yMin;
			}
		}
	}
}