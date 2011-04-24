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

package QuickB2.objects.tangibles
{
	import As3Math.*;
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.effects.*;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.loaders.proxies.*;
	import QuickB2.misc.*;
	import QuickB2.misc.acting.qb2IActor;
	import QuickB2.misc.acting.qb2IActorContainer;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	use namespace am_friend;
	
	[Event(name="preSolve",       type="QuickB2.events.qb2ContactEvent")]
	[Event(name="postSolve",      type="QuickB2.events.qb2ContactEvent")]
	[Event(name="contactStarted", type="QuickB2.events.qb2ContactEvent")]
	[Event(name="contactEnded",   type="QuickB2.events.qb2ContactEvent")]
	
	[Event(name="massPropsChanged",   type="QuickB2.events.qb2MassEvent")]

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Tangible extends qb2Object
	{		
		qb2_friend var _rigidImp:qb2InternalIRigidImplementation;
		
		public function qb2Tangible():void
		{
			initRigidImp();
			
			super();
			
			init();
		}
		
		private function initRigidImp():void
		{
			if ( this is qb2IRigidObject )
			{
				_rigidImp = new qb2InternalIRigidImplementation(this);
			}
		}
		
		private function init():void
		{
			if ( (this as Object).constructor == qb2Tangible )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
			
			//--- Set up default values for various properties.
			turnFlagOn(qb2_flags.IS_DEBUG_DRAGGABLE | qb2_flags.ALLOW_SLEEPING | qb2_flags.ALLOW_COMPLEX_POLYGONS, false);
			setProperty(qb2_props.CONTACT_CATEGORY_FLAGS, 0x0001 as uint, false);
			setProperty(qb2_props.CONTACT_MASK_FLAGS,     0xFFFF as uint, false);
			setProperty(qb2_props.FRICTION,              .2,              false);
			setProperty(qb2_props.SLICE_FLAGS,            0xFFFFFFFF,     false);
		}
		
		qb2_friend var _editSessionTracker:int;
		qb2_friend var _massAtStartOfEditSession:Number;
		qb2_friend var _areaAtStartOfEditSession:Number;
		qb2_friend var _geometryChangeOccuredWhileInEditSession:Boolean = false;
		qb2_friend var _positionInsideAncestorBodyChangedWhileInEditSession:Boolean = false;
		
		public function pushEditSession():void
		{
			if ( !_editSessionTracker )
			{
				editSessionStarted();
			}
			
			_editSessionTracker++;
		}
		
		public function popEditSession():void
		{
			_editSessionTracker--;
			
			if ( _editSessionTracker == 0 )
			{
				editSessionEnded();
			}
			else if( _editSessionTracker < 0 )
			{
				_editSessionTracker = 0;
			}
		}
		
		public function get inEditingSession():Boolean
		{
			return _editSessionTracker ? true : false;
		}
		
		qb2_friend function editSessionStarted():void
		{
			if ( !_ancestorBody && _rigidImp )
			{
				_rigidImp.freezeBodyB2();
			}
			else if( _ancestorBody )
			{
				_ancestorBody._rigidImp.freezeBodyB2();
			}
			
			_positionInsideAncestorBodyChangedWhileInEditSession = false;
			_geometryChangeOccuredWhileInEditSession = false;
			_massAtStartOfEditSession = _mass;
			_areaAtStartOfEditSession = _surfaceArea;
		}
		
		qb2_friend function editSessionEnded():void
		{
			if ( _geometryChangeOccuredWhileInEditSession || _positionInsideAncestorBodyChangedWhileInEditSession )
			{
				flushShapes();
			}
			
			_geometryChangeOccuredWhileInEditSession = false;
			_positionInsideAncestorBodyChangedWhileInEditSession = false;
			
			var massDiff:Number = _mass        - _massAtStartOfEditSession;
			var areaDiff:Number = _surfaceArea - _areaAtStartOfEditSession;
			
			var currParent:qb2Tangible = this;
			while (currParent)
			{					
				var beforeMass:Number = currParent._mass;
				var beforeArea:Number = currParent._surfaceArea;
				var beforeDens:Number = currParent.density;
				
				if ( currParent != this )
				{
					currParent._surfaceArea += areaDiff;
					currParent._mass        += massDiff;
				}
				
				if ( currParent.inEditingSession )  return;
				
				if ( !currParent._ancestorBody && currParent._rigidImp )
				{
					currParent._rigidImp.recomputeBodyB2Mass();
					currParent.wakeUp();
				}
				
				var dispatch:Boolean = true;
				if ( dispatch )
				{
					var evt:qb2MassEvent = qb2_cachedEvents.MASS_EVENT.inUse ? new qb2MassEvent() : qb2_cachedEvents.MASS_EVENT;
					evt.type = qb2MassEvent.MASS_PROPS_CHANGED;
					evt._affectedObject  = currParent;
					evt._massChange      = currParent._mass        - beforeMass;
					evt._areaChange      = currParent._surfaceArea - beforeArea;
					evt._densityChange   = currParent.density      - beforeDens;
					currParent.dispatchEvent(evt);
				}
				
				if ( currParent is qb2Shape )
				{
					currParent.updateFrictionJoints();
				}
				
				currParent = currParent._parent;
			}
		}
		
		qb2_friend function get _bodyB2():b2Body
		{
			return _rigidImp ? _rigidImp._bodyB2 : null;
		}
		
		public function get ancestorBody():qb2Body
			{  return _ancestorBody;  }
		qb2_friend var _ancestorBody:qb2Body;
		
		qb2_friend var _effectFields:Vector.<qb2EffectField>;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2Tangible = super.clone(deep) as qb2Tangible;
			
			cloned.copyTangibleProps(this, false);
			
			return cloned;
		}
			
		qb2_friend function copyTangibleProps(source:qb2Tangible, massPropsToo:Boolean = true ):void
		{
			if ( massPropsToo ) // clones will have this true by default, while convertTo*()'s will have it false.
			{
				this._surfaceArea = source._surfaceArea;
				this._mass        = source._mass;
			}
			
			//--- Copy velocities.
			if ( (this is qb2IRigidObject) && (source is qb2IRigidObject) )
			{
				_rigidImp._linearVelocity._x = source._rigidImp._linearVelocity._x;
				_rigidImp._linearVelocity._y = source._rigidImp._linearVelocity._y;
				_rigidImp._angularVelocity   = source._rigidImp._angularVelocity;
			}
		}
		
		public virtual function testPoint(point:amPoint2d):Boolean  { return false; }
		
		public virtual function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			return this;
		}
		
		public virtual function translateBy(vector:amVector2d):qb2Tangible { return null; }
		
		public virtual function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible { return null; }
		
		public function distanceTo(otherTangible:qb2Tangible, outputVector:amVector2d = null, outputPointThis:amPoint2d = null, outputPointOther:amPoint2d = null, excludes:Array = null):Number
		{
			return qb2InternalDistanceQuery.distanceTo(this, otherTangible, outputVector, outputPointThis, outputPointOther, excludes);
		}
		
		public function get density():Number
			{  return _mass / _surfaceArea;  }
		public virtual function set density(value:Number):void { }

		public function get mass():Number
			{  return _mass;  }
		public virtual function set mass(value:Number):void  { }
		qb2_friend var _mass:Number = 0;

		public function get surfaceArea():Number
			{  return _surfaceArea;  }
		qb2_friend var _surfaceArea:Number = 0;
		
		public function get metricSurfaceArea():Number
		{
			const conversion:Number = worldPixelsPerMeter * worldPixelsPerMeter;
			return _surfaceArea/ conversion;
		}
		
		public function get metricDensity():Number
			{  return _mass / metricSurfaceArea;  }
		public function set metricDensity(value:Number):void
			{  density = value / (worldPixelsPerMeter * worldPixelsPerMeter);  }

			
		public function get restitution():Number
			{  return getProperty(qb2_props.RESTITUTION) as Number;  }
		public function set restitution(value:Number):void
			{  setProperty(qb2_props.RESTITUTION, value);  }
		
		public function get contactCategoryFlags():uint
			{  return getProperty(qb2_props.CONTACT_CATEGORY_FLAGS) as uint;  }
		public function set contactCategoryFlags(bitmask:uint):void
			{  setProperty(qb2_props.CONTACT_CATEGORY_FLAGS, bitmask);  }
		
		public function get contactMaskFlags():uint
			{  return getProperty(qb2_props.CONTACT_MASK_FLAGS) as uint;  }
		public function set contactMaskFlags(bitmask:uint):void
			{  setProperty(qb2_props.CONTACT_MASK_FLAGS, bitmask);  }
		
		public function get contactGroupIndex():int
			{  return getProperty(qb2_props.CONTACT_GROUP_INDEX) as int; }
		public function set contactGroupIndex(index:int):void
			{  setProperty(qb2_props.CONTACT_GROUP_INDEX, index);  }
	
		public function get friction():Number
			{  return getProperty(qb2_props.FRICTION) as Number;  }
		public function set friction(value:Number):void
			{  setProperty(qb2_props.FRICTION, value);  }
		
		public function get frictionZ():Number
			{  return getProperty(qb2_props.FRICTION_Z) as Number;  }
		public function set frictionZ(value:Number):void
			{  setProperty(qb2_props.FRICTION_Z, value);  }
		
		public function get linearDamping():Number
			{  return getProperty(qb2_props.LINEAR_DAMPING) as Number;  }
		public function set linearDamping(value:Number):void
			{  setProperty(qb2_props.LINEAR_DAMPING, value);  }
		
		public function get angularDamping():Number
			{  return getProperty(qb2_props.ANGULAR_DAMPING) as Number;  }
		public function set angularDamping(value:Number):void
			{  setProperty(qb2_props.ANGULAR_DAMPING, value);  }
	
		public function get sliceFlags():uint
			{  return getProperty(qb2_props.SLICE_FLAGS) as Number;  }
		public function set sliceFlags(value:uint):void
			{  setProperty(qb2_props.SLICE_FLAGS, value);  }
			
		public function turnSliceFlagOn(sliceFlagOrFlags:uint):qb2Tangible
			{	sliceFlags |= sliceFlagOrFlags;  return this;  }
			
		public function turnSliceFlagOff(sliceFlagOrFlags:uint):qb2Tangible
			{	sliceFlags &= ~sliceFlagOrFlags;  return this;  }
		public function isSliceFlagOn(sliceFlagOrFlags:uint):Boolean
			{  return sliceFlags & sliceFlagOrFlags ? true : false;  }
			
		public function setSliceFlag(bool:Boolean, sliceFlagOrFlags:uint):qb2Tangible
		{
			if ( bool )
			{
				sliceFlags |= sliceFlagOrFlags;
			}
			else
			{
				sliceFlags &= ~sliceFlagOrFlags;
			}
			
			return this;
		}

		public function get isGhost():Boolean
			{  return _flags & qb2_flags.IS_GHOST ? true : false;  }
		public function set isGhost(bool:Boolean):void
			{  setFlag(bool, qb2_flags.IS_GHOST);  }
		
		public function get isKinematic():Boolean
			{  return _flags & qb2_flags.IS_KINEMATIC ? true : false;  }
		public function set isKinematic(bool:Boolean):void
			{  setFlag(bool, qb2_flags.IS_KINEMATIC);  }
	
		public function get hasFixedRotation():Boolean
			{  return _flags & qb2_flags.HAS_FIXED_ROTATION ? true : false;  }
		public function set hasFixedRotation(bool:Boolean):void
			{  setFlag(bool, qb2_flags.HAS_FIXED_ROTATION);  }
		
		public function get allowComplexPolygons():Boolean
			{  return _flags & qb2_flags.ALLOW_COMPLEX_POLYGONS ? true : false;  }
		public function set allowComplexPolygons(bool:Boolean):void
			{  setFlag(bool, qb2_flags.ALLOW_COMPLEX_POLYGONS);  }
		
		public function get isBullet():Boolean
			{  return _flags & qb2_flags.IS_BULLET ? true : false;  }
		public function set isBullet(bool:Boolean):void
			{  setFlag(bool, qb2_flags.IS_BULLET);  }
		
		public function get allowSleeping():Boolean
			{  return _flags & qb2_flags.ALLOW_SLEEPING ? true : false;  }
		public function set allowSleeping(bool:Boolean):void
			{  setFlag(bool, qb2_flags.ALLOW_SLEEPING);  }
		
		public function get sleepingWhenAdded():Boolean
			{  return _flags & qb2_flags.SLEEPING_WHEN_ADDED ? true : false;  }
		public function set sleepingWhenAdded(bool:Boolean):void
			{  setFlag(bool, qb2_flags.SLEEPING_WHEN_ADDED);  }
		
		public function get isDebugDraggable():Boolean
			{  return _flags & qb2_flags.IS_DEBUG_DRAGGABLE ? true : false;  }
		public function set isDebugDraggable(bool:Boolean):void
			{  setFlag(bool, qb2_flags.IS_DEBUG_DRAGGABLE);  }

		
		
		public function get isSleeping():Boolean
		{
			if ( _bodyB2 )
				return !_bodyB2.IsAwake();
			else if ( _ancestorBody )
				return _ancestorBody.isSleeping;
			else
				return true;
		}
			
		public function putToSleep():void
		{
			if ( _world && _world.isLocked )
			{
				_world.addDelayedCall(this, putToSleep);
				return;
			}
			
			if ( _bodyB2 )
			{
				_bodyB2.SetAwake(false);
			}
		}

		public function wakeUp():void
		{
			if ( _world && _world.isLocked )
			{
				_world.addDelayedCall(this, wakeUp);
				return;
			}
			
			if ( _bodyB2 )
				_bodyB2.SetAwake(true);
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody._bodyB2.SetAwake(true);
		}
		
		public virtual function get centerOfMass():amPoint2d { return null; }  // implemented by qb2Shape, qb2Body, and qb2Group all seperately
		
		qb2_friend static const delayedAppliesDict:Dictionary = new Dictionary(true);
		
		private static function addDelayedApply(tang:qb2Tangible, delayedApply:qb2InternalDelayedApply):void
		{
			var vec:Vector.<qb2InternalDelayedApply> = delayedAppliesDict[tang] ? delayedAppliesDict[tang] : new Vector.<qb2InternalDelayedApply>();
			delayedAppliesDict[tang] = vec;
			vec.push(delayedApply);			
		}
		
		public function applyImpulse(atPoint:amPoint2d, impulseVector:amVector2d):void
		{
			if ( !_world )
			{
				var delayedApply:qb2InternalDelayedApply = new qb2InternalDelayedApply();
				delayedApply.point = atPoint.clone();
				delayedApply.vector = impulseVector.clone();
				delayedApply.isForce = false;
				addDelayedApply(this, delayedApply);
				
				return;
			}
			
			if ( _world.isLocked )
			{
				_world.addDelayedCall(this, applyImpulse, atPoint.clone(), impulseVector.clone());
				return;
			}
			
			if ( _bodyB2 )
			{
				_bodyB2.ApplyImpulse(new V2(impulseVector.x, impulseVector.y), new V2(atPoint.x / worldPixelsPerMeter, atPoint.y / worldPixelsPerMeter));
				_rigidImp._linearVelocity._x = _bodyB2.m_linearVelocity.x;
				_rigidImp._linearVelocity._y = _bodyB2.m_linearVelocity.y;
			}
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody.applyImpulse(_parent.getWorldPoint(atPoint), _parent.getWorldVector(impulseVector));
		}
		
		public function applyForce(atPoint:amPoint2d, forceVector:amVector2d):void
		{
			if ( !_world )
			{
				var delayedApply:qb2InternalDelayedApply = new qb2InternalDelayedApply();
				delayedApply.point = atPoint.clone();
				delayedApply.vector = forceVector.clone();
				delayedApply.isForce = true;
				addDelayedApply(this, delayedApply);
				
				return;
			}
			
			if ( _world.isLocked )
			{
				_world.addDelayedCall(this, applyForce, atPoint.clone(), forceVector.clone());
				return;
			}
			
			if ( _bodyB2 )
				_bodyB2.ApplyForce(new V2(forceVector.x, forceVector.y), new V2(atPoint.x / worldPixelsPerMeter, atPoint.y / worldPixelsPerMeter));
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody.applyForce(_parent.getWorldPoint(atPoint), _parent.getWorldVector(forceVector));
		}
		
		public function applyTorque(torque:Number):void
		{
			if ( !_world )
			{
				var delayedApply:qb2InternalDelayedApply = new qb2InternalDelayedApply();
				delayedApply.torque = torque;
				addDelayedApply(this, delayedApply);
				
				return;
			}
			
			if ( _world.isLocked )
			{
				_world.addDelayedCall(this, applyTorque, torque);
				return;
			}
			
			if ( _bodyB2 )
			{
				_bodyB2.ApplyTorque(torque);
			}
		}
			
		public function getWorldPoint(localPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d
		{
			var worldPnt:amPoint2d = new amPoint2d(localPoint._x, localPoint._y);
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					var currParentX:Number = currParent._rigidImp._position._x;
					var currParentY:Number = currParent._rigidImp._position._y;
					var currParentRot:Number = currParent._rigidImp._rotation;
					
					worldPnt._x += currParentX;
					worldPnt._y += currParentY;
					
					var sinRad:Number = Math.sin(currParentRot);
					var cosRad:Number = Math.cos(currParentRot);
					var newVertX:Number = currParentX + cosRad * (worldPnt._x - currParentX) - sinRad * (worldPnt._y - currParentY);
					var newVertY:Number = currParentY + sinRad * (worldPnt._x - currParentX) + cosRad * (worldPnt._y - currParentY);
					
					worldPnt._x = newVertX;
					worldPnt._y = newVertY;
				}
				
				currParent = currParent._parent;
			}
			
			return worldPnt;
		}

		public function getLocalPoint(worldPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d
		{
			var localPnt:amPoint2d = new amPoint2d(worldPoint._x, worldPoint._y);
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					localPnt._x -= space._rigidImp._position._x;
					localPnt._y -= space._rigidImp._position._y;
					
					var sinRad:Number = Math.sin(-space._rigidImp._rotation);
					var cosRad:Number = Math.cos(-space._rigidImp._rotation);
					var newVertX:Number = cosRad * (localPnt._x) - sinRad * (localPnt._y);
					var newVertY:Number = sinRad * (localPnt._x) + cosRad * (localPnt._y);
					
					localPnt._x = newVertX;
					localPnt._y = newVertY;
				}
			}
			
			return localPnt;
		}

		public function getWorldVector(localVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d
		{
			var worldVector:amVector2d = new amVector2d(localVector._x, localVector._y);
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					var sinRad:Number = Math.sin(currParent._rigidImp._rotation);
					var cosRad:Number = Math.cos(currParent._rigidImp._rotation);
					var newVecX:Number = worldVector._x * cosRad - worldVector._y * sinRad;
					var newVecY:Number = worldVector._x * sinRad + worldVector._y * cosRad;
					
					worldVector._x = newVecX;
					worldVector._y = newVecY;
				}
				
				currParent = currParent._parent;
			}
			
			return worldVector;
		}

		public function getLocalVector(worldVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d
		{
			var localVector:amVector2d = new amVector2d(worldVector._x, worldVector._y);
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					var sinRad:Number = Math.sin(-space._rigidImp._rotation);
					var cosRad:Number = Math.cos(-space._rigidImp._rotation);
					var newVecX:Number = localVector._x * cosRad - localVector._y * sinRad;
					var newVecY:Number = localVector._x * sinRad + localVector._y * cosRad;
					
					localVector._x = newVecX;
					localVector._y = newVecY;
				}
			}
			
			return localVector;
		}
		
		public function getWorldRotation(localRotation:Number, overrideWorldSpace:qb2Tangible = null):Number
		{
			var worldRotation:Number = localRotation;
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					worldRotation += currParent._rigidImp._rotation;
				}
				
				currParent = currParent._parent;
			}
			
			return worldRotation;
		}

		public function getLocalRotation(worldRotation:Number, overrideWorldSpace:qb2Tangible = null):Number
		{
			var localRotation:Number = worldRotation;
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					localRotation -= space._rigidImp._rotation;
				}
			}
			
			return localRotation;
		}
		
		public function getBoundBox(worldSpace:qb2Tangible = null):amBoundBox2d
		{
			var box:amBoundBox2d = new amBoundBox2d();
			var boxSet:Boolean = false;
			
			var queue:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			queue.unshift(this);
			
			while ( queue.length )
			{
				var tang:qb2Tangible = queue.shift();
				
				if ( tang is qb2Shape )
				{
					if ( tang is qb2CircleShape )
					{
						var asCircleShape:qb2CircleShape = tang as qb2CircleShape;
						var circlePoint:amPoint2d = asCircleShape.parent.getWorldPoint(asCircleShape.position, worldSpace);
						
						if ( !boxSet )
						{
							box.min = circlePoint;
							box.max.copy(box.min);
							box.swell(asCircleShape.radius);
							boxSet = true;
						}
						else
						{
							box.expandToPoint(circlePoint, asCircleShape.radius);
						}
					}
					else if ( tang is qb2PolygonShape )
					{
						var asPolygonShape:qb2PolygonShape = tang as qb2PolygonShape;
						
						for (var i:int = 0; i < asPolygonShape.numVertices; i++) 
						{
							var ithVertex:amPoint2d = asPolygonShape.parent.getWorldPoint(asPolygonShape.getVertexAt(i), worldSpace);
							
							if ( !boxSet )
							{
								box.min = ithVertex
								box.max.copy(box.min);
								boxSet = true;
							}
							else
							{
								box.expandToPoint(ithVertex);
							}
						}
					}
				}
				else if ( tang is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
					
					for ( i = 0; i < asContainer._objects.length; i++) 
					{
						var ithObject:qb2Object = asContainer._objects[i];
						
						if ( ithObject is qb2Tangible )
						{
							queue.unshift(ithObject as qb2Tangible);
						}
					}
				}
			}
			
			if ( !boxSet && (this is qb2Body) )
			{
				var worldPos:amPoint2d = getWorldPoint( (this as qb2Body)._rigidImp._position, worldSpace);
				box.setByCopy(worldPos, worldPos);
			}
			
			return box;
		}
		
		public function getBoundCircle(worldSpace:qb2Tangible = null):amBoundCircle2d
		{
			var circle:amBoundCircle2d = new amBoundCircle2d();
			var circleSet:Boolean = false;
			
			var queue:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			queue.unshift(this);
			
			var points:Dictionary = new Dictionary(true);
			
			while ( queue.length )
			{
				var tang:qb2Tangible = queue.shift();
				
				if ( tang is qb2Shape )
				{
					if ( tang is qb2CircleShape )
					{
						var asCircleShape:qb2CircleShape = tang as qb2CircleShape;
						var circlePoint:amPoint2d = asCircleShape.parent.getWorldPoint(asCircleShape.position, worldSpace);
						points[circlePoint] = asCircleShape.radius;
					}
					else if ( tang is qb2PolygonShape )
					{
						var asPolygonShape:qb2PolygonShape = tang as qb2PolygonShape;
						
						for (var i:int = 0; i < asPolygonShape.numVertices; i++) 
						{
							var ithVertex:amPoint2d = asPolygonShape.parent.getWorldPoint(asPolygonShape.getVertexAt(i), worldSpace);
							points[ithVertex] = 0;
						}
					}
				}
				else if ( tang is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
					
					for ( i = 0; i < asContainer._objects.length; i++) 
					{
						var ithObject:qb2Object = asContainer._objects[i];
						
						if ( ithObject is qb2Tangible )
						{
							queue.push(ithObject as qb2Tangible);
						}
					}
				}
			}
			
			return circle;
		}
		
		public function getLinearVelocityAtPoint(point:amPoint2d):amVector2d
		{
			if ( _bodyB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var pointB2:V2 = new V2(point.x / conversion, point.y / conversion);
				var velVecB2:V2 = _bodyB2.GetLinearVelocityFromWorldPoint(pointB2);
				return new amVector2d(velVecB2.x, velVecB2.y);
			}
			else if ( _ancestorBody )
			{
				if ( _ancestorBody._bodyB2 )
				{
					return _ancestorBody.getLinearVelocityAtPoint(_parent.getWorldPoint(point));
				}
				else
				{
					return new amVector2d();
				}
			}
			else if ( this is qb2Group )
			{
				var asGroup:qb2Group = this as qb2Group;
				var rigids:Vector.<qb2IRigidObject> = asGroup.getRigidsAtPoint(point);
				if ( rigids )
				{
					var highestRigid:qb2IRigidObject = rigids[rigids.length - 1];
					return highestRigid.getLinearVelocityAtPoint(point);
				}
			}
			
			return new amVector2d();
		}
		
		public function getLinearVelocityAtLocalPoint(point:amPoint2d):amVector2d
		{
			if ( _bodyB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var pointB2:V2 = new V2(point.x / conversion, point.y / conversion);
				var velVecB2:V2 = _bodyB2.GetLinearVelocityFromLocalPoint(pointB2);
				return new amVector2d(velVecB2.x, velVecB2.y);
			}
			else if ( _ancestorBody )
			{
				if ( _ancestorBody._bodyB2 )
				{
					var ancestorBodyLocalPoint:amPoint2d = _ancestorBody.getLocalPoint(this.getWorldPoint(point));
					return _ancestorBody.getLinearVelocityAtLocalPoint(ancestorBodyLocalPoint);
				}
				else
				{
					return new amVector2d();
				}
			}
			else if ( this is qb2Group )
			{
				var asGroup:qb2Group = this as qb2Group;
				var rigids:Vector.<qb2IRigidObject> = asGroup.getRigidsAtPoint(point);
				if ( rigids )
				{
					var highestRigid:qb2IRigidObject = rigids[rigids.length - 1];
					return highestRigid.getLinearVelocityAtPoint(point);
				}
			}
			
			return new amVector2d();
		}
		
		qb2_friend function populateTerrainsBelowThisTang():void
		{
			var globalList:Vector.<qb2Terrain> = _world._globalTerrainList;
			
			_terrainsBelowThisTang = null;
			
			if ( globalList )
			{
				var numGlobalTerrains:int = globalList.length;
			
				for (var i:int = numGlobalTerrains-1; i >= 0; i-- ) 
				{
					var ithTerrain:qb2Terrain = globalList[i];
					
					if ( this == ithTerrain || this.isDescendantOf(ithTerrain) )  continue;
					
					if ( this.isAbove(ithTerrain) )
					{
						if ( !_terrainsBelowThisTang )
						{
							_terrainsBelowThisTang = new Vector.<qb2Terrain>();
						}
						
						_terrainsBelowThisTang.unshift(ithTerrain);
						
						if ( ithTerrain.ubiquitous )
						{
							break; // ubiquitous terrains cover up all other terrains beneath them, so we can move on.
						}
					}
					else
					{
						break; // all subsequent terrains will be over this shape, so we can move on.
					}
				}
			}
			
			_world._terrainRevisionDict[this] = _world._globalTerrainRevision;
		}
		qb2_friend var _terrainsBelowThisTang:Vector.<qb2Terrain>;
		
		public function slice(laser:amLine2d, outputIntPoints:Vector.<amPoint2d> = null):Vector.<qb2Tangible>
		{
			return (_sliceUtility ? _sliceUtility : _sliceUtility = new qb2InternalSliceUtility()).slice(this, laser, outputIntPoints);
		}
		qb2_friend var _sliceUtility:qb2InternalSliceUtility = null;
		
		public function intersectsLine(line:amLine2d, outputIntPoints:Vector.<amPoint2d> = null, orderPoints:Boolean = true):Boolean
		{
			return qb2InternalLineIntersectionFinder.intersectsLine(this, line, outputIntPoints, orderPoints);
		}
		
		protected override function update():void
		{
			var asRigid:qb2IRigidObject = this as qb2IRigidObject;  // assuming a little, but the only classes to call this super function are qb2Body and qb2Shape anyway...
			var isShape:Boolean = this is qb2Shape;
			
			for ( var i:int = 0; i < _world._effectFieldStack.length; i++ )
			{
				var field:qb2EffectField = _world._effectFieldStack[i];
				
				if ( field.applyPerShape && isShape || !field.applyPerShape && this._bodyB2 )
				{
					if ( !field.isDisabledFor(this, true) )
					{
						field.applyToRigid(asRigid);
					}
				}
			}
		}
		
		qb2_friend function drawDebugExtras(graphics:srGraphics2d):void
		{
			//--- Draw positions for rigid objects.
			if ( (this is qb2IRigidObject) && (qb2_debugDrawSettings.flags & qb2_debugDrawFlags.POSITIONS) )
			{
				var rigid:qb2IRigidObject = this as qb2IRigidObject;
				var point:amPoint2d = _parent ? _parent.getWorldPoint(rigid.position) : rigid.position;
				
				graphics.beginFill(qb2_debugDrawSettings.positionColor, qb2_debugDrawSettings.positionAlpha);
					graphics.drawCircle(point.x, point.y, qb2_debugDrawSettings.pointRadius);
				graphics.endFill();
			}
		
			var flags:uint = qb2_debugDrawSettings.flags;
			var depth:uint = 0;
			
			var currParent:qb2Tangible = this;
			while ( currParent != _world )
			{
				depth++;
				currParent = currParent.parent;
			}
			
			if ( flags & qb2_debugDrawFlags.BOUND_BOXES )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.boundBoxStartDepth, qb2_debugDrawSettings.boundBoxEndDepth) )
				{
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, qb2_debugDrawSettings.boundBoxColor, qb2_debugDrawSettings.boundBoxAlpha);
					//getBoundBox().draw(graphics);
				}
			}
			
			if ( flags & qb2_debugDrawFlags.BOUND_CIRCLES )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.boundCircleStartDepth, qb2_debugDrawSettings.boundCircleEndDepth) )
				{
					graphics.setLineStyle(qb2_debugDrawSettings.lineThickness, qb2_debugDrawSettings.boundCircleColor, qb2_debugDrawSettings.boundCircleAlpha);
					//getBoundCircle().draw(graphics);
				}
			}
			
			if ( flags & qb2_debugDrawFlags.CENTROIDS )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.centroidStartDepth, qb2_debugDrawSettings.centroidEndDepth) )
				{
					var centroid:amPoint2d = centerOfMass;
					if ( centroid )
					{
						graphics.beginFill(qb2_debugDrawSettings.centroidColor, qb2_debugDrawSettings.centroidAlpha);
							graphics.drawCircle(centroid.x, centroid.y, qb2_debugDrawSettings.pointRadius);
						graphics.endFill();
					}
				}
			}
		}
		
		protected function get debugOutlineColor():uint
		{
			if ( isKinematic )
				return qb2_debugDrawSettings.kinematicOutlineColor;
			else
				return mass == 0 ? qb2_debugDrawSettings.staticOutlineColor : qb2_debugDrawSettings.dynamicOutlineColor;
		}
		
		protected function get debugFillColor():uint
		{
			if ( debugFillColorStack.length )
			{
				return debugFillColorStack[debugFillColorStack.length-1];
			}
			else
			{
				if ( isKinematic )
					return qb2_debugDrawSettings.kinematicFillColor;
				else
					return mass == 0 ? qb2_debugDrawSettings.staticFillColor : qb2_debugDrawSettings.dynamicFillColor;
			}
		}
		
		protected static function pushDebugFillColor(color:uint):void
			{  debugFillColorStack.push(color);  }
		
		protected static function popDebugFillColor():void
			{  debugFillColorStack.pop();  }
		
		private static const debugFillColorStack:Vector.<uint> = new Vector.<uint>();
		
		qb2_friend function pushToEffectsStack():int
		{
			var numPushed:int = 0;
			
			if ( _world  )
			{
				if ( _effectFields )
				{
					//--- Push all of this object's fields to the effects stack.
					for (var i:int = 0; i < _effectFields.length; i++) 
					{
						var ithField:qb2EffectField = _effectFields[i];
						
						_world._effectFieldStack.push(ithField);
						numPushed++;
					}
				}
			}
			
			return numPushed;
		}
		
		qb2_friend function popFromEffectsStack(numToPop:int):void
		{
			for (var i:int = 0; i < numToPop; i++) 
			{
				var field:qb2EffectField = _world._effectFieldStack.pop();
			}
		}
		
		qb2_friend virtual function updateFrictionJoints():void { }
		
		qb2_friend virtual function flushShapes():void  {}
	}
}