package QuickB2.internals 
{
	import As3Math.geo2d.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2InternalLineIntersectionFinder
	{
		private static var traverser:qb2TreeTraverser = new qb2TreeTraverser();
		private static var utilPoint:amPoint2d = new amPoint2d();
		private static var utilLine:amLine2d = new amLine2d();
		private static var utilArray:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		
		private static const INT_TOLERANCE:Number  = .00000001;
		private static const DIST_TOLERANCE:Number = .001;
		private static const INFINITE:Number = 1000000;
		
		qb2_friend static function intersectsLine(rootTang:qb2Tangible, sliceLine:amLine2d, outputPoints:Vector.<amPoint2d> = null, orderPoints:Boolean = true):Boolean
		{
			traverser.root = rootTang;
			utilArray.length = 0;
			var infiniteBeg:amPoint2d = sliceLine.lineType == amLine2d.LINE_TYPE_INFINITE ?
					sliceLine.point1.translatedBy(sliceLine.direction.negate().scaleBy(INFINITE)) :
					sliceLine.point1;
					
			var distanceDict:Dictionary = outputPoints ? new Dictionary(true) : null;
			
			while ( traverser.hasNext )
			{
				var currObject:qb2Object = traverser.next();
				
				if ( !(currObject is qb2Shape) )  continue;
				
				var localSliceLine:amLine2d = currObject.parent && currObject != rootTang ?
						new amLine2d(currObject.parent.getLocalPoint(sliceLine.point1, rootTang), currObject.parent.getLocalPoint(sliceLine.point2, rootTang), sliceLine.lineType) :
						sliceLine;
						
				utilArray.length = 0;
				
				if ( currObject is qb2PolygonShape )
				{
					//--- Compare slice line against each polygon edge to determine intersection.
					var asPoly:qb2PolygonShape = currObject as qb2PolygonShape;
					if ( asPoly.polygon.intersectsLine(localSliceLine, outputPoints ? utilArray : null, INT_TOLERANCE, DIST_TOLERANCE ) )
					{
						if ( !outputPoints )
						{
							return true;
						}
					}
				}
				else
				{
					var asCircle:qb2CircleShape = currObject as qb2CircleShape;
					var geoCircle:amCircle2d = asCircle.asGeoCircle();
					if ( localSliceLine.intersectsCircle(geoCircle, outputPoints ? utilArray : null, INT_TOLERANCE) )
					{
						if ( !outputPoints )
						{
							return true;
						}
					}
				}
				
				for (var i:int = 0; i < utilArray.length; i++ )
				{
					var worldPoint:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(utilArray[i], rootTang.parent) : utilArray[i];
					worldPoint.userData = utilArray[i].userData;
					
					if ( orderPoints )
					{
						insertPointInOrder(worldPoint, outputPoints, distanceDict, infiniteBeg);
					}
					else
					{
						outputPoints.push(worldPoint);
					}
				}
			}
			
			if ( outputPoints && outputPoints.length )
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		qb2_friend static function insertPointInOrder(point:amPoint2d, otherPoints:Vector.<amPoint2d>, distanceDict:Dictionary, basePoint:amPoint2d):amPoint2d
		{
			var distance:Number = 0;
			if ( !distanceDict[point] )
			{
				distance = point.distanceTo(basePoint);
				distanceDict[point] = distance;
			}
			else
			{
				distance = distanceDict[point] as Number;
			}
			
			var inserted:Boolean = false;
			for (var i:int = 0; i < otherPoints.length; i++) 
			{
				if ( distance < distanceDict[otherPoints[i]] )
				{
					otherPoints.splice(i, 0, point);
					inserted = true;
					break;
				}
			}
			
			if ( !inserted )
			{
				otherPoints.push(point);
			}
			
			return point;
		}
	}
}