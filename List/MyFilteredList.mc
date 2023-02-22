import Toybox.Lang;
import Toybox.System;

module MyModule{
	(:List)
	module List{
		class MyFilteredList extends MyList{
			// filter based upon evaluation of each item with their relation to the predecescor and successor

			class RankedItem extends MyList.ListItem{
				var rankValue as Numeric?;
				var lowerRanked as RankedItem?;
				var higherRanked as RankedItem?;
				function initialize(object as Object){
					ListItem.initialize(object);
				}
			}

			hidden var _rankMethod as Method(previous as Object, item as Object, next as Object) as Numeric;
			hidden var _lowestRanked as RankedItem?;

			function initialize(rankMethod as Method(previous as Object, current as Object, next as Object) as Numeric){
				MyList.initialize();
				_rankMethod = rankMethod;
			}

			protected function createItem(object as Object) as MyList.ListItem{
				return new RankedItem(object) as MyList.ListItem;
			}

			hidden function updateRanking(item as RankedItem) as Void{
				var newRankValue = null;
				var previous = item.previous;
				var next = item.next;
				if(previous != null){
					if(next != null){
						// calculate
						newRankValue = _rankMethod.invoke(
							previous.object,
							item.object,
							next.object
						) as Numeric;
					}
				}
				if(newRankValue != item.rankValue){
					item.rankValue = newRankValue;
					var lower = item.lowerRanked;
					var higher = item.higherRanked;

					// remove from current ranking order
					if(lower != null){
						lower.higherRanked = higher;
					}
					if(higher != null){
						higher.lowerRanked = lower;
					}
					if(_lowestRanked == item){
						_lowestRanked = item.higherRanked;
					}

					if(newRankValue == null){
						// if no ranking value is available, then exclude from the ranking
						item.lowerRanked = null;
						item.higherRanked = null;
					}else{
						// search for the new ranking position (start at lowest)
						if(_lowestRanked != null){
							lower = null;
							higher = _lowestRanked;
							while(higher != null){
								if((higher.rankValue as Numeric) >= newRankValue){
									break;
								}
								lower = higher;
								higher = higher.higherRanked;
							}
							// (re)insert on the new ranking position
							item.lowerRanked = lower;
							item.higherRanked = higher;
							if(lower != null){
								lower.higherRanked = item;
							}
							if(higher != null){
								higher.lowerRanked = item;
							}
						}

						// update lowest ranked
						if(item.lowerRanked == null){
							_lowestRanked = item;
						}
					}
				}
			}

			public function refreshRanking() as Void{
				// this function will update all rankValues and rankingOrders
				var item = _first;
				while(item != null){
					updateRanking(item as RankedItem);
					item = item.next;
				}
			}

			// override functions to recalculate rankValues
			protected function insertItem(item as MyList.ListItem, ref as MyList.ListItem?) as Void{
				MyList.insertItem(item, ref);

				// Update the rank values
				updateRanking(item as RankedItem);
				if(item.previous != null){
					updateRanking(item.previous as RankedItem);
				}
				if(item.next != null){
					updateRanking(item.next as RankedItem);
				}
			}
			protected function deleteItem(item as MyList.ListItem) as Void{
				// remove from list
				var item_ = item as RankedItem;
				var previous = item_.previous;
				var next = item_.next;
				MyList.deleteItem(item_);

				// Update the rank values (keep in mind that item is deleted and has no relations to prev and next)
				updateRanking(item_);
				if(previous != null){
					updateRanking(previous as RankedItem);
				}
				if(next != null){
					updateRanking(next as RankedItem);
				}
			}

			hidden function getRankValues() as Array<Numeric>{
				// collect ranking values for evaluation
				var item = _lowestRanked;
				var array = [] as Array<Numeric>;
				while(item != null){
					array.add(item.rankValue);
					item = item.higherRanked;
				}
				return array;
			}

			function filterSize(maxSize as Number) as Void{
				// System.println(Lang.format("before filter: $1$", [getRankValues()]));
				while(_lowestRanked != null && size() > maxSize){
					// remove the item with the lowest rank untill the size is within the range
					deleteItem(_lowestRanked);
				}
				// System.println(Lang.format("after filter: $1$", [getRankValues()]));
			}

			public function filterRanking(minRankValue as Float) as Void{
				while(_lowestRanked != null){
					if(_lowestRanked.rankValue as Float < minRankValue){
						// remove the item with the lowest rank as long as this rank is lower than the minRanking
						deleteItem(_lowestRanked);
					}else{
						break;
					}
				}
			}
		}
	}
}