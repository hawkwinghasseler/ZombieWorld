package
{
	import flash.display.MovieClip;
	import flash.utils.*;
	import flash.events.*;
	
	public class Player extends MovieClip
	{
		var myID:String;
		var myHealth:int;
		var dead:Boolean = false;
		var myName:String;
		var tic:int;
		var pHUI:PlayerHUI;
		var isDisconnected:Boolean = false;
		var bloodStep:int = 0;
		var hitSize:int = 12;
		
		public function Player(myID_In:String, myName_In:String)
		{
			myID = myID_In;
			myHealth = 10;
			myName = myName_In;
			gotoAndStop("Alive");
		}
		
		public function getHitSize()
		{
			return hitSize;
		}
		
		public function changePosition(x_In:Number, y_In:Number, r_In:Number)
		{
			x = x_In;
			y = y_In;
			rotation = r_In;
		}
		
		public function say(s:String) {
			pHUI.say(s);
		}
		
		public function takeDamage(impact_Angle:Number)
		{
			myHealth--;
			checkForDeath();
		}
		
		public function setName(s:String)
		{
			//record("Name changed from " + myName + " to " + s);
			myName = s;
		}
		
		public function getName()
		{
			return myName;
		}
		
		public function incrementTic()
		{
			tic++;
		}
		
		public function setInitTic(tic_In:int)
		{
			tic = tic_In;
		}
		
		public function getTic()
		{
			return tic;
		}
		
		public function checkForDeath()
		{
			if (myHealth <= 0)
			{
				myHealth = 0;
				die();
			}
		}
		
		public function removeMe()
		{
			(parent as MovieClip).removeChild(this);
		}
		
		public function addPHUI(pHUI_In:PlayerHUI)
		{
			pHUI = pHUI_In;
		}
		
		public function getPHUI()
		{
			return pHUI;
		}
		
		public function die()
		{
			//dead = true;
			//gotoAndStop("Dead");
		}
		
		public function disconnected()
		{
			isDisconnected = true;
			gotoAndStop("Disconnected");
		}
		
		public function reconnected()
		{
			isDisconnected = false;
			gotoAndStop("Alive");
		}
		
		public function isConnected()
		{
			return !isDisconnected;
		}
		
		public function getInfoArray()
		{
			return [];
		}

		public function isAlive()
		{
			return !dead;
		}
		
		public function getID()
		{
			return myID;
		}
		
		public function record(s:String)
		{
			(parent.parent.parent as MovieClip).record(s);
		}
	}
}