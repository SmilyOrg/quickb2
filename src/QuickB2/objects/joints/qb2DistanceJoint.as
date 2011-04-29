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
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
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
	public class qb2DistanceJoint extends qb2Joint
	{
		public function qb2DistanceJoint(initObject1:qb2IRigidObject = null, initObject2:qb2IRigidObject = null, initWorldAnchor1:amPoint2d = null, initWorldAnchor2:amPoint2d = null)
		{
			turnFlagOn(qb2_flags.AUTO_SET_LENGTH, false);
			
			object1 = initObject1;
			object2 = initObject2;
			
			setWorldAnchor1(initWorldAnchor1 ? initWorldAnchor1 : initWorldPoint(object1));
			setWorldAnchor2(initWorldAnchor2 ? initWorldAnchor2 : initWorldPoint(object2));
		}
		
		public function get autoSetLength():Boolean
			{  return _flags & qb2_flags.AUTO_SET_LENGTH ? true : false;  }
		public function set autoSetLength(bool:Boolean):void
			{  setFlag(bool, qb2_flags.AUTO_SET_LENGTH, false);  }
		
		public function get isRope():Boolean
			{  return _flags & qb2_flags.IS_ROPE ? true : false;  }
		public function set isRope(bool:Boolean):void
			{  setFlag(bool, qb2_flags.IS_ROPE, false);  }
		
		protected override function flagsChanged(affectedFlags:uint):void
		{
			if ( affectedFlags & qb2_flags.IS_ROPE )
			{
				if ( jointB2 )
				{
					flush();
				}
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
		public function getWorldAnchor2():amPoint2d
		{
			return _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
		}

		public function setWorldAnchor1(worldAnchor:amPoint2d):void
		{
			localAnchor1 = _object1 ? (_object1 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
		}

		public function setWorldAnchor2(worldAnchor:amPoint2d):void
		{
			localAnchor2 = _object2 ? (_object2 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
		}

		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			correctLocals();
			updateLength();
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var corrected1:amPoint2d = getCorrectedLocal1(conversion, conversion);
				var corrected2:amPoint2d = getCorrectedLocal2(conversion, conversion);
				
				if ( jointB2 is b2DistanceJoint )
				{
					distJoint.m_localAnchor1.x = corrected1.x;
					distJoint.m_localAnchor1.y = corrected1.y;
					distJoint.m_localAnchor2.x = corrected2.x;
					distJoint.m_localAnchor2.y = corrected2.y;
				}
				else if( jointB2 is b2RopeJoint )
				{
					ropeJoint.m_localAnchorA.x = corrected1.x;
					ropeJoint.m_localAnchorA.y = corrected1.y;
					ropeJoint.m_localAnchorB.x = corrected2.x;
					ropeJoint.m_localAnchorB.y = corrected2.y;
				}
			}
		}
		
		public function get length():Number
			{  return getProperty(qb2_props.LENGTH) as Number;  }
		public function set length(value:Number):void
			{  setProperty(qb2_props.LENGTH, value);  }

		public function get frequencyHz():Number
			{  return getProperty(qb2_props.FREQUENCY_HZ) as Number;  }
		public function set frequencyHz(value:Number):void
			{  setProperty(qb2_props.FREQUENCY_HZ, value);  }
			
		public function get dampingRatio():Number
			{  return getProperty(qb2_props.DAMPING_RATIO) as Number;  }
		public function set dampingRatio(value:Number):void
			{  setProperty(qb2_props.DAMPING_RATIO, value);  }
			
		protected override function propertyChanged(propertyName:String):void
		{
			if ( !jointB2 )  return;
			
			var value:Number = _propertyMap[propertyName];
			
			if ( propertyName == qb2_props.LENGTH )
			{
				if( jointB2 is b2DistanceJoint )
					distJoint.m_length = value / worldPixelsPerMeter;
				else if ( jointB2 is b2RopeJoint )
					ropeJoint.m_length = value / worldPixelsPerMeter;
					
				wakeUpAttached();
			}
			else if ( propertyName == qb2_props.DAMPING_RATIO )
			{
				if ( jointB2 is b2DistanceJoint )
					distJoint.SetFrequency(value);
				else
					ropeJoint.SetFrequency(value);
			}
			else if ( propertyName == qb2_props.FREQUENCY_HZ )
			{
				if ( jointB2 is b2DistanceJoint )
					distJoint.SetFrequency(value);
				else
					ropeJoint.SetFrequency(value);
			}
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
			updateLength();
		}
		
		private function updateLength():void
		{
			if ( !autoSetLength )  return;
		
			if ( _object1 && _object2 && _localAnchor1 && _localAnchor2 )
			{
				length = _object1.getWorldPoint(_localAnchor1).distanceTo(_object2.getWorldPoint(_localAnchor2));
			}
		}
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			var makingRopeJoint:Boolean = isRope;
			
			var conversion:Number = theWorld.pixelsPerMeter;
			var corrected1:amPoint2d    = getCorrectedLocal1(conversion, conversion);
			var corrected2:amPoint2d    = getCorrectedLocal2(conversion, conversion);
			
			if ( makingRopeJoint )
			{
				var ropeJointDef:b2RopeJointDef = b2Def.ropeJoint;
				ropeJointDef.localAnchorA.x = corrected1.x;
				ropeJointDef.localAnchorA.y = corrected1.y;
				ropeJointDef.localAnchorB.x = corrected2.x;
				ropeJointDef.localAnchorB.y = corrected2.y;
				ropeJointDef.maxLength      = length / theWorld.pixelsPerMeter;
				
				//--- NOTE: b2RopeJointDef doesn't have the frequencyHz and dampingRatio properties, so it's applied to the actual joint at the end of this function.
				// ropeJointDef.frequencyHz    = frequencyHz;
				// ropeJointDef.dampingRatio   = dampingRatio;
				
				jointDef = ropeJointDef;
			}
			else
			{
				var distJointDef:b2DistanceJointDef = b2Def.distanceJoint;
				distJointDef.localAnchorA.x = corrected1.x;
				distJointDef.localAnchorA.y = corrected1.y;
				distJointDef.localAnchorB.x = corrected2.x;
				distJointDef.localAnchorB.y = corrected2.y;
				distJointDef.length         = length / theWorld.pixelsPerMeter;
				distJointDef.frequencyHz    = frequencyHz;
				distJointDef.dampingRatio   = dampingRatio;
				
				jointDef = distJointDef;
			}
			
			super.make(theWorld);
			
			//--- It's these kinds of API inconsistencies in Box2D that gives QuickB2 a purpose in life.
			if ( makingRopeJoint )
			{
				ropeJoint.SetFrequency(frequencyHz);
				ropeJoint.SetDampingRatio(dampingRatio);
			}
		}
		
		private function get distJoint():b2DistanceJoint
			{  return jointB2 ? jointB2 as b2DistanceJoint : null;  }
			
		private function get ropeJoint():b2RopeJoint
			{  return jointB2 ? jointB2 as b2RopeJoint : null;  }
			
		public override function clone(deep:Boolean = true):qb2Object
		{
			var distJoint:qb2DistanceJoint = super.clone(deep) as qb2DistanceJoint;
			
			distJoint._localAnchor1._x = this._localAnchor1._x;
			distJoint._localAnchor1._y = this._localAnchor1._y;
			distJoint._localAnchor2._x = this._localAnchor2._x;
			distJoint._localAnchor2._y = this._localAnchor2._y;
			
			return distJoint;
		}
		
		public static var dashedLineDrawSegmentLength:Number = 5;
		
		public override function draw(graphics:srGraphics2d):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if ( !worldPoints || worldPoints.length != 2 )   return;
			
			var world1:amPoint2d = new amPoint2d(worldPoints[0].x, worldPoints[0].y);
			var world2:amPoint2d = new amPoint2d(worldPoints[1].x, worldPoints[1].y);
			
			var diff:amVector2d = world2.minus(world1);
			var distance:Number = diff.length;
			var numSegs:int = Math.round(distance / dashedLineDrawSegmentLength);
			var actualSegLength:Number = distance / (numSegs as Number);
			diff.setLength(actualSegLength);
			
			graphics.moveTo(world1.x, world1.y);
			for (var i:int = 0; i < numSegs; i++) 
			{
				world1.translateBy(diff);
				
				if ( i % 2 == 0 )
				{
					graphics.lineTo(world1.x, world1.y);
				}
				else
				{
					graphics.moveTo(world1.x, world1.y);
				}
			}
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			var bodyA:b2Body, bodyB:b2Body;
			var anchorA:b2Vec2, anchorB:b2Vec2;
			if ( distJoint )
			{
				bodyA = distJoint.m_bodyA;
				bodyB = distJoint.m_bodyB;
				anchorA = distJoint.m_localAnchor1;
				anchorB = distJoint.m_localAnchor2;
			}
			else
			{
				bodyA   = ropeJoint.m_bodyA;
				bodyB   = ropeJoint.m_bodyB;
				anchorA = ropeJoint.m_localAnchorA;
				anchorB = ropeJoint.m_localAnchorB;
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
			{  return qb2_toString(this, "qb2DistanceJoint");  }
	}
}