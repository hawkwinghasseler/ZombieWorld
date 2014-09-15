package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class InvItem extends MovieClip
	{
		//Initiate Constants
		var NAME:String = "";
		var WEIGHT:Number = 0;
		var CONDITION:Number = 100;
		var CATEGORY:String = "";
		var QUANTITY:int = 1;
		
		public function InvItem(category_In:String, name_In:String, weight_In:Number, condition_In:Number, quantity_In:Number)
		{
			CATEGORY = category_In;
			NAME = name_In;
			WEIGHT = weight_In;
			CONDITION = condition_In;
			QUANTITY = quantity_In;
		}
		
		public function getCategory() {
			return CATEGORY;
		}
		
		public function getCondition()
		{
			return CONDITION;
		}
		
		public function getQuantity()
		{
			return QUANTITY;
		}
		
		public function changeQuantity(n:Number) {
			QUANTITY += n;
		}
		
		public function getName()
		{
			return NAME;
		}
		
		public function getWeight()
		{
			return WEIGHT;
		}
		
		override public function toString():String
		{
			return NAME + " (" + QUANTITY + ")";
		}
	}
}