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

package TopDown.objects
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import TopDown.*;
	import TopDown.ai.*;
	import TopDown.carparts.*;
	import TopDown.internals.*;
	
	use namespace td_friend;
	
	use namespace qb2_friend;
	
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdCarBody extends tdSmartBody
	{
		public var rollingFrictionWithThrottle:Boolean = false;
		public var rollingFrictionWithBrakes:Boolean = false;
		
		td_friend static var MINIMUM_LINEAR_VELOCITY:Number = .01;
		td_friend static var SKID_SLOP:Number = .00000001; // fixes floating point round-off errors that cause a tire to not set isSkidding to true when it sometimes should.
		td_friend static var STOPPED_SLOP:Number = .0000001; // car speed below this just sets the car's velocities to zero...
		
		public var maxTurnAngle:Number = Math.PI / 4;
		public var turnAxis:Number = 0;
		public var zCenterOfMass:Number = 1;
		
		//--- If brakes ever get implemented 'correctly', these variables will be needed.
		/*public var brakePadFriction:Number  = .5;
		public var brakeForceMaximum:Number = 50000;  // maximum force that can be applied to brake pads
		public var brakeDiscRadius:Number   = .2     // how far away from a tire's rotational axis that the brake force is applied.*/
		
		public var parked:Boolean          = false;
		public var tractionControl:Boolean = true;
		public var autoSetTurnAxis:Boolean = true;

		td_friend var tires:Vector.<tdTire> = new Vector.<tdTire>();
		
		td_friend var numDrivenTires:uint = 0;
		
		td_friend var _currTurnAngle:Number = 0;
		
		td_friend var _kinematics:tdKinematics = new tdKinematics();
		
		td_friend var freezeTireCalc:Boolean = false;
		
		protected var axle:tdInternalAxleLayout = null;
		
		public var testTiresIndividuallyAgainstTerrains:Boolean = true;

		public function tdCarBody()
		{
			super();
			init();
		}
		
		private function init():void
		{
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved,    null, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved,    null, true);
			addEventListener(qb2ContainerEvent.INDEX_CHANGED,      indexChanged,      null, true);
			addEventListener(qb2MassEvent.MASS_PROPS_CHANGED,      massPropsUpdated,  null, true);
			addEventListener(qb2ContainerEvent.ADDED_OBJECT,       justAddedObject,   null, true);
			addEventListener(qb2ContainerEvent.REMOVED_OBJECT,     justRemovedObject, null, true);
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			invalidateTireMetrics();
			
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				_map = getAncestorOfType(tdMap) as tdMap;
			}
			else
			{
				_map = null;
			}
		}
		
		private function indexChanged(evt:qb2ContainerEvent):void
		{
			_world._terrainRevisionDict[this] = -1; // let this car know that it needs to update its terrain list on the next pass.
		}
		
		public function get map():tdMap
			{  return _map;  }
		private var _map:tdMap;
		
		private function invalidateTireMetrics():void
		{
			for ( var i:int = 0; i < tires.length; i++ )
			{
				tires[i].invalidateMetrics();
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:tdCarBody = super.clone(deep) as tdCarBody;
			
			cloned.parked = this.parked;
			cloned.maxTurnAngle = this.maxTurnAngle;
			cloned.tractionControl = this.tractionControl;
			cloned.zCenterOfMass = this.zCenterOfMass;
			cloned.autoSetTurnAxis = this.autoSetTurnAxis;
			cloned.rollingFrictionWithBrakes = this.rollingFrictionWithBrakes;
			cloned.rollingFrictionWithThrottle = this.rollingFrictionWithThrottle;
			
			return cloned;
		}
		
		public function get engine():tdEngine
			{  return _engine;  }
		td_friend var _engine:tdEngine = null;
		
		public function get tranny():tdTransmission
			{  return _tranny;  }
		td_friend var _tranny:tdTransmission = null;
			
		public function get reversing():Boolean
			{  return kinematics.longSpeed < 0;  }
			
		public function get kinematics():tdKinematics
			{  return _kinematics;  }
	
		public function get currTurnAngle():Number
			{  return _currTurnAngle;  }
			
		private function justAddedObject(evt:qb2ContainerEvent):void
		{
			var object:qb2Object = evt.child;
			
			if ( object is tdTire )
			{
				var tire:tdTire = object as tdTire;
				tire._carBody = this;
				
				if ( tire.isDriven )  numDrivenTires++;
				
				tire.invalidateMetrics();
				
				tires.push(tire);
				
				calcTireShares();
			}
			else if ( object is tdEngine )
			{
				_engine = object as tdEngine;
				_engine._carBody = this;
			}
			else if ( object is tdTransmission )
			{
				_tranny = object as tdTransmission;
				_tranny._carBody = this;
			}
		}
		
		private function justRemovedObject(evt:qb2ContainerEvent):void
		{
			var object:qb2Object = evt.child;
			
			if ( object is tdTire )
			{
				var tire:tdTire = object as tdTire;
				
				tire._carBody = null;
				
				tire.invalidateMetrics();
				
				tires.splice(tires.indexOf(tire), 1);
				
				calcTireShares();
			}
			else if ( object is tdEngine )
			{
				_engine._carBody = null;
				_engine = null;
			}
			else if ( object is tdTransmission )
			{
				_tranny._carBody = null;
				_tranny = null;
			}
		}
		
		td_friend function calcTireShares():void
		{
			if ( freezeTireCalc )  return;
			
			if ( !tires.length )
			{
				axle = null;
				return;
			}
			
			var centroid:amPoint2d = this.getLocalPoint(this.centerOfMass, this.parent);
			//trace("calcling tires");
	
			axle = axle ? axle : new tdInternalAxleLayout();
			var totMass:Number = this.mass;
			axle.avgLeft = axle.avgRight = 0;// centroid.x;
			axle.avgTop = axle.avgBot = 0;// centroid.y;
			
			var avgTurnAxis:Number = 0;
			var numTurningTires:int = 0;
			
			axle.numLeft = axle.numRight = axle.numTop = axle.numBot = 0;
			
			for ( var i:int = 0; i < tires.length; i++ )
			{
				var iTire:tdTire = tires[i];
				
				if ( iTire.canTurn )
				{
					avgTurnAxis += iTire.position.y
					numTurningTires++;
				}
				
				iTire.quadrant = 0;
			
				if ( iTire._position.y <= centroid.y )
				{
					iTire.quadrant |= tdTire.QUAD_TOP;
					axle.avgTop += iTire._position.y;
					axle.numTop++;
				}
				else
				{
					iTire.quadrant |= tdTire.QUAD_BOT;
					axle.avgBot += iTire._position.y;
					axle.numBot++;
				}
				
				if ( iTire._position.x >= centroid.x )
				{
					iTire.quadrant |= tdTire.QUAD_RIGHT;
					axle.avgRight += iTire._position.x;
					axle.numRight++;
				}
				else
				{
					iTire.quadrant |= tdTire.QUAD_LEFT;
					axle.avgLeft += iTire._position.x;
					axle.numLeft++;
				}
			}
			
			turnAxis = autoSetTurnAxis ? avgTurnAxis / numTurningTires : turnAxis;
			
			axle.avgTop   /= axle.numTop;
			axle.avgBot   /= axle.numBot;
			axle.avgLeft  /= axle.numLeft;
			axle.avgRight /= axle.numRight;
			
			if ( !axle.numTop )
			{
				axle.numTop = 1;
				axle.avgTop = centroid.y - (axle.avgBot - centroid.y);
			}
			
			if ( !axle.numBot )
			{
				axle.numBot = 1;
				axle.numBot = centroid.y - (axle.avgTop - centroid.y);
			}
			
			if ( !axle.numLeft )
			{
				axle.numLeft = 1;
				axle.numLeft = centroid.x - (axle.avgRight - centroid.x);
			}
			
			if ( !axle.numRight )
			{
				axle.numRight = 1;
				axle.numRight = centroid.x - (axle.avgLeft - centroid.x);
			}
			
			turnAxis = axle.avgTop;
			
			
			
			//--- Calculate mass share. The mass share of a tire times the world's
			//--- z gravity determines the at-rest load on a tire.
			var baseHeight:Number = axle.avgBot - axle.avgTop;
			var baseWidth:Number = axle.avgRight - axle.avgLeft;
			for ( i = 0; i < tires.length; i++ )
			{
				iTire = tires[i];
				
				var upDownMass:Number = 0;
				
				if ( iTire.quadrant & tdTire.QUAD_TOP )
				{
					var ratio:Number = (Math.abs(centroid.y - axle.avgBot) / baseHeight);
					upDownMass = (ratio ? ratio : 1) * totMass;
					upDownMass /= axle.numTop;
				}
				else
				{
					ratio = (Math.abs(centroid.y - axle.avgTop) / baseHeight);
					upDownMass = (ratio ? ratio : 1) * totMass;
					upDownMass /= axle.numBot;
				}
				
				var leftRightMass:Number = 0;
				
				if ( iTire.quadrant & tdTire.QUAD_RIGHT )
				{
					ratio = (Math.abs(centroid.x - axle.avgLeft) / baseWidth);
					leftRightMass = (ratio ? ratio : 1) * totMass;
					leftRightMass /= axle.numRight;
				}
				else
				{
					ratio = (Math.abs(centroid.x - axle.avgRight) / baseWidth);
					leftRightMass = (ratio ? ratio : 1) * totMass;
					leftRightMass /= axle.numLeft;
				}
				
				iTire._massShare = leftRightMass / 2 + upDownMass / 2;
			}
		}
		
		private static var reusableTerrainList:Vector.<qb2Terrain> = new Vector.<qb2Terrain>();
		private static var terrainIterator:qb2TreeTraverser = new qb2TreeTraverser();
		
		protected override function update():void
		{
			super.update();
			
			if ( !axle )  return;
			
			if( _world._terrainRevisionDict[this] != _world._globalTerrainRevision )
			{
				populateTerrainsBelowThisTang();
			}
			
			var pedal:Number = brainPort.NUMBER_PORT_1;
			var turn:Number  = brainPort.NUMBER_PORT_2;
			var brake:Number = brainPort.NUMBER_PORT_3;
			
			var lengthSquared:Number = linearVelocity.lengthSquared;
			if ( lengthSquared && angularVelocity && lengthSquared < STOPPED_SLOP && angularVelocity < STOPPED_SLOP )
			{
				this.linearVelocity.zeroOut();
				this.angularVelocity = 0;
			}
			
			_currTurnAngle = turn;

			var driveTorquePerTire:Number = 0;
			if ( _engine && _tranny )
			{
				_tranny.relay_update();
				_engine.throttle(Math.abs(pedal));
				driveTorquePerTire = tranny.calcTireTorque(engine.torque) / numDrivenTires;
				driveTorquePerTire = tranny.inReverse ? -driveTorquePerTire : driveTorquePerTire;
			}
			
			var avgRadsPerSec:Number = 0;
			
			if ( parked )  brake = 1;  // Override braking for if the car is parked...like as if it had its parking brake on.
			
			//--- Get some vectors for orientation/speed.
			var carVec:amVector2d = this.getNormal();
			var turnVec:amVector2d = new amVector2d();
			var sideVec:amVector2d = carVec.perpVector(1);
			var carLinVel:amVector2d = this.linearVelocity.clone();
			
			//--- Figure out the accelerations/velocities of this body by comparing things from last frame.
			_kinematics._overallSpeed = carLinVel.length;
			carLinVel.normalize();
			var longDot:Number = carLinVel.dotProduct(carVec);
			var latDot:Number = carLinVel.dotProduct(sideVec);
			var tempLongSpeed:Number = _kinematics._overallSpeed * longDot;
			var tempLatSpeed:Number = _kinematics._overallSpeed * latDot;
			_kinematics._longAccel = tempLongSpeed - _kinematics._longSpeed;
			_kinematics._latAccel = tempLatSpeed - _kinematics._latSpeed;
			_kinematics._longAccel /= _world.lastTimeStep;
			if ( isNaN(_kinematics._longAccel) )  _kinematics._longAccel = 0;
			_kinematics._latAccel /= _world.lastTimeStep;
			if ( isNaN(_kinematics._latAccel) )  _kinematics._latAccel = 0;
			_kinematics._longSpeed = tempLongSpeed;
			_kinematics._latSpeed = tempLatSpeed;
			
			//--- Calculate weight transfer and center of mass. This is later factored into each tire's load.
			//--- Tires like on a motorcycle will have 0 lateral weight transfer applied, because in real
			//--- life the driver is responsible for adjusting center of mass to keep lateral tranfer zeroed out.
			var totMass:Number = this.mass;
			var vertDiff:Number = axle.avgBot   - axle.avgTop,
				horDiff:Number  = axle.avgRight - axle.avgLeft;
			var longTransfer:Number = vertDiff ? (zCenterOfMass / vertDiff) * totMass * _kinematics._longAccel : 0;
			var latTransfer:Number  = horDiff  ? (zCenterOfMass / horDiff)  * totMass * _kinematics._latAccel  : 0;
			
			reusableTerrainList.length = 0;
			if ( _terrainsBelowThisTang )
			{
				var globalTerrains:Vector.<qb2Terrain> = _terrainsBelowThisTang;
				for (var j:int = globalTerrains.length-1; j >= 0; j--) 
				{
					var jthTerrain:qb2Terrain = globalTerrains[j];
					if ( jthTerrain.ubiquitous )
					{
						reusableTerrainList.unshift(jthTerrain);
					}
					else if( _contactTerrainDict && _contactTerrainDict[jthTerrain] )
					{
						reusableTerrainList.unshift(jthTerrain);
					}
				}
			}

			//--- Iterate through the tires, applying various forces to the body at the tires' locations.
			var actualNumDrivenTires:int = numDrivenTires;
			for ( var i:uint = 0; i < tires.length; i++ )
			{			
				var tire:tdTire = tires[i];
				
				tire._currTurnAngle = tire.canTurn ? _currTurnAngle : 0;
				tire._currTurnAngle = tire.flippedTurning ? -tire._currTurnAngle : tire._currTurnAngle;
				if ( tire.actor )  tire.actor.setRotation(tire._currTurnAngle * TO_DEG);
				tire._wasSkidding = tire._isSkidding;
				tire._isSkidding = false;
				
				var worldTirePos:amPoint2d = tire.getWorldPosition();
				
				//--- Figure out the load on this tire based on its mass share and the body's acceleration/weight transfer.
				tire._load = tire._massShare * _world.gravityZ;
				if ( tire.quadrant & tdTire.QUAD_TOP )
					tire._load -= longTransfer / axle.numTop;
				else
					tire._load += longTransfer / axle.numBot;
				if ( tire.quadrant & tdTire.QUAD_RIGHT )
					tire._load -= latTransfer / axle.numRight;
				else
					tire._load += latTransfer / axle.numLeft;

					
				const tireLoad:Number = tire._load < 0 ? 0 : tire._load; // A tire can have a negative load (e.g. if it would be up in the air in a 3d simulation), so load in this case must be manually set to 0.

				//--- If the load on the tire is <= zero, it means it's actually up in the air, and thus incapable of delivering forces to the car's chassis.
				//--- In real life, this means that the car would be doing a wheelie or rolling or something. This is just a 2d simulation though, unfortunately :)
				//if ( tire._load <= 0 )  continue;

				//--- Get the tire's overall speed and direction of movement.
				var worldTireLinVel:amVector2d = this.getLinearVelocityAtPoint(worldTirePos);
				var tireSpeed:Number = worldTireLinVel.length;
				tire._linearVelocity.copy(worldTireLinVel);
				var tireMovementDirection:amVector2d = worldTireLinVel.normalize();
				
				//--- Get the vectors describing the tire's orientation.
				turnVec.copy(carVec).rotateBy(tire._currTurnAngle);
				var tireOrientation:amVector2d = tire.canTurn ? turnVec.clone() : carVec.clone();
				var tireSideways:amVector2d    = tireOrientation.perpVector();
				tireSideways = Math.abs(tireSideways.angleTo(tireMovementDirection)) < Math.PI / 2 ? tireSideways.negate() : tireSideways;
				
				var dot:Number = tireMovementDirection.dotProduct(tireOrientation);
				if ( isNaN(dot) )  dot = 0;
				var tireSpeedLong:Number = (tireSpeed * dot);
				tire._baseRadsPerSec = tireSpeedLong / tire.metricRadius;
				
				if ( this.isSleeping && !pedal && !tire._extraRadsPerSec )  continue;  // skip sleeping bodies to boost performance.
				
				var highestTerrain:qb2Terrain = null;
				
				var frictionMultiplier:Number = 1, rollingFrictionMultiplier:Number = 1;
				if ( reusableTerrainList.length )
				{
					for ( j = reusableTerrainList.length-1; j >= 0; j-- )
					{
						jthTerrain = reusableTerrainList[j];
						
						if ( jthTerrain.ubiquitous || !testTiresIndividuallyAgainstTerrains )
						{
							highestTerrain = jthTerrain;
							break;
						}
						else if( jthTerrain.testPoint(worldTirePos) )
						{
							highestTerrain = jthTerrain;
							break;
						}
					}
				}
				
				if ( highestTerrain )
				{
					frictionMultiplier *= highestTerrain.frictionZMultiplier;
					
					if ( highestTerrain is tdTerrain )
					{
						rollingFrictionMultiplier *= (highestTerrain as tdTerrain).rollingFrictionZMultiplier;
					}
				}
				
				//--- Some helpers...
				var force:Number = 0;
				const tireFric:Number = tire.friction * frictionMultiplier;
				var fricForce:Number = tireFric * tireLoad;
				const tireSpinDirection:Number = amUtils.sign(tire.radsPerSec);
				
				var totalTorque:Number = 0;
				
				if ( tire._extraRadsPerSec )
				{
					var torqueFromExtraSpin:Number = fricForce * tire.metricRadius * amUtils.sign(tire._extraRadsPerSec);
					
					totalTorque += torqueFromExtraSpin;
					
					const negatingAccel:Number = torqueFromExtraSpin / tire.metricInertia;
				
					const radsPerSecDiff:Number = negatingAccel * world.lastTimeStep;
				
					var was:Number = tire._extraRadsPerSec;
					tire._extraRadsPerSec -= radsPerSecDiff;
					
					if ( was < 0 && tire._extraRadsPerSec > 0 || was > 0 && tire._extraRadsPerSec < 0 )
					{
						tire._extraRadsPerSec = 0;
					}
				}
				
				//--- Apply engine power to the tire if appropriate.
				if( tire.isDriven && tranny )
				{
					totalTorque += driveTorquePerTire;
				}
				
				force = totalTorque / tire.metricRadius;
				
				var absForce:Number = Math.abs(force);
				if ( absForce >= fricForce - SKID_SLOP )
				{
					tire._isSkidding = !tractionControl;
					force = fricForce * amUtils.sign(force);
					
					if ( !tractionControl && absForce > fricForce )
					{
						const leftOverTorque:Number = (absForce - fricForce) * tire.metricRadius;
						const leftOverAccel:Number = leftOverTorque / tire.metricInertia;
						tire._extraRadsPerSec += amUtils.sign(force) * leftOverAccel * world.lastTimeStep;
					}
				}

				if( force )
					this.applyForce(worldTirePos, tireOrientation.scaledBy(force));
					
				if ( tire.canBrake && brake )
				{
					var negater:Number = tireSpeedLong * tireLoad;
					var brakeForce:Number = negater > fricForce ? fricForce * -tireSpinDirection : -negater;
					if( brakeForce )
						this.applyForce(worldTirePos, tireOrientation.scaledBy(brakeForce));
					tire._isSkidding = true
					tire._baseRadsPerSec = tire._extraRadsPerSec = 0;
					
					if ( tire.isDriven )
					{
						actualNumDrivenTires--;
					}
				}
				else
				{
					tire.rotation += (tire.radsPerSec * _world.lastTimeStep);
				}
				
				//--- Handle rolling friction.
				if ( (rollingFrictionWithThrottle || pedal == 0) && (rollingFrictionWithBrakes || brake == 0) )
				{
					var rollingFriction:Number = tire.rollingFriction * rollingFrictionMultiplier;
					var rollingFrictionForce:Number = tire.massShare * (rollingFriction * -tireSpeedLong);
					rollingFrictionForce *= 1 - amUtils.constrain(turn / maxTurnAngle, 0, 1);
					if ( rollingFrictionForce )
					{
						this.applyForce(worldTirePos, tireOrientation.scaledBy(rollingFrictionForce));
					}
				}
					
				if( tire.isDriven && tranny )
					avgRadsPerSec += tranny.calcRadsPerSecInv(tire.radsPerSec);
				

				//--- Get the lateral component of the tire's speed and calculate a force that negates it.
				dot = Math.abs(tireMovementDirection.dotProduct(tireSideways));
				dot = isNaN(dot) ? 1 : dot;  // just to be safe
				force = (tireSpeed * dot) * tireLoad;

				//--- If the force is greater than the friction opposition force, start skidding.
				if ( force > fricForce)
				{
					tire._isSkidding = true;
					force = fricForce;
				}
	
				//--- Apply lateral friction force.
				if ( force )
				{
					this.applyForce(worldTirePos, tireSideways.scaleBy(force * 1));
				}
				
				if ( highestTerrain && (highestTerrain is tdTerrain) )
				{
					var highestTdTerrain:tdTerrain = highestTerrain as tdTerrain;
					
					var drawSliding:Boolean = highestTdTerrain.drawSlidingSkids && tire._isSkidding;
					var drawRolling:Boolean = highestTdTerrain.drawRollingSkids;
					
					if ( drawSliding || drawRolling )
					{
						var start:amPoint2d = null, end:amPoint2d = worldTirePos;
						
						if ( tire.lastWorldPos )
						{
							start = tire.lastWorldPos;
						}
						else
						{
							var translater:amVector2d = linearVelocity.normal.scaleBy( -worldPixelsPerMeter * world.lastTimeStep);
							
							if ( !translater.isNaNVec() )
								start = worldTirePos.translatedBy(linearVelocity.normal.scaleBy( -worldPixelsPerMeter * world.lastTimeStep));
							else
								start = worldTirePos;
						}
						
						highestTdTerrain.addSkid(start, end, tire._width, drawSliding ? tdTerrain.SKID_TYPE_SLIDING : tdTerrain.SKID_TYPE_ROLLING);
					}
				}
				
				tire.lastWorldPos = worldTirePos;
			}
			
			//--- Feed average driven tire speed back into the engine, because it's all connected.
			if ( _engine)
			{
				_engine.setRadsPerSec(actualNumDrivenTires ? Math.abs(avgRadsPerSec / actualNumDrivenTires) : 0);
			}
		}
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			for (var i:int = 0; i < tires.length; i++) 
			{
				var tire:tdTire = tires[i];
				tire.scaleBy(xValue, yValue);
			}
			
			return super.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors);
		}
		
		td_friend function registerContactTerrain(terrain:qb2Terrain):void
		{
			if ( !_contactTerrainDict )
			{
				_contactTerrainDict = new Dictionary(false);
				_contactTerrainDict[NUM_TERRAINS] = 0;
			}
			
			_contactTerrainDict[terrain] = true;
			_contactTerrainDict[NUM_TERRAINS]++;
		}
		
		td_friend function unregisterContactTerrain(terrain:qb2Terrain):void
		{
			delete _contactTerrainDict[terrain];
			_contactTerrainDict[NUM_TERRAINS]--;
			
			if ( _contactTerrainDict[NUM_TERRAINS] == 0 )
			{
				_contactTerrainDict = null;
			}
		}
		
		private static const NUM_TERRAINS:String = "numTerrains";
		
		private var _contactTerrainDict:Dictionary = null;

		public override function toString():String
		{
			return "[tdCarBody()]";
		}
		
		private function massPropsUpdated(evt:qb2MassEvent):void
		{
			calcTireShares();
		}
	}
}