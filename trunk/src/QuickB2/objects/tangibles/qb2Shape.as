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
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.drawing.qb2_debugDrawFlags;
	import QuickB2.debugging.drawing.qb2_debugDrawSettings;
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	
	use namespace qb2_friend;
	
	use namespace am_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Shape extends qb2Tangible implements qb2IRigidObject
	{
		qb2_friend const shapeB2s:Vector.<b2Shape> = new Vector.<b2Shape>();  // must be an array, because non-convex polygons can decompose to several actual shapes...in general this will be length 1 though
		qb2_friend const fixtures:Vector.<b2Fixture> = new Vector.<b2Fixture>();
		
		qb2_friend var flaggedForDestroy:Boolean = false;
		
		public function qb2Shape()
		{
			super();
			
			init();
		}
		
		private function init():void
		{
			if ( (this as Object).constructor == qb2Shape )  qb2_throw(qb2_errors.ABSTRACT_CLASS_ERROR);
			
			turnFlagOn(qb2_flags.ALLOW_COMPLEX_POLYGONS, false); // for the "convertToPoly" function, this should be defined for circles and polys.
		}
		
		public function get b2_fixtures():Vector.<b2Fixture>
		{
			var newFixtureArray:Vector.<b2Fixture> = new Vector.<b2Fixture>();
			for (var i:int = 0; i < fixtures.length; i++) 
			{
				newFixtureArray.push(fixtures[i]);
			}
			return newFixtureArray;
		}
		
		public function get b2_body():b2Body
			{  return _bodyB2;  }
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			if ( shapeB2s.length )
			{
				point = _ancestorBody ? _parent.getWorldPoint(point) : point;
				var pntB2:V2 = new V2(point.x/worldPixelsPerMeter, point.y/worldPixelsPerMeter);
				for ( var i:int = 0; i < fixtures.length; i++ )
				{
					var ithFixture:b2Fixture = fixtures[i];
					var ithShape:b2Shape = ithFixture.GetShape();
					var parentBodyB2:b2Body = ithFixture.GetBody();
					
					if ( ithShape.TestPoint( parentBodyB2.GetTransform(), pntB2) )
					{
						return true;
					}
				}
			}
			
			return false;
		}

		public override function set density(value:Number):void
		{
			pushEditSession();
			{
				_mass = value * _surfaceArea;
				updateFixtureDensities();
			}
			popEditSession();
		}

		public override function set mass(value:Number):void
		{
			pushEditSession();
			{
				_mass = value;
				updateFixtureDensities();
			}
			popEditSession();
		}
		
		private function updateFixtureDensities():void
		{
			if ( fixtures.length )
			{
				var newDensity:Number = this.metricDensity;
				for ( var i:int = 0; i < fixtures.length; i++ )
				{
					fixtures[i].SetDensity(newDensity);
				}
			}
		}
			
		public virtual function get perimeter():Number
			{ return NaN; }
		
		public function get metricPerimeter():Number
			{ return perimeter / worldPixelsPerMeter; }
	
		protected override function propertyChanged(propertyName:String):void
		{
			_rigidImp.propertyChanged(propertyName); // sets body properties if this shape is flying solo and has a b2Body
			
			if ( !this.fixtures.length )  return;
				
			var i:int;
			var value:* = _propertyMap[propertyName];
			
			if ( propertyName == qb2_props.RESTITUTION )
			{
				for ( i = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].SetRestitution(value as Number);
				}
			}
			else if ( propertyName == qb2_props.CONTACT_CATEGORY_FLAGS )
			{
				for ( i = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].m_filter.categoryBits = value as uint;
					this.fixtures[i].Refilter();
				}
			}
			else if ( propertyName == qb2_props.CONTACT_MASK_FLAGS )
			{
				for ( i = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].m_filter.maskBits = value as uint;
					this.fixtures[i].Refilter();
				}
			}
			else if ( propertyName == qb2_props.CONTACT_GROUP_INDEX )
			{
				for ( i = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].m_filter.groupIndex = value as int;
					this.fixtures[i].Refilter();
				}
			}
			else if ( propertyName == qb2_props.FRICTION )
			{
				for ( i = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].SetFriction(value as Number);
				}
			}
			else if ( propertyName == qb2_props.FRICTION_Z )
			{
				updateFrictionJoints();
			}
		}
		
		protected override function flagsChanged(affectedFlags:uint):void
		{
			_rigidImp.flagsChanged(affectedFlags);
			
			if ( !this.fixtures.length )  return;
			
			if ( affectedFlags & qb2_flags.IS_GHOST )
			{
				var isAGhost:Boolean = isGhost;
				for ( var i:int = 0; i < this.fixtures.length; i++ )
				{
					this.fixtures[i].SetSensor(isAGhost);
				}
			}
			else if ( affectedFlags & qb2_flags.CONTACT_REPORTING_FLAGS )
			{
				for ( i = 0; i < shapeB2s.length; i++ )
				{
					fixtures[i].m_reportBeginContact = _flags & qb2_flags.REPORTS_CONTACT_STARTED ? true : false;
					fixtures[i].m_reportEndContact   = _flags & qb2_flags.REPORTS_CONTACT_ENDED   ? true : false;
					fixtures[i].m_reportPreSolve     = _flags & qb2_flags.REPORTS_PRE_SOLVE       ? true : false;
					fixtures[i].m_reportPostSolve    = _flags & qb2_flags.REPORTS_POST_SOLVE      ? true : false;
				}
			}
		}
		
		qb2_friend override function flushShapes():void
		{
			destroyShapeB2Wrapper(_world);
			makeShapeB2Wrapper(_world);
		}
		
		qb2_friend var frictionJoints:Vector.<b2FrictionJoint>;
		
		qb2_friend override function updateFrictionJoints():void
		{
			var needJoints:Boolean = true;
			
			if ( !_world || !_world.gravityZ || !frictionZ || !_mass || isKinematic )
			{
				destroyFrictionJoints();
				
				if ( _world )
				{
					_world._gravityZRevisionDict[this] = _world._globalGravityZRevision;
				}
				
				return;
			}
			
			if ( _world.isLocked )
			{
				_world.addDelayedCall(null, updateFrictionJoints);
				return;
			}
			
			if ( _world._terrainRevisionDict[this] != _world._globalTerrainRevision )
			{
				populateTerrainsBelowThisTang();
			}
			
			makeFrictionJoints();
			
			_world._gravityZRevisionDict[this] = _world._globalGravityZRevision;
		}
		
		qb2_friend final function populateFrictionJointArray(numPoints:int):void
		{
			if ( frictionJoints )  return;
			
			var theBodyB2:b2Body = _bodyB2 ? _bodyB2 : _ancestorBody._bodyB2;
			var fricDef:b2FrictionJointDef = b2Def.frictionJoint;
			fricDef.bodyA = theBodyB2;
			fricDef.bodyB = theBodyB2.m_world.m_groundBody;
			fricDef.userData = this;
			
			frictionJoints = new Vector.<b2FrictionJoint>();
			
			for (var j:int = 0; j < numPoints; j++) 
			{
				frictionJoints.push(_world._worldB2.CreateJoint(fricDef));
			}
		}
		
		qb2_friend virtual function makeFrictionJoints():void  {}
		
		qb2_friend final function destroyFrictionJoints():void
		{
			if ( frictionJoints )
			{
				for (var j:int = 0; j < frictionJoints.length; j++) 
				{
					var jthFrictionJoint:b2FrictionJoint = frictionJoints[j];
					
					var theWorld:qb2World = qb2World.worldDict[jthFrictionJoint.m_world] as qb2World;
					
					if ( theWorld.isLocked )
					{
						theWorld.addDelayedCall(null, jthFrictionJoint.m_world.DestroyJoint, jthFrictionJoint);
					}
					else
					{
						jthFrictionJoint.m_world.DestroyJoint(jthFrictionJoint);
					}
				}
				
				frictionJoints.length = 0;
				frictionJoints = null;
			}
			
			if ( _terrainsBelowThisTang )
			{
				_terrainsBelowThisTang.length = 0;
				_terrainsBelowThisTang = null;
			}
		}
		
		qb2_friend override function shouldMake():Boolean
			{  return true;  }
		
		qb2_friend override function shouldDestroy():Boolean
			{  return true;  }
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			//--- If this is a lone shape being added to the world, internally it must have its own body.
			if ( !_ancestorBody )
			{
				_rigidImp.makeBodyB2(theWorld);
			}
			
			makeShapeB2(theWorld);
		}
		
		qb2_friend function makeShapeB2Wrapper(theWorld:qb2World):void
		{
			if ( theWorld )
			{
				if ( theWorld.isLocked )
				{
					theWorld.addDelayedCall(this, makeShapeB2Wrapper, theWorld);
				}
				else
				{
					makeShapeB2(theWorld);
				}
			}
		}
		
		qb2_friend function destroyShapeB2Wrapper(theWorld:qb2World):void
		{
			if ( theWorld )
			{
				if ( theWorld.isLocked )
				{
					theWorld.addDelayedCall(this, destroyShapeB2Wrapper, theWorld);
				}
				else
				{
					destroyShapeB2(theWorld);
				}
			}
		}
		
		qb2_friend function makeShapeB2(theWorld:qb2World):void
		{
			var body:b2Body = _ancestorBody ? _ancestorBody._bodyB2 : _bodyB2;
			
			const conversion:Number = theWorld._pixelsPerMeter;
		
			//--- Populate the fixture definition.
			var fixtureDef:b2FixtureDef    = b2Def.fixture;
			fixtureDef.density             =  _mass / (_surfaceArea / (conversion * conversion));
			fixtureDef.filter.categoryBits = contactCategoryFlags;
			fixtureDef.filter.maskBits     = contactMaskFlags;
			fixtureDef.filter.groupIndex   = contactGroupIndex;
			fixtureDef.friction            = friction;
			fixtureDef.isSensor            = isGhost;
			fixtureDef.restitution         = restitution;
			
			for ( var i:int = 0; i < shapeB2s.length; i++ )
			{
				fixtureDef.shape = shapeB2s[i];
				fixtures.push(body.CreateFixture(fixtureDef));
				fixtures[i].SetUserData(this);
				
				fixtures[i].m_reportBeginContact = _flags & qb2_flags.REPORTS_CONTACT_STARTED ? true : false;
				fixtures[i].m_reportEndContact   = _flags & qb2_flags.REPORTS_CONTACT_ENDED   ? true : false;
				fixtures[i].m_reportPreSolve     = _flags & qb2_flags.REPORTS_PRE_SOLVE       ? true : false;
				fixtures[i].m_reportPostSolve    = _flags & qb2_flags.REPORTS_POST_SOLVE      ? true : false;
			}
			
			theWorld._terrainRevisionDict[this]  = 0 as int;
			theWorld._gravityZRevisionDict[this] = 0 as int;
			
			updateFrictionJoints();
		}
		
		qb2_friend override function destroy(theWorld:qb2World):void
		{
			if ( _bodyB2 )
			{
				_rigidImp.destroyBodyB2(theWorld);
			}
			
			destroyShapeB2(theWorld);
		}
		
		qb2_friend function destroyShapeB2(theWorld:qb2World):void
		{
			for ( var i:int = 0; i < fixtures.length; i++ )
			{
				var fixture:b2Fixture = fixtures[i];
			
				//--- qb2InternalDestructionListener marks any impliclity destroyed fixtures (fixtures that were destroyed because
				//--- the body was destroyed).  So we only have to destroy the fixture here if, e.g. this shape is being removed from a body by itself.
				if ( doNotDestroyList[fixture] )
				{
					delete doNotDestroyList[fixture];
				}
				else
				{
					fixture.GetBody().DestroyFixture(fixture);
				}
				
				// fixture.SetUserData(null);
				shapeB2s[i].destroy(); // this just cleans up C++ memory...supposedly...it has nothing to do with the qb2Object::destroy() function
			}
			
			fixtures.length = shapeB2s.length = 0;
			
			delete theWorld._terrainRevisionDict[this];
			delete theWorld._gravityZRevisionDict[this];
			
			updateFrictionJoints();
		}
		
		qb2_friend const doNotDestroyList:Dictionary = new Dictionary(true);
		
		protected override function update():void
		{
			var numToPop:int = pushToEffectsStack();
			
			_rigidImp.update();
			super.update();
			
			if ( _world._gravityZRevisionDict[this] != _world._globalGravityZRevision || frictionJoints && _world._terrainRevisionDict[this] != _world._globalTerrainRevision )
			{
				updateFrictionJoints();
			}
			
			//--- Update friction joint max force based on which terrains each friction point is touching.
			if ( frictionJoints && _terrainsBelowThisTang )
			{
				var frictionJointBodyB2:b2Body = frictionJoints[0].m_bodyA;
				var transform:b2Transform = frictionJointBodyB2.m_xf;
				var p:b2Vec2 = transform.position;
				var r:b2Mat22 = transform.R;
				var col1:b2Vec2 = r.col1;
				var col2:b2Vec2 = r.col2;
				var frictionJointWorldV2:V2 = new V2();
				
				var maxForce:Number = (_world.gravityZ * frictionZ * _mass) / frictionJoints.length;
				var numFrictionJoints:int = frictionJoints.length;
				for (var i:int = 0; i < numFrictionJoints; i++) 
				{
					var ithFricJoint:b2FrictionJoint = frictionJoints[i];
					var force:Number = maxForce;
					
					var v:b2Vec2 = ithFricJoint.m_localAnchorA;
					frictionJointWorldV2.x = col1.x * v.x + col2.x * v.y + p.x;
					frictionJointWorldV2.y = col1.y * v.x + col2.y * v.y + p.y;
					
					for (var j:int = _terrainsBelowThisTang.length - 1; j >= 0; j-- ) 
					{
						var jthTerrain:qb2Terrain = _terrainsBelowThisTang[j];
						
						var terrainBodyB2:b2Body = jthTerrain._bodyB2 ? jthTerrain._bodyB2 : jthTerrain._ancestorBody._bodyB2;
						var xf:XF = terrainBodyB2.GetTransform();
						var pointTouchingTerrain:Boolean = false;
						
						if ( jthTerrain.ubiquitous )
						{
							force *= jthTerrain.frictionZMultiplier;
							pointTouchingTerrain = true;
						}
						else if ( !jthTerrain.ubiquitous && _contactTerrainDict && _contactTerrainDict[jthTerrain] )
						{
							terrainIterator.root = jthTerrain;
							
							while ( terrainIterator.hasNext )
							{
								var object:qb2Object = terrainIterator.next();
								
								if ( object is qb2Shape )
								{
									var asShape:qb2Shape = object as qb2Shape;
									
									if ( !asShape.shapeB2s.length )
									{
										break;
									}
									
									var numTerrainShapeB2s:int = asShape.shapeB2s.length;
									
									for (var k:int = 0; k < numTerrainShapeB2s; k++)
									{
										var kthTerrainShapeB2:b2Shape = asShape.shapeB2s[k];
										
										if ( kthTerrainShapeB2.TestPoint(xf, frictionJointWorldV2) )
										{
											force *= jthTerrain.frictionZMultiplier;
											terrainIterator.clear();
											pointTouchingTerrain = true;
											break;
										}
									}
								}
							}
						}
						
						if ( pointTouchingTerrain )
						{
							break;
						}
					}
					
					ithFricJoint.m_maxForce  = force;
					ithFricJoint.m_maxTorque = 0;
				}
			}
			
			popFromEffectsStack(numToPop);
		}
		
		private static var terrainIterator:qb2TreeTraverser = new qb2TreeTraverser();

		public override function translateBy(vector:amVector2d):qb2Tangible
			{  _rigidImp._position.translateBy(vector);  return this;  }

		public override function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible 
			{  return setTransform(_rigidImp._position.rotateBy(radians, origin), rotation + radians) as qb2Tangible;  }

		public function setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject
			{  return _rigidImp.setTransform(point, rotationInRadians);  }

		public function updateActor():void
			{  _rigidImp.updateActor();  }

		public function get numAttachedJoints():uint
			{  return _rigidImp._attachedJoints ? _rigidImp._attachedJoints.length : 0;  }

		public function getAttachedJointAt(index:uint):qb2Joint
			{  return _rigidImp._attachedJoints ? _rigidImp._attachedJoints[index] : null;  }
			
		public function get attachedMass():Number
			{  return _rigidImp.attachedMass;  }

		public function get position():amPoint2d
			{  return _rigidImp._position;  }
		public function set position(newPoint:amPoint2d):void
			{  setTransform(newPoint, rotation);  }
			
		public function getMetricPosition():amPoint2d
		{
			const pixPer:Number = worldPixelsPerMeter;
			return new amPoint2d(_rigidImp._position.x / pixPer, _rigidImp._position.y / pixPer);
		}

		public function get linearVelocity():amVector2d
			{  return _rigidImp._linearVelocity;  }
		public function set linearVelocity(newVector:amVector2d):void
			{  _rigidImp.setLinearVelocity(newVector);  }
			
		public function get angularVelocity():Number
			{  return _rigidImp._angularVelocity;  }
		public function set angularVelocity(radsPerSec:Number):void
			{  _rigidImp.setAngularVelocity(radsPerSec);  }

		public function getNormal():amVector2d
			{  return amVector2d.newRotVector(0, -1, rotation);  }

		public function get rotation():Number
			{  return _rigidImp._rotation; }
		public function set rotation(value:Number):void
			{  setTransform(_rigidImp._position, value);  }

		public override function drawDebug(graphics:srGraphics2d):void
		{
			if ( frictionJoints && fixtures.length )
			{
				if ( qb2_debugDrawSettings.flags & qb2_debugDrawFlags.FRICTION_Z_POINTS )
				{
					graphics.setLineStyle();
					graphics.beginFill(qb2_debugDrawSettings.frictionPointColor, qb2_debugDrawSettings.frictionPointAlpha);
					var frictionPointRadius:Number = qb2_debugDrawSettings.pointRadius;
					
					var theBodyB2:b2Body = fixtures[0].m_body;
					var transform:b2Transform = theBodyB2.m_xf;
					var p:b2Vec2 = transform.position;
					var r:b2Mat22 = transform.R;
					var col1:b2Vec2 = r.col1;
					var col2:b2Vec2 = r.col2;
					var pixPerMeter:Number = worldPixelsPerMeter;
					
					var numFrictionJoints:int = frictionJoints.length;
					for ( var i:int = 0; i < numFrictionJoints; i++)
					{
						var ithJoint:b2FrictionJoint = frictionJoints[i];
						var v:b2Vec2 = ithJoint.m_localAnchorA;
						
						var x:Number = col1.x * v.x + col2.x * v.y;
						var y:Number = col1.y * v.x + col2.y * v.y;
						
						x += p.x;
						y += p.y;
						
						x *= pixPerMeter;
						y *= pixPerMeter;
						
						graphics.drawCircle(x, y, frictionPointRadius);
					}
					
					graphics.endFill();
				}
			}
		}
		
		public function asTangible():qb2Tangible
			{  return this as qb2Tangible;  }
	
		qb2_friend function registerContactTerrain(terrain:qb2Terrain):void
		{
			if ( !_contactTerrainDict )
			{
				_contactTerrainDict = new Dictionary(true);
				_contactTerrainDict[NUM_TERRAINS] = 0;
			}
			
			_contactTerrainDict[terrain] = true;
			_contactTerrainDict[NUM_TERRAINS]++;
		}
		
		qb2_friend function unregisterContactTerrain(terrain:qb2Terrain):void
		{
			delete _contactTerrainDict[terrain];
			_contactTerrainDict[NUM_TERRAINS]--;
			
			if ( _contactTerrainDict[NUM_TERRAINS] == 0 )
			{
				_contactTerrainDict = null;
			}
		}
		
		qb2_friend var _contactTerrainDict:Dictionary = null;
		
		private static const NUM_TERRAINS:String = "NUM_TERRAINS";
	}
}