import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Timer;
using MyModule.MyMath;

module MyModule{
	(:Graph)
	module Graph{

		class Data{
			// working variables
			var maxCount as Number;
			var filter as Filter;
			protected var initialized as Boolean = false; // indicates if init after 1st point was done

			// point indicators for min and max values
			var ptMin as Array or Null = null; // point containing the lowest value
			var ptMax as Array or Null = null; // point containing the highest value

			// current min and max values
			var xMin as Float;
			var xMax as Float;
			var yMin as Float;
			var yMax as Float;

			// data and calculating averages
			var pts as Lang.Array = []; // array containing all stored datapoints
			
			// timer to add data in smaller parts to prevent "Error: Watchdog Tripped Error - Code Executed Too Long"
			protected var bufferTimer as Timer = new Timer.Timer();
			protected var buffer as Array< Array<Numeric> > = []; // buffer of array with [x,y] values
			protected var bufferBusy as Boolean = false; // indicates if the bufferTimer is running

			function initialize(options as {
				:maxCount as Number, 
				:reducedCount as Number,
			}){
				me.maxCount = options.hasKey(:maxCount) ? options.get(:maxCount) : 60;
				var reducedCount = (options.hasKey(:reducedCount)) ? options.get(:reducedCount) : maxCount * 3 / 4;
				filter = new VisvalingamFilter({:maxCount => reducedCount});
			}
			
			protected function addToBuffer(x as Numeric, y as Numeric) as Void{
				buffer.add([x,y]);
				// start timer to process the buffered items 
				
				if(!bufferBusy){
					bufferProcess();
					// start processing the buffer timer
					// System.println("Start processing");
					bufferTimer.start(method(:bufferProcess), 100, true);
					bufferBusy = true;
				}
			}
			function bufferProcess(){
				// process some items of the buffer
				var count = MyMath.min([me.buffer.size(), 10]);
				var items = buffer.slice(null, count);
				me.buffer = buffer.slice(count, null);
				
				for(var i=0; i<items.size(); i++){
					var xy = items[i]; 
					addPoint2(xy[0], xy[1]);
				}			
				
				// stop timer if buffer is empty	
				if(me.buffer.size() == 0){
					bufferTimer.stop();
					bufferBusy = false;
					// System.println("Finished processing");
				}
			}
			
			public function addPoint(x as Lang.Float, y as Lang.Float) as Void{
				addToBuffer(x,y);
			}
			protected function addPoint2(x as Lang.Float, y as Lang.Float){
				//System.println(Lang.format("(x,y) = ( $1$, $2$ )", [x, y]));
				if((x != null ) && (y!= null)){
					if(!initialized){
						initialized = true;
						// init min/max values
						ptMin = [x,y];
						ptMax = [x,y];
						xMin = x;
						xMax = x;
						yMin = y;
						yMax = y;

						pts.add([x,y]);
					} else {
						// update min/max values
						if(x < xMin){
							xMin = x;
						}else if(x > xMax){
							xMax = x;
						}
						if(y < yMin){
							yMin = y;
							ptMin = [x,y];
						}else if(y > yMax){
							yMax = y;
							ptMax = [x,y];
						}
						// add new point
						pts.add([x,y]);
						if(pts.size() >= maxCount){
							filter.apply(pts);
						}
					}
				}
			}
		}
	}
}