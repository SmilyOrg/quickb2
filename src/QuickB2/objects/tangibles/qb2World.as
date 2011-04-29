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
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.effects.*;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2World extends qb2Group
	{
		qb2_friend const preEventers:Dictionary = new Dictionary(true);
		qb2_friend const postEventers:Dictionary = new Dictionary(true);
		
		qb2_friend var _worldB2:b2World;
		
		public static const DEFAULT_TIME_STEP:Number = 1.0 / 30.0;
		
		/** If using auto-stepping with start()/stop(), this is the default time step (in seconds) taken each frame.
		 * You generally want this to coincide with your display rate. This value is ignored if realTimeUpdate==true.
		 * @default 1.0/30.0
		 * @see #realTimeUpdate
		 */
		public var defaultTimeStep:Number = DEFAULT_TIME_STEP;
		
		/** If true, things will update based on the actual elapsed time since the last update.
		 * If false, the simulation will update on the fixed time step specified by defaultTimeStep.
		 * @default true
		 * @see #defaultTimeStep
		 */
		public var realtimeUpdate:Boolean = false;
		
		/** Number of position iterations to use for each update. A higher number will produce a slower but more accurate simulation.
		 * @default 3
		 */
		public var defaultPositionIterations:uint = 3;
		
		/** Number of velocity iterations to use for each update. A higher number will produce a slower but more accurate simulation.
		 * @default 3
		 */
		public var defaultVelocityIterations:uint = 8;
		
		/** If realtimeUpdate is true, this is the maximum step that will be taken per frame.  Large timesteps cause instabilities,
		 * so this setting makes it so that under heavy load, or on slow computers, the physics don't go completely haywire.
		 * @default = 1.0/10.0
		 * @see #realtimeUpdate
		 */
		public var maximumRealtimeStep:Number = 1.0/10.0;
		
		private var lastTime:Number = 0;
	
		//---- Used to register an event loop.
		private var eventer:Sprite = new Sprite();
		
		/** Use this body to attach joints to the background of you application.
		 **/
		public function get background():qb2Body
			{  return _background;  }
		qb2_friend var _background:qb2Body = new qb2Body();
		
		qb2_friend var isLocked:Boolean = false;
		
		private const delayedTangCalls:Vector.<qb2InternalDelayedCall>  = new Vector.<qb2InternalDelayedCall>();
		private const delayedJointCalls:Vector.<qb2InternalDelayedCall> = new Vector.<qb2InternalDelayedCall>();
		
		//--- (b2World=>qb2World) Maintains an array of all active worlds, only useful for qb2DebugDrawPanel for the time being.
		//--- Weak keys allow the world to be garbage collected, and effectively automatically removed from the array.
		//--- The user should really never instantiate more than one world, but you never know I guess.
		qb2_friend static const worldDict:Dictionary = new Dictionary(true);

		/** Creates a new qb2World instance.
		 */
		public function qb2World()
		{
			b2Base.initialize(true);
			
			b2World.defaultContactListener     = qb2InternalContactListener;
			b2World.defaultDestructionListener = qb2InternalDestructionListener;
			_worldB2 = new b2World(new V2(), true);
			_world = this;
			
			worldDict[_worldB2] = this;
			
			gravity = new amVector2d();
			
			//--- Just manually set this stuff, since this body isn't technically part of the world hierarchy.
			_background._world = this;
			_background._parent = this;
			_background._rigidImp._bodyB2 = _worldB2.m_groundBody;
		}
		
		/** The box2d world that qb2World wraps.  This object has lower-level properties and functions that might not
		 * be exposed through QuickB2, but generally you don't need to use it.  The b2World should be considered read-only.
		 */
		public function get b2_world():b2World
			{  return _worldB2;  }
			
		/** Defines gravity in the z direction.  Use this property for top-down games in combination with frictionZ.
		 * @default 0
		 */
		public function get gravityZ():Number
			{ return _gravityZ; }
		public function set gravityZ(value:Number):void 
		{
			_gravityZ = value;
			
			_globalGravityZRevision++;
		}
		private var _gravityZ:Number = 0;
		
		/** Defines gravity in the x and y directions.
		 * @default zero gravity
		 */
		public function get gravity():amVector2d
			{ return _gravity; }
		public function set gravity(value:amVector2d):void 
		{
			if ( _gravity )  _gravity.removeEventListener(amUpdateEvent.ENTITY_UPDATED, gravityUpdated);
			_gravity = value;
			_gravity.addEventListener(amUpdateEvent.ENTITY_UPDATED, gravityUpdated, null, true);
			gravityUpdated(null);
		}
		private var _gravity:amVector2d = null;
		
		private function gravityUpdated(evt:amUpdateEvent):void
			{  _worldB2.SetGravity(new V2(_gravity.x, _gravity.y));  }
		
		public function get continuousPhysics():Boolean
			{  return _worldB2.m_continuousPhysics;  }
		public function set continuousPhysics(bool:Boolean):void
			{  _worldB2.m_continuousPhysics = bool;  }
		
		qb2_friend function addDelayedCall(object:qb2Object, closure:Function, ... args):void
		{
			var delayedCall:qb2InternalDelayedCall = new qb2InternalDelayedCall();
			delayedCall.object = object;
			delayedCall.closure = closure;
			delayedCall.args = args;
			if ( object is qb2Shape )
			{
				(object as qb2Shape).flaggedForDestroy = true; // shape won't send any more contact events in this pass.
			}
			
			if ( object as qb2Joint )
			{
				delayedJointCalls.push(delayedCall);
			}
			else
			{
				delayedTangCalls.push(delayedCall);
			}
		}

		/** If set, objects in the world will be drawn to the context according to the values in qb2_debugDrawSettings.
		 * This is not meant as a production-level rendering solution, but is very useful for quick debugging.
		 * @default null
		 */
		public var debugDrawGraphics:srGraphics2d = null;
		
		/** If set, debug mouse dragging is enabled using the mouseX/Y of the given object. This makes every dynamic object draggable (except if the object has isDebugDraggable set to false.
		 * It is called debug because it is not meant as a robust solution for most games or simulations. Usually you set this to the stage or another high-level display list object.
		 * @default null
		 * @see #debugDragAccel
		 * @warning Make sure the display object you set this to can receive MouseEvent's.
		 */
		public function get debugDragSource():InteractiveObject
			{  return _debugDragSource;  }
		public function set debugDragSource(interactiveObject:InteractiveObject):void
		{
			mouseDown = false;
			
			if ( _debugDragSource )
			{
				if ( _debugDragSource.stage )
					_debugDragSource.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseEvent);
				_debugDragSource.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
			}
			
			_debugDragSource = interactiveObject;

			if ( _debugDragSource )
			{
				if ( !containsObject(_debugMouseJoint) )
				{
					_debugMouseJoint.object = null;
					addObject(_debugMouseJoint);
				}
					
				_debugDragSource.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent, false, 0, true);
			}
			else
			{
				if ( containsObject(_debugMouseJoint) )
				{
					removeObject(_debugMouseJoint);
				}
			}
		}
		private var _debugDragSource:InteractiveObject;
		
		
		/** If debugDragSource is set to something meaningful, this value determines how forcefully the mouse can drag bodies.
		 * It is scaled by the mass of the body being dragged, so all bodies will be dragged with the same apparent force.
		 * @default 1000.0
		 * @see #debugDragSource
		 */
		public var debugDragAccel:Number = 1000.0;
		
		//--- Internal variables for mouse tracking.
		private var mouseDown:Boolean = false;
		
		public function get debugMouseJoint():qb2MouseJoint
			{  return _debugMouseJoint;  }
		private const _debugMouseJoint:qb2MouseJoint = new qb2MouseJoint();
		
		/** The relationship between the physics world in meters and the Flash world in pixels. Box2D is tuned to work with values much
		 * smaller than the average resolutions of Flash apps.  30 pixels per 1 meter seems to be a good ratio for most simulations.
		 * NOTE: Unless otherwise noted, ALL units passed back and forth through qb2World are in pixels, for convenience. qb2World automatically does the conversion to "meters".
		 * @default 30.0
		 */
		public function get pixelsPerMeter():Number
			{	return _pixelsPerMeter;  }
		public function set pixelsPerMeter(value:Number):void
			{	_pixelsPerMeter = value;  }
		qb2_friend var _pixelsPerMeter:Number  = 30.0;
		
		//--- For internal use...listens for mouse events if _debugDragSource is set to something meaningful.
		private function mouseEvent(evt:MouseEvent):void
		{
			if ( !_debugDragSource )
			{
				mouseDown = false;
				return;
			}
			
			mouseDown = evt.type == MouseEvent.MOUSE_DOWN;
			
			if ( mouseDown )
			{
				_debugDragSource.stage.addEventListener(MouseEvent.MOUSE_UP, mouseEvent, false, 0, true);
			}
			else
			{
				_debugDragSource.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseEvent);
			}
		}
		
		private static const mouseDrag_iterator:qb2TreeTraverser = new qb2TreeTraverser();

		private function mouseDrag():void
		{
			// mouse press
			if( _debugDragSource && mouseDown && !_debugMouseJoint.object )
			{
				var rigid:qb2IRigidObject = null;
				
				var mousePoint:amPoint2d = new amPoint2d(_debugDragSource.mouseX, _debugDragSource.mouseY);
				var mousePointV2:V2 = new V2(mousePoint.x / _pixelsPerMeter, mousePoint.y / _pixelsPerMeter);
				
				mouseDrag_iterator.path = qb2TreeTraverser.Z_ORDER_TOP_TO_BOTTOM;
				mouseDrag_iterator.root = this;
				
				var mouseBit:uint = qb2_flags.IS_DEBUG_DRAGGABLE;
				while ( mouseDrag_iterator.hasNext )
				{
					var object:qb2Object = mouseDrag_iterator.currentObject;
					
					if ( !(object is qb2Tangible) )
					{
						mouseDrag_iterator.next(false);
						continue;
					}
					
					var asTang:qb2Tangible = object as qb2Tangible;
					
					if ( !(asTang._flags & mouseBit) || asTang.mass == 0 || asTang.isKinematic )
					{
						mouseDrag_iterator.next(false);
						continue;
					}
					
					if ( object is qb2Shape )
					{
						var asShape:qb2Shape = object as qb2Shape;
						var numShapeB2s:int = asShape.shapeB2s.length;
						
						if ( !numShapeB2s )  continue;
						
						var theBodyB2:b2Body = asShape.fixtures[0].m_body;
						var xf:XF = theBodyB2.GetTransform();
						
						var hit:Boolean = false;
						for (var i:int = 0; i < numShapeB2s; i++) 
						{
							var shapeB2:b2Shape = asShape.shapeB2s[i];
							
							if ( shapeB2.TestPoint(xf, mousePointV2) )
							{
								rigid = asShape;
								hit = true;
								break;
							}
						}
						
						if ( hit )
						{
							break;
						}
					}
					
					mouseDrag_iterator.next();
				}
				
				if ( rigid )
				{
					var massToUse:Number = 0;
					
					while ( rigid )
					{
						if ( rigid.b2_body )
						{
							break;
						}
						
						rigid = rigid.parent as qb2IRigidObject;
					}
					
					_debugMouseJoint.object = rigid;
					if ( !containsObject(_debugMouseJoint) ) // a world.removeAllObjects(), for example, could remove this joint inadvertently.
						addObject(_debugMouseJoint);
					_debugMouseJoint.setWorldAnchor(mousePoint);
					_debugMouseJoint.maxForce = (rigid.mass + rigid.attachedMass) * debugDragAccel;
					setObjectIndex(_debugMouseJoint, numObjects - 1); // make joint be drawn on top of everything else...this could be done every frame to be guaranteed always on top, but that prolly costs more than it's worth.
				}
			}

			if( _debugMouseJoint.object && (!mouseDown || !_debugDragSource || !_debugMouseJoint.object.world) )
			{
				_debugMouseJoint.object = null;
			}

			if( _debugMouseJoint.object )
			{
				_debugMouseJoint.worldTarget.set(_debugDragSource.mouseX, _debugDragSource.mouseY);
			}
		}
		
		/** Whether or not start() has been called.
		 * @default false
		 * @see #start()
		 */
		public function get running():Boolean
			{  return _running;  }
		private var _running:Boolean = false;
	
		/** Starts the simulation by registering an Event.ENTER_FRAME on an internal dummy Sprite, which calls step().
		 * If you want to operate on an frequency different than your display rate, set up a timer or something and call step() yourself.
		 * @see #stop()
		 * @see #step()
		 */
		public function start():void
			{  _running = true;  lastTime = getTimer() / 1000.0;  eventer.addEventListener(Event.ENTER_FRAME, enterFrame, false, 0, true);  }
		
		/** Stops the simulation by unregistering the Event.ENTER_FRAME started with start().
		 * @see #start()
		 * @see #step()
		 */
		public function stop():void
			{  _running = false;  eventer.removeEventListener(Event.ENTER_FRAME, enterFrame);  }
		
		private function enterFrame(evt:Event):void
		{
			var currTime:Number = getTimer() / 1000.0;
			var timeStep:Number = realtimeUpdate ? amUtils.constrain(currTime - lastTime, 0, maximumRealtimeStep) : defaultTimeStep;
			
			step(timeStep, defaultPositionIterations, defaultVelocityIterations);
			
			lastTime = currTime;
		}
		
		/**
		 * The last time step that was used to advance the physics world in step().
		 * This can change slightly for each pass if realTimeUpdate == true.
		 * @default 0
		 * @see #step()
		 * @see #realTimeUpdate
		 */
		public function get lastTimeStep():Number
			{  return _lastTimeStep;  }
		private var _lastTimeStep:Number = 0;
		
		/**
		 * The amount of time in seconds that has passed in the physics world since the simulation started.
		 * That is, the number of times step() has been called multiplied by the time step used on each call.
		 * @default 0
		 */
		public function get clock():Number
			{  return _clock;  }
		private var _clock:Number = 0;
		
		/**
		 * Updates the physics world. This includes processing debug mouse input, drawing debug graphics, updating the clock, firing pre/post events, and updating sprite/actor positions (if applicable).
		 * You can call step any time and as often as you want, it doesn't have to be once per frame.  For example you can call step a dozen or so times in a for-loop in order to simulate something to rest.
		 * step() is called automatically once per frame if you're using start()/stop() to manage your game loop.
		 * @see #defaultTimeStep
		 * @see #realtimeUpdate
		 * @see #start()
		 * @see #stop()
		 */
		public function step( timeStep:Number = DEFAULT_TIME_STEP, positionIterations:uint = 3, velocityIterations:uint = 8 ):void
		{
			for (var key:* in preEventers)
			{
				var dispatcher:qb2Object = key as qb2Object;
				var preEvent:qb2UpdateEvent = qb2_cachedEvents.UPDATE_EVENT;
				preEvent.type = qb2UpdateEvent.PRE_UPDATE;
				preEvent._object = dispatcher;
				dispatcher.dispatchEvent(preEvent);
			}
			
			mouseDrag();
			
			_lastTimeStep = timeStep;
			_clock += _lastTimeStep;
	
			isLocked = true;
			{
				b2Base.lib.b2World_Step(_worldB2._ptr, timeStep, velocityIterations, positionIterations);
			}
			isLocked = false;
			
			//--- Go through the changes made by the user to the physics world (if any) inside contact callbacks.
			//--- These are delayed until now because changing things in the middle of a timestep is not allowed in Box2D.
			for ( var i:int = 0; i < delayedTangCalls.length; i++ )
			{
				processDelayedCall(delayedTangCalls[i]);
			}
			for ( i = 0; i < delayedJointCalls.length; i++ )
			{
				processDelayedCall(delayedJointCalls[i]);
			}
			delayedTangCalls.length = delayedJointCalls.length = 0;
			
			update();
			
			if ( debugDrawGraphics )
			{
				debugDrawGraphics.clear();
				drawDebug(debugDrawGraphics);
			}
			
			//--- Give the user a chance to do some logic.
			for ( key in postEventers)
			{
				dispatcher = key as qb2Object;
				var postEvent:qb2UpdateEvent = qb2_cachedEvents.UPDATE_EVENT;
				postEvent.type = qb2UpdateEvent.POST_UPDATE;
				postEvent._object = dispatcher;
				dispatcher.dispatchEvent(postEvent);
			}
		}
		
		private static function processDelayedCall(delayedCall:qb2InternalDelayedCall):void
		{				
			var makeTheCall:Boolean = true; // the call isn't made if it appears it is for destroying a box2d object that was already destroyed implicitly.
			var object:qb2Object = delayedCall.object;
			var args:Array = delayedCall.args;
			
			if ( object is qb2Shape )
			{
				(object as qb2Shape).flaggedForDestroy = false;
				
				if ( args[0] is b2Fixture)
				{
					makeTheCall = (args[0] as b2Fixture).GetBody().m_fixtureCount > 0;
				}
			}
			else if ( object is qb2Joint )
			{
				if ( args[0] is b2Joint )
				{
					makeTheCall = (args[0] as b2Joint).m_userData != qb2InternalDestructionListener.JOINT_DESTROYED_IMPLICITLY;
				}
			}
			
			if ( makeTheCall )
			{
				delayedCall.closure.apply(null, args);
			}
		}
		
		public function get totalNumPolygons():uint
			{  return _totalNumPolygons;  }
		qb2_friend var _totalNumPolygons:uint  = 0;
		
		public function get totalNumCircles():uint
			{  return _totalNumCircles;  }
		qb2_friend var _totalNumCircles:uint  = 0;
		
		public function get totalNumJoints():uint
			{  return _totalNumJoints;  }
		qb2_friend var _totalNumJoints:uint = 0;
		
		public override function removeObject(object:qb2Object):qb2ObjectContainer
		{
			if ( object == _background )  throw new Error("Background body cannot be removed from the world");
			return super.removeObject(object);
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			qb2_throw(qb2_errors.CLONE_ERROR);
			
			return null;
		}
		
		qb2_friend const _effectFieldStack:Vector.<qb2EffectField> = new Vector.<qb2EffectField>();
		
		qb2_friend function registerGlobalTerrain(terrain:qb2Terrain):void
		{
			terrain.addEventListener(qb2ContainerEvent.INDEX_CHANGED, terrainIndexChanged, null, true);
			
			addTerrainToList(terrain);
		}
		
		private function terrainIndexChanged(evt:qb2ContainerEvent):void
		{
			var terrain:qb2Terrain = evt.child as qb2Terrain;
			
			_globalTerrainList.splice(_globalTerrainList.indexOf(terrain), 1);
			
			addTerrainToList(terrain);
		}
		
		private function addTerrainToList(terrain:qb2Terrain):void
		{
			if ( !_globalTerrainList )
			{
				_globalTerrainList = new Vector.<qb2Terrain>();
				_globalTerrainList.push(terrain);
			}
			else
			{
				var inserted:Boolean = false;
				for (var i:int = 0; i < _globalTerrainList.length; i++) 
				{
					var ithTerrain:qb2Terrain = _globalTerrainList[i];
					
					if ( terrain.isBelow(ithTerrain) )
					{
						inserted = true;
						_globalTerrainList.splice(i, 0, terrain);
						break;
					}
				}
				
				if ( !inserted )
				{
					_globalTerrainList.push(terrain);
				}
			}
			
			_globalTerrainRevision++;
		}
		
		qb2_friend function unregisterGlobalTerrain(terrain:qb2Terrain):void
		{
			_globalTerrainList.splice(_globalTerrainList.indexOf(terrain), 1);
			
			if ( !_globalTerrainList.length )
			{
				_globalTerrainList = null;
			}
			
			terrain.removeEventListener(qb2ContainerEvent.INDEX_CHANGED, terrainIndexChanged);
			
			_globalTerrainRevision++;
		}
		
		qb2_friend var _globalTerrainList:Vector.<qb2Terrain> = null;
		
		qb2_friend var _globalGravityZRevision:int = 0;
		qb2_friend var _globalTerrainRevision:int = 0;
		
		qb2_friend const _terrainRevisionDict:Dictionary = new Dictionary(true);
		qb2_friend const _gravityZRevisionDict:Dictionary = new Dictionary(true);
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2World");  }
	}
}