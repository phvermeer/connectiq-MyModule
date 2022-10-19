import Toybox.Lang;
import Toybox.Graphics;

module MyModule{
	(:Graph)
	module Graph{

		enum DrawStyle {
			DRAW_STYLE_FILLED = 0x0,
			DRAW_STYLE_LINE = 0x1,
		}
		enum MarkerType{
			MARKER_MIN = 0x1,
			MARKER_MAX = 0x2,
		}

		class Serie{

			var color as Graphics.ColorValue or Null = null; // if null then let the graph decide (based upon background)
			var data as Graph.Data;
			var style as DrawStyle = DRAW_STYLE_FILLED;
			var markers as MarkerType or Number = MARKER_MIN | MARKER_MAX;
			var yRangeMin as Numeric = 20.0f; // (x,y) minimum range

			function initialize(options as {
				:data as Graph.Data,  // required
				:color as Graphics.ColorValue, // optional
				:style as DrawStyle, //optional
				:markers as MarkerType,
				:yRangeMin as Numeric,
			}){
				data = options.get(:data) as Data;
				if(options.hasKey(:color)){ color = options.get(:color); }
				if(options.hasKey(:style)){ style = options.get(:style) as DrawStyle; }
				if(options.hasKey(:markers)){ markers = options.get(:markers) as Number; }
				if(options.hasKey(:yRangeMin)){ yRangeMin = options.get(:yRangeMin) as Numeric; }
			}
		}
	}
}