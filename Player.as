package
{
	import flash.display.MovieClip;
	
	public class Player extends MovieClip
	{
		var myID:String;
		var myHealth:int;
		var dead:Boolean = false;
		var myName:String;
		var tic:int;
		var pHUI:PlayerHUI;
		
		public function Player(myID_In:String, myName_In:String)
		{
			myID = myID_In;
			myHealth = 3;
			myName = myName_In;
			gotoAndStop("Alive");
		}
		
		public function changePosition(x_In:Number, y_In:Number, r_In:Number)
		{
			x = x_In;
			y = y_In;
			rotation = r_In;
		}
		
		public function takeDamage()
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
		
		public function removeMe() {
			(parent as MovieClip).removeChild(this);
		}
		
		public function addPHUI(pHUI_In:PlayerHUI) {
			pHUI = pHUI_In;
		}
		
		public function getPHUI() {
			return pHUI;
		}
		
		public function die()
		{
			//dead = true;
			//gotoAndStop("Death");
		}
		
		public function disconnected()
		{
			gotoAndStop("Disconnected");
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