package
{
	import flash.display.InterpolationMethod;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class Inventory extends MovieClip
	{
		//Initiate Constants
		var CURRENT_ITEMS:Array = new Array();
		
		public function Inventory()
		{
		}
		
		public function has(item:InvItem)
		{
			for each (var someItem in CURRENT_ITEMS)
			{
				if (someItem == item)
				{
					return true;
				}
			}
			return false;
		}
		
		public function getItemsByCategory(s:String)
		{
			var aItems:Array = new Array();
			for each (var someItem in CURRENT_ITEMS)
			{
				if (someItem.getCategory() == s)
				{
					aItems.push(someItem);
				}
			}
			return false;
		}
		
		public function remove(item:InvItem)
		{
			for each (var e in CURRENT_ITEMS)
			{
				if (e.getName() == item.getName() && e.getCondition() == item.getCondition())
				{
					e.changeQuantity(-item.getQuantity());
				}
			}
			consolidateInventory();
		}
		
		public function getAll()
		{
			return CURRENT_ITEMS;
		}
		
		public function add(item:InvItem)
		{
			CURRENT_ITEMS.push(item);
			consolidateInventory();
		}
		
		public function consolidateInventory()
		{
			//trace("Before Inv: " + "[" + CURRENT_ITEMS + "]");
			if (CURRENT_ITEMS.length > 1)
			{
				var a:Array = new Array();
				for each (var e in CURRENT_ITEMS)
				{
					var isNew:Boolean = true;
					var g:InvItem;
					if (a.length > 0)
					{
						for each (var f in a)
						{
							if (e.getName() == f.getName() && e.getCondition() == f.getCondition())
							{
								g = f;
								isNew = false;
							}
						}
					}
					if (e.getQuantity() > 0)
					{
						if (isNew)
						{
							a.push(e);
						}
						else
						{
							g.changeQuantity(e.getQuantity());
							if (g.getQuantity() <= 0) {
								consolidateInventory();
							}
						}
					}
				}
				CURRENT_ITEMS = a;
			}
			
			(parent as MovieClip).updateVisualInventory(CURRENT_ITEMS);
			//trace("# After Inv: " + "[" + CURRENT_ITEMS + "]");
		}
		
		public function printItems()
		{
			record("INVENTORY");
			for each (var someItem in CURRENT_ITEMS)
			{
				record(someItem.toString());
			}
		}
		
		public function drop(item:InvItem)
		{
			CURRENT_ITEMS.splice(CURRENT_ITEMS.indexOf(item), 1);
		}
		
		public function record(s:String)
		{
			(parent as MovieClip).record(s);
		}
	}
}