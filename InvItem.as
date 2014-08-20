package
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	public class InvItem extends MovieClip
	{
		//Initiate Constants
		var NAME:String = "";
		var WEIGHT:String = 0;
		var CONDITION:Number = 100;
		
		public function InvItem(name_In:String, weight_In:Number, condition_In:Number)
		{
			NAME = name_In;
			WEIGHT = weight_In;
			CONDITION = condition_In;
		}
		
		public function getCondition() {
			return CONDITION;
		}
		
		public function getName() {
			return NAME;
		}
		
		public function getWeight() {
			return WEIGHT;
		}
	}
}