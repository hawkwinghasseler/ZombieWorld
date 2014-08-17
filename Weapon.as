package
{
	import flash.display.MovieClip;
	
	public class Weapon extends MovieClip
	{
		var names:Array = ["M1911", "UMP", "Shotgun", "Desert Eagle"];
		var ammo:Array = [".45 Auto", ".45 Auto", "12 Gauge Shell", ".357"];
		var accuracy:Array = [5, 30, 30, 8];
		var kick:Array = [12, 10, 30, 25];
		var clipSize:Array = [7, 25, 6, 9];
		var fireRate:Array = [15, 15, 70, 40];
		var autoFire:Array = [false, true, false, false];
		var penetrationChance:Array = [10, 5, 70, 80];
		
		//Pick a starting weapon
		var currentWeapon:String = names[0];
		
		public function Weapon()
		{
		
		}
		
		public function getName()
		{
			return currentWeapon;
		}
		
		public function swap(s:String)
		{
			if (names.indexOf(s) >= 0)
			{
				currentWeapon = s;
			}
		}
		
		public function getAccuracy()
		{
			return accuracy[names.indexOf(currentWeapon)];
		}
		
		public function getAutoFire()
		{
			return autoFire[names.indexOf(currentWeapon)];
		}
		
		public function getClipSize()
		{
			return clipSize[names.indexOf(currentWeapon)];
		}
		
		public function getFireRate()
		{
			return fireRate[names.indexOf(currentWeapon)];
		}
		
		public function getKick()
		{
			return kick[names.indexOf(currentWeapon)];
		}
		
		public function getAmmoType()
		{
			return ammo[names.indexOf(currentWeapon)];
		}
		
		public function getPenetrationChance() {
			return penetrationChance[names.indexOf(currentWeapon)];
		}
		
		public function easyPrint() {
			var s:String = "Weapons/Ammo";
			for each (var someS in names) {
				s += "\n" + someS + "(" + ammo[names.indexOf(someS)] + ")";
			}
			return s;
		}
	}
}