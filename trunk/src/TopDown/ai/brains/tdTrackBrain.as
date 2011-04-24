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

package TopDown.ai.brains
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.debugging.*;
	import TopDown.events.*;
	import TopDown.internals.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTrackBrain extends tdBrain
	{
		public function get aggression():Number
			{  return _aggression;  }
		public function set aggression(value:Number):void
			{  _aggression = amUtils.constrain(value, 0, 1);  }
		private var _aggression:Number = 0;
		
		public function get temper():Number
			{  return _temper;  }
		public function set temper(value:Number):void
			{  _temper = amUtils.constrain(value, 0, 1);  }
		private var _temper:Number = .5;
		
		public function get cooldownRate():Number
			{  return _cooldownRate;  }
		public function set cooldownRate(value:Number):void
			{  _cooldownRate = value;  }
		private var _cooldownRate:Number = .02;
			
		public var minHitSpeed:Number = 5;
		public var maxHitSpeed:Number = 50;
		
		public var tetherMultiplier:Number = 15;
		public var tetherMinimum:Number = 10;
		public var tetherMaximum:Number = 150;
		
		public var ignoreGod:Boolean = false;
		public var avoidUTurns:Boolean = true;
		public var uTurnDistance:Number = 100;
		
		public var turnChance:Number = .5;
		
		public var parallelTolerance:Number = 1 * (Math.PI / 180.0);
		
		public var autoSearchForTrack:Boolean = true;
		
		public var historyDepth:uint = 4;
		
		
		private var history:Vector.<tdTrack> = new Vector.<tdTrack>();
		
		private var justGotHit:Boolean = false;
		
		public function get currTrack():tdTrack
		{
			return _currTrack;
		}
		public function set currTrack(track:tdTrack):void
		{
			clearHistory();
			_currTrack = track;
			unshiftHistory(_currTrack);
		}
		private var _currTrack:tdTrack = null;
		
		public var currDistance:Number = 0;
		private var _currPoint:amPoint2d;
		
		private var _hasHost:Boolean = false;
		
		private static const antennaDict:Dictionary = new Dictionary(true);
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var clone:tdTrackBrain = super.clone(deep) as tdTrackBrain;
			
			clone._temper = this._temper;
		
			clone._cooldownRate = this._cooldownRate;
				
			clone.minHitSpeed = this.minHitSpeed;
			clone.maxHitSpeed = this.maxHitSpeed;
			
			clone.tetherMultiplier = this.tetherMultiplier;
			clone.tetherMinimum = this.tetherMinimum;
			clone.tetherMaximum = this.tetherMaximum
			
			clone.ignoreGod = this.ignoreGod;
			clone.avoidUTurns = this.avoidUTurns;
			clone.uTurnDistance = this.uTurnDistance;
			
			clone.turnChance = this.turnChance;
			
			clone.parallelTolerance = this.parallelTolerance;
			
			clone.autoSearchForTrack = this.autoSearchForTrack;
			
			clone.historyDepth = this.historyDepth;
			
			clone.useAntenna = this.useAntenna;
			clone.antennaLength = this.antennaLength;
			
			return clone;
		}
		
		protected override function addedToHost():void
		{
			if ( !(host is tdCarBody) )  return;
			
			host.addEventListener(qb2MassEvent.MASS_PROPS_CHANGED, geomChanged, null, true);
			host.addEventListener(qb2ContactEvent.CONTACT_STARTED, hostHit, null, true);
			_hasHost = true;
			
			refreshAntenna();
		}
		
		protected override function removedFromHost():void
		{
			if ( !(host is tdCarBody) )  return;
			
			host.removeEventListener(qb2MassEvent.MASS_PROPS_CHANGED, geomChanged);
			host.removeEventListener(qb2ContactEvent.CONTACT_STARTED, hostHit);
			
			_hasHost = false;
			
			refreshAntenna();
		}
		
		protected override function addedToWorld():void
		{
			var currParent:qb2Object = host;
			_map = null;
			
			while ( currParent )
			{
				if ( currParent is tdMap )
				{
					_map = currParent as tdMap;
					
					return;
				}
				
				currParent = currParent.parent;
			}
			
			clearHistory();
		}
		
		protected override function removedFromWorld():void
		{
			_map = null;
			_currTrack = null;
			_currPoint = null;
			clearHistory();
		}
		
		private var _map:tdMap;
		
		
		private function hostHit(evt:qb2ContactEvent):void
		{
			if ( evt.localShape == _antenna || (_antenna is qb2ObjectContainer) && evt.localShape.isDescendantOf((_antenna as qb2ObjectContainer)) )
			{
				return;
			}
			var force:Number = 0;
			
			if ( evt.contactPoint )
			{
				var localPoint:amPoint2d = host.getLocalPoint(evt.contactPoint);
				force = evt.otherShape.getLinearVelocityAtPoint(localPoint).length;
			}
			
			var modForce:Number = amUtils.constrain(force, minHitSpeed, maxHitSpeed);
			var ratio:Number = (modForce - minHitSpeed) / (maxHitSpeed - minHitSpeed);
			ratio *= _temper;
			
			_aggression += ratio;
		}
		
		protected override function update():void
		{
			if ( !_map )  return;
			
			var theHost:tdSmartBody = host;
			var carPos:amPoint2d = host.position;
			var asCar:tdCarBody = host as tdCarBody;
			
			if ( !asCar )  return;
			
			if ( !_currTrack || !_currTrack.map || _currTrack.map != _map )
			{
				clearHistory();
				
				_currTrack = autoSearchForTrack ? findClosestTrack() : null; // right now just a linear search...might be optimized in some way.
				
				if ( !_currTrack )  return;
				
				unshiftHistory(_currTrack);
				
				currDistance = this.distance;
			}
			
			_currPoint = _currPoint ? _currPoint : _currTrack.lineRep.getPointAtDist(currDistance);
			
			var carNorm:amVector2d = theHost.getNormal();
			var axlePos:amPoint2d  = turnAxis;
			var maxTurnAngle:Number = asCar.maxTurnAngle;
			
			var tetherVec:amVector2d = _currPoint.minus(axlePos);
			var tetherLen:Number = tetherVec.length;
			
			var angle:Number;
			var count:uint = 0;
			
			movePoint();
			
			if ( _aggression )
			{
				aggression = _aggression - _cooldownRate * theHost.world.lastTimeStep;
			}
			
			//--- Adjust pedal based on aggression and the road's speed limit.
			var speedLimit:Number = _currTrack.speedLimit;
			var pedalRatio:Number = speedLimit ? amUtils.constrain(asCar.kinematics.overallSpeed / (speedLimit + speedLimit * aggression), 0, 1) : 0;
			var pedal:Number = Math.sqrt(1 - pedalRatio);
			pedal += aggression;
			pedal = amUtils.constrain(pedal, 0, 1);
			
			//--- Find angle ratio and adjust pedal based on turn angle...i.e. sharp turns have less pedal applied to them.
			angle = carNorm.signedAngleTo(tetherVec);
			angle = amUtils.constrain(angle, -maxTurnAngle, maxTurnAngle);
			var angleRatio:Number = amUtils.sign(angle) * Math.abs(angle) / maxTurnAngle;
			var pedalModifier:Number = angleRatio - _aggression;
			pedalModifier = amUtils.constrain(pedalModifier, 0, 1);
			pedalModifier -= .5;
		//	pedalModifier = 1 - angleRatio;
			pedalModifier = amUtils.constrain(pedalModifier, 0, 1);
			//pedal *= pedalModifier;
			
			//--- Find brake value.
			var stop:Boolean = false;
			var brakes:Number = contactCount ? 1 : 0;
			if ( _aggression > 1 - _temper )
			{
				brakes = 0;
			}
			
			pedal = brakes ? 0 : pedal;
			
			var brake:Number = 0;// tdCar(theHost).getLatSpeed() / (tdCar(theHost).getLatSpeed() + tdCar(theHost).getLongSpeed());

			host.brainPort.NUMBER_PORT_1 = pedal;
			host.brainPort.NUMBER_PORT_2 = angleRatio * maxTurnAngle;
			host.brainPort.NUMBER_PORT_3 = brakes; 
			
			//trace(_aggression, angleRatio);
		}
		
		protected function get distance():Number
		{
			var axlePos:amPoint2d = turnAxis;
			var asLine:amLine2d = _currTrack.lineRep;
			var closestPoint:amPoint2d = asLine.closestPointTo(axlePos);
			var distToTrack:Number = closestPoint.distanceTo(axlePos);
			var tetherMax:Number = Math.min(tetherMaximum, tetherOffset);
			var availableDistance:Number = tetherMax - distToTrack;
			//trace("Avail", availableDistance);
			
			var distance:Number = asLine.point1.distanceTo(closestPoint);
			distance += availableDistance > 0 ? availableDistance : 0;
			distance = amUtils.constrain(distance, 0, asLine.length);
			
			return distance;
		}
		
		protected function get tetherOffset():Number
		{
			var defaultValue:Number = (host as tdCarBody).kinematics.longSpeed * tetherMultiplier;
			return amUtils.constrain(defaultValue, tetherMinimum, tetherMaximum);
		}
		
		private function movePoint():void
		{
			var _currTrackLength:Number = _currTrack.length;
			
			//--- See if any branches are available for the next step.
			var branches:Vector.<tdInternalTrackBranch> = _currTrack.branches;
			var nextDistance:Number = this.distance;
			
			var potentialBranches:Vector.<tdInternalTrackBranch>;
			var freshBranches:Vector.<tdInternalTrackBranch>;
			var lastBranchReached:Boolean = false;
			for (var k:int = 0; k < branches.length; k++) 
			{
				var branch:tdInternalTrackBranch = branches[k];
				
				if ( branch.distance > currDistance && branch.distance <= nextDistance )
				{
					if ( !potentialBranches )
					{
						potentialBranches = new Vector.<tdInternalTrackBranch>();
					}
					potentialBranches.push(branch);
					
					if ( history.indexOf(branch.track) < 0 )
					{
						if ( !freshBranches )
						{
							freshBranches = new Vector.<tdInternalTrackBranch>();
						}
						freshBranches.push(branch);
					}
					
					if ( k == branches.length - 1 )
					{
						lastBranchReached = true;
					}
					else if ( avoidUTurns && k == branches.length - 2 )
					{
						if ( getIndexOnTrack(_currTrack, branch.track) == branch.track.numBranches-1 )
						{
							continue;
						}
						
						var possibleBranchBeforeU:tdTrack = branches[branches.length - 1].track
						var indexOn:int = getIndexOnTrack(_currTrack, possibleBranchBeforeU);
						
						if ( indexOn+1 == possibleBranchBeforeU.numBranches - 1 )
						{
							var possibleU:tdTrack = possibleBranchBeforeU.getBranchAt(indexOn+1);
							
							if ( possibleU.lineRep.isAntidirectionalTo(_currTrack.lineRep, parallelTolerance) )
							{
								lastBranchReached = true;
							}
						}
					}
				}
			}
			
			currDistance = nextDistance;
			
			if ( !potentialBranches )
			{
				//--- If there are no branches, just continue on our merry way.
				keepOnKeepinOn();
			}
			else
			{
				if ( lastBranchReached || freshBranches && Math.random() <= turnChance )
				{
					if ( lastBranchReached && !freshBranches )
					{
						freshBranches = potentialBranches;
					}
					
					//--- Here we're just taking a turn because fate decreed it to happen.  It might happen that every possible turn here is illegal
					//--- in which case we'll just ignore it and go on straight anyway.
					if ( avoidUTurns )
					{
						//--- Here we weed out any fresh branches that happen to be parallel, anti-directional,
						//--- and within a certain distance to a past track traversed.  This is done to prevent U-turns.
						var nonUTurnBranches:Vector.<tdInternalTrackBranch>;
						for (var i:int = 0; i < freshBranches.length; i++) 
						{
							var freshBranch:tdInternalTrackBranch = freshBranches[i];
							
							if ( !checkBranchAgainstHistory(freshBranch) )  continue;
							
							var freshTrackNumBranches:int = freshBranch.track.branches.length;
							var freshTrackIntPoint:amPoint2d = new amPoint2d();
							_currTrack.lineRep.intersectsLine(freshBranch.track.lineRep, freshTrackIntPoint);
							
							var wayOut:Boolean = true;
							
							var index:int = getIndexOnTrack(_currTrack, freshBranch.track);
							if ( index == freshBranch.track.numBranches - 1 )
							{
								wayOut = false; // track is a dead end.
							}
							else if( index == freshBranch.track.numBranches-2 )
							{
								possibleU = freshBranch.track.getBranchAt(index + 1);
								
								if ( possibleU.lineRep.isAntidirectionalTo(_currTrack.lineRep, parallelTolerance) )
								{
									wayOut = false;
								}
							}
							
							if ( wayOut )
							{
								if ( !nonUTurnBranches )
								{
									nonUTurnBranches = new Vector.<tdInternalTrackBranch>();
								}
								
								nonUTurnBranches.push(freshBranch);
							}
						}
						
						//--- If all fresh branches were found to be u-turns, then we just keep going straight.
						if ( nonUTurnBranches )
						{
							changeTracks(nonUTurnBranches);
						}
						else
						{
							if ( lastBranchReached )
							{
								changeTracks(potentialBranches);
							}
							else
							{
								keepOnKeepinOn();
							}
						}
					}
					else
					{
						changeTracks(freshBranches);
					}
				}
				else
				{
					keepOnKeepinOn();
				}
			}
		}
		
		private function checkBranchAgainstHistory(branch:tdInternalTrackBranch):Boolean
		{
			var nextTrack:tdTrack = branch.track;
			var nextTrackLineRep:amLine2d = nextTrack.lineRep;
			
			var branchIntersection:amPoint2d = null;
			
			for (var j:int = 1; j < history.length; j++)
			{
				var jthLineRep:amLine2d = history[j].lineRep;
				
				var anti:Boolean = jthLineRep.isAntidirectionalTo(nextTrackLineRep, parallelTolerance);
				
				if ( anti  )
				{
					var jthMinusOneLineRep:amLine2d = history[j - 1].lineRep;
					
					var historyIntersection:amPoint2d = new amPoint2d();
					if ( !jthLineRep.intersectsLine(jthMinusOneLineRep, historyIntersection) )
					{
						continue;
					}
					
					if ( !branchIntersection )
					{
						branchIntersection = new amPoint2d();
						if ( !nextTrackLineRep.intersectsLine(_currTrack.lineRep, branchIntersection) )
						{
							continue;
						}
					}
					
					if ( historyIntersection.distanceTo(branchIntersection) <= uTurnDistance )
					{
						return false; // branch is not good because it forms a u-turn with a track in history.
					}
				}
			}
			
			return true;
		}
		
		private function keepOnKeepinOn():void
		{
			_currPoint = _currTrack.lineRep.getPointAtDist(currDistance);
		}
		
		private function changeTracks(availableBranches:Vector.<tdInternalTrackBranch>):void
		{
			var nextIndex:int = amUtils.getRandInt(0, availableBranches.length - 1);
			var nextBranch:tdInternalTrackBranch = availableBranches[nextIndex];
			//var nextDistance:Number = currDistance + tetherInc;
			
			
			_currTrack = nextBranch.track;
			currDistance = this.distance;
			_currPoint = _currTrack.lineRep.getPointAtDist(currDistance);
			
			unshiftHistory(_currTrack);
		}
		
		private function unshiftHistory(track:tdTrack):void
		{
			history.unshift(track);
			
			track.addEventListener(tdTrackEvent.TRACK_MOVED, trackChanged, null, true);
			track.addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, trackChanged, null, true);
			
			if ( history.length > historyDepth )
			{
				var popped:tdTrack = history.pop();
				
				stopListening(popped);
			}
		}
		
		private function clearHistory():void
		{
			for (var i:int = 0; i < history.length; i++) 
			{
				stopListening(history[i]);
			}
			history.length = 0;
		}
		
		private function stopListening(track:tdTrack):void
		{
			track.removeEventListener(tdTrackEvent.TRACK_MOVED, trackChanged);
			track.removeEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, trackChanged);
		}
		
		private function trackChanged(evt:qb2ContainerEvent):void
		{
			var track:tdTrack = evt.child as tdTrack;
			
			if ( !track )  return;
			
			stopListening(track);
			
			var index:int = history.indexOf(track);
			if ( index >= 0 )
			{
				history.splice(index, 1);
			}
		}
		
		private static function getDistanceOnTrack(testTrack:tdTrack, otherTrack:tdTrack):Number
		{
			var branches:Vector.<tdInternalTrackBranch> = otherTrack.branches;
			for (var i:int = 0; i < branches.length; i++) 
			{
				if ( branches[i].track == testTrack )
				{
					return branches[i].distance;
				}
			}
			
			return 0;
		}
		
		private static function getIndexOnTrack(testTrack:tdTrack, otherTrack:tdTrack):int
		{
			var branches:Vector.<tdInternalTrackBranch> = otherTrack.branches;
			for (var i:int = 0; i < branches.length; i++) 
			{
				if ( branches[i].track == testTrack )
				{
					return i;
				}
			}
			
			return -1;
		}
		
		public function get useAntenna():Boolean
			{  return _useAntenna;  }
		public function set useAntenna(bool:Boolean):void
		{
			_useAntenna = bool;
			
			refreshAntenna();
		}
		private var _useAntenna:Boolean = true;
		
		public function get antennaLength():Number
			{  return _antennaLength;  }
		public function set antennaLength(value:Number):void
		{
			_antennaLength = value;
			
			refreshAntenna();
		}
		private var _antennaLength:Number = 50;
		
		public function get minAntennaWidth():Number
			{  return _minAntennaWidth;  }
		public function set minAntennaWidth(value:Number):void
		{
			_minAntennaWidth = value;
			
			refreshAntenna();
		}
		private var _minAntennaWidth:Number;
		
		public function get antenna():qb2Tangible
			{  return _antenna;  }
		private var _antenna:qb2Tangible;
		
		protected function makeAntenna():qb2Tangible
		{
			var bb:amBoundBox2d = host.getBoundBox(host);
			var bbWid:Number = bb.width;
			var wid:Number = bbWid < _minAntennaWidth ? _minAntennaWidth : bbWid;
			
			var tri:qb2Shape = qb2Stock.newIsoTriShape(bb.topCenter, wid, _antennaLength, 0, 0);
			tri.turnFlagOff(qb2_flags.JOINS_IN_DEBUG_DRAWING | qb2_flags.IS_DEBUG_DRAGGABLE );
			
			return tri;
		}
		
		private function geomChanged(evt:qb2MassEvent):void
		{
			if ( !addingOrRemovingAntenna )
			{
				refreshAntenna();
			}
		}
		
		protected final function refreshAntenna():void
		{
			if ( _antenna && _antenna.parent == host )
			{
				addingOrRemovingAntenna = true;
				{
					delete antennaDict[_antenna];
					_antenna.removeFromParent();
				}
				addingOrRemovingAntenna = false;
				
				_antenna.removeEventListener(qb2ContactEvent.CONTACT_STARTED, antennaHit);
				_antenna.removeEventListener(qb2ContactEvent.CONTACT_ENDED, antennaHit);
				
				contactCount = 0;
				
				_antenna = null;
			}
			
			if ( _useAntenna && _hasHost )
			{
				addingOrRemovingAntenna = true;
				{
					_antenna = makeAntenna();
					antennaDict[_antenna] = true;
					_antenna.mass = 0;
					host.addObject(_antenna);
				}
				addingOrRemovingAntenna = false;
				
				_antenna.addEventListener(qb2ContactEvent.CONTACT_STARTED, antennaHit, null, true);
				_antenna.addEventListener(qb2ContactEvent.CONTACT_ENDED,   antennaHit, null, true);
				
				_antenna.isGhost = true;
			}
		}
		
		private var contactCount:int = 0;
		
		private function antennaHit(evt:qb2ContactEvent):void
		{
			if ( isAntenna(evt.otherShape) || evt.otherShape.mass == 0 )  return;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				contactCount++;
			}
			else
			{
				contactCount--;
			}
		}
		
		private function isAntenna(shape:qb2Shape):Boolean
		{
			if ( antennaDict[shape] )  return true;
			
			for ( var key:* in antennaDict )
			{
				var antenna:qb2Tangible = key as qb2Tangible;
				
				if ( !(antenna is qb2ObjectContainer) )  continue;
				
				if ( shape.isDescendantOf(antenna as qb2ObjectContainer) )
				{
					return true;
				}
			}
			
			return false;
		}
		
		private var addingOrRemovingAntenna:Boolean = false;
		
		//--- Right now just a linear algorithm...might be optimized in some way if you have an insane amount of roads.
		protected function findClosestTrack():tdTrack
		{
			var numObjects:int = _map.numObjects;
			var closestTrack:tdTrack = null;
			var closestDistance:Number = Number.MAX_VALUE;
			
			var carPos:amPoint2d = host.position;
			
			for (var i:int = 0; i < numObjects; i++) 
			{
				var ithObject:qb2Object = _map.getObjectAt(i);
				
				if ( !(ithObject is tdTrack) )  continue;
				
				var ithTrack:tdTrack = ithObject as tdTrack;
				var asLine:amLine2d = ithTrack.lineRep;
				var distToTrack:Number = asLine.distanceToPoint(carPos);
				
				if ( distToTrack < closestDistance )
				{
					closestTrack    = ithTrack;
					closestDistance = distToTrack;
				}
			}
			
			return closestTrack;
		}
		
		protected function get turnAxis():amPoint2d
		{
			var carNorm:amVector2d = host.getNormal();
			var axlePos:amPoint2d  = host.position.translatedBy(carNorm.scaleBy( -(host as tdCarBody).turnAxis));
			return axlePos;
		}
		
		public override function drawDebug(graphics:srGraphics2d):void
		{
			if ( _antenna && (td_debugDrawSettings.flags & td_debugDrawFlags.ANTENNAS) )
			{
				graphics.setLineStyle();
				graphics.beginFill(td_debugDrawSettings.antennaColor, qb2_debugDrawSettings.fillAlpha);
				_antenna.draw(graphics);
				graphics.endFill();
			}
			
			if ( td_debugDrawSettings.flags & td_debugDrawFlags.TRACK_TETHERS )
			{
				if ( !_currTrack || !_currPoint )  return;
			
				var carPos:amPoint2d = host.position;
				var asCar:tdCarBody = host as tdCarBody;
				
				if ( !asCar )  return;
			
				
				var axlePos:amPoint2d = turnAxis;
				var tetherVec:amVector2d = _currPoint.minus(axlePos);
				graphics.setLineStyle(td_debugDrawSettings.tetherThickness, td_debugDrawSettings.tetherColor, td_debugDrawSettings.tetherAlpha);
				tetherVec.draw(graphics, axlePos, 0, 0, 1);
			}
		}
	}
}