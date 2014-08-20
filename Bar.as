package
{
	import flash.display.*;
	import flash.events.*;
	
	public class Bar extends MovieClip
	{
		var amount_current:Number = 0;
		var amount_total:Number = 0;
		var amount_goal:Number = 0;
		var scaleModifier:Number;
		
		public function Bar()
		{
			trace("A Bar has been initiated");
			scaleModifier = scaleX;
			addEventListener(Event.ENTER_FRAME, everyFrame);
		}
		
		public function update(i:int)
		{
			amount_goal = i;
		}
		
		public function setTotal(i:int)
		{
			if (amount_total != 0)
			{
				var pre_total:int = amount_total;
				amount_total = i;
				
				amount_current = (amount_total / pre_total) * amount_goal;
			}
			else
			{
				amount_total = i;
			}
		}
		
		public function isDone()
		{
			//trace(amount_current + "/" + amount_goal);
			if (amount_current == amount_goal)
			{
				return true;
			}
			return false;
		}
		
		public function everyFrame(event:Event)
		{
			scaleX = (amount_current / amount_total) * scaleModifier;
			if (amount_current != amount_goal)
			{
				var amount_change:Number = ((amount_goal - amount_current) / 5);
				amount_current += amount_change;
					//trace("amount_current: " + amount_current);
			}
			if (amount_current > (amount_goal - .1) && amount_current < (amount_goal + .1))
			{
				amount_current = amount_goal;
					//trace("done");
			}
		}
	}
}