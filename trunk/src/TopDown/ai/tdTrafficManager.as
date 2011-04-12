/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package TopDown.ai 
{
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.system.*;
	import flash.utils.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import revent.rEventDispatcher;
	import TopDown.*;
	import TopDown.ai.brains.*;
	import TopDown.loaders.*;
	import TopDown.loaders.proxies.*;
	import TopDown.objects.*;
	
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTrafficManager extends rEventDispatcher
	{
		public const horizon:amBoundBox2d = new amBoundBox2d();
		
		public var killBuffer:Number = 100;
		
		public var maxNumCars:uint = 0;
		public var carSpawnChance:Number = .3;
		public var spawnInterval:Number = 1;
		
		public var startCarsAtSpeedLimit:Boolean = true;
		
		public var carSeeds:Array = null;
		public var brainSeeds:Array = null;
		
		public var flashLoader:tdFlashLoader = null;
		
		public var removeBrainlessCars:Boolean = true;
		
		public var applicationDomain:ApplicationDomain = null;
		
		public var alternateContainer:qb2Group = null;
		
		private var cars:Dictionary = null;
		
		public function tdTrafficManager()
		{
			
		}
		
		td_friend function setMap(aMap:tdMap):void
		{
			cars = null;
			
			if ( _map )
			{
				_map.removeEventListener(qb2ContainerEvent.ADDED_OBJECT,              mapAddedOrRemovedSomething);
				_map.removeEventListener(qb2ContainerEvent.REMOVED_OBJECT,            mapAddedOrRemovedSomething);
				_map.removeEventListener(qb2ContainerEvent.DESCENDANT_ADDED_OBJECT,   mapAddedOrRemovedSomething);
				_map.removeEventListener(qb2ContainerEvent.DESCENDANT_REMOVED_OBJECT, mapAddedOrRemovedSomething);
			}
			
			_map = aMap;
			
			if ( _map )
			{
				cars = new Dictionary(true);
				
				loadUpCarDict(_map);
				
				_map.addEventListener(qb2ContainerEvent.ADDED_OBJECT,              mapAddedOrRemovedSomething);
				_map.addEventListener(qb2ContainerEvent.REMOVED_OBJECT,            mapAddedOrRemovedSomething);
				_map.addEventListener(qb2ContainerEvent.DESCENDANT_ADDED_OBJECT,   mapAddedOrRemovedSomething);
				_map.addEventListener(qb2ContainerEvent.DESCENDANT_REMOVED_OBJECT, mapAddedOrRemovedSomething);
			}
		}
		
		private function loadUpCarDict(container:qb2Group):void
		{
			cars = new Dictionary(true);
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(container);
			
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var tang:qb2Tangible = object as qb2Tangible;
				
				if ( tang is qb2Group )
				{
					var container:qb2Group = tang as qb2Group;
					for ( var i:int = 0; i < container.numObjects; i++ )
					{
						queue.push(container.getObjectAt(i));
					}
				}
				else if ( tang is tdCarBody )
				{
					cars[tang] = true;
				}
			}
		}
		
		public function get map():tdMap
			{  return _map;  }
		td_friend var _map:tdMap;
		
		private function mapAddedOrRemovedSomething(evt:qb2ContainerEvent):void
		{
			var object:qb2Object = evt.child;
			if ( object is tdCarBody )
			{
				if( evt.type == qb2ContainerEvent.ADDED_OBJECT || evt.type == qb2ContainerEvent.DESCENDANT_ADDED_OBJECT )
					cars[object] = true;
				else
					delete cars[object];
			}
			else if ( object is qb2Group )
			{
				loadUpCarDict(object as qb2Group);
			}
		}
		
		protected function makeRandomCar():tdCarBody
		{
			if ( !carSeeds || !carSeeds.length )  return null;
			
			var seed:* = carSeeds[amUtils.getRandInt(0, carSeeds.length - 1)];
			
			if ( seed is Class )
			{
				return makeCarFromInstance(new (seed as Class));
			}
			else if ( seed is String )
			{
				var classDef:Class = (applicationDomain ? applicationDomain.getDefinition(seed as String) : getDefinitionByName(seed as String)) as Class;
				return makeCarFromInstance(new classDef);
			}
			else if ( seed is tdCarBody )
			{
				var clone:tdCarBody = (seed as tdCarBody).clone() as tdCarBody;
				clone.linearVelocity.set();
				clone.angularVelocity = 0;
				
				return clone;
			}
			
			return null;
		}
		
		protected function makeCarFromInstance(instance:Object):tdCarBody
		{
			if ( instance is tdProxyCarBody )
			{
				if ( flashLoader )
				{
					return flashLoader.loadObject(instance) as tdCarBody;
				}
			}
			else if ( instance is tdCarBody )
			{
				return instance as tdCarBody;
			}
			
			return null;
		}
		
		protected function getCrossingTracks():Vector.<tdTrack>
		{
			var crossings:Vector.<tdTrack>;
			var viewCenter:amPoint2d = horizon.center;
			var viewRadius:Number = Math.sqrt( horizon.width * horizon.width + horizon.height * horizon.height);

			var numObjects:int = map.numObjects;
			for (var i:int = 0; i < numObjects; i++) 
			{
				var ithTrack:tdTrack = map.getObjectAt(i) as tdTrack;
				
				if ( !ithTrack )  continue;
				
				//trace(ithTrack.lineRep.distanceToPoint(viewCenter), viewRadius);
				
				if ( ithTrack.lineRep.distanceToPoint(viewCenter) <= viewRadius )
				{
					if ( !crossings )
					{
						crossings = new Vector.<tdTrack>();
					}
					crossings.push(ithTrack);
				}
			}
			
			return crossings;
		}
		
		protected function isLocationFree(location:amPoint2d):Boolean
		{
			for ( var key:* in cars )
			{
				var car:tdCarBody = key as tdCarBody;
				
				if ( !car )  continue;
				
				var boundBox:amBoundBox2d = car.getBoundBox(car.parent);
				
				if ( boundBox.containsPoint(location) )
				{
					return false;
				}
			}
			
			return true;
		}
		
		protected function makeTrackBrain():tdTrackBrain
		{
			if ( brainSeeds && brainSeeds.length )
			{
				var index:int = amUtils.getRandInt(0, brainSeeds.length - 1);
				
				var prototype:Object = brainSeeds[index];
				
				if ( prototype is Class )
				{
					return new (prototype as Class);
				}
				else if( prototype is tdBrain )
				{
					return (prototype as tdBrain).clone() as tdTrackBrain;
				}
			}
			else
			{
				return makeDefaultTrackBrain();
			}
			
			return null;
		}
		
		protected function makeDefaultTrackBrain():tdTrackBrain
		{
			var brain:tdTrackBrain = new tdTrackBrain();
			brain.aggression = 0;
			return brain;
		}
		
		td_friend function relay_update():void
			{  update();  }
		
		protected function update():void
		{
			var currCenter:amPoint2d = horizon.center;
	
			var numTrackCars:uint = 0;
			for ( var key:* in cars )
			{
				var car:tdCarBody = key as tdCarBody;
				
				if ( !car )
				{
					trace("Huh?");
					continue;
				}
	
				if ( !car.brain && removeBrainlessCars || car.brain && (car.brain is tdTrackBrain) && (car.brain as tdTrackBrain).ignoreGod == false )
				{
					if ( !horizon.containsPoint(car.position, killBuffer) )
					{
						car.removeFromParent();
						continue;
					}
					
					numTrackCars++;
				}
			}//trace(numTrackCars);
			
			//--- Attempt to spawn a new car if we're below the max and chance favors it.
			if ( numTrackCars < maxNumCars && Math.random() <= carSpawnChance )
			{
				//--- Go through the tracks that cross the boundary of our view rect.
				var tracks:Vector.<tdTrack> = getCrossingTracks();
				
				if ( !tracks )  return;
				
				var track:tdTrack = tracks[amUtils.getRandInt(0, tracks.length - 1)];
	
				//--- Skip this track if it spawned a car too recently.
				if ( map.world.clock - track.lastSpawnTime < spawnInterval )  return;

				var pos1:uint = horizon.getContainment(track.start);
				var pos2:uint = horizon.getContainment(track.end);
				
				if ( pos1 == amBoundBox2d.INSIDE && pos2 == amBoundBox2d.INSIDE )  return;

				var intPnts:Vector.<amPoint2d>;
				var lines:Vector.<amLine2d> = horizon.asLines();
				for ( var j:uint = 0; j < lines.length; j++ )
				{
					var intPoint:amPoint2d = new amPoint2d();
					
					if ( lines[j].intersectsLine(track.lineRep, intPoint, 0) )
					{
						if ( !intPnts )
						{
							intPnts = new Vector.<amPoint2d>();
						}
						intPnts.push(intPoint);
					}
				}
			
				if ( !intPnts )  return;

				intPoint = intPnts[amUtils.getRandInt(0, intPnts.length - 1)];
				
				//--- Avoid spawning a car on a dead-end.
				if ( !track.numBranches )  return;
				var distanceToStart:Number = track.start.distanceTo(intPoint);
				if ( distanceToStart > track.getDistanceToBranchAt(track.numBranches - 1) )  return;
				if ( distanceToStart < track.getDistanceToBranchAt(0) )
				{
					//trace("ererer");
					return;
				}
	
				//--- Avoid spawning cars on top of each other.
				if ( !isLocationFree(intPoint) )  return;

				var newCar:tdCarBody = makeRandomCar();
				
				if ( !newCar )  return;
				
				var trackBrain:tdTrackBrain = makeTrackBrain();
				trackBrain.currTrack = track;
				var trackDir:amVector2d = track.lineRep.direction;
				
				var currDistanceOnTrack:Number = track.lineRep.getDistAtPoint(intPoint);
				//currDistanceOnTrack = amUtils.constrain(currDistanceOnTrack, 0, track.length);
				
				trackBrain.currDistance = currDistanceOnTrack;
				newCar.addObject(trackBrain);
				
				newCar.position = intPoint;
				newCar.rotation = trackDir.angle;
				if( alternateContainer )
					alternateContainer.addObject(newCar);
				else
					_map.addObject(newCar);
					
				if ( startCarsAtSpeedLimit )
				{
					newCar.linearVelocity.copy(trackDir).scaleBy(track.speedLimit);
				}

				track.lastSpawnTime = _map.world.clock;
			}
		}
	}
}