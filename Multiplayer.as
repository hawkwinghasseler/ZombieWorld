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
		private const DEVKEY:String = "05128451c1c88dc70e01d26c-90847af16dc9";
		private const SERV_KEY:String = SERVER + DEVKEY;
		
		private var mConnection:MultiUserSession;
		private var mPlayers:Object = {};
		private var mMyName:String;
		private var myUserID:String;
		var currentPlayers:int = 0;
		var receivedObjectCounter:int = 0;
		
		public function Multiplayer()
		{
			Logger.LEVEL = Logger.ALL;
			initialize();
		}
		
		public function getSentObjectCounter()
		{
			return mConnection.getSentObjectCount();
		}
		
		public function getReceivedObjectCounter()
		{
			return receivedObjectCounter;
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
		
		public function sendDisconnectOrder(s:String, id_In:String)
		{
			//mConnection.sendObject({c: "DisconnectOrder", r: s, w: id_In});
		}
		
		public function sendAliveQuery()
		{
			//Are you alive? (Sent when a character has lagged)
			mConnection.sendObject({c: "AreYouAlive", w: myUserID});
		}
		
		public function sendTic()
		{
			mConnection.sendObject({c: "AvailableTic"});
		}
		
		public function sendTotalTic(n:Number)
		{
			mConnection.sendObject({c: "TotalTic", t: n});
		}
		
		public function sendTicSync(n:Number)
		{
			(parent as MovieClip).syncTics();
			mConnection.sendObject({c: "TicSync", t: n});
		}
		
		public function sendCharacterInfo(x_In:Number, y_In:Number, r_In:Number)
		{
			mConnection.sendObject({c: "ChangePosition", x: x_In, y: y_In, r: r_In});
		}
		
		public function sendBullet(x_In:Number, y_In:Number, r_In:Number, immune_In:String, penetrates:Boolean)
		{
			mConnection.sendObject({c: "Bullet", x: x_In, y: y_In, r: r_In, immune: immune_In, pen: penetrates});
		}
		
		public function sendNameChange(s:String)
		{
			//record("Sending name change: " + s);
			mConnection.sendObject({c: "NameChange", n: s});
		}
		
		public function sendNewUserQuery()
		{
			record("Sending a New User Query");
			mConnection.sendObject({c: "NewUserQuery"});
		}
		
		public function sendLoadingComplete()
		{
			mConnection.sendObject({c: "LoadingComplete"});
		}
		
		public function sendForceReconnectOrder()
		{
			mConnection.sendObject({c: "ReconnectOrder"});
		}
		
		public function sendElement(what:String, infoArray:Array)
		{
			//record("Sending " + what + ", [" + infoArray + "]");
			if (what != "Player")
			{
				mConnection.sendObject({c: "Element", w: what, i: infoArray});
			}
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
			receivedObjectCounter++;
			var objectCategoryStr:String = theData.c;
			switch (objectCategoryStr)
			{
				case "Message": 
					record("<font color='#000000'>" + theData.m + "</font");
					say(theUserId, theData.m);
					break;
				case "ChangePosition": 
					changePlayerPosition(theUserId, theData.x, theData.y, theData.r);
					break;
				case "Bullet": 
					(parent as MovieClip).createBullet(theData.x, theData.y, theData.r, theData.immune, theData.pen);
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
					break;
				case "TicSync": 
					record("Tic sync received (" + mPlayers[myUserID].getTics() + "/" + theData.t);
					(parent as MovieClip).syncTics(theData.t);
					break;
				case "NewUserQuery": 
					//record("New user query received");
					(parent as MovieClip).newUserUpdate();
					break;
				case "LoadingComplete": 
					(parent as MovieClip).loadingComplete();
					break;
				case "DisconnectOrder": 
					if (theData.w == myUserID)
					{
						record("<font color='#990000'>" + "Disconnected!</font>\nReason: " + theData.r);
						(parent as MovieClip).disconnectMe();
					}
					else
					{
						//record("A Disconnect Order was issued to " + theData.w);
					}
					break;
				case "ReconnectOrder": 
					(parent as MovieClip).forceReconnect(mPlayers[theUserId].getName());
					break;
				case "AreYouAlive": 
					//record("You're lagging");
					//Get the question "Are you alive" aka YOU are lagging! Respond with "IAmAlive"
					mConnection.sendObject({c: "IAmAlive"});
					break;
				case "IAmAlive": 
					//Get "IAmAlive" response from a laggard, then send them the real tic count (to catch up)
					//record("You should update everyone";
					var trueTicCount:Number = mPlayers[myUserID].getTics();
					sendTicSync(trueTicCount);
					(parent as MovieClip).syncTics();
					break;
				case "Element": 
					if (theData.w == "Zombie")
					{
						(parent as MovieClip).createZombie(theData.i[0], theData.i[1], theData.i[2], theData.i[3]);
					}
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
		
		public function say(theUserId:String, s:String)
		{
			mPlayers[theUserId].say(s.substring(s.indexOf(": ") + 2));
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