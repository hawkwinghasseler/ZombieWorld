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
		
		public function getAll()
		{
			return CURRENT_ITEMS;
		}
		
		public function add(item:InvItem)
		{
			CURRENT_ITEMS.push(item);
		}
		
		public function drop(item:InvItem)
		{
			CURRENT_ITEMS.splice(CURRENT_ITEMS.indexOf(item), 1);
		}
	}
}