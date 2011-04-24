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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
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
	public class qb2PistonJoint extends qb2Joint
	{
		//--- It seems that if you set the lower and upper translations equal on a piston or line joint, it makes the joint get stuck at 0.
		//--- It seems that they need to be offset by *just* over a centimeter for this not to happen, so this number fixes that.
		private static const IDENTICAL_LIMIT_CORRECTION:Number = .01001; // (in meters)
	
		public function qb2PistonJoint(initObject1:qb2IRigidObject = null, initObject2:qb2IRigidObject = null, initWorldAnchor1:amPoint2d = null, initWorldAnchor2:amPoint2d = null)
		{
			turnFlagOn(qb2_flags.OPTIMIZED_SPRING | qb2_flags.AUTO_SET_LENGTH | qb2_flags.AUTO_SET_DIRECTION, false);
			setProperty(qb2_props.LOWER_LIMIT, -Infinity, false);
			setProperty(qb2_props.UPPER_LIMIT,  Infinity, false);
			
			object1 = initObject1;
			object2 = initObject2;
			
			localDirection = new amVector2d();
			
			setWorldAnchor1(initWorldAnchor1 ? initWorldAnchor1 : initWorldPoint(object1));
			setWorldAnchor2(initWorldAnchor2 ? initWorldAnchor2 : initWorldPoint(object2));
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
			
		public function get freeRotation():Boolean
			{  return _flags & qb2_flags.FREE_ROTATION ? true : false;  }
		public function set freeRotation(bool:Boolean):void
			{  setFlag(bool, qb2_flags.FREE_ROTATION, false);  }
			
		public function get autoSetLength():Boolean
			{  return _flags & qb2_flags.AUTO_SET_LENGTH ? true : false;  }
		public function set autoSetLength(bool:Boolean):void
			{  setFlag(bool, qb2_flags.AUTO_SET_LENGTH, false);  }
			
		public function get autoSetDirection():Boolean
			{  return _flags & qb2_flags.AUTO_SET_DIRECTION ? true : false;  }
		public function set autoSetDirection(bool:Boolean):void
			{  setFlag(bool, qb2_flags.AUTO_SET_DIRECTION, false);  }
			
		protected override function flagsChanged(affectedFlags:uint):void
		{
			if ( flags & qb2_flags.FREE_ROTATION )
			{
				if ( jointB2 )
				{
					flush();
				}
				
				//--- This has to be called so that when going from non-synced to synced, the reference angle is refreshed.
				objectsUpdated();
			}
		}
		
		public function get springLength():Number
			{  return getProperty(qb2_props.LENGTH) as Number;  }
		public function set springLength(value:Number):void
			{  setProperty(qb2_props.LENGTH, value);  }

		public function get springDamping():Number
			{  return getProperty(qb2_props.SPRING_DAMPING) as Number;  }
		public function set springDamping(value:Number):void
			{  setProperty(qb2_props.SPRING_DAMPING, value);  }
			
		public function get springK():Number
			{  return getProperty(qb2_props.SPRING_K) as Number;  }
		public function set springK(value:Number):void
			{  setProperty(qb2_props.SPRING_K, value);  }
			
		public function get maxForce():Number
			{  return getProperty(qb2_props.MAX_FORCE) as Number;  }
		public function set maxForce(value:Number):void
			{  setProperty(qb2_props.MAX_FORCE, value);  }
			
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
			
			if ( propertyName == qb2_props.MAX_FORCE )
			{
				if ( !callingFromUpdate && optimizedSpring && springK )
					throw qb2_errors.OPT_SPRING_ERROR;
				
				if ( jointB2 is b2PrismaticJoint )
				{
					prisJoint.SetMaxMotorForce(value);
					prisJoint.EnableMotor(value ? true : false);
				}
				else if ( jointB2 is b2LineJoint )
				{
					lineJoint.SetMaxMotorForce(value);
					lineJoint.EnableMotor(value ? true : false);
				}
				
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.TARGET_SPEED )
			{
				if ( !callingFromUpdate && optimizedSpring && springK )
					throw qb2_errors.OPT_SPRING_ERROR;
					
				if ( jointB2 is b2PrismaticJoint )
				{
					prisJoint.SetMotorSpeed(value);
				}
				else if ( jointB2 is b2LineJoint )
				{
					lineJoint.SetMotorSpeed(value);
				}
						
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.REFERENCE_ANGLE )
			{
				if ( jointB2 is b2PrismaticJoint )
				{
					prisJoint.m_refAngle = value;
				}
				
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
		
		public function getWorldAnchor1():amPoint2d
		{
			return _object1 ? (_object1 as qb2Tangible).getWorldPoint(_localAnchor1) : _localAnchor1.clone();
		}
		
		public function setWorldAnchor1(worldAnchor:amPoint2d):void
		{
			localAnchor1 = (_object1 as qb2Tangible) ? _object1.getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		public function getWorldAnchor2():amPoint2d
		{
			return _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
		}

		public function setWorldAnchor2(worldAnchor:amPoint2d):void
		{
			localAnchor2 = (_object2 as qb2Tangible) ? _object2.getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		public function get localDirection():amVector2d
			{  return _localDirection;  }
		public function set localDirection(newVector:amVector2d):void
		{
			if ( _localDirection )  _localDirection.removeEventListener(amUpdateEvent.ENTITY_UPDATED, vectorUpdated);
			_localDirection = newVector;
			_localDirection.addEventListener(amUpdateEvent.ENTITY_UPDATED, vectorUpdated, null, true);
			vectorUpdated(null);
		}
		private var _localDirection:amVector2d = new amVector2d();
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			correctLocals();
			updateDirectionAndSpringLength();
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				
				correctLocalVec();
				
				var corrected1:amPoint2d = getCorrectedLocal1(conversion, conversion);
				var corrected2:amPoint2d = getCorrectedLocal2(conversion, conversion);
				
				
				if ( jointB2 is b2PrismaticJoint )
				{
					prisJoint.m_localAnchor1.x = corrected1.x;
					prisJoint.m_localAnchor1.y = corrected1.y;
					prisJoint.m_localAnchor2.x = corrected2.x;
					prisJoint.m_localAnchor2.y = corrected2.y;
				}
				else if ( jointB2 is b2LineJoint )
				{
					lineJoint.m_localAnchor1.x = corrected1.x;
					lineJoint.m_localAnchor1.y = corrected1.y;
					lineJoint.m_localAnchor2.x = corrected2.x;
					lineJoint.m_localAnchor2.y = corrected2.y;
				}
			}
		}
		
		private function getCorrectedLocalVec():amVector2d
		{
			return _object1._bodyB2 ? _localDirection : _object1.getWorldVector(_localDirection, _object1._ancestorBody);
		}
		
		private function correctLocalVec():void
		{
			//--- Be thankful you don't have to deal with this.
			if ( jointB2 )
			{
				var correctedVec:amVector2d = getCorrectedLocalVec();
				
				if ( jointB2 is b2PrismaticJoint )
				{
					prisJoint.m_localXAxis1.x = correctedVec.x;
					prisJoint.m_localXAxis1.y = correctedVec.y;
					prisJoint.m_localYAxis1.x = -prisJoint.m_localXAxis1.y;
					prisJoint.m_localYAxis1.y =  prisJoint.m_localXAxis1.x;
				}
				else
				{
					lineJoint.m_localXAxis1.x = correctedVec.x;
					lineJoint.m_localXAxis1.y = correctedVec.y;
					lineJoint.m_localYAxis1.x = -lineJoint.m_localXAxis1.y;
					lineJoint.m_localYAxis1.y =  lineJoint.m_localXAxis1.x;
				}
			}
		}
		
		private function vectorUpdated(evt:amUpdateEvent):void
		{
			_localDirection.pushDispatchBlock(vectorUpdated);
			{
				_localDirection.normalize();
			}
			_localDirection.popDispatchBlock(vectorUpdated);
			
			correctLocalVec();
			
			wakeUpAttached();
		}
		
		public function setWorldDirection(worldVector:amVector2d):void
		{
			localDirection = _object1 ? _object1.getLocalVector(worldVector) : worldVector.clone();
		}
		
		private var callingFromUpdate:Boolean = false;
		
		protected override function update():void
		{
			if ( springK == 0 )  return;
			if ( !_object1 || !_object2 || !_object2.world || !_object2.world )  return;
			if ( _object1.isSleeping && _object2.isSleeping )  return;
			
			var conversion:Number = worldPixelsPerMeter;
			var diffLen:Number = currJointTranslation;
			var flip:Boolean = !springCanFlip && diffLen < 0;
			
			if ( optimizedSpring )
			{
				callingFromUpdate = true;
				{
					var modDiffLen:Number = springCanFlip ? Math.abs(diffLen) : diffLen;
					var dampingForce:Number = springCanFlip && diffLen < 0 ? -currPistonSpeed * springDamping : currPistonSpeed * springDamping;
					maxForce = Math.abs((((modDiffLen - springLength) / conversion) * springK) + dampingForce);
					
					if ( springCanFlip && diffLen < 0 )
					{
						targetSpeed = diffLen + springLength > 0 ? -MAX_SPRING_SPEED : MAX_SPRING_SPEED;
					}
					else
					{
						targetSpeed = diffLen - springLength < 0 ? MAX_SPRING_SPEED : -MAX_SPRING_SPEED;
					}
				}
				callingFromUpdate = false;
			}
			else
			{
				var world1:amPoint2d = getWorldAnchor1();
				var world2:amPoint2d = getWorldAnchor2();
				var transVec:amVector2d = world2.minus(world1);
				
				if ( springCanFlip && diffLen < 0 )
				{
					diffLen = -diffLen;
				}
				
				var diff:amVector2d = (flip ? transVec.clone().negate() : world2.minus(world1)).normalize();
				diff.scaleBy( ((diffLen - springLength) / conversion) * springK );
				
				_object1.applyForce(world1, diff);
				_object2.applyForce(world2, diff.negate());
				
				if ( springDamping )
				{
					diff = world1.minus(world2).normalize();
					var linVel1:amVector2d = _object1.getLinearVelocityAtPoint(world1);
					var jointComponent:Number = diff.dotProduct(linVel1);
					_object1.applyForce(world1, diff.scaledBy(-jointComponent * springDamping));
					
					diff.copy(transVec).normalize();
					var linVel2:amVector2d = _object2.getLinearVelocityAtPoint(world2);
					jointComponent = diff.dotProduct(linVel2);
					_object2.applyForce(world2, diff.scaledBy(-jointComponent * springDamping));
				}
			}
		}		
		
		public function get currJointTranslation():Number
		{
			if ( jointB2 )
			{
				if ( jointB2 is b2PrismaticJoint )
					return prisJoint.GetJointTranslation() * worldPixelsPerMeter;
				else if ( jointB2 is b2LineJoint )
					return lineJoint.GetJointTranslation() * worldPixelsPerMeter;
			}
			
			return 0;
		}
			
		public function get currPistonSpeed():Number
		{
			if ( jointB2 )
			{
				if ( jointB2 is b2PrismaticJoint )
					return prisJoint.GetJointSpeed();
				else if ( jointB2 is b2LineJoint )
					return lineJoint.GetJointSpeed();
			}
			
			return 0;
		}
			
		public function get currForce():Number
		{
			if ( jointB2 )
			{
				if ( jointB2 is b2PrismaticJoint )
					return prisJoint.GetMotorForce();
				else if ( jointB2 is b2LineJoint )
					return lineJoint.GetMotorForce();
			}
			
			return 0;
		}
		
		public function setLimits(lower:Number, upper:Number):void
		{
			lowerLimit = lower;
			upperLimit = upper;
		}
		
		private function updateLimits():void
		{
			if ( !jointB2 )  return;
			
			var limits:Array = getMetricLimits(worldPixelsPerMeter);
			
			if ( jointB2 is b2PrismaticJoint )
			{
				prisJoint.SetLimits(limits[0], limits[1]);
				prisJoint.EnableLimit(hasLimits);
			}
			else if ( jointB2 is b2LineJoint )
			{
				lineJoint.SetLimits(limits[0], limits[1]);
				lineJoint.EnableLimit(hasLimits);
			}
		}
		
		public function get hasLimits():Boolean
			{  return isFinite(lowerLimit) || isFinite(upperLimit);  }
			
		private function getMetricLimits(scale:Number):Array
		{
			var lower:Number = lowerLimit / scale;
			var upper:Number = upperLimit / scale;

			//--- "Fix" the limits if they are within 1 centimeter of each other, cause otherwise the joint will get tweaked out and set itself to zero limit.
			if ( Math.abs(upper-lower) < IDENTICAL_LIMIT_CORRECTION )
			{
				upper = lower + IDENTICAL_LIMIT_CORRECTION;
			}
			
			return [lower, upper];
		}
		
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
			if ( _object1 &&_object2 )  referenceAngle = _object2._rigidImp._rotation - _object1._rigidImp._rotation;
			updateDirectionAndSpringLength();
		}
		
		private function updateDirectionAndSpringLength():void
		{
			if ( _object1 && _object2  && _localAnchor1 && _localAnchor2)
			{
				if ( autoSetDirection )
				{
					var worldVector:amVector2d = _object2.getWorldPoint(_localAnchor2).minus(_object1.getWorldPoint(_localAnchor1));
					localDirection = _object1.getLocalVector(worldVector.lengthSquared ? worldVector : worldVector.set(0, -1));
				}
				if ( autoSetLength )
				{
					springLength = _object1.getWorldPoint(_localAnchor1).distanceTo(_object2.getWorldPoint(_localAnchor2));
				}
			}
		}
		
		
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			var limits:Array = getMetricLimits(theWorld.pixelsPerMeter);
			
			var conversion:Number = theWorld.pixelsPerMeter;
			var corrected1:amPoint2d    = getCorrectedLocal1(conversion, conversion);
			var corrected2:amPoint2d    = getCorrectedLocal2(conversion, conversion);
			var correctedVec:amVector2d = getCorrectedLocalVec();
			
			if ( !freeRotation )
			{
				var prisJointDef:b2PrismaticJointDef = b2Def.prismaticJoint;
				prisJointDef.localAnchorA.x   = corrected1.x;
				prisJointDef.localAnchorA.y   = corrected1.y;
				prisJointDef.localAnchorB.x   = corrected2.x;
				prisJointDef.localAnchorB.y   = corrected2.y;
				prisJointDef.localAxis1.x     = correctedVec.x;
				prisJointDef.localAxis1.y     = correctedVec.y;
				prisJointDef.enableLimit      = hasLimits;
				prisJointDef.enableMotor      = maxForce ? true : false;
				prisJointDef.lowerTranslation = limits[0];
				prisJointDef.upperTranslation = limits[1];
				prisJointDef.maxMotorForce    = maxForce;
				prisJointDef.motorSpeed       = targetSpeed;
				prisJointDef.referenceAngle   = referenceAngle;
				
				jointDef = prisJointDef;
			}
			else
			{
				var lineJointDef:b2LineJointDef = b2Def.lineJoint;
				lineJointDef.localAnchorA.x   = corrected1.x;
				lineJointDef.localAnchorA.y   = corrected1.y;
				lineJointDef.localAnchorB.x   = corrected2.x;
				lineJointDef.localAnchorB.y   = corrected2.y;
				lineJointDef.localAxisA.x     = correctedVec.x;
				lineJointDef.localAxisA.y     = correctedVec.y;
				lineJointDef.enableLimit      = hasLimits
				lineJointDef.enableMotor      = maxForce ? true : false;
				lineJointDef.lowerTranslation = limits[0];
				lineJointDef.upperTranslation = limits[1];
				lineJointDef.maxMotorForce    = maxForce;
				lineJointDef.motorSpeed       = targetSpeed;
				
				jointDef = lineJointDef;
			}
			
			super.make(theWorld);
		}
		
		private function get prisJoint():b2PrismaticJoint
			{  return jointB2 ? jointB2 as b2PrismaticJoint : null;  }
			
		private function get lineJoint():b2LineJoint
			{  return jointB2 ? jointB2 as b2LineJoint : null;  }
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var pistJoint:qb2PistonJoint = super.clone(deep) as qb2PistonJoint;
			
			pistJoint._localAnchor1._x = this._localAnchor1._x;
			pistJoint._localAnchor1._y = this._localAnchor1._y;
			
			pistJoint._localAnchor2._x = this._localAnchor2._x;
			pistJoint._localAnchor2._y = this._localAnchor2._y;
			
			pistJoint._localDirection.copy(this._localDirection);
			
			return pistJoint;
		}
		
		public static var numSpringCoils:Number = 13;
		public static var pistonBaseDrawWidth:Number = anchorDrawRadius * 2;
		public static var springDrawWidth:Number = pistonBaseDrawWidth * 1.5;
		
		public override function draw(graphics:srGraphics2d):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if ( !worldPoints || worldPoints.length != 2 )   return;
			
			var world1:amPoint2d = new amPoint2d(worldPoints[0].x, worldPoints[0].y);
			var world2:amPoint2d = new amPoint2d(worldPoints[1].x, worldPoints[1].y);
			
			if ( world1.equals(world2) )  return;
			
			var diff:amVector2d = world2.minus(world1);
			var side:amVector2d = diff.perpVector(1).setLength(pistonBaseDrawWidth / 2);
			var distance:Number = diff.length;
			
			//--- Draw piston base.
			var drawPnt:amPoint2d = world1.clone();
			drawPnt.translateBy(side);
			graphics.moveTo(drawPnt.x, drawPnt.y);
			drawPnt.translateBy(diff.scaleBy(.5));
			graphics.lineTo(drawPnt.x, drawPnt.y);
			drawPnt.translateBy(side.negate().scaleBy(2));
			graphics.lineTo(drawPnt.x, drawPnt.y);
			drawPnt.translateBy(diff.negate());
			graphics.lineTo(drawPnt.x, drawPnt.y);
			
			//--- Draw piston shaft.
			drawPnt.copy(world1);
			drawPnt.translateBy(diff.negate());
			graphics.moveTo(drawPnt.x, drawPnt.y);
			drawPnt.translateBy(diff);
			graphics.lineTo(drawPnt.x, drawPnt.y);
			
			//--- Draw spring.
			var segLength:Number = distance / 2 / numSpringCoils;
			side.setLength(springDrawWidth / 2);
			diff.setLength(segLength / 2).negate();
			drawPnt.translateBy(side).translateBy(diff);
			graphics.lineTo(drawPnt.x, drawPnt.y);
			diff.scaleBy(2);
			side.scaleBy(2);
			for (var i:int = 0; i < numSpringCoils-1; i++) 
			{
				side.negate();
				drawPnt.translateBy(side).translateBy(diff);
				
				graphics.lineTo(drawPnt.x, drawPnt.y);
			}
			side.negate().scaleBy(.5);
			diff.scaleBy(.5);
			drawPnt.translateBy(side).translateBy(diff);
			graphics.lineTo(drawPnt.x, drawPnt.y);
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			var bodyA:b2Body, bodyB:b2Body;
			var anchorA:b2Vec2, anchorB:b2Vec2;
			if ( prisJoint )
			{
				bodyA = prisJoint.m_bodyA;
				bodyB = prisJoint.m_bodyB;
				anchorA = prisJoint.m_localAnchor1;
				anchorB = prisJoint.m_localAnchor2;
			}
			else
			{
				bodyA   = lineJoint.m_bodyA;
				bodyB   = lineJoint.m_bodyB;
				anchorA = lineJoint.m_localAnchor1;
				anchorB = lineJoint.m_localAnchor2;
			}
			
			reusableV2.xy(anchorA.x, anchorA.y);
			var anch1:V2 = bodyA.GetWorldPoint(reusableV2);
			reusableV2.xy(anchorB.x, anchorB.y);
			var anch2:V2 = bodyB.GetWorldPoint(reusableV2);
			anch1.multiplyN(worldPixelsPerMeter);
			anch2.multiplyN(worldPixelsPerMeter);
			
			return Vector.<V2>([anch1, anch2]);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2PistonJoint");  }
	}
}