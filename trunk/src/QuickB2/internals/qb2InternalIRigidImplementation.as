package QuickB2.internals 
{
	import As3Math.consts.TO_DEG;
	import As3Math.general.amUpdateEvent;
	import As3Math.general.amUtils;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import Box2DAS.Common.b2Def;
	import Box2DAS.Common.V2;
	import Box2DAS.Dynamics.b2Body;
	import Box2DAS.Dynamics.b2BodyDef;
	import flash.geom.Matrix;
	import flash.utils.Dictionary;
	import QuickB2.*;
	import QuickB2.misc.qb2_flags;
	import QuickB2.misc.qb2_props;
	import QuickB2.objects.joints.qb2Joint;
	import QuickB2.objects.tangibles.qb2IRigidObject;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import QuickB2.objects.tangibles.qb2World;
	import QuickB2.*;
	import As3Math.*;
	
	
	use namespace qb2_friend;
	use namespace am_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2InternalIRigidImplementation 
	{
		qb2_friend static const diffTol:Number = .0000000001;
		qb2_friend static const rotTol:Number  = .0000001;
		
		qb2_friend var _bodyB2:b2Body;
		qb2_friend var _attachedJoints:Vector.<qb2Joint> = null;
		qb2_friend var _linearVelocity:amVector2d = null;
		qb2_friend var _angularVelocity:Number = 0;
		qb2_friend var _position:amPoint2d = null;
		qb2_friend var _rotation:Number = 0;
		qb2_friend var _tang:qb2Tangible;
		
		public function qb2InternalIRigidImplementation(tang:qb2Tangible) 
		{
			init(tang);
		}
		
		private function init(tang:qb2Tangible):void
		{
			_tang = tang;
			_position = new amPoint2d();
			_position.addEventListener(amUpdateEvent.ENTITY_UPDATED, pointUpdated, null, true);
			_linearVelocity = new amVector2d();
			_linearVelocity.addEventListener(amUpdateEvent.ENTITY_UPDATED, vectorUpdated, null, true);
		}
		
		qb2_friend function setLinearVelocity(newVector:amVector2d):void
		{
			if ( _linearVelocity )  _linearVelocity.removeEventListener(amUpdateEvent.ENTITY_UPDATED, vectorUpdated);
			_linearVelocity = newVector;
			_linearVelocity.addEventListener(amUpdateEvent.ENTITY_UPDATED, vectorUpdated, null, true);
			vectorUpdated(null);
		}
		
		qb2_friend function setAngularVelocity(radsPerSec:Number):void
		{
			_angularVelocity = radsPerSec;
			if ( _tang._bodyB2 )
			{
				_tang._bodyB2.m_angularVelocity = radsPerSec;
				_tang._bodyB2.SetAwake(true);
			}
		}
		
		qb2_friend function flagsChanged(affectedFlags:uint):void
		{
			//--- Make actual changes to a simulating body if the property has an actual effect.
			if ( _tang._bodyB2 )
			{
				if ( affectedFlags & qb2_flags.IS_KINEMATIC )
				{
					recomputeBodyB2Mass();
					_tang.updateFrictionJoints();
				}
				
				if ( affectedFlags & qb2_flags.HAS_FIXED_ROTATION )
				{
					_tang._bodyB2.SetFixedRotation(_tang.hasFixedRotation );
					_tang._bodyB2.SetAwake(true);
					(_tang as qb2IRigidObject).angularVelocity = 0; // object won't stop spinning if we don't stop it manually, because now it has infinite intertia.
				}
				
				if ( affectedFlags & qb2_flags.IS_BULLET )
				{
					_tang._bodyB2.SetBullet(_tang.isBullet);
				}
				
				if ( affectedFlags & qb2_flags.ALLOW_SLEEPING )
				{
					_tang._bodyB2.SetSleepingAllowed(_tang.allowSleeping);
				}
			}
		}
		
		qb2_friend final function propertyChanged(propertyName:String):void
		{
			//--- Make actual changes to a simulating body if the property has an actual effect.
			if ( _tang._bodyB2 )
			{
				if ( propertyName == qb2_props.LINEAR_DAMPING )
				{
					_tang._bodyB2.m_linearDamping = _tang.linearDamping;
				}
				else if ( propertyName == qb2_props.ANGULAR_DAMPING )
				{
					_tang._bodyB2.m_angularDamping = _tang.angularDamping;
				}
			}
		}
		
		private static function shouldTransform(oldPos:amPoint2d, newPos:amPoint2d, oldRot:Number, newRot:Number):Boolean
		{
			//--- Return true if oldPos and newPos reference the same object, cause in this case it's likely that pointUpdated was invoked, and _position was changed.
			return !oldPos.equals(newPos, diffTol) || !amUtils.isWithin(oldRot, newRot - rotTol, newRot + rotTol);
		}
		
		qb2_friend function makeBodyB2(theWorld:qb2World):void
		{			
			var conversion:Number = theWorld._pixelsPerMeter;
			
			//--- Populate body def.  
			var bodDef:b2BodyDef  = b2Def.body;
			bodDef.allowSleep     = _tang.allowSleeping;
			bodDef.fixedRotation  = _tang.hasFixedRotation;
			bodDef.bullet         = _tang.isBullet;
			bodDef.awake          = !_tang.sleepingWhenAdded;
			bodDef.linearDamping  = _tang.linearDamping;
			bodDef.angularDamping = _tang.angularDamping;
			bodDef.type           = b2Body.b2_staticBody; // NOTE: type is taken care of in recomputeB2Mass, which will be called after this function some time.
			bodDef.position.x     = _position.x / conversion;
			bodDef.position.y     = _position.y / conversion;
			bodDef.angle          = _rotation;
			
			_bodyB2 = theWorld._worldB2.CreateBody(bodDef);
			_bodyB2.m_linearVelocity.x = _linearVelocity.x;
			_bodyB2.m_linearVelocity.y = _linearVelocity.y;
			_bodyB2.m_angularVelocity  = _angularVelocity;
			_bodyB2.SetUserData(_tang);
		}
		
		qb2_friend function destroyBodyB2(theWorld:qb2World):void
		{
			_bodyB2.SetUserData(null);
			theWorld._worldB2.DestroyBody(_bodyB2);
			_bodyB2 = null;
		}
		
		qb2_friend function freezeBodyB2():void
		{
			var theWorld:qb2World = _tang.world;
			if ( !theWorld )  return;
			
			if ( theWorld.isLocked )
			{
				theWorld.addDelayedCall(null, freezeBodyB2);
				return;
			}
			
			if ( !_bodyB2 )  return;
			
			if ( _bodyB2.m_type == b2Body.b2_staticBody )  return;
			
			_linearVelocity._x = _bodyB2.m_linearVelocity.x;
			_linearVelocity._y = _bodyB2.m_linearVelocity.y;
			_angularVelocity   = _bodyB2.m_angularVelocity;
			
			_bodyB2.SetType(b2Body.b2_staticBody);
		}
		
		qb2_friend function recomputeBodyB2Mass():void
		{
			//--- Box2D gets pissed sometimes if you change a body from dynamic to static/kinematic within a contact callback.
			//--- So whenever this happen's the call is delayed until after the physics step, which shouldn't affect the simulation really.
			var theWorld:qb2World = _tang.world;
			if ( !theWorld )  return;
			if ( theWorld.isLocked )
			{
				theWorld.addDelayedCall(null, this.recomputeBodyB2Mass);
				return;
			}
			
			if ( !_bodyB2 )  return;
			
			var thisIsKinematic:Boolean = _tang.isKinematic;			
			
			_bodyB2.SetType(thisIsKinematic ? b2Body.b2_kinematicBody : (_tang._mass ? b2Body.b2_dynamicBody : b2Body.b2_staticBody));
			//_bodyB2.ResetMassData(); // this is called by SetType(), so was redundant, but i'm still afraid that commenting it out would break something, so it's here for now.
			
			//--- The mechanism by which we save some costly b2Body::ResetMassData() calls (by setting the body to static until all shapes are done adding),
			//--- causes the body's velocities to be zeroed out, so here we just set them back to what they were.
			if ( _bodyB2.m_type != b2Body.b2_staticBody )
			{
				_bodyB2.m_linearVelocity.x = _linearVelocity._x;
				_bodyB2.m_linearVelocity.y = _linearVelocity._y;
				_bodyB2.m_angularVelocity  = _angularVelocity;
			}
		}
		
		qb2_friend function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):void
		{
			_position.pushDispatchBlock(pointUpdated);
			{
				_position.scaleBy(xValue, yValue, origin);
			}
			_position.popDispatchBlock(pointUpdated);
				
			if ( scaleJointAnchors )
			{
				qb2Joint.scaleJointAnchors(xValue, yValue, _tang as qb2IRigidObject);
			}
			
			if ( _tang.actor && scaleActor )
			{
				_tang.actor.scaleBy(xValue, yValue);
			}
		}
		
		qb2_friend function update():void
		{
			if ( _bodyB2 )
			{
				//--- Clear forces.  This isn't done right after b2World::Step() with b2World::ClearForces(),
				//--- because we would have to go through the whole list of bodies twice.
				_bodyB2.m_force.x = _bodyB2.m_force.y = 0;
				_bodyB2.m_torque = 0;
				
				//--- Get new position/angle.
				const pixPerMeter:Number = _tang.worldPixelsPerMeter;
				var newRotation:Number = _bodyB2.GetAngle();
				var newPosition:amPoint2d = new amPoint2d(_bodyB2.GetPosition().x * pixPerMeter, _bodyB2.GetPosition().y * pixPerMeter);
				
				//--- Check if the new transform invalidates the bound box.
				if ( shouldTransform( _position, newPosition, _rotation, newRotation) )
				{
					if ( _tang is qb2PolygonShape ) // sloppy, but not doing this in qb2PolygonShape::update() saves a decent amount of double-checking
					{
						(_tang as qb2PolygonShape).updateFromLagPoints(newPosition, newRotation);
					}
				}
				
				//--- Update the transform, without invoking pointUpdated
				_position._x = newPosition._x;
				_position._y = newPosition._y;
				_rotation    = newRotation;
				
				//--- Update velocities, again without invoking callbacks.
				_linearVelocity._x = _bodyB2.m_linearVelocity.x;
				_linearVelocity._y = _bodyB2.m_linearVelocity.y;
				_angularVelocity   = _bodyB2.m_angularVelocity;
				
				updateActor();
			}
		}
	
		qb2_friend function updateActor():void
		{
			if ( _tang._actor )
			{
				 _tang._actor.x = _position.x;   _tang._actor.y = _position.y;
				_tang._actor.rotation = _rotation * TO_DEG;
			}
		}
		
		qb2_friend function setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject
		{
			var asRigid:qb2IRigidObject = _tang as qb2IRigidObject;
			if ( point != _position ) // if e.g. rotateBy or pointUpdated() calls this function, 'point' and '_position' refer to the same point object, otherwise _position must be made to refer to the new object
			{
				if ( _position )  _position.removeEventListener(amUpdateEvent.ENTITY_UPDATED, pointUpdated);
				_position = point;
				_position.addEventListener(amUpdateEvent.ENTITY_UPDATED, pointUpdated, null, true);
			}
			
			_rotation = rotationInRadians;
			
			adjustBodyB2Transform();
			
			updateActor();
			
			_tang.wakeUp();
			
			if ( _tang._ancestorBody ) // (if this object is a child of some body whose only other ancestors are qb2Groups...)
			{
				_tang.pushEditSession(); // this is only done to prevent b2Body::ResetMassData() from being effectively called more than necessary by setting body type to static.
				{
					_tang._positionInsideAncestorBodyChangedWhileInEditSession = true;
				}
				_tang.popEditSession();
				
				for (var i:int = 0; i < asRigid.numAttachedJoints; i++) 
				{
					var attachedJoint:qb2Joint = asRigid.getAttachedJointAt(i);
					attachedJoint.correctLocals();
				}
			}		
			
			return asRigid;
		}
		
		qb2_friend function adjustBodyB2Transform():void
		{
			if ( _bodyB2 )
			{
				var world:qb2World = _tang._world;
				
				if ( world.isLocked )
				{
					world.addDelayedCall(null, this.adjustBodyB2Transform);
				}
				else
				{
					var pixPerMeter:Number = world.pixelsPerMeter;
					_bodyB2.SetTransform(new V2(_position.x / pixPerMeter, _position.y / pixPerMeter), _rotation);
				}
			}
		}
		
		qb2_friend function vectorUpdated(evt:amUpdateEvent):void
		{
			if ( _bodyB2 )
			{
				_bodyB2.m_linearVelocity.x = _linearVelocity.x;
				_bodyB2.m_linearVelocity.y = _linearVelocity.y;
				_bodyB2.SetAwake(true);
			}
		}

		qb2_friend function pointUpdated(evt:amUpdateEvent):void
		{
			(_tang as qb2IRigidObject).setTransform(_position, _rotation);
		}
		
		qb2_friend function get attachedMass():Number
		{
			if ( !_attachedJoints )  return 0;
			
			var totalMass:Number = 0;
			var queue:Vector.<qb2IRigidObject> = new Vector.<qb2IRigidObject>();
			queue.unshift(_tang as qb2IRigidObject);
			var alreadyVisited:Dictionary = new Dictionary(true);
			while ( queue.length )
			{
				var rigid:qb2IRigidObject = queue.shift();
				
				if ( alreadyVisited[rigid] || !rigid.world )  continue;
				
				totalMass += rigid.mass;
				alreadyVisited[rigid] = true;
				
				for (var i:int = 0; i < rigid.numAttachedJoints; i++) 
				{
					var joint:qb2Joint = rigid.getAttachedJointAt(i);
					
					var otherObject:qb2Tangible = joint._object1 == rigid ? joint._object2 : joint._object1;
					
					if ( otherObject )  queue.unshift(otherObject as qb2IRigidObject);
				}
			}
			
			return totalMass - _tang.mass;
		}
	}
}