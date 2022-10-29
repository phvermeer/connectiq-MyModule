import Toybox.Lang;

module MyModule{
	(:MyList)
	module MyList{
		class List{
			class ListItem{
				var previous as ListItem?;
				var next as ListItem?;
				var object as Object;
				function initialize(object as Object){
					self.object = object;
				}
			}

			hidden var count as Number = 0;
			hidden var current as ListItem?;

			public function Add(object as Object) as Void{
				// Adds an item behind current position and moves the current position to the new item
				var item = new ListItem(object);
				if(current != null){
					item.previous = current;
					current.next = item;
					var next = current.next;
					if(next != null){
						item.next = next;
						next.previous = item;
					}
				}
				current = item;
			}

			public function Delete() as Boolean{
				// deletes the item at current position
				if(current != null){
					var previous = current.previous;
					var next = current.next;

					if(previous != null && next != null){
						previous.next = next;
						next.previous = previous;
						current = next;
					}else if(previous != null){
						previous.next = null;
						current = previous;
					}else if(next != null){
						next.previous = null;
						current = next;
					}
					count--;
					return true;
				}
				return false;
			}

			public function Current() as Object?{
				if(current != null){
					return current.object;
				}
				return null;
			}
			public function Previous() as Object?{
				if(current != null){
					var item = current.previous;
					if(item != null){
						current = item;
						return Current();
					}
				}
				return null;
			}
			public function Next() as Object?{
				if(current != null){
					var item = current.next;
					if(item != null){
						current = item;
						return Current();
					}
				}
				return null;
			}
		}
	}
}