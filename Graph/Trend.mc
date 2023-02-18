import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Graphics;

module MyModule{
	(:Graph)
	module Graph{
		class Trend extends WatchUi.Drawable{
			enum Alignment{
				HALIGN_LEFT = 0x1,
				HALIGN_CENTER = 0x2,
				HALIGN_RIGHT = 0x4,
				VALIGN_TOP = 0x8,
				VALIGN_CENTER = 0x10,
				VALIGN_BOTTOM = 0x20,
			}

			hidden var series as Array<Graph.Serie> = [] as Array<Graph.Serie>;
			hidden var align as Alignment or Number = HALIGN_LEFT | VALIGN_CENTER;
			hidden var xRangeMin as Numeric = 20.0f;

			public var frameColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var textColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var xyMarkerColor as Graphics.ColorType = Graphics.COLOR_BLACK;
			public var maxMarkerColor as Graphics.ColorType = Graphics.COLOR_RED;
			public var minMarkerColor as Graphics.ColorType = Graphics.COLOR_GREEN;

			// values to calculate screen positions from x,y
			// (these values are updates when frame is drawn)
			hidden var topMargin as Numeric = 0;
			hidden var leftMargin as Numeric = 0;
			hidden var innerWidth as Numeric = 0;
			hidden var innerHeight as Numeric = 0;
			
			// (these values are determined when series are drawn)
			hidden var xOffset as Numeric = 0;
			hidden var yOffset as Numeric = 0;
			hidden var xFactor as Numeric = 0;
			hidden var yFactor as Numeric = 0;

			function initialize(options as {
				:locX as Number, 
				:locY as Number,
				:width as Number, 
				:height as Number,
				:align as Alignment, 
				:series as Array<Serie>,
				:darkMode as Boolean,
				:xRangeMin as Float,
			}){
				if(!options.hasKey(:identifier)){ options.put(:identifier, "Graph"); }
				Drawable.initialize(options);

				if(options.hasKey(:align)){ setAlignment(options.get(:align) as Number); }
				if(options.hasKey(:series)){ series = options.get(:series); }
				if(options.hasKey(:darkMode)){ setDarkMode(options.get(:darkMode) as Boolean); }
				if(options.hasKey(:xRangeMin)){ xRangeMin = options.get(:xRangeMin) as Numeric; }
			}

			function draw(dc as Dc){
				if(series == null){ return; }

				drawFrame(dc);
				drawSeries(dc);
			}

			protected function drawFrame(dc as Dc) as Void{

				var font = Graphics.FONT_XTINY;
				var labelHeight = dc.getFontHeight(font);
				self.topMargin = labelHeight + 6; // space for the markers
				var bottomMargin = 0; // space for the min/max distance 
				var axisWidth = 2;
				var axisMargin = 0.5f + Math.ceil(0.5f * axisWidth); // space for the axis width
				self.leftMargin = axisMargin;
				self.innerHeight = height - (topMargin + bottomMargin + axisMargin);
				self.innerWidth = width - (2 * axisMargin);

				// draw the xy-axis frame
				dc.setPenWidth(axisWidth);
				dc.setColor(frameColor, Graphics.COLOR_TRANSPARENT);
				dc.drawLine(locX, locY+topMargin, locX, locY+height-bottomMargin);
				dc.drawLine(locX, locY+height-bottomMargin, locX+width, locY+height-bottomMargin);
				dc.drawLine(locX+width, locY+topMargin, locX+width, locY+height-bottomMargin);
			}
				
			protected function drawSeries(dc as Dc) as Void{
				// determine min and max values

				// calculate graph limits
				var xMin = 0;
				var xMax = 0;
				var yMin = 0;
				var yMax = 0;

				if(self.series.size() > 0){
					for(var i=0; i<series.size(); i++){
						var data = series[i].data;
						if(i==0){
							xMin = data.xMin;
							xMax = data.xMax;
							yMin = data.yMin;
							yMax = data.yMax;
						}else{
							if(data.xMin < xMin) { xMin = data.xMin; }
							if(data.xMax > xMax) { xMax = data.xMax; }
							if(data.yMin < yMin) { yMin = data.yMin; }
							if(data.yMax > yMax) { yMax = data.yMax; }
						}
					}

					if(xMin >= xMax) { return; }
					if(yMin >= yMax) { return; }

					// the following values are also used when drawing the current position
					self.xFactor = innerWidth / (xMax - xMin);
					self.yFactor = -1 * innerHeight / (yMax - yMin);
					self.xOffset = locX + leftMargin - xMin * xFactor;
					self.yOffset = locY + topMargin + innerHeight - yMin * yFactor;

					// now do the drawing
					for(var s=0; s<series.size(); s++){
						var serie = series[s];
						if(serie.data != null){
							var pts = serie.data.pts;
							if(pts.size() < 2){
								// skip this serie
								continue;
							}

							var ptFirst = pts[0];
							var ptLast = pts[pts.size()-1];
						
							var yRangeMin = serie.yRangeMin; // minimal vertical range

							if((pts.size() > 1) && (xMax > xMin)){

								if((xMax - xMin) < xRangeMin){
									var xExtra = xRangeMin - (xMax - xMin);
									xMax += 1.0 * xExtra;
									xMin -= 0.0 * xExtra;
								}

								if((yMax - yMin) < yRangeMin){
									var yExtra = yRangeMin - (yMax - yMin);
									yMax += 0.8 * yExtra;
									yMin -= 0.2 * yExtra;
								}

								// Create an array of point with screen xy
								var color = (serie.color != null) ? serie.color as ColorType : textColor;
								dc.setColor(color, Graphics.COLOR_TRANSPARENT);
								
								if(serie.style == DRAW_STYLE_FILLED){
									var screenPts = [
										[xOffset + xFactor * ptLast[0], locY + topMargin + innerHeight] as Array<Numeric>,
										[xOffset + xFactor * ptFirst[0], locY + topMargin + innerHeight] as Array<Numeric>
									] as Array< Array< Numeric> >;
									for(var i=0; i<pts.size(); i++){
										var pt=pts[i];
										var x = xOffset + xFactor * pt[0] as Numeric;
										var y = yOffset + yFactor * pt[1] as Numeric;
										screenPts.add([x, y] as Array<Numeric>);
									}
									dc.fillPolygon(screenPts);
								}else if(serie.style == DRAW_STYLE_LINE){
									var xPrev = 0;
									var yPrev = 0; 
									for(var i=0; i<pts.size(); i++){
										var pt=pts[i];
										var x = xOffset + xFactor * pt[0] as Numeric;
										var y = yOffset + yFactor * pt[1] as Numeric;
										if(i>0){
											dc.drawLine(xPrev, yPrev, x, y);
										}
										xPrev = x;
										yPrev = y;
									}
								}

								// Draw min and max values
								// Min value
								if((serie.markers != null) && (serie.data.ptMin != null) && (MARKER_MIN == MARKER_MIN)){
									var ptMin = serie.data.ptMin as Array<Numeric>;
									dc.setColor(minMarkerColor, Graphics.COLOR_TRANSPARENT);

									drawMarker(
										dc, 
										xOffset + xFactor * ptMin[0], 
										yOffset + yFactor * ptMin[1], 
										leftMargin, 
										ptMin[1].format("%d")
									);
								}

								// Max value
								if((serie.markers != null) && (serie.data.ptMax != null) && (MARKER_MAX == MARKER_MAX)){
									var ptMax = serie.data.ptMax as Array<Numeric>;
									dc.setColor(maxMarkerColor, Graphics.COLOR_TRANSPARENT);
									drawMarker(
										dc, 
										xOffset + xFactor * ptMax[0], 
										yOffset + yFactor * ptMax[1], 
										leftMargin, 
										ptMax[1].format("%d")
									);
								}
							}
						}
					}
				}
			}

			public function drawCurrentXY(dc as Dc, x as Numeric, y as Numeric) as Void{
				// draw current x and y markers
				dc.setColor(xyMarkerColor, Graphics.COLOR_TRANSPARENT);
				dc.setPenWidth(1);

				var xScreen = xOffset + xFactor * x;
				dc.drawLine(xScreen, locY + topMargin, xScreen, locY + topMargin + innerHeight);

				var yScreen = yOffset + yFactor * y;
				dc.drawLine(locX + leftMargin, yScreen, locX + leftMargin + innerWidth, yScreen);
			}

			protected function drawMarker(dc as Dc, x as Numeric, y as Numeric, margin as Numeric, text as String) as Void{
				var font = Graphics.FONT_XTINY;
				var w2 = dc.getTextWidthInPixels(text, font)/2;
				var h = dc.getFontHeight(font);
				var xText = x;
				if((x-w2) < (locX + margin)){
					xText = locX + margin + w2;
				}else if((x+w2) > (locX + width - margin)){
					xText = locX + width - margin - w2;
				}
				dc.fillPolygon([
					[x, y] as Array<Numeric>,
					[x-5, y-6] as Array<Numeric>,
					[x+5, y-6] as Array<Numeric>
				] as Array< Array<Numeric> >);
				dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
				dc.drawText(xText, y-6-h, font, text, Graphics.TEXT_JUSTIFY_CENTER);
			}

			public function setDarkMode(darkMode as Boolean) as Void{
				self.textColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;
				self.frameColor = darkMode ? Graphics.COLOR_LT_GRAY : Graphics.COLOR_DK_GRAY;
				self.xyMarkerColor = darkMode ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;				
				self.minMarkerColor = darkMode ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
				self.maxMarkerColor = darkMode ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
			}

			public function setAlignment(align as Alignment or Number) as Void{
				self.align = align;
			}
			public function addSerie(serie as Graph.Serie) as Void{
				series.add(serie);
			}
			public function removeSerie(serie as Graph.Serie) as Void{
				series.remove(serie);
			}
		}
	}
}