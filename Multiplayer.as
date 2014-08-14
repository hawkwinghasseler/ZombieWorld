package
{
	import com.reyco1.multiuser.data.UserObject;
	import com.reyco1.multiuser.debug.Logger;
	import com.reyco1.multiuser.MultiUserSession;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	
	public class Multiplayer extends MovieClip
	{
		private const SERVER:String = "rtmfp://p2p.rtmfp.net/";
		private const DEVKEY:String = "05128451c1c88dc70e01d26c-90847af16dc9"; // TODO: add your Cirrus key here. You can get a key from here : http://labs.adobe.com/technologies/cirrus/
		private const SERV_KEY:String = SERVER + DEVKEY;
		
		private var mConnection:MultiUserSession;
		private var mPlayers:Object = {};
		private var mMyName:String;
		private var myUserID:String;
		var currentPlayers:int = 0;
		
		public function Multiplayer()
		{
			Logger.LEVEL = Logger.ALL;
			initialize();
		}
		
		public function getName()
		{
			return mMyName;
		}
		
		public function initialize():void
		{
			mConnection = new MultiUserSession(SERV_KEY, "multiuser/test"); // create a new instance of MultiUserSession
			
			mConnection.onConnect = handleConnect; // set the method to be executed when connected
			mConnection.onUserAdded = handleUserAdded; // set the method to be executed once a user has connected
			mConnection.onObjectRecieve = handleGetObject; // set the method to be executed when we recieve data from a user
			
			mMyName = "User_" + Math.round(Math.random() * 999999);
			
			mConnection.connect(mMyName, {name: mMyName});
		}
		
		public function getCurrentConnections()
		{
			return currentPlayers;
		}
		
		public function sendStr(s:String)
		{
			mConnection.sendObject({c: "Message", m: s});
		}
		
		public function sendTic()
		{
			mConnection.sendObject({c: "AvailableTic"});
		}
		
		public function sendTotalTic(n:Number)
		{
			mConnection.sendObject({c: "TotalTic", t: n});
		}
		
		public function sendCharacterInfo(x_In:Number, y_In:Number, r_In:Number)
		{
			mConnection.sendObject({c: "ChangePosition", x: x_In, y: y_In, r: r_In});
		}
		
		public function sendBullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String)
		{
			mConnection.sendObject({c: "Bullet", x: x_In, y: y_In, r: r_In, immune: immune_In});
		}
		
		public function sendNameChange(s:String)
		{
			//record("Sending name change: " + s);
			mConnection.sendObject({c: "NameChange", n: s});
		}
		
		public function sendNewUserQuery()
		{
			mConnection.sendObject({c: "NewUserQuery"});
		}
		
		public function sendLoadingComplete()
		{
			mConnection.sendObject({c: "LoadingComplete"});
		}
		
		public function handleConnect(theUser:UserObject):void
		{
			record("Connection successful!\nYou are " + theUser.name);
			currentPlayers++;
			
			//Add a player for ME
			var aPlayer:Player = new Player(theUser.id, theUser.details.name);
			(parent as MovieClip).createPlayer(aPlayer);
			mPlayers[theUser.id] = aPlayer;
			myUserID = theUser.id;
			
			(parent as MovieClip).changeMyName(mMyName);
			(parent as MovieClip).setNick(mMyName);
		}
		
		public function getMyID()
		{
			return myUserID;
		}
		
		public function getNameFromID(s:String)
		{
			return mPlayers[s].getName();
		}
		
		public function decrementPlayers()
		{
			currentPlayers--;
		}
		
		public function handleUserAdded(theUser:UserObject):void
		{
			record("<font color='#993399'>" + "A user connected: " + theUser.name + "</font");
			currentPlayers++;
			
			//Add a player for THEM
			var aPlayer:Player = new Player(theUser.id, theUser.details.name);
			(parent as MovieClip).createPlayer(aPlayer);
			mPlayers[theUser.id] = aPlayer;
			
			//If I'm a new user, query for new user data
			if ((parent as MovieClip).isNew())
			{
				(parent as MovieClip).readyToSendNUQ();
			}
		}
		
		public function handleGetObject(theUserId:String, theData:Object):void
		{
			var objectCategoryStr:String = theData.c;
			switch (objectCategoryStr)
			{
				case "Message": 
					record("<font color='#000000'>" + theData.m + "</font");
					break;
				case "ChangePosition": 
					changePlayerPosition(theUserId, theData.x, theData.y, theData.r);
					break;
				case "Bullet": 
					(parent as MovieClip).createBullet(theData.x, theData.y, theData.r, theData.immune);
					break;
				case "NameChange": 
					//record("Received a name change " + theData.n);
					changePlayerName(theUserId, theData.n);
					break;
				case "AvailableTic": 
					incrementTic(theUserId);
					break;
				case "TotalTic": 
					setTic(theData.t);
				case "NewUserQuery": 
					//record("New user query received");
					(parent as MovieClip).newUserUpdate();
					break;
				case "LoadingComplete": 
					(parent as MovieClip).loadingComplete();
					break;
			}
		}
		
		public function incrementTic(theUserId:String)
		{
			mPlayers[theUserId].incrementTic();
		}
		
		public function setTic(n:Number)
		{
			(parent as MovieClip).setTic(n);
		}
		
		public function changePlayerPosition(theUserId:String, x_In:Number, y_In:Number, r_In:Number)
		{
			mPlayers[theUserId].changePosition(x_In, y_In, r_In);
		}
		
		public function changePlayerName(theUserId:String, n_In:String)
		{
			mPlayers[theUserId].setName(n_In);
		}
		
		public function record(s:String)
		{
			(parent as MovieClip).record(s);
		}
	}
}