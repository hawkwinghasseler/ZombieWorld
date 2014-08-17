package
{
	import flash.display.MovieClip;
	
	public class Weapon extends MovieClip
	{
		var names:Array = ["M1911", "UMP", "Shotgun"];
		var ammo:Array = [".45 Auto", "12 Gauge Shell"];
		
		//Pick a starting weapon
		var currentWeapon:String = names[0];
		
		public function Weapon()
		{
		
		}
		
		public function getName() {
			return currentWeapon;
		}
		
		public function swap(s:String)
		{
			if (names.indexOf(s) >= 0)
			{
				currentWeapon = s;
			}
		}
		
		public function getAmmoType()
		{
			return ammo[names.indexOf(currentWeapon)];
		}
	}
}