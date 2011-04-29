package QuickB2.internals 
{
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import Box2DAS.Collision.b2Distance;
	import Box2DAS.Collision.b2DistanceInput;
	import Box2DAS.Collision.b2DistanceOutput;
	import Box2DAS.Collision.Shapes.b2CircleShape;
	import Box2DAS.Common.b2Def;
	import Box2DAS.Common.V2;
	import Box2DAS.Common.XF;
	import Box2DAS.Dynamics.b2Fixture;
	import QuickB2.*;
	import QuickB2.debugging.logging.qb2_errors;
	import QuickB2.debugging.logging.qb2_throw;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	import QuickB2.objects.tangibles.qb2Shape;
	import QuickB2.objects.tangibles.qb2Tangible;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2InternalDistanceQuery 
	{
		private static var pointShape:b2CircleShape;
		
		qb2_friend static function distanceTo(tang1:qb2Tangible, tang2:qb2Tangible, outputVector:amVector2d = null, outputPointtang1:amPoint2d = null, outputPointOther:amPoint2d = null, excludes:Array = null):Number
		{
			//--- Do a bunch of checks for whether tang1 is a legal operation in the first place.
			if ( !tang1.world || !tang2.world )
			{
				qb2_throw(qb2_errors.BAD_DISTANCE_QUERY);
				return NaN;
			}
			if ( tang1 == tang2 )
			{
				qb2_throw(qb2_errors.BAD_DISTANCE_QUERY);
				return NaN;
			}
			if ( tang1 is qb2ObjectContainer )
			{
				if ( tang2.isDescendantOf(tang1 as qb2ObjectContainer) )
				{
					qb2_throw(qb2_errors.BAD_DISTANCE_QUERY);
					return NaN;
				}
			}
			if ( tang2 is qb2ObjectContainer )
			{
				if ( tang1.isDescendantOf(tang2 as qb2ObjectContainer) )
				{
					qb2_throw(qb2_errors.BAD_DISTANCE_QUERY);
					return NaN;
				}
			}
			
			var fixtures1:Array = getFixtures(tang1, excludes);
			var fixtures2:Array = getFixtures(tang2, excludes);
			
			var numFixtures1:int = fixtures1.length;
			var smallest:Number = Number.MAX_VALUE;
			var vec:V2 = null;
			var pointA:amPoint2d = new amPoint2d();
			var pointB:amPoint2d = new amPoint2d();
			
			var din:b2DistanceInput = b2Def.distanceInput;
			var dout:b2DistanceOutput = b2Def.distanceOutput;
			pointShape = pointShape ? pointShape : new b2CircleShape();
			
			for (var i:int = 0; i < numFixtures1; i++) 
			{
				var ithFixture:* = fixtures1[i];
				
				if ( ithFixture is b2Fixture )
				{
					var asFix:b2Fixture = ithFixture as b2Fixture;
					din.proxyA.Set( asFix.m_shape);
					din.transformA.xf = asFix.m_body.GetTransform();
				}
				else
				{
					din.proxyA.Set( pointShape);
					din.transformA.xf = ithFixture as XF;
				}
				
				var numFixtures2:int = fixtures2.length;
				for (var j:int = 0; j < numFixtures2; j++) 
				{
					var jthFixture:* = fixtures2[j];
					
					if ( jthFixture is b2Fixture )
					{
						asFix = jthFixture as b2Fixture;
						din.proxyB.Set( (jthFixture as b2Fixture).m_shape);
						din.transformB.xf = asFix.m_body.GetTransform();
					}
					else
					{
						din.proxyB.Set(pointShape);
						din.transformB.xf = jthFixture as XF;
					}
					
					din.useRadii = true;
					b2Def.simplexCache.count = 0;
					b2Distance();
					var seperation:V2 = dout.pointB.v2.subtract(dout.pointA.v2);
					var distance:Number = seperation.lengthSquared();
					
					if ( distance < smallest )
					{
						smallest = distance;
						vec = seperation;
						pointA.set(dout.pointA.x, dout.pointA.y);
						pointB.set(dout.pointB.x, dout.pointB.y);
					}
				}					
			}
			
			if ( !vec )
			{
				qb2_throw(qb2_errors.BAD_DISTANCE_QUERY);
				return NaN;
			}
			
			var physScale:Number = tang1.worldPixelsPerMeter;
			
			vec.multiplyN(physScale);
			
			if ( outputVector )
			{
				outputVector.set(vec.x, vec.y);
			}
			if ( outputPointtang1 )
			{
				pointA.scaleBy(physScale, physScale);
				outputPointtang1.copy(pointA);
			}
			if ( outputPointOther )
			{
				pointB.scaleBy(physScale, physScale);
				outputPointOther.copy(pointB);
			}
		
			return vec.length();
		}
		
		private static function getFixtures(tang:qb2Tangible, excludes:Array):Array
		{
			var returnFixtures:Array = [];
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(tang);
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( excludes )
				{
					for (var k:int = 0; k < excludes.length; k++) 
					{
						var exclude:* = excludes[k];
						if ( exclude is Class )
						{
							var asClass:Class = exclude as Class;
							if ( object is asClass )
							{
								continue;
							}
						}
						else if ( object == exclude )
						{
							continue;
						}
					}
				}
				
				if ( object is qb2Shape )
				{
					var shapeFixtures:Vector.<b2Fixture> = (object as qb2Shape).fixtures;
					
					for (var i:int = 0; i < shapeFixtures.length; i++) 
					{
						returnFixtures.push(shapeFixtures[i]);
					}
				}
				else if ( object is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = object as qb2ObjectContainer;
					var numObjects:int = asContainer._objects.length;
					var hasTangChildren:Boolean = false;
					for (var j:int = 0; j < numObjects; j++) 
					{
						var jth:qb2Object = asContainer._objects[j];
						if ( jth is qb2Tangible )
						{
							queue.push(jth);
							
							hasTangChildren = true;
						}
					}
					
					if ( !hasTangChildren )
					{
						if ( asContainer._bodyB2 )
						{
							returnFixtures.push(asContainer._bodyB2.GetTransform());
						}
						else
						{
							var worldPnt:amPoint2d = asContainer.getWorldPoint(new amPoint2d());
							var xf:XF = new XF();
							xf.p.x = worldPnt.x / asContainer.worldPixelsPerMeter;
							xf.p.y = worldPnt.y / asContainer.worldPixelsPerMeter;
							returnFixtures.push(xf);
						}
					}
				}
			}
			
			return returnFixtures;
		}
	}
}