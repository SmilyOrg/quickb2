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

package QuickB2.objects.joints
{
	import As3Math.*;
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;
	
	use namespace am_friend;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2RevoluteJoint extends qb2Joint
	{		
		public function qb2RevoluteJoint(initObject1:qb2IRigidObject = null, initObject2:qb2IRigidObject = null, initWorldAnchor:amPoint2d = null) 
		{
			turnFlagOn(qb2_flags.OPTIMIZED_SPRING, false);
			setProperty(qb2_props.LOWER_LIMIT, -Infinity, false);
			setProperty(qb2_props.UPPER_LIMIT,  Infinity, false);
			
			hasOneWorldPoint = true;
		
			object1 = initObject1;
			object2 = initObject2;
			
			setWorldAnchor(initWorldAnchor ? initWorldAnchor : initWorldPoint(object1));
		}
		
		public function get springCanFlip():Boolean
			{  return _flags & qb2_flags.SPRING_CAN_FLIP ? true : false;  }
		public function set springCanFlip(bool:Boolean):void
			{  setFlag(bool, qb2_flags.SPRING_CAN_FLIP, false);  }
			
		public function get dampenSpringJitter():Boolean
			{  return _flags & qb2_flags.DAMPEN_SPRING_JITTER ? true : false;  }
		public function set dampenSpringJitter(bool:Boolean):void
			{  setFlag(bool, qb2_flags.DAMPEN_SPRING_JITTER, false);  }
			
		public function get optimizedSpring():Boolean
			{  return _flags & qb2_flags.OPTIMIZED_SPRING ? true : false;  }
		public function set optimizedSpring(bool:Boolean):void
			{  setFlag(bool, qb2_flags.OPTIMIZED_SPRING, false);  }
			
			
			
		public function get springDamping():Number
			{  return getProperty(qb2_props.SPRING_DAMPING) as Number;  }
		public function set springDamping(value:Number):void
			{  setProperty(qb2_props.SPRING_DAMPING, value);  }
			
		public function get springK():Number
			{  return getProperty(qb2_props.SPRING_K) as Number;  }
		public function set springK(value:Number):void
			{  setProperty(qb2_props.SPRING_K, value);  }
	
		public function get maxTorque():Number
			{  return getProperty(qb2_props.MAX_TORQUE) as Number;  }
		public function set maxTorque(value:Number):void
			{  setProperty(qb2_props.MAX_TORQUE, value);  }
			
		public function get targetSpeed():Number
			{  return getProperty(qb2_props.TARGET_SPEED) as Number;  }
		public function set targetSpeed(value:Number):void
			{  setProperty(qb2_props.TARGET_SPEED, value);  }
			
		public function get referenceAngle():Number
			{  return getProperty(qb2_props.REFERENCE_ANGLE) as Number;  }
		public function set referenceAngle(value:Number):void
			{  setProperty(qb2_props.REFERENCE_ANGLE, value);  }
			
		public function get lowerLimit():Number
			{  return getProperty(qb2_props.LOWER_LIMIT) as Number;  }
		public function set lowerLimit(value:Number):void
			{  setProperty(qb2_props.LOWER_LIMIT, value);  }
			
		public function get upperLimit():Number
			{  return getProperty(qb2_props.UPPER_LIMIT) as Number;  }
		public function set upperLimit(value:Number):void
			{  setProperty(qb2_props.UPPER_LIMIT, value);  }
			
		protected override function propertyChanged(propertyName:String):void
		{
			if ( !jointB2 )  return;
			
			var value:Number = _propertyMap[propertyName];
			
			if ( propertyName == qb2_props.MAX_TORQUE )
			{
				if ( !callingFromUpdate && optimizedSpring && springK )
					qb2_throw(qb2_errors.OPT_SPRING_ERROR);
			
				joint.SetMaxMotorTorque(value);
				joint.EnableMotor(value ? true : false);
				
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.TARGET_SPEED )
			{
				if ( !callingFromUpdate && optimizedSpring && springK )
					qb2_throw(qb2_errors.OPT_SPRING_ERROR);
				
				joint.SetMotorSpeed(value);
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.REFERENCE_ANGLE )
			{
				joint.m_referenceAngle = value;
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.LOWER_LIMIT || propertyName == qb2_props.UPPER_LIMIT )
			{
				updateLimits();
				wakeUpAttached();
			}
			else
			{
				wakeUpAttached();
			}
		}
		
		public function get localAnchor1():amPoint2d
			{  return _localAnchor1;  }
		public function set localAnchor1(newPoint:amPoint2d):void
			{  setLocalAnchor1(newPoint);  }
		
		public function get localAnchor2():amPoint2d
			{  return _localAnchor2;  }
		public function set localAnchor2(newPoint:amPoint2d):void
			{  setLocalAnchor2(newPoint);  }
		
		public function getWorldAnchor():amPoint2d
		{
			var world1:amPoint2d = _object1 ? (_object1 as qb2Tangible).getWorldPoint(_localAnchor1) : _localAnchor1.clone();
			var world2:amPoint2d = _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
			return world1.midwayPoint(world2);
		}
		
		public function setWorldAnchor(worldAnchor:amPoint2d):void
		{
			localAnchor1 = _object1 ? (_object1 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
			localAnchor2 = _object2 ? (_object2 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			correctLocals();
			wakeUpAttached();
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var corrected1:amPoint2d = getCorrectedLocal1(conversion, conversion);
				var corrected2:amPoint2d = getCorrectedLocal2(conversion, conversion);
				
				joint.m_localAnchor1.x = corrected1.x;
				joint.m_localAnchor1.y = corrected1.y;
				joint.m_localAnchor2.x = corrected2.x;
				joint.m_localAnchor2.y = corrected2.y;
			}
		}
		
		public function setLimits(lower:Number, upper:Number):void
		{
			lowerLimit = lower;
			upperLimit = upper;
		}
		
		private function updateLimits():void
		{
			if ( !jointB2 )  return;
			
			var conversion:Number = world.pixelsPerMeter;
			
			joint.SetLimits(lowerLimit / conversion, upperLimit / conversion);
			joint.EnableLimit(hasLimits);
		}
		
		public function get hasLimits():Boolean
			{  return isFinite(lowerLimit) || isFinite(upperLimit);  }
		
		public function get currJointAngle():Number
			{  return jointB2 ? joint.GetJointAngle() : 0;  }
			
		public function get currMotorSpeed():Number
			{  return jointB2 ? joint.GetJointSpeed() : 0;  }
			
		public function get currTorque():Number
			{  return jointB2 ? joint.GetMotorTorque() : 0;  }
		
		public function get object1():qb2IRigidObject
			{  return _object1 as qb2IRigidObject;   }
		public function set object1(newObject:qb2IRigidObject):void
			{  setObject1(newObject);  }
		
		public function get object2():qb2IRigidObject
			{  return _object2 as qb2IRigidObject;  }
		public function set object2(newObject:qb2IRigidObject):void
			{  setObject2(newObject);  }
		
		qb2_friend override function objectsUpdated():void
		{
			if ( _object1 && _object2 )
				referenceAngle = _object2._rigidImp._rotation - _object1._rigidImp._rotation;
		}
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			var conversion:Number       = theWorld.pixelsPerMeter;
			var corrected1:amPoint2d    = getCorrectedLocal1(conversion, conversion);
			var corrected2:amPoint2d    = getCorrectedLocal2(conversion, conversion);
			
			var revJointDef:b2RevoluteJointDef = b2Def.revoluteJoint;
			revJointDef.localAnchorA.x   = corrected1.x;
			revJointDef.localAnchorA.y   = corrected1.y;
			revJointDef.localAnchorB.x   = corrected2.x;
			revJointDef.localAnchorB.y   = corrected2.y;
			
			revJointDef.enableLimit    = hasLimits;
			revJointDef.enableMotor    = maxTorque ? true : false;
			revJointDef.lowerAngle     = lowerLimit;
			revJointDef.upperAngle     = upperLimit;
			revJointDef.maxMotorTorque = maxTorque;
			revJointDef.motorSpeed     = targetSpeed;
			revJointDef.referenceAngle = referenceAngle;
			
			jointDef = revJointDef;
			
			super.make(theWorld);
		}
		
		private function get joint():b2RevoluteJoint
			{  return jointB2 ? jointB2 as b2RevoluteJoint : null;  }
			
		private var callingFromUpdate:Boolean = false;
		
		protected override function update():void
		{
			if ( springK == 0 )  return;
			if ( !_object1 || !_object2 || !_object2.world || !_object2.world )  return;
			if ( _object1.isSleeping && _object2.isSleeping )  return;
			
			var jointAngle:Number = this.currJointAngle;
			if ( springCanFlip )
			{
				 //--- Basically do a kind of modulus on the angle here to allow it to flip...
				var sign:Number = amUtils.sign(jointAngle);
				var modAngle:Number = Math.abs(jointAngle) % (AM_PI * 2);
				jointAngle = modAngle > AM_PI ? sign * (modAngle - AM_PI * 2) : sign*modAngle;
			}
			
			if ( optimizedSpring )
			{
				callingFromUpdate = true;
				{
					maxTorque = Math.abs((jointAngle * springK) + (currMotorSpeed * springDamping));
					targetSpeed = jointAngle > 0 ? -MAX_SPRING_SPEED : MAX_SPRING_SPEED;
				}
				callingFromUpdate = false;
			}
			
			/*var conversion:Number = worldPixelsPerMeter;
		
			var world1:amPoint2d = getWorldAnchor1();
			var world2:amPoint2d = getWorldAnchor2();
			
			var diff:amVector2d = world2.minus(world1);
			var diffLen:Number = diff.length;
			diff.normalize();
			
			//--- Make it so the spring doesn't "flip" around if so chosen, because by default the distance between objects isn't signed.
			var worldAxis:amVector2d
			if ( !springCanFlip )
			{
				worldAxis = _object1.getWorldVector(_localDirection);
				if ( worldAxis.dotProduct(diff) < 0 )
				{
					diffLen = -diffLen;
					diff.negate();
				}
			}
			
			diff.scaleBy( ((diffLen - springLength)/conversion) * springK );
			
			_object1.applyForce(world1, diff);
			_object2.applyForce(world2, diff.negate());
			
			if ( springDamping )
			{
				var linVel1:amVector2d = _object1.getLinearVelocityAtPoint(world1);
				var linVel2:amVector2d = _object2.getLinearVelocityAtPoint(world2);
				
				var velDiff:amVector2d = linVel2.minus(linVel1).normalize();
				var dampingForceVec:amVector2d = diff.normalize();
				dampingForceVec.scaleBy(velDiff.dotProduct(dampingForceVec) * springDamping);
				_object1.applyForce(world1, dampingForceVec);
				_object2.applyForce(world2, dampingForceVec.negate());
			}*/
		}
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var revJoint:qb2RevoluteJoint = super.clone(deep) as qb2RevoluteJoint;
			
			revJoint._localAnchor1._x = this._localAnchor1._x;
			revJoint._localAnchor1._y = this._localAnchor1._y;
			
			revJoint._localAnchor2._x = this._localAnchor2._x;
			revJoint._localAnchor2._y = this._localAnchor2._y;
			
			return revJoint;
		}
		
		public static var arrowDrawRadius:Number = anchorDrawRadius*3;
		
		public override function draw(graphics:srGraphics2d):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if (!worldPoints )   return;
			 
			var world1:V2 = worldPoints[0];
			
			var arrowSize:Number = arrowDrawRadius * .25;
			
			graphics.moveTo(world1.x, world1.y-arrowDrawRadius);
			graphics.curveTo(world1.x + arrowDrawRadius, world1.y - arrowDrawRadius, world1.x + arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x + arrowDrawRadius - arrowSize, world1.y - arrowSize);
			graphics.moveTo(world1.x + arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x + arrowDrawRadius + arrowSize, world1.y - arrowSize);
			
			graphics.moveTo(world1.x, world1.y+arrowDrawRadius);
			graphics.curveTo(world1.x - arrowDrawRadius, world1.y + arrowDrawRadius, world1.x - arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x - arrowDrawRadius - arrowSize, world1.y + arrowSize);
			graphics.moveTo(world1.x - arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x - arrowDrawRadius + arrowSize, world1.y + arrowSize);
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			reusableV2.xy(joint.m_localAnchor1.x, joint.m_localAnchor1.y);
			var anch1:V2 = joint.m_bodyA.GetWorldPoint(reusableV2);
			reusableV2.xy(joint.m_localAnchor2.x, joint.m_localAnchor2.y);
			var anch2:V2 = joint.m_bodyB.GetWorldPoint(reusableV2);
			anch1.multiplyN(worldPixelsPerMeter);
			anch2.multiplyN(worldPixelsPerMeter);
			
			var vecX:Number = (anch2.x - anch1.x) / 2;
			var vecY:Number = (anch2.y - anch1.y) / 2;
			anch1.x += vecX;
			anch1.y += vecY;
			
			return Vector.<V2>([anch1]);
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2RevoluteJoint");  }
	}
}