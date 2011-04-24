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

package TopDown.carparts
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.events.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import revent.rEvent;
	import surrender.srGraphics2d;
	import TopDown.*;
	import TopDown.debugging.*;
	import TopDown.internals.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTire extends qb2Object
	{
		td_friend static const QUAD_LEFT:uint = 1;
		td_friend static const QUAD_RIGHT:uint = 2;
		td_friend static const QUAD_TOP:uint = 4;
		td_friend static const QUAD_BOT:uint = 8;
		
		td_friend var quadrant:uint = 0;

		td_friend var _position:amPoint2d;
		
		td_friend var _radius:Number = 10;
		td_friend var _width:Number = 7;
		
		td_friend var _rotation:Number = 0;
		
		td_friend var _metricInertia:Number;
		td_friend var _metricRadius:Number;
		td_friend var _metricWidth:Number;
		
		td_friend var _mass:Number = 20;
		
		td_friend const _linearVelocity:amVector2d = new amVector2d();

		public var friction:Number = 1.5
		public var rollingFriction:Number = .01;
		
		public var isDriven:Boolean = false;
		public var canTurn:Boolean  = false;
		public var canBrake:Boolean = false;
		public var flippedTurning:Boolean = false;
		
		td_friend var _isSkidding:Boolean = false, _wasSkidding:Boolean = false;
		td_friend var _currTurnAngle:Number = 0;
		td_friend var _baseRadsPerSec:Number = 0;
		td_friend var _extraRadsPerSec:Number = 0;
		
		//td_friend var terrains:Vector.<tdTerrain> = new Vector.<tdTerrain>();

		td_friend var _load:Number = 0;
		td_friend var _massShare:Number = 0;
		
		public function tdTire(initPosition:amPoint2d = null, initWidth:Number= 6, initRadius:Number = 10, initIsDriven:Boolean = false, initCanTurn:Boolean = false, initCanBrake:Boolean = false, initFriction:Number = 1, initRollingFriction:Number = .1 )
		{
			super();
			init(initPosition, initWidth, initRadius, initIsDriven, initCanTurn, initCanBrake, initFriction, initRollingFriction);
		}
		
		private function init(initPosition:amPoint2d = null, initWidth:Number= 6, initRadius:Number = 10, initIsDriven:Boolean = false, initCanTurn:Boolean = false, initCanBrake:Boolean = false, initFriction:Number = 1, initRollingFriction:Number = .1):void
		{
			position = initPosition ? initPosition : new amPoint2d();
			
			isDriven = initIsDriven;
			canTurn = initCanTurn;
			canBrake = initCanBrake;
			friction = initFriction;
			rollingFriction = initRollingFriction;
			
			width = initWidth;
			radius = initRadius;
			
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved);
		}
		
		private function addedOrRemoved(evt:rEvent):void
		{
			lastWorldPos = null;
		}
		
		td_friend var lastWorldPos:amPoint2d = null;
		
		public function get carBody():tdCarBody
			{  return _carBody;  }
		td_friend var _carBody:tdCarBody;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var tire:tdTire = super.clone(deep) as tdTire;
			
			tire.position.copy(this.position);
			tire.canBrake = this.canBrake;
			tire.isDriven = this.isDriven;
			tire.canTurn  = this.canTurn;
			tire.rollingFriction = this.rollingFriction;
			tire.friction = this.friction;
			tire.mass = this.mass;
			tire.radius = this.radius;
			tire.width = this.width;
			tire.flippedTurning = this.flippedTurning;
			
			return tire;
		}
		
		private function updateActor():void
		{
			if ( !actor )  return;
			
			actor.x = position.x;
			actor.y = position.y;
			actor.rotation = _currTurnAngle * TO_DEG;
		}
		
		public function get linearVelocity():amVector2d
			{  return _linearVelocity;  }
		
		/*public function get numTerrains():uint
			{  return terrains.length;  }
		
		public function getTerrainAt(index:uint):tdTerrain
			{  return terrains[index];  }
			
		public function get highestTerrain():tdTerrain
		{
			if ( !terrains.length )  return null;
		
			var highest:tdTerrain = terrains[0];
			for ( var i:uint = 1; i < terrains.length; i++)
			{
				var terrain:tdTerrain = terrains[i];
				if ( terrain.priority > highest.priority )
				{
					highest = terrain;
				}
			}
			
			return highest;
		}*/

		
		
		private var metricsValidated:Boolean = false;
		
		public function get metricInertia():Number
		{
			validateMetrics();
			return _metricInertia;
		}
		
		public function get metricRadius():Number
		{
			validateMetrics();
			return _metricRadius;
		}
		public function set metricRadius(value:Number):void
			{  radius = value * worldPixelsPerMeter;  }
		
		public function get metricWidth():Number
		{
			validateMetrics();
			return _metricWidth;
		}
		public function set metricWidth(value:Number):void
			{  width = value * worldPixelsPerMeter;  }
		
		public function get radius():Number
			{  return _radius;  }
		public function set radius(value:Number):void
		{
			_radius = value;
			invalidateMetrics();
		}
		
		public function get width():Number
			{  return _width;  }
		public function set width(value:Number):void
		{
			_width = value;
			invalidateMetrics();
		}
		
		private function validateMetrics():void
		{
			if ( metricsValidated )  return;
			
			_metricRadius = _radius / worldPixelsPerMeter;
			_metricWidth = _width / worldPixelsPerMeter;
			_metricInertia = (_mass * (_metricRadius * _metricRadius)) / 2;
			
			metricsValidated = true;
		}
		
		td_friend function invalidateMetrics():void
		{
			metricsValidated = false;
		}
		
		
		public function get position():amPoint2d
			{  return _position;  }
		public function set position(newPoint:amPoint2d):void
		{
			if ( _position )  _position.removeEventListener(amUpdateEvent.ENTITY_UPDATED, pointUpdated);
			_position = newPoint;
			_position.addEventListener(amUpdateEvent.ENTITY_UPDATED, pointUpdated);
			pointUpdated(null);
		}
		
		public function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null):void
		{
			_position.scaleBy(xValue, yValue, origin);
			width *= Math.abs(xValue);
			radius *= Math.abs(yValue);
		}
		
		private function pointUpdated(evt:amUpdateEvent):void
		{
			if ( _carBody )
				_carBody.calcTireShares();
				
			updateActor();
		}

		public function getWorldPosition():amPoint2d
		{
			if ( _carBody )
			{
				return _carBody.getWorldPoint(_position);
			}
			
			return _position.clone();
		}
		
		public function getWorldNormal():amVector2d
		{
			var localVec:amVector2d = amVector2d.newRotVector(0, -1, _currTurnAngle);
			if ( _carBody )
			{
				return _carBody.getWorldVector(localVec);
			}
			
			return localVec;
		}
			
		public function get isSkidding():Boolean
			{  return _isSkidding;  }
			
		public function get wasSkidding():Boolean
			{  return _wasSkidding;  }
			
		public function get currTurnAngle():Number
			{  return _currTurnAngle;  }

		/// The total force pushing down on this tire in Newtons, as of the last time step taken.
		/// This considers the world's zGravity, the mass of the car, the number of other tires and their positions, and load transfer while accelerating/turning.
		public function get load():Number
			{  return _load;  }
			
		public function get massShare():Number
			{  return _massShare;  }
			
		public function set mass(value:Number):void
		{
			_mass = mass;
			invalidateMetrics();
		}
		
		public function get mass():Number
			{  return _mass;  }
			
		public function set rotation(value:Number):void
		{
			_rotation = value % (Math.PI * 2);
			_rotation = _rotation < 0 ? Math.PI * 2 + _rotation : _rotation;
		}
			
		public function get rotation():Number
			{  return _rotation;  }
	
		public function get circumference():Number
			{  return 2 * _radius * Math.PI;  }

		public function get radsPerSec():Number
			{  return _baseRadsPerSec + _extraRadsPerSec;  }

		public function get rpm():Number
			{  return qb2UnitConverter.radsPerSec_to_RPM(radsPerSec);  }
			
			
		public override function drawDebug(graphics:srGraphics2d):void
		{
			var drawFlags:uint = td_debugDrawSettings.flags;
			var drawTires:Boolean = drawFlags & td_debugDrawFlags.TIRES ? true : false;
			var drawLoads:Boolean = drawFlags & td_debugDrawFlags.TIRE_LOADS ? true : false;
			
			if ( drawTires || drawLoads )
			{
				var tireScale:Number = td_debugDrawSettings.tireScale;
				var pixPerMeter:Number = this.worldPixelsPerMeter;
				var realRadius:Number = _radius * tireScale;
				var realWidth:Number = _width * tireScale;
				
				var worldPoint:amPoint2d = this.getWorldPosition();
				var localVec:amVector2d = amVector2d.newRotVector(0, -realRadius, _currTurnAngle);
				var worldVec:amVector2d = _carBody ? _carBody.getWorldVector(localVec) : localVec;
				var sideVec:amVector2d = worldVec.perpVector( -1).setLength( realWidth / 2);
				
				worldPoint.translateBy(worldVec).translateBy(sideVec);
				sideVec.negate().scaleBy(2);
				worldVec.negate().scaleBy(2);
				
				if ( drawTires )
				{
					graphics.beginFill(td_debugDrawSettings.tireFillColor, qb2_debugDrawSettings.fillAlpha);
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, td_debugDrawSettings.tireOutlineColor, qb2_debugDrawSettings.outlineAlpha);
					
					graphics.moveTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(sideVec);
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(worldVec);
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(sideVec.negate());
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(worldVec.negate());
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					graphics.endFill();
				}
				
				if ( drawLoads )
				{
					var avgAlpha:Number = 0;
					var carLoad:Number = _carBody.mass * world.gravityZ;
					for ( var i:int = 0; i < _carBody.tires.length; i++ )
					{
						var tire:tdTire = _carBody.tires[i]
						avgAlpha += tire._load / carLoad;
					}
					avgAlpha /= _carBody.tires.length;
					
					var loadAlpha:Number = this._load / carLoad;
					loadAlpha += (loadAlpha - avgAlpha) * td_debugDrawSettings.tireLoadAlphaScale;
					
					if ( drawTires )
					{
						sideVec.negate();
						worldVec.negate();
					}
					
					graphics.beginFill(td_debugDrawSettings.tireLoadColor, loadAlpha);
					graphics.setLineStyle();
					
					graphics.moveTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(sideVec);
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(worldVec);
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(sideVec.negate());
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					worldPoint.translateBy(worldVec.negate());
					graphics.lineTo(worldPoint.x, worldPoint.y);
					
					graphics.endFill();
				}
				
				const numRotLines:int = td_debugDrawSettings.tireNumRotLines;
				
				if ( numRotLines ) // this block draws the tire rotation lines.
				{
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, td_debugDrawSettings.tireOutlineColor, qb2_debugDrawSettings.outlineAlpha);
					
					sideVec.negate();
					worldPoint.translateBy(sideVec).translateBy(worldVec.negated().scaleBy(.5));
					sideVec.negate();// .scaleBy(2);
					worldVec.normalize();
					
					var rotInc:Number = (Math.PI * 2) / numRotLines;
					var currRot:Number = _rotation;
					for ( i = 0; i < numRotLines; i++ )
					{
						if ( currRot > Math.PI / 2 && currRot < Math.PI * 1.5)
						{
							currRot += rotInc;
							currRot = currRot % (Math.PI * 2);
							continue;  // Line is underneath the tire.
						}
						var yScale:Number = Math.sin(currRot);
						var vecClone:amVector2d = worldVec.clone();
						vecClone.scaleBy(realRadius * yScale);
						var pntClone:amPoint2d = worldPoint.translatedBy(vecClone);
						graphics.moveTo(pntClone.x, pntClone.y);
						pntClone.translateBy(sideVec);
						graphics.lineTo(pntClone.x, pntClone.y);
						
						currRot += rotInc;
						currRot = currRot % (Math.PI * 2);
					}
				}
			}
		}
			
		public override function draw(graphics:srGraphics2d):void
		{
			
		}
		
		public override function toString():String
		{
			return qb2DebugTraceUtils.formatToStringWithCustomVars(this, "position", "radius", "massShare");
		}
	}
}